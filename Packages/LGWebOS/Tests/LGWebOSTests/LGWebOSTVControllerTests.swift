import Foundation
import NetworkCore
@testable import LGWebOS
import Testing
import TVDomain

@Suite("LG webOS: pareamento e abertura de apps")
struct LGWebOSTVControllerTests {
    static let device = TVDevice(id: "192.168.0.20", name: "LG OLED55C1", host: "192.168.0.20", platform: "webOS")
    static let pairing = TVPairing(device: device, credential: "KEY")

    func makeController(tv: FakeTV, storage: InMemoryTVPairingStore = InMemoryTVPairingStore()) -> LGWebOSTVController {
        LGWebOSTVController(socketFactory: tv, storage: storage, pairingTimeout: .seconds(1), replyTimeout: .seconds(1))
    }

    @Test("Pareamento: espera o aceite na TV, salva a chave e usa o modelo como nome")
    func pairing() async throws {
        let tv = FakeTV { message in
            switch message["type"]?.stringValue {
            case "request":
                return [FakeTV.reply(to: message, payload: ["returnValue": true, "modelName": "OLED55C1PSA"])]
            case "register":
                // Primeiro a TV avisa que mostrou o pedido; depois alguém aceita.
                return [
                    ["id": "register_0", "type": "response", "payload": ["pairingType": "PROMPT"]],
                    ["id": "register_0", "type": "registered", "payload": ["client-key": "NEW-KEY"]],
                ]
            default:
                return []
            }
        }
        let storage = InMemoryTVPairingStore()

        let device = try await makeController(tv: tv, storage: storage).pairTV(host: " http://192.168.0.20:3000 ")

        #expect(tv.openedHosts == ["192.168.0.20"])
        #expect(device.name == "LG OLED55C1PSA")
        #expect(device.platform == "webOS")
        #expect(try storage.load().map(\.credential) == ["NEW-KEY"])
        #expect(tv.sent.first { $0["type"]?.stringValue == "register" }?["payload"]?["client-key"] == nil)
    }

    @Test("Pareamento recusado ou sem resposta na TV")
    func pairingFailures() async throws {
        let rejected = FakeTV { message in
            message["type"]?.stringValue == "register"
                ? [["id": "register_0", "type": "error", "error": "403 User denied access"]] : []
        }
        await #expect(throws: TVError.pairingRejected) {
            try await makeController(tv: rejected).pairTV(host: "192.168.0.20")
        }

