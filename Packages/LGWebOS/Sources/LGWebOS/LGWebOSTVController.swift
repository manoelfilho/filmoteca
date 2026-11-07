import Foundation
import TVDomain

/// Implementação das interfaces de `TVDomain` para TVs LG webOS.
///
/// Cada operação abre uma conexão curta com a TV, faz o que precisa e fecha:
/// o app não mantém conexão aberta com a TV.
public actor LGWebOSTVController {
    private let socketFactory: any LGWebOSSocketFactory
    private let storage: any TVPairingStore
    private let pairingTimeout: Duration
    private let replyTimeout: Duration

    /// - Parameter pairingTimeout: quanto esperar alguém aceitar o pedido na tela da TV.
    public init(pairingTimeout: Duration = .seconds(60)) {
        self.init(
            socketFactory: WebSocketLGWebOSSocketFactory(),
            storage: KeychainTVPairingStore(
                service: "Filmoteca.LGWebOS",
                // Nome anterior do app: os pareamentos já feitos passam para o novo nome.
                legacyServices: ["SuperApp.LGWebOS"]
            ),
            pairingTimeout: pairingTimeout
        )
    }

    init(
        socketFactory: any LGWebOSSocketFactory,
        storage: any TVPairingStore,
        pairingTimeout: Duration = .seconds(60),
        replyTimeout: Duration = .seconds(10)
    ) {
        self.socketFactory = socketFactory
        self.storage = storage
        self.pairingTimeout = pairingTimeout
        self.replyTimeout = replyTimeout
    }

    static let platform = "webOS"

    private func withSession<T>(host: String, _ body: (inout LGWebOSSession) async throws -> T) async throws -> T {
        let socket = try await socketFactory.open(host: host)
        var session = LGWebOSSession(socket: socket, replyTimeout: replyTimeout)
        do {
            let result = try await body(&session)
            await socket.close()
            return result
        } catch {
            await socket.close()
            throw error
        }
    }
}

// MARK: - Interfaces de TVDomain

extension LGWebOSTVController: TVPlatformController {
    public nonisolated var platform: String { Self.platform }

    /// Uma TV webOS responde ao `hello` sem pedir pareamento.
    public func recognizesTV(at host: String) async -> Bool {
        guard let socket = try? await socketFactory.open(host: host) else { return false }
        await socket.close()
        return true
    }
}

extension LGWebOSTVController: PairTV {
    public func pairTV(host input: String) async throws -> TVDevice {
        guard let host = TVHost.normalize(input) else { throw TVError.invalidHost }
        let previousKey = try storage.load().first { $0.device.host == host }?.credential

        let (clientKey, modelName) = try await withSession(host: host) { session in
            // TVs mais novas exigem a consulta de sistema antes do registro.
            let info = try? await session.request(LGWebOSMessages.systemInfoURI)
            let key = try await session.register(clientKey: previousKey, promptTimeout: pairingTimeout)
            return (key, info?["modelName"]?.stringValue)
        }

        let device = TVDevice(
            id: host,
            name: modelName.map { "LG \($0)" } ?? "LG TV (\(host))",
            host: host,
            platform: Self.platform
        )
        var pairings = try storage.load().filter { $0.device.id != device.id }
        pairings.insert(TVPairing(device: device, credential: clientKey), at: 0)
        try storage.save(pairings)
        return device
    }
}

extension LGWebOSTVController: ListPairedTVs {
    public func listPairedTVs() throws -> [TVDevice] {
        try storage.load().sorted { $0.pairedAt > $1.pairedAt }.map(\.device)
    }
}

extension LGWebOSTVController: ForgetTV {
    public func forgetTV(id: TVDevice.ID) throws {
        try storage.save(storage.load().filter { $0.device.id != id })
    }
}

extension LGWebOSTVController: LaunchOnTV {
    public func launchOnTV(_ request: TVLaunchRequest, on device: TVDevice) async throws -> TVLaunchResult {
        guard let pairing = try storage.load().first(where: { $0.device.id == device.id }) else {
            throw TVError.notPaired
        }

        return try await withSession(host: pairing.device.host) { session in
            // Sem esperar confirmação: se a TV pedir de novo, o pareamento foi desfeito nela.
            _ = try await session.register(clientKey: pairing.credential, promptTimeout: nil)

            let payload = try await session.request(LGWebOSMessages.listAppsURI)
            let apps = (payload["launchPoints"]?.arrayValue ?? []).compactMap { item -> LGWebOSApp? in
                guard let id = item["id"]?.stringValue else { return nil }
                return LGWebOSApp(id: id, title: item["title"]?.stringValue ?? id)
            }
            guard let app = LGWebOSAppResolver.app(for: request.serviceName, in: apps) else {
                throw TVError.appNotInstalled(serviceName: request.serviceName)
            }

            if let contentID = LGWebOSAppResolver.contentID(appID: app.id, webURL: request.webURL) {
                _ = try await session.request(
                    LGWebOSMessages.launchAppURI,
                    payload: ["id": .string(app.id), "contentId": .string(contentID)]
                )
                return .openedContent
            }
            _ = try await session.request(LGWebOSMessages.launchAppURI, payload: ["id": .string(app.id)])
            return .openedApp
        }
    }
}
