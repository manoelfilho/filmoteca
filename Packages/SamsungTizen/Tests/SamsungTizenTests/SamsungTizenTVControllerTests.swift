import Foundation
import NetworkCore
@testable import SamsungTizen
import Testing
import TVDomain

@Suite("Samsung Tizen: pareamento e abertura de apps")
struct SamsungTizenTVControllerTests {
    static let device = TVDevice(id: "192.168.0.30", name: "Samsung Q60", host: "192.168.0.30", platform: "Tizen")

    func makeController(_ tv: FakeSamsungTV, storage: InMemoryTVPairingStore = InMemoryTVPairingStore()) -> SamsungTizenTVController {
        SamsungTizenTVController(
            webSocketClient: tv,
            httpClient: tv,
            storage: storage,
            pairingTimeout: .seconds(1),
            replyTimeout: .seconds(1),
            launchConfirmationTimeout: .milliseconds(10),
            launchCheckDelay: .zero,
            restRetryDelay: .zero
        )
    }

    func paired(token: String? = "TOKEN-1") -> InMemoryTVPairingStore {
        InMemoryTVPairingStore([TVPairing(device: Self.device, credential: token)])
    }

    @Test("Reconhece a TV pela API HTTP")
    func recognizes() async {
        #expect(await makeController(FakeSamsungTV()).recognizesTV(at: "192.168.0.30"))

        var options = FakeSamsungTV.Options()
        options.deviceJSON = #"{"type":"Other"}"#
        #expect(await makeController(FakeSamsungTV(options)).recognizesTV(at: "192.168.0.30") == false)
    }

    @Test("Pareamento: porta segura, nome em base64, token salvo e nome do aparelho")
    func pairing() async throws {
        let tv = FakeSamsungTV()
        let storage = InMemoryTVPairingStore()

        let device = try await makeController(tv, storage: storage).pairTV(host: "192.168.0.30")

        #expect(device.name == "Samsung Q60 Series (55)")
        #expect(device.platform == "Tizen")
        #expect(try storage.load().map(\.credential) == ["TOKEN-1"])
        let url = try #require(tv.connectedURLs.first)
        #expect(url.scheme == "wss")
        #expect(url.port == 8002)
        #expect(url.path() == "/api/v2/channels/samsung.remote.control")
        #expect(url.query(percentEncoded: false)?.contains("name=U3VwZXJBcHA=") == true)
    }

    @Test("TV antiga: sem porta segura, usa a 8001")
    func legacyPort() async throws {
        var options = FakeSamsungTV.Options()
        options.secureClosed = true
        options.token = nil
        let tv = FakeSamsungTV(options)

        _ = try await makeController(tv).pairTV(host: "192.168.0.30")
        #expect(tv.connectedURLs.map(\.port) == [8002, 8001])
    }

    @Test("Pedido recusado ou sem resposta na TV")
    func pairingFailures() async throws {
        var rejected = FakeSamsungTV.Options()
        rejected.authorization = SamsungTizenMessages.Event.unauthorized
        await #expect(throws: TVError.pairingRejected) {
            try await makeController(FakeSamsungTV(rejected)).pairTV(host: "192.168.0.30")
        }

