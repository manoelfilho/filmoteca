import Foundation
import MovieDomain
import NetworkCore

/// Implementação das interfaces de `MovieDomain` usando a API do TMDB.
///
/// Uma única instância atende todas as interfaces. Quem consome os dados
/// recebe apenas o protocolo de que precisa (`any ListMovies`, `any GetMovie`...).
public final class TMDBMovieRepository: Sendable {
    private let configuration: TMDBConfiguration
    private let client: any HTTPClient
    private let images: TMDBImageURLBuilder

    public init(configuration: TMDBConfiguration, client: any HTTPClient) {
        self.configuration = configuration
        self.client = client
        self.images = TMDBImageURLBuilder(baseURL: configuration.imageBaseURL)
    }

    private func send<Response: Decodable>(_ endpoint: TMDBEndpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.send(
                endpoint.request(configuration: configuration),
                decoding: Response.self,
                decoder: .tmdb()
            )
        } catch let error as NetworkError {
            throw DataSourceError(error)
        } catch is CancellationError {
            throw DataSourceError.cancelled
        }
    }
}

// MARK: - Interfaces

extension TMDBMovieRepository: ListMovies {
    public func listMovies(_ query: MovieListQuery) async throws -> PaginatedResult<Movie> {
        try await send(.list(query), as: TMDBPageDTO<TMDBMovieDTO>.self).toDomain(images: images)
    }
}

extension TMDBMovieRepository: GetMovie {
    public func getMovie(_ query: MovieDetailsQuery) async throws -> MovieDetails {
        try await send(.details(query), as: TMDBMovieDetailsDTO.self).toDomain(images: images)
    }
}

extension TMDBMovieRepository: SearchMovies {
    public func searchMovies(_ query: MovieSearchQuery) async throws -> PaginatedResult<Movie> {
        let text = query.text.trimmingCharacters(in: .whitespacesAndNewlines)
        // O TMDB devolve lista vazia para busca em branco; evita a requisição.
        guard !text.isEmpty else { return .empty }

        var query = query
        query.text = text
        return try await send(.search(query), as: TMDBPageDTO<TMDBMovieDTO>.self).toDomain(images: images)
    }
}

extension TMDBMovieRepository: DiscoverMovies {
    public func discoverMovies(_ query: MovieDiscoverQuery) async throws -> PaginatedResult<Movie> {
        try await send(.discover(query), as: TMDBPageDTO<TMDBMovieDTO>.self).toDomain(images: images)
    }
}

extension TMDBMovieRepository: ListGenres {
    public func listGenres(_ query: GenreListQuery) async throws -> [Genre] {
        try await send(.genres(query), as: TMDBGenreListDTO.self).genres.map { $0.toDomain() }
    }
}

extension TMDBMovieRepository: GetMovieCredits {
    public func getMovieCredits(_ query: MovieCreditsQuery) async throws -> MovieCredits {
        try await send(.credits(query), as: TMDBCreditsDTO.self).toDomain(images: images)
    }
}

extension TMDBMovieRepository: ListMovieVideos {
    public func listMovieVideos(_ query: MovieVideosQuery) async throws -> [MovieVideo] {
        try await send(.videos(query), as: TMDBVideoListDTO.self).results.map { $0.toDomain() }
    }
}

extension TMDBMovieRepository: ListRelatedMovies {
    public func listRelatedMovies(_ query: RelatedMoviesQuery) async throws -> PaginatedResult<Movie> {
        try await send(.related(query), as: TMDBPageDTO<TMDBMovieDTO>.self).toDomain(images: images)
    }
}

extension TMDBMovieRepository: GetMovieWatchProviders {
    public func getMovieWatchProviders(_ query: MovieWatchProvidersQuery) async throws -> MovieWatchProviders {
        let region = query.region ?? configuration.defaultRegion ?? Self.fallbackRegion
        return try await send(.movieWatchProviders(query), as: TMDBMovieWatchProvidersDTO.self)
            .toDomain(region: region, images: images)
    }
}

extension TMDBMovieRepository: ListWatchProviders {
    public func listWatchProviders(_ query: WatchProviderListQuery) async throws -> [WatchProvider] {
        let region = query.region ?? configuration.defaultRegion ?? Self.fallbackRegion
        var query = query
        query.region = region
        return try await send(.watchProviders(query), as: TMDBWatchProviderListDTO.self)
            .results
            .map { $0.toDomain(images: images, region: region) }
            .sorted { $0.displayPriority < $1.displayPriority }
    }
}

extension TMDBMovieRepository {
    /// Rotas de streaming dependem de um país; usa os EUA quando nada foi configurado.
    static let fallbackRegion = "US"
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
            let message = (try? JSONDecoder.tmdb().decode(TMDBErrorDTO.self, from: data))?.statusMessage
            switch code {
            case 401: self = .unauthorized(message: message)
            case 404: self = .notFound
            case 429: self = .rateLimited
            case 400, 422: self = .invalidQuery(message ?? "HTTP \(code)")
            default: self = .server(statusCode: code, message: message)
            }
        }
    }
}
