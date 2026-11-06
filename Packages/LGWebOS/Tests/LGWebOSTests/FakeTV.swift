import Foundation
import NetworkCore
@testable import LGWebOS
import TVDomain

/// TV simulada: responde às mensagens conforme o roteiro do teste.
final class FakeTV: LGWebOSSocketFactory, LGWebOSSocket, @unchecked Sendable {
    typealias Script = @Sendable (JSONValue) -> [JSONValue]

    private let lock = NSLock()
    private var inbox: [JSONValue] = []
    private var _sent: [JSONValue] = []
    private var _openedHosts: [String] = []
    private let script: Script

    var sent: [JSONValue] { lock.withLock { _sent } }
    var openedHosts: [String] { lock.withLock { _openedHosts } }
    var sentRequests: [JSONValue] { sent.filter { $0["type"]?.stringValue == "request" } }

    init(script: @escaping Script) {
        self.script = script
    }

    func open(host: String) async throws -> any LGWebOSSocket {
        lock.withLock { _openedHosts.append(host) }
        return self
    }

    func send(_ message: JSONValue) async throws {
        let replies = script(message)
        lock.withLock {
            _sent.append(message)
            inbox.append(contentsOf: replies)
        }
    }

    /// Sem resposta na fila, simula o tempo esgotado.
    func receive(timeout: Duration) async throws -> JSONValue {
        try lock.withLock {
            guard !inbox.isEmpty else { throw LGWebOSTimeout() }
            return inbox.removeFirst()
        }
    }

    func close() async {}

    // MARK: - Respostas prontas

    static func reply(to message: JSONValue, payload: JSONValue) -> JSONValue {
        ["id": message["id"] ?? .null, "type": "response", "payload": payload]
    }

    static let apps: JSONValue = [
        "returnValue": true,
        "launchPoints": [
            ["id": "netflix", "title": "Netflix"],
            ["id": "amazon", "title": "Prime Video"],
            ["id": "com.disney.disneyplus-prod", "title": "Disney+"],
            ["id": "com.cbs-ent.paramountplus", "title": "Paramount+"],
        ],
    ]

    /// TV que já conhece a chave `KEY` e tem os apps acima instalados.
    static func paired(promptAgain: Bool = false) -> FakeTV {
        FakeTV { message in
            switch message["type"]?.stringValue {
            case "register":
                if promptAgain {
                    return [["id": "register_0", "type": "response", "payload": ["pairingType": "PROMPT"]]]
                }
                return [["id": "register_0", "type": "registered", "payload": ["client-key": "KEY"]]]
            case "request":
                switch message["uri"]?.stringValue {
                case LGWebOSMessages.listAppsURI: return [reply(to: message, payload: apps)]
                default: return [reply(to: message, payload: ["returnValue": true])]
                }
            default:
                return []
            }
        }
    }
}
