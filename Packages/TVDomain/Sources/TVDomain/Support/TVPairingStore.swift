import Foundation
import Security

/// TV pareada e a credencial que a TV entregou no pareamento (chave ou token).
public struct TVPairing: Codable, Hashable, Sendable {
    public var device: TVDevice
    public var credential: String?
    public var pairedAt: Date

    public init(device: TVDevice, credential: String?, pairedAt: Date = .now) {
        self.device = device
        self.credential = credential
        self.pairedAt = pairedAt
    }
}

/// Onde os pareamentos de uma marca ficam guardados.
public protocol TVPairingStore: Sendable {
    func load() throws -> [TVPairing]
    func save(_ pairings: [TVPairing]) throws
}

/// Guarda os pareamentos no Keychain: a credencial da TV dá controle sobre ela.
public struct KeychainTVPairingStore: TVPairingStore {
    public let service: String
    public let account: String
    /// Nomes antigos do serviço no Keychain. Se o atual ainda não tem nada, os pareamentos
    /// salvos com um nome antigo passam para o atual (e o item antigo é apagado).
    public let legacyServices: [String]

    public init(service: String, account: String = "pairings", legacyServices: [String] = []) {
        self.service = service
        self.account = account
        self.legacyServices = legacyServices
    }

    public func load() throws -> [TVPairing] {
        if let pairings = try read(service: service) {
            return pairings
        }
        for legacy in legacyServices {
            guard let pairings = try read(service: legacy) else { continue }
            try save(pairings)
            SecItemDelete(Self.query(service: legacy, account: account) as CFDictionary)
            return pairings
        }
        return []
    }

    /// `nil` quando não há item com esse nome no Keychain.
    private func read(service: String) throws -> [TVPairing]? {
        var query = Self.query(service: service, account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            // Dado em formato antigo ou corrompido não pode travar o pareamento: recomeça do zero.
            guard let data = result as? Data, let pairings = try? JSONDecoder().decode([TVPairing].self, from: data) else {
                return []
            }
            return pairings
        case errSecItemNotFound:
            return nil
        default:
            throw TVError.commandFailed("Keychain read failed (\(status))")
        }
    }

    public func save(_ pairings: [TVPairing]) throws {
        let data = try JSONEncoder().encode(pairings)
        let status = SecItemUpdate(baseQuery as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var item = baseQuery
            item[kSecValueData as String] = data
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(item as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw TVError.commandFailed("Keychain write failed (\(addStatus))") }
        } else if status != errSecSuccess {
            throw TVError.commandFailed("Keychain write failed (\(status))")
        }
    }

    private var baseQuery: [String: Any] {
        Self.query(service: service, account: account)
    }

    private static func query(service: String, account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}

/// Pareamentos só em memória (testes e previews).
public final class InMemoryTVPairingStore: TVPairingStore, @unchecked Sendable {
    private let lock = NSLock()
    private var pairings: [TVPairing]

    public init(_ pairings: [TVPairing] = []) {
        self.pairings = pairings
    }

    public func load() throws -> [TVPairing] { lock.withLock { pairings } }
    public func save(_ pairings: [TVPairing]) throws { lock.withLock { self.pairings = pairings } }
}
