import Foundation
import Security
import Testing
import TVDomain

@Suite("Keychain: pareamentos salvos com o nome antigo do app")
struct KeychainTVPairingStoreTests {
    let suffix = UUID().uuidString
    var legacyName: String { "Test.Legacy.\(suffix)" }
    var currentName: String { "Test.Current.\(suffix)" }

    /// Apaga os itens de teste do Keychain.
    func removeItems() {
        for service in [legacyName, currentName] {
            SecItemDelete([
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
            ] as CFDictionary)
        }
    }

    let device = TVDevice(id: "192.168.0.20", name: "LG TV", host: "192.168.0.20", platform: "webOS")

    @Test("Passa os pareamentos do nome antigo para o novo e apaga o antigo")
    func migratesLegacyItem() throws {
        let legacy = KeychainTVPairingStore(service: legacyName)
        let current = KeychainTVPairingStore(service: currentName, legacyServices: [legacyName])
        defer { removeItems() }

        try legacy.save([TVPairing(device: device, credential: "KEY")])

        let migrated = try current.load()
        #expect(migrated.map(\.device) == [device])
        #expect(migrated.first?.credential == "KEY")
        // Já está no nome novo, e o antigo ficou vazio.
        #expect(try KeychainTVPairingStore(service: currentName).load().map(\.device) == [device])
        #expect(try legacy.load().isEmpty)
    }

    @Test("Com pareamentos no nome novo, o antigo é ignorado (mesmo se o novo estiver vazio)")
    func currentWins() throws {
        let legacy = KeychainTVPairingStore(service: legacyName)
        let current = KeychainTVPairingStore(service: currentName, legacyServices: [legacyName])
        defer { removeItems() }

        try legacy.save([TVPairing(device: device, credential: "OLD")])
        try current.save([])

        #expect(try current.load().isEmpty)
    }
}
