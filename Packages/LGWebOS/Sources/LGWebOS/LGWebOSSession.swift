import Foundation
import NetworkCore
import TVDomain

/// Conversa com uma TV já conectada: registro (pareamento) e comandos.
struct LGWebOSSession {
    let socket: any LGWebOSSocket
    var replyTimeout: Duration = .seconds(10)
    private var counter = 0

    init(socket: any LGWebOSSocket, replyTimeout: Duration = .seconds(10)) {
        self.socket = socket
        self.replyTimeout = replyTimeout
    }

    /// Registra o app na TV e devolve a chave do pareamento.
    ///
    /// - Parameters:
    ///   - clientKey: chave de um pareamento anterior. Sem ela, a TV pede confirmação na tela.
    ///   - promptTimeout: quanto esperar alguém aceitar na TV. `nil` não aceita novo pedido
    ///     (a chave salva não vale mais) e lança `TVError.notPaired`.
    func register(clientKey: String?, promptTimeout: Duration?) async throws -> String {
        try await socket.send(LGWebOSMessages.register(clientKey: clientKey))

        // Depois que a TV mostra o pedido na tela, a espera é pela pessoa, não pela rede.
        // O prazo vale para a etapa toda: mensagens que não interessam não o renovam.
        var isWaitingForPrompt = false
        var deadline = ContinuousClock.now + replyTimeout
        while true {
            let message: JSONValue
            do {
                message = try await receive(until: deadline)
            } catch is LGWebOSTimeout {
                throw isWaitingForPrompt ? TVError.pairingTimedOut : TVError.unreachable
            }

            switch message["type"]?.stringValue {
            case "registered":
                guard let key = message["payload"]?["client-key"]?.stringValue else {
                    throw TVError.commandFailed("Missing client-key")
                }
                return key
            case "response" where message["payload"]?["pairingType"]?.stringValue == "PROMPT":
                guard let promptTimeout else { throw TVError.notPaired }
                isWaitingForPrompt = true
                deadline = ContinuousClock.now + promptTimeout
            case "error":
                let error = message["error"]?.stringValue ?? ""
                throw error.localizedCaseInsensitiveContains("cancel") || error.localizedCaseInsensitiveContains("reject")
                    || error.localizedCaseInsensitiveContains("denied")
                    ? TVError.pairingRejected : TVError.commandFailed(error)
            default:
                continue
            }
        }
    }

    /// Envia um comando e devolve o `payload` da resposta.
    mutating func request(_ uri: String, payload: [String: JSONValue] = [:]) async throws -> JSONValue {
        counter += 1
        let id = "req_\(counter)"
        try await socket.send(LGWebOSMessages.request(id: id, uri: uri, payload: payload))

        let deadline = ContinuousClock.now + replyTimeout
        while true {
            let message: JSONValue
            do {
                message = try await receive(until: deadline)
            } catch is LGWebOSTimeout {
                throw TVError.unreachable
            }
            guard message["id"]?.stringValue == id else { continue }

            if message["type"]?.stringValue == "error" {
                throw TVError.commandFailed(message["error"]?.stringValue ?? uri)
            }
            let payload = message["payload"] ?? [:]
            if payload["returnValue"]?.boolValue == false {
                throw TVError.commandFailed(payload["errorText"]?.stringValue ?? uri)
            }
            return payload
        }
    }

    /// Próxima mensagem dentro do prazo da etapa.
    private func receive(until deadline: ContinuousClock.Instant) async throws -> JSONValue {
        let remaining = deadline - ContinuousClock.now
        guard remaining > .zero else {
            await socket.close()
            throw LGWebOSTimeout()
        }
        return try await socket.receive(timeout: remaining)
    }
}
