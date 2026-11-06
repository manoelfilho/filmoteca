import Foundation
import NetworkCore
import os
import TVDomain

/// Conexão aberta e autorizada com a TV.
struct SamsungTizenSession {
    let connection: any WebSocketConnection
    let replyTimeout: Duration

    /// Abre o canal de controle remoto e espera a TV autorizar.
    ///
    /// - Parameters:
    ///   - token: token de um pareamento anterior (só na porta segura).
    ///   - approvalTimeout: quanto esperar alguém permitir na TV. `nil` não espera
    ///     (a TV não aceita mais o token) e lança `TVError.notPaired`.
    /// - Returns: a sessão e o token atual (a TV pode entregar um novo).
    static func connect(
        host: String,
        token: String?,
        client: any WebSocketClient,
        approvalTimeout: Duration?,
        replyTimeout: Duration
    ) async throws -> (session: SamsungTizenSession, token: String?) {
        for secure in [true, false] {
            guard let url = SamsungTizenMessages.remoteControlURL(host: host, secure: secure, token: token) else {
                throw TVError.invalidHost
            }
            samsungLog.debug("Conectando na porta \(secure ? 8002 : 8001) (token salvo: \(token != nil))")
            // A porta segura usa certificado autoassinado.
            let connection = client.connect(to: url, trustedSelfSignedHost: host)
            do {
                let deadline = ContinuousClock.now + (approvalTimeout ?? replyTimeout)
                guard let authorization = try await connection.receive(until: deadline, accept: authorizationEvent) else {
                    samsungLog.notice("A TV não autorizou dentro do prazo")
                    // A TV está lá, mas ninguém permitiu na tela.
                    throw approvalTimeout == nil ? TVError.notPaired : TVError.pairingTimedOut
                }
                switch authorization {
                case .authorized(let newToken):
                    samsungLog.debug("Autorizado (token novo: \(newToken != nil && newToken != token))")
                    return (SamsungTizenSession(connection: connection, replyTimeout: replyTimeout), newToken ?? token)
                case .rejected:
                    samsungLog.notice("A TV recusou a conexão")
                    await connection.close()
                    throw approvalTimeout == nil ? TVError.notPaired : TVError.pairingRejected
                case .expired:
                    await connection.close()
                    throw TVError.pairingTimedOut
                }
            } catch let error as TVError {
                throw error
            } catch {
                // Porta fechada: TVs mais antigas só têm a 8001.
                samsungLog.debug("Porta \(secure ? 8002 : 8001) indisponível: \(String(describing: error), privacy: .public)")
                await connection.close()
            }
        }
        throw TVError.unreachable
    }

    private enum Authorization: Sendable {
        case authorized(token: String?)
        case rejected
        case expired
    }

    private static func authorizationEvent(_ text: String) throws -> Authorization? {
        let message = try JSONValue.decode(text)
        let event = message["event"]?.stringValue
        switch event {
        case SamsungTizenMessages.Event.connect:
            return .authorized(token: message["data"]?["token"]?.stringValue)
        case SamsungTizenMessages.Event.unauthorized:
            return .rejected
        case SamsungTizenMessages.Event.timeOut:
            return .expired
        default:
            // A TV manda avisos de estado antes da autorização; não interessam aqui.
            samsungLog.debug("Evento ignorado: \(event ?? "?", privacy: .public)")
            return nil
        }
    }

    /// Apps instalados. `nil` quando a TV não responde à lista (vários modelos de 2020
    /// em diante); nesse caso a conexão foi fechada.
    func installedApps() async throws -> [SamsungTizenApp]? {
        try await connection.send(SamsungTizenMessages.installedApps.encoded(), timeout: replyTimeout)
        let deadline = ContinuousClock.now + replyTimeout

        let apps: [SamsungTizenApp]?? = try await connection.receive(until: deadline) { text in
            let message = try JSONValue.decode(text)
            switch message["event"]?.stringValue {
            case SamsungTizenMessages.Event.installedApps:
                return .some((message["data"]?["data"]?.arrayValue ?? []).compactMap { item in
                    guard let id = item["appId"]?.stringValue else { return nil }
                    var appType: Int?
                    if case .number(let value)? = item["app_type"] { appType = Int(value) }
                    return SamsungTizenApp(id: id, name: item["name"]?.stringValue ?? id, appType: appType)
                })
            case SamsungTizenMessages.Event.error:
                return .some(nil)
            default:
                return nil
            }
        }
        let list = apps ?? nil
        samsungLog.debug("Lista de apps: \(list.map { "\($0.count) apps" } ?? "sem resposta", privacy: .public)")
        return list
    }

    /// Pede para abrir o app pelo canal. Muitas TVs não confirmam (nem fazem nada, em
    /// alguns modelos): quem chama confere pela API HTTP se o app abriu.
    /// - Returns: se a TV confirmou a abertura.
    func launch(_ app: SamsungTizenApp, metaTag: String?, confirmationTimeout: Duration) async throws -> Bool {
        samsungLog.debug("Abrindo \(app.id, privacy: .public) (\(app.actionType, privacy: .public), deep link: \(metaTag != nil))")
        try await connection.send(
            SamsungTizenMessages.launch(appID: app.id, actionType: app.actionType, metaTag: metaTag).encoded(),
            timeout: replyTimeout
        )
        let deadline = ContinuousClock.now + confirmationTimeout

        enum Outcome: Sendable { case confirmed, failed(String) }
        let outcome: Outcome? = try await connection.receive(until: deadline) { text in
            let message = try JSONValue.decode(text)
            switch message["event"]?.stringValue {
            case SamsungTizenMessages.Event.launch: return .confirmed
            case SamsungTizenMessages.Event.error: return .failed(message["data"]?["message"]?.stringValue ?? "ed.apps.launch")
            default: return nil
            }
        }
        switch outcome {
        case .confirmed:
            samsungLog.debug("A TV confirmou a abertura")
            return true
        case .failed(let message):
            samsungLog.notice("A TV recusou a abertura: \(message, privacy: .public)")
            throw TVError.commandFailed(message)
        case nil:
            samsungLog.debug("A TV não confirmou a abertura")
            return false
        }
    }

    func close() async {
        await connection.close()
    }
}
