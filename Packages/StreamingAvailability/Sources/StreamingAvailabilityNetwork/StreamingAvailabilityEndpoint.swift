import Foundation
import MovieDomain
import NetworkCore

/// Rotas da API Streaming Availability usadas pelo app.
/// Referência: https://docs.movieofthenight.com
enum StreamingAvailabilityEndpoint: Hashable, Sendable {
    /// `GET /shows/{id}`: o filme com as ofertas de streaming por país.
    case show(MovieID, country: String?)

    func request(configuration: StreamingAvailabilityConfiguration) -> HTTPRequest {
        HTTPRequest(
            baseURL: configuration.baseURL,
            path: path(configuration: configuration),
            query: parameters,
            headers: ["X-API-Key": configuration.apiKey, "Accept": "application/json"],
            timeout: configuration.timeout
        )
    }

    private func path(configuration: StreamingAvailabilityConfiguration) -> String {
        switch self {
        case .show(let movieID, _):
            "shows/\(Self.showID(for: movieID, format: configuration.movieIDFormat))"
        }
    }

    private var parameters: [String: String] {
        switch self {
        case .show(_, let country):
            // Sem país, a API devolve as ofertas de todos os países.
            country.map { ["country": $0.lowercased()] } ?? [:]
        }
    }

    static func showID(for movieID: MovieID, format: StreamingAvailabilityConfiguration.MovieIDFormat) -> String {
        switch format {
        case .tmdb: "movie/\(movieID.rawValue)"
        case .imdb: movieID.rawValue
        }
    }
}
