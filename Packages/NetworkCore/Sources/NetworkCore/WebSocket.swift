import Foundation

/// Conexão WebSocket de texto, sem depender da implementação.
///
/// Usada por protocolos de dispositivos na rede local (ex.: controle de TVs).
public protocol WebSocketConnection: Sendable {
    func send(_ text: String) async throws
    /// Espera a próxima mensagem. Ao passar do prazo, fecha a conexão e lança `NetworkError.timeout`.
    func receive(timeout: Duration) async throws -> String
    func close() async
}

public protocol WebSocketClient: Sendable {
    /// Abre a conexão. Falhas de rede só aparecem no primeiro envio ou recebimento.
    ///
    /// - Parameter trustedSelfSignedHost: aceita o certificado autoassinado deste host
    ///   (aparelhos da rede local costumam usar um). `nil` valida o certificado normalmente.
    func connect(to url: URL, trustedSelfSignedHost: String?) -> any WebSocketConnection
}

extension WebSocketConnection {
    /// Envia com prazo: numa conexão que caiu sem aviso, o envio pode ficar esperando.
    public func send(_ text: String, timeout: Duration) async throws {
        try await withDeadline(timeout, closing: self) { try await self.send(text) }
    }

    /// Espera mensagens até `deadline` e devolve a primeira que `accept` aceitar (não `nil`).
    ///
    /// O prazo vale para a espera toda: mensagens que não interessam (avisos de estado
    /// que alguns aparelhos mandam o tempo todo) não renovam o tempo.
    /// - Returns: `nil` se o prazo acabar antes (a conexão é fechada).
    public func receive<T: Sendable>(
        until deadline: ContinuousClock.Instant,
        accept: (String) throws -> T?
    ) async throws -> T? {
        while true {
            let remaining = deadline - ContinuousClock.now
            guard remaining > .zero else {
                await close()
                return nil
            }
            let text: String
            do {
                text = try await receive(timeout: remaining)
            } catch NetworkError.timeout {
                return nil
            }
            if let value = try accept(text) {
                return value
            }
        }
    }

    /// Envia e espera a resposta, com um único prazo para as duas etapas.
    /// Sem ninguém do outro lado, é o envio que fica esperando a conexão.
    public func send(_ text: String, awaitingReplyWithin timeout: Duration) async throws -> String {
        try await withDeadline(timeout, closing: self) {
            try await self.send(text)
            return try await self.receive(timeout: timeout)
        }
    }
}

/// Executa `operation` com prazo. Ao estourar, fecha `connection` (o que destrava
/// envios e recebimentos pendentes) e lança `NetworkError.timeout`.
func withDeadline<T: Sendable>(
    _ timeout: Duration,
    closing connection: any WebSocketConnection,
    _ operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await Task.sleep(for: timeout)
            await connection.close()
            throw NetworkError.timeout
        }
        defer { group.cancelAll() }
        guard let first = try await group.next() else { throw NetworkError.timeout }
        return first
    }
}

// MARK: - URLSession

public struct URLSessionWebSocketClient: WebSocketClient {
    public init() {}

    public func connect(to url: URL, trustedSelfSignedHost: String?) -> any WebSocketConnection {
        URLSessionWebSocketConnection(url: url, trustedSelfSignedHost: trustedSelfSignedHost)
    }
}

final class URLSessionWebSocketConnection: WebSocketConnection {
    private let session: URLSession
    private let task: URLSessionWebSocketTask

    init(url: URL, trustedSelfSignedHost: String?) {
        session = URLSession(
            configuration: .ephemeral,
            delegate: SelfSignedTrustDelegate(trustedHost: trustedSelfSignedHost),
            delegateQueue: nil
        )
        task = session.webSocketTask(with: url)
        task.resume()
    }

    func send(_ text: String) async throws {
        do {
            try await task.send(.string(text))
        } catch {
            throw Self.networkError(error)
        }
    }

    func receive(timeout: Duration) async throws -> String {
        let task = task
        return try await withDeadline(timeout, closing: self) {
            do {
                switch try await task.receive() {
                case .string(let text): return text
                case .data(let data): return String(decoding: data, as: UTF8.self)
                @unknown default: throw NetworkError.invalidResponse
                }
            } catch let error as NetworkError {
                throw error
            } catch {
                throw Self.networkError(error)
            }
        }
    }

    func close() async {
        task.cancel(with: .normalClosure, reason: nil)
        session.finishTasksAndInvalidate()
    }

    private static func networkError(_ error: Error) -> NetworkError {
        guard let urlError = error as? URLError else { return .transport(String(describing: error)) }
        switch urlError.code {
        case .timedOut: return .timeout
        case .cancelled: return .cancelled
        case .notConnectedToInternet, .cannotConnectToHost, .cannotFindHost, .networkConnectionLost,
             .dnsLookupFailed, .secureConnectionFailed:
            return .connectivity
        default: return .transport(urlError.localizedDescription)
        }
    }
}

/// Aceita o certificado autoassinado só do host informado.
private final class SelfSignedTrustDelegate: NSObject, URLSessionDelegate, Sendable {
    let trustedHost: String?

    init(trustedHost: String?) {
        self.trustedHost = trustedHost
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        guard let trustedHost,
              challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              challenge.protectionSpace.host == trustedHost,
              let trust = challenge.protectionSpace.serverTrust
        else { return (.performDefaultHandling, nil) }
        return (.useCredential, URLCredential(trust: trust))
    }
}
