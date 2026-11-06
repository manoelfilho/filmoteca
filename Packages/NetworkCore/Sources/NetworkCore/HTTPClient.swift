import Foundation

/// Interface de transporte HTTP.
///
/// Os provedores de dados dependem deste protocolo, não do Alamofire.
/// Em testes, basta uma implementação que devolva `HTTPResponse` fixos.
public protocol HTTPClient: Sendable {
    /// Executa a requisição e devolve a resposta, qualquer que seja o status HTTP.
    /// Lança `NetworkError` apenas quando não há resposta (sem conexão, timeout etc.).
    func send(_ request: HTTPRequest) async throws -> HTTPResponse
}

extension HTTPClient {
    /// Executa a requisição, valida o status 2xx e decodifica o corpo.
    public func send<Response: Decodable>(
        _ request: HTTPRequest,
        decoding type: Response.Type,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> Response {
        let response = try await send(request)

        guard response.isSuccess else {
            throw NetworkError.httpStatus(code: response.statusCode, data: response.data)
        }

        do {
            return try decoder.decode(Response.self, from: response.data)
        } catch {
            throw NetworkError.decoding(String(describing: error))
        }
    }
}
