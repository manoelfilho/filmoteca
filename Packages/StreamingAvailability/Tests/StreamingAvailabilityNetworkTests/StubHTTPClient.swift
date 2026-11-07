import Foundation
import NetworkCore

/// `HTTPClient` falso: registra as requisições e devolve respostas fixas.
final class StubHTTPClient: HTTPClient, @unchecked Sendable {
    private let lock = NSLock()
    private var responses: [String: HTTPResponse] = [:]
    private var _requests: [HTTPRequest] = []

    var requests: [HTTPRequest] {
        lock.withLock { _requests }
    }

    var lastRequest: HTTPRequest? { requests.last }

    func stub(path: String, status: Int = 200, json: String) {
        lock.withLock {
            responses[path] = HTTPResponse(statusCode: status, data: Data(json.utf8))
        }
    }

    func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        try lock.withLock {
            _requests.append(request)
            guard let response = responses[request.path] else {
                throw NetworkError.connectivity
            }
            return response
        }
    }
}
