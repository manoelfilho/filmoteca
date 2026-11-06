import Foundation
import NetworkCore

/// Mensagens do protocolo SSAP da TV.
///
/// O conteúdo do registro segue o da biblioteca aiowebostv (Home Assistant, Apache-2.0):
/// https://github.com/home-assistant-libs/aiowebostv
enum LGWebOSMessages {
    static let launchAppURI = "ssap://system.launcher/launch"
    static let listAppsURI = "ssap://com.webos.applicationManager/listLaunchPoints"
    static let systemInfoURI = "ssap://system/getSystemInfo"

    static let hello: JSONValue = ["id": "hello", "type": "hello", "payload": [:]]

    /// Pedido de registro. Sem `clientKey`, a TV mostra o pedido de pareamento na tela.
    static func register(clientKey: String?) -> JSONValue {
        var payload: [String: JSONValue] = [
            "forcePairing": false,
            "pairingType": "PROMPT",
            "manifest": [
                "appVersion": "1.1",
                "manifestVersion": .number(1),
                "permissions": .array(permissions.map(JSONValue.string)),
            ],
        ]
        if let clientKey {
            payload["client-key"] = .string(clientKey)
        }
        return ["id": "register_0", "type": "register", "payload": .object(payload)]
    }

    static func request(id: String, uri: String, payload: [String: JSONValue] = [:]) -> JSONValue {
        ["id": .string(id), "type": "request", "uri": .string(uri), "payload": .object(payload)]
    }

    /// Só o necessário para descobrir os apps instalados e abri-los.
    static let permissions = [
        "LAUNCH",
        "LAUNCH_WEBAPP",
        "APP_TO_APP",
        "READ_INSTALLED_APPS",
        "READ_RUNNING_APPS",
        "READ_APP_STATUS",
        "READ_NETWORK_STATE",
        "READ_POWER_STATE",
        "READ_COUNTRY_INFO",
    ]
}
