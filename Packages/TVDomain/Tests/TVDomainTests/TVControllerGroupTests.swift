import Foundation
import Testing
import TVDomain

/// Marca falsa: reconhece só os endereços informados.
final class FakeBrand: TVPlatformController, @unchecked Sendable {
    let platform: String
    private let hosts: Set<String>
    private let lock = NSLock()
    private var paired: [TVDevice] = []
    private(set) var launched: [TVLaunchRequest] = []

    init(platform: String, hosts: Set<String>, paired: [TVDevice] = []) {
        self.platform = platform
        self.hosts = hosts
        self.paired = paired
    }

    func recognizesTV(at host: String) async -> Bool { hosts.contains(host) }

    func pairTV(host: String) async throws -> TVDevice {
        let device = TVDevice(id: host, name: "\(platform) TV", host: host, platform: platform)
        lock.withLock { paired.append(device) }
        return device
    }

    func listPairedTVs() async throws -> [TVDevice] { lock.withLock { paired } }

    func forgetTV(id: TVDevice.ID) async throws { lock.withLock { paired.removeAll { $0.id == id } } }

    func launchOnTV(_ request: TVLaunchRequest, on device: TVDevice) async throws -> TVLaunchResult {
        lock.withLock { launched.append(request) }
        return .openedApp
    }
}

@Suite("Grupo de TVs de várias marcas")
struct TVControllerGroupTests {
    @Test("Pareia com a marca que reconhece o endereço")
    func pairsWithRecognizingBrand() async throws {
        let lg = FakeBrand(platform: "webOS", hosts: ["10.0.0.2"])
        let samsung = FakeBrand(platform: "Tizen", hosts: ["10.0.0.3"])
        let group = TVControllerGroup([lg, samsung])

        #expect(try await group.pairTV(host: "http://10.0.0.3:8001").platform == "Tizen")
        #expect(try await group.pairTV(host: "10.0.0.2").platform == "webOS")
        #expect(try await group.listPairedTVs().map(\.platform).sorted() == ["Tizen", "webOS"])
    }

    @Test("Nenhuma marca reconhece: TV inalcançável; endereço inválido nem pergunta")
    func unknownHost() async throws {
        let group = TVControllerGroup([FakeBrand(platform: "webOS", hosts: [])])
        await #expect(throws: TVError.unreachable) { try await group.pairTV(host: "10.0.0.9") }
        await #expect(throws: TVError.invalidHost) { try await group.pairTV(host: "sala de tv") }
    }

    @Test("Abre o conteúdo na implementação da plataforma da TV")
    func launchRoutesByPlatform() async throws {
        let lg = FakeBrand(platform: "webOS", hosts: [])
        let samsung = FakeBrand(platform: "Tizen", hosts: [])
        let device = TVDevice(id: "10.0.0.3", name: "Samsung", host: "10.0.0.3", platform: "Tizen")

        _ = try await TVControllerGroup([lg, samsung]).launchOnTV(TVLaunchRequest(serviceName: "Netflix"), on: device)

        #expect(samsung.launched.map(\.serviceName) == ["Netflix"])
        #expect(lg.launched.isEmpty)
    }

    @Test("Normaliza endereços", arguments: [
        (" 192.168.0.20 ", "192.168.0.20"),
        ("http://192.168.0.20:3000", "192.168.0.20"),
        ("192.168.0.20:8002", "192.168.0.20"),
        ("tv-sala.local", "tv-sala.local"),
    ])
    func hostNormalization(input: String, expected: String) {
        #expect(TVHost.normalize(input) == expected)
    }
}
