import Foundation
import NetworkCore
import os
import TVDomain

/// Implementação das interfaces de `TVDomain` para TVs Samsung (Tizen).
///
/// Cada operação abre uma conexão curta com a TV, faz o que precisa e fecha.
public actor SamsungTizenTVController {
    static let platform = "Tizen"

    private let webSocketClient: any WebSocketClient
    private let httpClient: any HTTPClient
    private let storage: any TVPairingStore
    private let pairingTimeout: Duration
    private let replyTimeout: Duration
    private let launchConfirmationTimeout: Duration
    private let launchCheckDelay: Duration
    private let restRetryDelay: Duration

    /// - Parameters:
    ///   - httpClient: usado para identificar a TV e conferir apps instalados.
    ///   - pairingTimeout: quanto esperar alguém permitir o acesso na tela da TV.
    public init(httpClient: any HTTPClient, pairingTimeout: Duration = .seconds(60)) {
        self.init(
            webSocketClient: URLSessionWebSocketClient(),
            httpClient: httpClient,
            storage: KeychainTVPairingStore(
                service: "Filmoteca.SamsungTizen",
                // Nome anterior do app: os pareamentos já feitos passam para o novo nome.
                legacyServices: ["SuperApp.SamsungTizen"]
            ),
            pairingTimeout: pairingTimeout
        )
    }

    init(
        webSocketClient: any WebSocketClient,
        httpClient: any HTTPClient,
        storage: any TVPairingStore,
        pairingTimeout: Duration = .seconds(60),
        replyTimeout: Duration = .seconds(5),
        launchConfirmationTimeout: Duration = .seconds(3),
        launchCheckDelay: Duration = .milliseconds(1500),
        restRetryDelay: Duration = .seconds(1)
    ) {
        self.webSocketClient = webSocketClient
        self.httpClient = httpClient
        self.storage = storage
        self.pairingTimeout = pairingTimeout
        self.replyTimeout = replyTimeout
        self.launchConfirmationTimeout = launchConfirmationTimeout
        self.launchCheckDelay = launchCheckDelay
        self.restRetryDelay = restRetryDelay
    }

    // MARK: - API HTTP da TV

    private struct DeviceInfo {
        let name: String?
        let isSamsungTV: Bool
    }

    private func deviceInfo(host: String) async -> DeviceInfo? {
        guard let url = SamsungTizenMessages.restBaseURL(host: host),
              let response = try? await httpClient.send(HTTPRequest(baseURL: url, path: "", timeout: 3)),
              response.isSuccess,
              let json = try? JSONValue.decode(String(decoding: response.data, as: UTF8.self))
        else { return nil }

        let type = json["type"]?.stringValue ?? json["device"]?["type"]?.stringValue ?? ""
        // "[TV] Samsung Q60 Series (55)" → "Samsung Q60 Series (55)"
        let name = (json["device"]?["name"]?.stringValue ?? json["name"]?.stringValue)?
            .replacingOccurrences(of: "[TV]", with: "")
            .trimmingCharacters(in: .whitespaces)
        return DeviceInfo(name: name?.isEmpty == false ? name : nil, isSamsungTV: type.localizedCaseInsensitiveContains("samsung"))
    }

    /// Para TVs que não informam a lista de apps: confere os IDs conhecidos um a um.
    private func installedKnownApps(for serviceName: String, host: String) async -> [SamsungTizenApp] {
        guard let base = SamsungTizenMessages.restBaseURL(host: host) else { return [] }
        // Para no primeiro encontrado: a API HTTP da TV é lenta e, com muitas consultas
        // seguidas, chega a recusar conexões por alguns segundos.
        for id in SamsungTizenAppResolver.knownIDs(for: serviceName) {
            let request = HTTPRequest(baseURL: base, path: "applications/\(id)", timeout: 3)
            if let response = try? await httpClient.send(request), response.isSuccess {
                samsungLog.debug("App \(id, privacy: .public) instalado")
                return [SamsungTizenApp(id: id, name: serviceName)]
            }
        }
        return []
    }

    /// Falhas de rede no meio de um comando chegam a quem usa as interfaces como erro de TV.
    private func mappingNetworkErrors<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch is NetworkError {
            throw TVError.unreachable
        }
    }

    enum AppStatus: Equatable {
        /// Aberto na tela.
        case visible
        /// Fechado, ou rodando em segundo plano (a Samsung deixa a Netflix assim).
        case notVisible
        /// A TV respondeu, mas não informa o estado do app.
        case unknown
        /// A API HTTP não respondeu.
        case unreachable
    }

    /// Estado do app pela API HTTP. "Rodando" não basta: o que interessa é estar na tela.
    private func appStatus(_ appID: String, host: String) async -> AppStatus {
        guard let base = SamsungTizenMessages.restBaseURL(host: host),
              let response = try? await httpClient.send(HTTPRequest(baseURL: base, path: "applications/\(appID)", timeout: 3))
        else { return .unreachable }
        guard response.isSuccess, let json = try? JSONValue.decode(String(decoding: response.data, as: UTF8.self)) else {
            return .unknown
        }
        if let visible = json["visible"]?.boolValue {
            return visible ? .visible : .notVisible
        }
        if let running = json["running"]?.boolValue {
            return running ? .visible : .notVisible
        }
        return .unknown
    }

    /// Abre o app pela API HTTP (sem deep link). Funciona em modelos que ignoram o pedido pelo canal.
    /// Tenta de novo uma vez: a API HTTP da TV às vezes recusa conexões por alguns segundos.
    private func launchViaREST(_ appID: String, host: String) async -> Bool {
        guard let base = SamsungTizenMessages.restBaseURL(host: host) else { return false }
        let request = HTTPRequest(baseURL: base, path: "applications/\(appID)", method: .post, timeout: 5)
        for attempt in 1...2 {
            if let response = try? await httpClient.send(request) {
                samsungLog.debug("Abertura pela API HTTP: status \(response.statusCode)")
                return response.isSuccess
            }
            samsungLog.notice("API HTTP não respondeu (tentativa \(attempt))")
            if attempt == 1 { try? await Task.sleep(for: restRetryDelay) }
        }
        return false
    }

    private func connect(host: String, token: String?, approvalTimeout: Duration?) async throws -> (SamsungTizenSession, String?) {
        try await SamsungTizenSession.connect(
            host: host,
            token: token,
            client: webSocketClient,
            approvalTimeout: approvalTimeout,
            replyTimeout: replyTimeout
        )
    }
}

