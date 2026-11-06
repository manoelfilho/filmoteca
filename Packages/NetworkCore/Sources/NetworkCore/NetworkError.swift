import Foundation

public enum NetworkError: Error, Hashable, Sendable {
    case invalidRequest(String)
    case connectivity
    case timeout
    case cancelled
    case transport(String)
    case invalidResponse
    case httpStatus(code: Int, data: Data)
    case decoding(String)
}
