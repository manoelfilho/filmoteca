import Foundation
import NetworkCore
@testable import SamsungTizen

/// TV Samsung simulada: WebSocket (controle remoto) e HTTP (informações e apps).
final class FakeSamsungTV: WebSocketClient, HTTPClient, @unchecked Sendable {
    struct Options {
        /// Porta segura fechada (TV antiga, só 8001).
        var secureClosed = false
        /// O que a TV responde ao abrir o canal: evento enviado, ou nada (pedido na tela sem resposta).
        var authorization: String? = SamsungTizenMessages.Event.connect
        var token: String? = "TOKEN-1"
        /// Responde à lista de apps? (alguns modelos recentes não respondem)
        var listsApps = true
        var apps: [(id: String, name: String, type: Int)] = [
            ("3201907018807", "Netflix", 2),
            ("3201910019365", "Prime Video", 2),
            ("3201901017640", "Disney+", 2),
        ]
        var launchError: String?
        /// Confirma a abertura pelo canal? (muitos modelos não confirmam)
        var confirmsLaunch = true
        /// O pedido pelo canal abre mesmo o app? (alguns modelos ignoram)
        var opensAppFromChannel = true
        /// Informa o estado dos apps pela API HTTP?
        var reportsAppStatus = true
        /// Manda avisos de estado sem parar, como algumas TVs fazem.
        var isNoisy = false
        /// Apps rodando em segundo plano desde o início (a Samsung deixa a Netflix assim).
        var backgroundApps: Set<String> = []
        /// Depois do pedido pelo canal, o app só aparece na tela nesta consulta de estado
        /// (0 = na hora). Simula a Netflix demorando a abrir.
        var visibleAfterStatusChecks = 0
        /// A API HTTP recusa conexões (como a TV fez depois de muitas consultas seguidas).
        var restRefuses = false
        var deviceJSON = #"{"type":"Samsung SmartTV","device":{"type":"Samsung SmartTV","name":"[TV] Samsung Q60 Series (55)"}}"#
    }

    var options: Options
    /// Desligada: não responde nem por HTTP.
    var isOff = false
    private let lock = NSLock()
    private var _connectedURLs: [URL] = []
    private var _sent: [JSONValue] = []
    private var _httpPaths: [String] = []
    private var _httpRequests: [HTTPRequest] = []
    private var runningApps: Set<String> = []
    private var visibleApps: Set<String> = []
    /// Apps abertos pelo canal que ainda não apareceram na tela, com as consultas que faltam.
    private var pendingVisible: [String: Int] = [:]

    var httpRequests: [HTTPRequest] { lock.withLock { _httpRequests } }
    var restLaunches: [String] { httpRequests.filter { $0.method == .post }.map(\.path) }

    var connectedURLs: [URL] { lock.withLock { _connectedURLs } }
    var sent: [JSONValue] { lock.withLock { _sent } }
    var httpPaths: [String] { lock.withLock { _httpPaths } }
    var launches: [JSONValue] { sent.filter { $0["params"]?["event"]?.stringValue == "ed.apps.launch" } }

    init(_ options: Options = Options()) {
        self.options = options
    }

    // MARK: WebSocketClient

    func connect(to url: URL, trustedSelfSignedHost: String?) -> any WebSocketConnection {
        lock.withLock { _connectedURLs.append(url) }
        return Connection(tv: self, secure: url.scheme == "wss")
    }

    final class Connection: WebSocketConnection, @unchecked Sendable {
        let tv: FakeSamsungTV
        let secure: Bool
        private let lock = NSLock()
        private var inbox: [String] = []

        init(tv: FakeSamsungTV, secure: Bool) {
            self.tv = tv
            self.secure = secure
            var first: [String] = [#"{"event":"ed.edenTV.update","data":{}}"#]
            if let event = tv.options.authorization {
                let token = tv.options.token.map { #","token":"\#($0)""# } ?? ""
                first.append(#"{"event":"\#(event)","data":{"id":"1"\#(token)}}"#)
            }
            inbox = first
        }

        func send(_ text: String) async throws {
            if secure && tv.options.secureClosed { throw NetworkError.connectivity }
            let message = try JSONValue.decode(text)
            tv.lock.withLock { tv._sent.append(message) }
            let replies: [String] = switch message["params"]?["event"]?.stringValue {
            case "ed.installedApp.get" where tv.options.listsApps:
                [#"{"event":"ed.installedApp.get","data":{"data":[\#(tv.options.apps.map { #"{"appId":"\#($0.id)","name":"\#($0.name)","app_type":\#($0.type)}"# }.joined(separator: ","))]}}"#]
            case "ed.apps.launch":
                if let error = tv.options.launchError {
                    [#"{"event":"ms.error","data":{"message":"\#(error)"}}"#]
                } else {
                    tv.channelLaunch(message["params"]?["data"]?["appId"]?.stringValue)
                }
            default:
                []
            }
            lock.withLock { inbox.append(contentsOf: replies) }
        }

        func receive(timeout: Duration) async throws -> String {
            if secure && tv.options.secureClosed { throw NetworkError.connectivity }
            return try lock.withLock {
                guard !inbox.isEmpty else {
                    if tv.options.isNoisy { return #"{"event":"ed.edenTV.update","data":{}}"# }
                    throw NetworkError.timeout
                }
                return inbox.removeFirst()
            }
        }

        func close() async {}
    }

    /// Respostas da TV ao pedido de abertura pelo canal.
    fileprivate func channelLaunch(_ appID: String?) -> [String] {
        if options.opensAppFromChannel, let appID {
            lock.withLock {
                _ = runningApps.insert(appID)
                if options.visibleAfterStatusChecks > 0 {
                    pendingVisible[appID] = options.visibleAfterStatusChecks
                } else {
                    _ = visibleApps.insert(appID)
                }
            }
        }
        return options.confirmsLaunch ? [#"{"event":"ed.apps.launch","data":200}"#] : []
    }

    // MARK: HTTPClient

    func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        let path = request.url.absoluteString
        lock.withLock {
            _httpPaths.append(path)
            _httpRequests.append(request)
        }
        if isOff { throw NetworkError.timeout }
        if options.restRefuses, !request.path.isEmpty { throw NetworkError.connectivity }
        if request.path.isEmpty {
            return HTTPResponse(statusCode: 200, data: Data(options.deviceJSON.utf8))
        }
        if request.path.hasPrefix("applications/"), options.apps.contains(where: { request.path == "applications/\($0.id)" }) {
            let id = String(request.path.dropFirst("applications/".count))
            if request.method == .post {
                lock.withLock {
                    _ = runningApps.insert(id)
                    _ = visibleApps.insert(id)
                }
                return HTTPResponse(statusCode: 200, data: Data("true".utf8))
            }
            guard options.reportsAppStatus else { return HTTPResponse(statusCode: 200, data: Data(#"{"id":"\#(id)"}"#.utf8)) }
            let (running, visible) = lock.withLock {
                if let remaining = pendingVisible[id] {
                    if remaining <= 1 {
                        pendingVisible[id] = nil
                        _ = visibleApps.insert(id)
                    } else {
                        pendingVisible[id] = remaining - 1
                    }
                }
                return (runningApps.contains(id) || options.backgroundApps.contains(id), visibleApps.contains(id))
            }
            return HTTPResponse(statusCode: 200, data: Data(#"{"id":"\#(id)","running":\#(running),"visible":\#(visible)}"#.utf8))
        }
        return HTTPResponse(statusCode: 404, data: Data())
    }
}
