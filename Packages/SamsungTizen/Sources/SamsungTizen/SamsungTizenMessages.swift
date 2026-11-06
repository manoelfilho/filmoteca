import Foundation
import NetworkCore

/// Endereços e mensagens da API de controle remoto das TVs Samsung (Tizen).
///
/// Protocolo descrito pela comunidade; referência: https://github.com/xchwarze/samsung-tv-ws-api
enum SamsungTizenMessages {
    /// Nome exibido na TV no pedido de permissão.
    static let clientName = "SuperApp"

    /// `wss://host:8002` (TVs de 2018 em diante, com token) ou `ws://host:8001` (anteriores).
    static func remoteControlURL(host: String, secure: Bool, token: String?) -> URL? {
        var components = URLComponents()
        components.scheme = secure ? "wss" : "ws"
        components.host = host
        components.port = secure ? 8002 : 8001
        components.path = "/api/v2/channels/samsung.remote.control"
        var query = [URLQueryItem(name: "name", value: Data(clientName.utf8).base64EncodedString())]
        if secure, let token {
            query.append(URLQueryItem(name: "token", value: token))
        }
        components.queryItems = query
        return components.url
    }

    /// Base da API HTTP da TV (`GET /` traz as informações do aparelho).
    static func restBaseURL(host: String) -> URL? {
        URL(string: "http://\(host):8001/api/v2/")
    }

    static let installedApps: JSONValue = [
        "method": "ms.channel.emit",
        "params": ["event": "ed.installedApp.get", "to": "host"],
    ]

    /// - Parameter actionType: `DEEP_LINK` (apps Tizen) ou `NATIVE_LAUNCH` (apps nativos).
    static func launch(appID: String, actionType: String, metaTag: String?) -> JSONValue {
        [
            "method": "ms.channel.emit",
            "params": [
                "event": "ed.apps.launch",
                "to": "host",
                "data": [
                    "appId": .string(appID),
                    "action_type": .string(actionType),
                    "metaTag": .string(metaTag ?? ""),
                ],
            ],
        ]
    }

    enum Event {
        static let connect = "ms.channel.connect"
        static let unauthorized = "ms.channel.unauthorized"
        static let timeOut = "ms.channel.timeOut"
        static let error = "ms.error"
        static let installedApps = "ed.installedApp.get"
        static let launch = "ed.apps.launch"
    }
}
