import Foundation
import MovieDomain
import NetworkCore

/// Rotas da API do Watchmode usadas pelo app.
/// Referência: https://api.watchmode.com/docs
enum WatchmodeEndpoint: Hashable, Sendable {
    case titleSources(StreamingOffersQuery)

    func request(configuration: WatchmodeConfiguration) -> HTTPRequest {
        HTTPRequest(
            baseURL: configuration.baseURL,
            path: path(configuration: configuration),
            query: parameters(configuration: configuration),
            // Forma recomendada pela API; o parâmetro `apiKey` na URL é legado.
            headers: ["X-API-Key": configuration.apiKey, "Accept": "application/json"],
            timeout: configuration.timeout
        )
    }

    private func path(configuration: WatchmodeConfiguration) -> String {
        switch self {
        case .titleSources(let query):
            "title/\(Self.titleID(for: query.movieID, format: configuration.movieIDFormat))/sources/"
        }
    }

    private func parameters(configuration: WatchmodeConfiguration) -> [String: String] {
        switch self {
        case .titleSources(let query):
            let regions = query.regions.isEmpty ? [configuration.defaultRegion].compactMap { $0 } : query.regions
            return regions.isEmpty ? [:] : ["regions": regions.map { $0.uppercased() }.joined(separator: ",")]
        }
    }

    static func titleID(for movieID: MovieID, format: WatchmodeConfiguration.MovieIDFormat) -> String {
        switch format {
        case .tmdb: "movie-\(movieID.rawValue)"
        case .imdb, .watchmode: movieID.rawValue
        }
    }
}