        let ignored = FakeTV { message in
            message["type"]?.stringValue == "register"
                ? [["id": "register_0", "type": "response", "payload": ["pairingType": "PROMPT"]]] : []
        }
        await #expect(throws: TVError.pairingTimedOut) {
            try await makeController(tv: ignored).pairTV(host: "192.168.0.20")
        }
    }

    @Test("Endereço inválido nem tenta conectar")
    func invalidHost() async throws {
        let tv = FakeTV.paired()
        await #expect(throws: TVError.invalidHost) {
            try await makeController(tv: tv).pairTV(host: "minha tv/sala")
        }
        #expect(tv.openedHosts.isEmpty)
    }

    @Test("Netflix: abre o app direto no filme a partir do link web")
    func launchNetflixContent() async throws {
        let tv = FakeTV.paired()
        let controller = makeController(tv: tv, storage: InMemoryTVPairingStore([Self.pairing]))

        let result = try await controller.launchOnTV(
            TVLaunchRequest(serviceName: "Netflix", webURL: URL(string: "https://www.netflix.com/title/26004747")),
            on: Self.device
        )

        #expect(result == .openedContent)
        let launch = try #require(tv.sentRequests.last)
        #expect(launch["uri"]?.stringValue == LGWebOSMessages.launchAppURI)
        #expect(launch["payload"]?["id"]?.stringValue == "netflix")
        #expect(launch["payload"]?["contentId"]?.stringValue == "m=https://www.netflix.com/watch/26004747&source_type=4")
        #expect(tv.sent.first { $0["type"]?.stringValue == "register" }?["payload"]?["client-key"]?.stringValue == "KEY")
    }

    @Test("Outros serviços: abre só o app; canal \"via\" abre o app indicado")
    func launchAppOnly() async throws {
        let tv = FakeTV.paired()
        let controller = makeController(tv: tv, storage: InMemoryTVPairingStore([Self.pairing]))

        let disney = try await controller.launchOnTV(TVLaunchRequest(serviceName: "Disney Plus"), on: Self.device)
        #expect(disney == .openedApp)
        #expect(tv.sentRequests.last?["payload"]?["id"]?.stringValue == "com.disney.disneyplus-prod")
        #expect(tv.sentRequests.last?["payload"]?["contentId"] == nil)

        _ = try await controller.launchOnTV(TVLaunchRequest(serviceName: "Paramount+ (Via Amazon Prime)"), on: Self.device)
        #expect(tv.sentRequests.last?["payload"]?["id"]?.stringValue == "amazon")
    }

    @Test("App do serviço ausente na TV")
    func appNotInstalled() async throws {
        let controller = makeController(tv: FakeTV.paired(), storage: InMemoryTVPairingStore([Self.pairing]))
        await #expect(throws: TVError.appNotInstalled(serviceName: "Globoplay")) {
            try await controller.launchOnTV(TVLaunchRequest(serviceName: "Globoplay"), on: Self.device)
        }
    }

    @Test("Pareamento desfeito na TV ou TV desconhecida exigem parear de novo")
    func notPaired() async throws {
        let unpaired = makeController(tv: FakeTV.paired(promptAgain: true), storage: InMemoryTVPairingStore([Self.pairing]))
        await #expect(throws: TVError.notPaired) {
            try await unpaired.launchOnTV(TVLaunchRequest(serviceName: "Netflix"), on: Self.device)
        }

        let unknown = makeController(tv: FakeTV.paired())
        await #expect(throws: TVError.notPaired) {
            try await unknown.launchOnTV(TVLaunchRequest(serviceName: "Netflix"), on: Self.device)
        }
    }

    @Test("Lista e esquece TVs pareadas")
    func listAndForget() async throws {
        let older = TVPairing(
            device: TVDevice(id: "10.0.0.2", name: "LG Quarto", host: "10.0.0.2", platform: "webOS"),
            credential: "OLD",
            pairedAt: .distantPast
        )
        let controller = makeController(tv: FakeTV.paired(), storage: InMemoryTVPairingStore([older, Self.pairing]))

        #expect(try await controller.listPairedTVs().map(\.name) == ["LG OLED55C1", "LG Quarto"])
        try await controller.forgetTV(id: Self.device.id)
        #expect(try await controller.listPairedTVs().map(\.name) == ["LG Quarto"])
    }
}

@Suite("LG webOS: correspondência de apps")
struct LGWebOSAppResolverTests {
    let apps = [
        LGWebOSApp(id: "netflix", title: "Netflix"),
        LGWebOSApp(id: "amazon", title: "Prime Video"),
        LGWebOSApp(id: "com.wbd.stream", title: "Max"),
        LGWebOSApp(id: "youtube.leanback.v4", title: "YouTube"),
        LGWebOSApp(id: "com.globo.globoplay", title: "Globoplay"),
    ]

    @Test("Nomes do Watchmode encontram o app da TV", arguments: [
        ("Netflix", "netflix"),
        ("Prime Video", "amazon"),
        ("Amazon Prime", "amazon"),
        ("HBO Max", "com.wbd.stream"),
        ("Globoplay", "com.globo.globoplay"),
        ("Paramount+ (Via Amazon Prime)", "amazon"),
    ])
    func matches(serviceName: String, appID: String) {
        #expect(LGWebOSAppResolver.app(for: serviceName, in: apps)?.id == appID)
    }

    @Test("IDs de conteúdo: Netflix e YouTube; outros não")
    func contentIDs() {
        #expect(LGWebOSAppResolver.contentID(appID: "netflix", webURL: URL(string: "https://www.netflix.com/br/watch/80100172?trackId=1"))
            == "m=https://www.netflix.com/watch/80100172&source_type=4")
        #expect(LGWebOSAppResolver.contentID(appID: "youtube.leanback.v4", webURL: URL(string: "https://www.youtube.com/watch?v=abc123")) == "abc123")
        #expect(LGWebOSAppResolver.contentID(appID: "netflix", webURL: URL(string: "https://www.netflix.com/browse")) == nil)
        #expect(LGWebOSAppResolver.contentID(appID: "amazon", webURL: URL(string: "https://app.primevideo.com/detail?gti=x")) == nil)
    }
}