// MARK: - Interfaces de TVDomain

extension SamsungTizenTVController: TVPlatformController {
    public nonisolated var platform: String { Self.platform }

    /// A TV Samsung se identifica pela API HTTP, sem pedir permissão.
    public func recognizesTV(at host: String) async -> Bool {
        await deviceInfo(host: host)?.isSamsungTV == true
    }
}

extension SamsungTizenTVController: PairTV {
    public func pairTV(host input: String) async throws -> TVDevice {
        try await mappingNetworkErrors { try await pair(host: input) }
    }

    private func pair(host input: String) async throws -> TVDevice {
        guard let host = TVHost.normalize(input) else { throw TVError.invalidHost }
        // Sem resposta HTTP, não há TV Samsung ligada no endereço: nem abre o canal (que esperaria o aceite).
        guard let info = await deviceInfo(host: host) else { throw TVError.unreachable }
        let previousToken = try storage.load().first { $0.device.host == host }?.credential

        let (session, token) = try await connect(host: host, token: previousToken, approvalTimeout: pairingTimeout)
        await session.close()

        let device = TVDevice(id: host, name: info.name ?? "Samsung TV (\(host))", host: host, platform: Self.platform)
        var pairings = try storage.load().filter { $0.device.id != device.id }
        pairings.insert(TVPairing(device: device, credential: token), at: 0)
        try storage.save(pairings)
        return device
    }
}

extension SamsungTizenTVController: ListPairedTVs {
    public func listPairedTVs() throws -> [TVDevice] {
        try storage.load().sorted { $0.pairedAt > $1.pairedAt }.map(\.device)
    }
}

extension SamsungTizenTVController: ForgetTV {
    public func forgetTV(id: TVDevice.ID) throws {
        try storage.save(storage.load().filter { $0.device.id != id })
    }
}

extension SamsungTizenTVController: LaunchOnTV {
    public func launchOnTV(_ request: TVLaunchRequest, on device: TVDevice) async throws -> TVLaunchResult {
        try await mappingNetworkErrors { try await launch(request, on: device) }
    }

    private func launch(_ request: TVLaunchRequest, on device: TVDevice) async throws -> TVLaunchResult {
        guard let pairing = try storage.load().first(where: { $0.device.id == device.id }) else {
            throw TVError.notPaired
        }
        let host = pairing.device.host

        // TV desligada não responde no canal, o que pareceria token recusado. Confere antes.
        guard await deviceInfo(host: host) != nil else { throw TVError.unreachable }

        var (session, token) = try await connect(host: host, token: pairing.credential, approvalTimeout: nil)
        if token != pairing.credential {
            var pairings = try storage.load()
            if let index = pairings.firstIndex(where: { $0.device.id == device.id }) {
                pairings[index].credential = token
                try storage.save(pairings)
            }
        }

        let apps: [SamsungTizenApp]
        if let listed = try await session.installedApps() {
            apps = listed
        } else {
            // Sem lista, a conexão foi fechada: confere os apps conhecidos e reconecta para abrir.
            apps = await installedKnownApps(for: request.serviceName, host: host)
            (session, _) = try await connect(host: host, token: token, approvalTimeout: nil)
        }

        guard let app = SamsungTizenAppResolver.app(for: request.serviceName, in: apps) else {
            await session.close()
            throw TVError.appNotInstalled(serviceName: request.serviceName)
        }

        let metaTag = SamsungTizenAppResolver.metaTag(appID: app.id, webURL: request.webURL)
        let result: TVLaunchResult = metaTag == nil ? .openedApp : .openedContent
        let confirmed: Bool
        do {
            confirmed = try await session.launch(app, metaTag: metaTag, confirmationTimeout: launchConfirmationTimeout)
            await session.close()
        } catch {
            await session.close()
            throw error
        }
        if confirmed { return result }

        // Sem confirmação: confere se o app apareceu na tela; se não, abre pela API HTTP.
        try await Task.sleep(for: launchCheckDelay)
        let status = await appStatus(app.id, host: host)
        samsungLog.debug("Estado do app após o pedido pelo canal: \(String(describing: status), privacy: .public)")
        if status == .visible {
            return result
        }

        samsungLog.notice("O app não apareceu pelo canal; abrindo pela API HTTP")
        guard await launchViaREST(app.id, host: host) else {
            // Sem confirmação pelo canal e sem a API HTTP: não dá para dizer que abriu.
            throw status == .unreachable ? TVError.unreachable : TVError.commandFailed("The TV didn't open \(app.id)")
        }
        // Pela API HTTP não há deep link: abre só o app.
        return .openedApp
    }
}