        var ignored = FakeSamsungTV.Options()
        ignored.authorization = nil
        await #expect(throws: TVError.pairingTimedOut) {
            try await makeController(FakeSamsungTV(ignored)).pairTV(host: "192.168.0.30")
        }
    }

    @Test("Netflix: abre direto no filme com o token salvo")
    func launchNetflix() async throws {
        let tv = FakeSamsungTV()
        let result = try await makeController(tv, storage: paired()).launchOnTV(
            TVLaunchRequest(serviceName: "Netflix", webURL: URL(string: "https://www.netflix.com/title/26004747")),
            on: Self.device
        )

        #expect(result == .openedContent)
        let data = try #require(tv.launches.last?["params"]?["data"])
        #expect(data["appId"]?.stringValue == "3201907018807")
        #expect(data["action_type"]?.stringValue == "DEEP_LINK")
        #expect(data["metaTag"]?.stringValue == "m=26004747&source_type=4")
        #expect(tv.connectedURLs.first?.query()?.contains("token=TOKEN-1") == true)
    }

    @Test("Outros serviços abrem só o app; canal \"via\" abre o app indicado")
    func launchApp() async throws {
        let tv = FakeSamsungTV()
        let controller = makeController(tv, storage: paired())

        #expect(try await controller.launchOnTV(TVLaunchRequest(serviceName: "Disney Plus"), on: Self.device) == .openedApp)
        #expect(tv.launches.last?["params"]?["data"]?["appId"]?.stringValue == "3201901017640")

        _ = try await controller.launchOnTV(TVLaunchRequest(serviceName: "MAX (Via Amazon Prime)"), on: Self.device)
        #expect(tv.launches.last?["params"]?["data"]?["appId"]?.stringValue == "3201910019365")
    }

    @Test("TV que não lista apps: confere os IDs conhecidos pela API HTTP e reconecta")
    func launchWithoutAppList() async throws {
        var options = FakeSamsungTV.Options()
        options.listsApps = false
        let tv = FakeSamsungTV(options)

        let result = try await makeController(tv, storage: paired()).launchOnTV(
            TVLaunchRequest(serviceName: "Netflix", webURL: URL(string: "https://www.netflix.com/title/26004747")),
            on: Self.device
        )

        #expect(result == .openedContent)
        #expect(tv.httpPaths.contains { $0.hasSuffix("/api/v2/applications/3201907018807") })
        #expect(tv.connectedURLs.count == 2)
    }

    @Test("Erros: app ausente, TV recusa o token, TV desconhecida, TV desligada, erro ao abrir")
    func launchFailures() async throws {
        await #expect(throws: TVError.appNotInstalled(serviceName: "Globoplay")) {
            try await makeController(FakeSamsungTV(), storage: paired()).launchOnTV(TVLaunchRequest(serviceName: "Globoplay"), on: Self.device)
        }

        var revoked = FakeSamsungTV.Options()
        revoked.authorization = SamsungTizenMessages.Event.unauthorized
        await #expect(throws: TVError.notPaired) {
            try await makeController(FakeSamsungTV(revoked), storage: paired()).launchOnTV(TVLaunchRequest(serviceName: "Netflix"), on: Self.device)
        }

        await #expect(throws: TVError.notPaired) {
            try await makeController(FakeSamsungTV()).launchOnTV(TVLaunchRequest(serviceName: "Netflix"), on: Self.device)
        }

        var off = FakeSamsungTV.Options()
        off.deviceJSON = ""
        off.authorization = nil
        let offTV = FakeSamsungTV(off)
        offTV.isOff = true
        await #expect(throws: TVError.unreachable) {
            try await makeController(offTV, storage: paired()).launchOnTV(TVLaunchRequest(serviceName: "Netflix"), on: Self.device)
        }
        #expect(offTV.connectedURLs.isEmpty)

        var failing = FakeSamsungTV.Options()
        failing.launchError = "unrecognized method"
        await #expect(throws: TVError.commandFailed("unrecognized method")) {
            try await makeController(FakeSamsungTV(failing), storage: paired()).launchOnTV(TVLaunchRequest(serviceName: "Netflix"), on: Self.device)
        }
    }

    @Test("Sem confirmação pelo canal: confere pela API HTTP que o app abriu")
    func unconfirmedButRunning() async throws {
        var options = FakeSamsungTV.Options()
        options.confirmsLaunch = false
        let tv = FakeSamsungTV(options)

        let result = try await makeController(tv, storage: paired()).launchOnTV(
            TVLaunchRequest(serviceName: "Netflix", webURL: URL(string: "https://www.netflix.com/title/26004747")),
            on: Self.device
        )
        #expect(result == .openedContent)
        #expect(tv.restLaunches.isEmpty)
    }

    @Test("TV que ignora o pedido pelo canal: abre o app pela API HTTP")
    func channelIgnoredFallsBackToREST() async throws {
        var options = FakeSamsungTV.Options()
        options.confirmsLaunch = false
        options.opensAppFromChannel = false
        let tv = FakeSamsungTV(options)

        let result = try await makeController(tv, storage: paired()).launchOnTV(
            TVLaunchRequest(serviceName: "Netflix", webURL: URL(string: "https://www.netflix.com/title/26004747")),
            on: Self.device
        )
        #expect(result == .openedApp)
        #expect(tv.restLaunches == ["applications/3201907018807"])
    }

    @Test("TV que não informa o estado dos apps: abre também pela API HTTP")
    func noStatusFallsBackToREST() async throws {
        var options = FakeSamsungTV.Options()
        options.confirmsLaunch = false
        options.reportsAppStatus = false
        let tv = FakeSamsungTV(options)

        _ = try await makeController(tv, storage: paired()).launchOnTV(TVLaunchRequest(serviceName: "Disney+"), on: Self.device)
        #expect(tv.restLaunches == ["applications/3201901017640"])
    }

    @Test("TV que manda avisos sem parar não trava a abertura")
    func noisyTVDoesNotHang() async throws {
        var options = FakeSamsungTV.Options()
        options.isNoisy = true
        options.listsApps = false
        options.confirmsLaunch = false
        let tv = FakeSamsungTV(options)
        let controller = SamsungTizenTVController(
            webSocketClient: tv,
            httpClient: tv,
            storage: paired(),
            replyTimeout: .milliseconds(200),
            launchConfirmationTimeout: .milliseconds(200),
            launchCheckDelay: .zero
        )

        let start = ContinuousClock.now
        let result = try await controller.launchOnTV(
            TVLaunchRequest(serviceName: "Netflix", webURL: URL(string: "https://www.netflix.com/title/26004747")),
            on: Self.device
        )
        #expect(result == .openedContent)
        #expect(ContinuousClock.now - start < .seconds(3))
    }

    @Test("Netflix rodando em segundo plano não conta como aberta: abre pela API HTTP (caso da TU8000)")
    func backgroundNetflixIsNotOpen() async throws {
        var options = FakeSamsungTV.Options()
        options.listsApps = false
        options.confirmsLaunch = false
        options.opensAppFromChannel = false
        options.backgroundApps = ["3201907018807"]
        let tv = FakeSamsungTV(options)

        let result = try await makeController(tv, storage: paired()).launchOnTV(
            TVLaunchRequest(serviceName: "Netflix", webURL: URL(string: "https://www.netflix.com/title/26004747")),
            on: Self.device
        )
        #expect(result == .openedApp)
        #expect(tv.restLaunches == ["applications/3201907018807"])
        // Achou a Netflix no primeiro ID conhecido: não consulta o ID antigo.
        #expect(!tv.httpPaths.contains { $0.hasSuffix("/applications/11101200001") })
    }

    @Test("Sem confirmação e com a API HTTP recusando: erro, não sucesso")
    func refusedRESTIsAnError() async throws {
        var options = FakeSamsungTV.Options()
        options.confirmsLaunch = false
        options.opensAppFromChannel = false
        options.restRefuses = true
        let tv = FakeSamsungTV(options)

        await #expect(throws: TVError.unreachable) {
            try await makeController(tv, storage: paired()).launchOnTV(TVLaunchRequest(serviceName: "Netflix"), on: Self.device)
        }
    }
}
