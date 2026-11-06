import Foundation
import NetworkCore
import TVDomain

/// Conexão com a TV em mensagens JSON. Abstraída para os testes simularem a TV.
protocol LGWebOSSocket: Sendable {
    func send(_ message: JSONValue) async throws
    /// Espera a próxima mensagem da TV. Ao passar do tempo, fecha a conexão e lança `LGWebOSTimeout`.
    func receive(timeout: Duration) async throws -> JSONValue
    func close() async
}

protocol LGWebOSSocketFactory: Sendable {
    /// Abre a conexão e confirma que do outro lado há uma TV webOS (mensagem `hello`).
    func open(host: String) async throws -> any LGWebOSSocket
}

struct LGWebOSTimeout: Error {}

// MARK: - WebSocket do NetworkCore

/// Abre `ws://host:3000` e, se a TV recusar, `wss://host:3001` (TVs mais novas só aceitam a segura).
struct WebSocketLGWebOSSocketFactory: LGWebOSSocketFactory {
    var client: any WebSocketClient = URLSessionWebSocketClient()
    var helloTimeout: Duration = .seconds(5)

    func open(host: String) async throws -> any LGWebOSSocket {
        for url in [URL(string: "ws://\(host):3000"), URL(string: "wss://\(host):3001")].compactMap({ $0 }) {
            // A TV usa certificado autoassinado na porta segura.
            let connection = client.connect(to: url, trustedSelfSignedHost: host)
            do {
                let reply = try JSONValue.decode(
                    try await connection.send(LGWebOSMessages.hello.encoded(), awaitingReplyWithin: helloTimeout)
                )
                guard reply["type"]?.stringValue == "hello" else { throw TVError.unreachable }
                return WebSocketLGWebOSSocket(connection: connection)
            } catch {
                await connection.close()
            }
        }
        throw TVError.unreachable
    }
}

struct WebSocketLGWebOSSocket: LGWebOSSocket {
    let connection: any WebSocketConnection

    func send(_ message: JSONValue) async throws {
        do {
            try await connection.send(message.encoded())
        } catch is NetworkError {
            throw TVError.unreachable
        }
    }

    func receive(timeout: Duration) async throws -> JSONValue {
        do {
            return try JSONValue.decode(try await connection.receive(timeout: timeout))
        } catch NetworkError.timeout {
            throw LGWebOSTimeout()
        } catch is NetworkError {
            throw TVError.unreachable
        }
    }

    func close() async {
        await connection.close()
    }
}
