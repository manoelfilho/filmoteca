import Foundation
import MovieDomain
import NetworkCore

/// Implementação das interfaces de `MovieDomain` usando a API Streaming Availability
/// (Movie of the Night).
public final class StreamingAvailabilityRepository: Sendable {
    private let configuration: StreamingAvailabilityConfiguration
    private let client: any HTTPClient

    public init(configuration: StreamingAvailabilityConfiguration, client: any HTTPClient) {
        self.configuration = configuration
        self.client = client
    }

    private func send<Response: Decodable>(_ endpoint: StreamingAvailabilityEndpoint, as type: Response.Type) async throws -> Response {
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

extension StreamingAvailabilityRepository: ListStreamingOffers {
    /// Filme que a API não conhece devolve lista vazia: para quem consome, é o mesmo
    /// que não estar disponível em nenhum serviço.
    public func listStreamingOffers(_ query: StreamingOffersQuery) async throws -> [StreamingOffer] {
        guard !configuration.apiKey.isEmpty else {
            throw DataSourceError.unauthorized(message: "Streaming Availability API key is missing")
        }

        let regions = Set((query.regions.isEmpty ? [configuration.defaultRegion].compactMap { $0 } : query.regions)
            .map { $0.lowercased() })
        // A API filtra por um país só. Com vários, pede todos e filtra aqui.
        let country = regions.count == 1 ? regions.first : nil

        let show: StreamingAvailabilityShowDTO
        do {
            show = try await send(.show(query.movieID, country: country), as: StreamingAvailabilityShowDTO.self)
        } catch DataSourceError.notFound {
            return []
        }

        return show.streamingOptions
            .filter { regions.isEmpty || regions.contains($0.key.lowercased()) }
            .sorted { $0.key < $1.key }
            .flatMap { country, options in options.compactMap { $0.toDomain(country: country) } }
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
            let message = (try? JSONDecoder().decode(StreamingAvailabilityErrorDTO.self, from: data))?.message
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
