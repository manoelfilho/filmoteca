import Foundation

/// Descrição de uma requisição HTTP, sem depender da biblioteca que a executa.
public struct HTTPRequest: Hashable, Sendable {
    public enum Method: String, Hashable, Sendable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
    }

    public var baseURL: URL
    public var path: String
    public var method: Method
    public var query: [String: String]
    public var headers: [String: String]
    public var timeout: TimeInterval?

    public init(
        baseURL: URL,
        path: String,
        method: Method = .get,
        query: [String: String] = [:],
        headers: [String: String] = [:],
        timeout: TimeInterval? = nil
    ) {
        self.baseURL = baseURL
        self.path = path
        self.method = method
        self.query = query
        self.headers = headers
        self.timeout = timeout
    }

    /// URL sem os parâmetros de query.
    public var url: URL {
        path.isEmpty ? baseURL : baseURL.appending(path: path)
    }
}

public struct HTTPResponse: Sendable {
    public let statusCode: Int
    public let headers: [String: String]
    public let data: Data

    public init(statusCode: Int, headers: [String: String] = [:], data: Data) {
        self.statusCode = statusCode
        self.headers = headers
        self.data = data
    }

    public var isSuccess: Bool { (200..<300).contains(statusCode) }
}
