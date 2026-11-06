import Foundation
import MovieDomain
import NetworkCore

/// Implementação das interfaces de `MovieDomain` usando a API do Watchmode.
public final class WatchmodeStreamingRepository: Sendable {
    private let configuration: WatchmodeConfiguration
    private let client: any HTTPClient

    public init(configuration: WatchmodeConfiguration, client: any HTTPClient) {
        self.configuration = configuration
        self.client = client
    }

    private func send<Response: Decodable>(_ endpoint: WatchmodeEndpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.send(endpoint.request(configuration: configuration), decoding: Response.self)
        } catch let error as NetworkError {
            throw DataSourceError(error)
        } catch is CancellationError {
            throw DataSourceError.cancelled
        }
    }
}

// MARK: - Interfaces

extension WatchmodeStreamingRepository: ListStreamingOffers {
    /// Filme que o Watchmode não conhece devolve lista vazia: para quem consome, é o mesmo
    /// que não estar disponível em nenhum serviço.
    public func listStreamingOffers(_ query: StreamingOffersQuery) async throws -> [StreamingOffer] {
        guard !configuration.apiKey.isEmpty else {
            throw DataSourceError.unauthorized(message: "Watchmode API key is missing")
        }

        let sources: [WatchmodeSourceDTO]
        do {
            sources = try await send(.titleSources(query), as: [WatchmodeSourceDTO].self)
        } catch DataSourceError.notFound {
            return []
        }

        return sources
            .compactMap { $0.toDomain() }
            .filter { query.kinds.isEmpty || query.kinds.contains($0.kind) }
    }
}

// MARK: - Erros

extension DataSourceError {
    init(_ error: NetworkError) {
        switch error {
        case .connectivity: self = .connectivity
        case .timeout: self = .timeout
        case .cancelled: self = .cancelled
        case .invalidRequest(let message): self = .invalidQuery(message)
        case .transport(let message): self = .unknown(message)
        case .invalidResponse: self = .invalidResponse
        case .decoding(let message): self = .decoding(message)
        case .httpStatus(let code, let data):
            let message = (try? JSONDecoder().decode(WatchmodeErrorDTO.self, from: data))?.message
            switch code {
            case 401, 403: self = .unauthorized(message: message)
            case 404: self = .notFound
            case 429: self = .rateLimited
            case 400, 422: self = .invalidQuery(message ?? "HTTP \(code)")
            default: self = .server(statusCode: code, message: message)
            }
        }
    }
}
