import Foundation

// Modelos que espelham o JSON do TMDB. São internos: fora deste módulo
// só circulam os modelos de `MovieDomain`.
//
// O decoder usa `.convertFromSnakeCase`, então `poster_path` vira `posterPath`.
// Quase tudo é opcional porque o TMDB omite ou manda `null` em muitos campos.

struct TMDBPageDTO<Item: Decodable & Sendable>: Decodable, Sendable {
    let page: Int
    let results: [Item]
    let totalPages: Int?
    let totalResults: Int?
}

/// `/movie/popular`, `/search/movie`, `/discover/movie` etc.
struct TMDBMovieDTO: Decodable, Sendable {
    let id: Int
    let title: String?
    let originalTitle: String?
    let originalLanguage: String?
    let overview: String?
    let releaseDate: String?
    let posterPath: String?
    let backdropPath: String?
    let genreIds: [Int]?
    let voteAverage: Double?
    let voteCount: Int?
    let popularity: Double?
    let adult: Bool?
}

/// `/movie/{movie_id}`
struct TMDBMovieDetailsDTO: Decodable, Sendable {
    let id: Int
    let title: String?
    let originalTitle: String?
    let originalLanguage: String?
    let overview: String?
    let tagline: String?
    let releaseDate: String?
    let posterPath: String?
    let backdropPath: String?
    let genres: [TMDBGenreDTO]?
    let runtime: Int?
    let status: String?
    let budget: Int?
    let revenue: Int?
    let homepage: String?
    let imdbId: String?
    let voteAverage: Double?
    let voteCount: Int?
    let popularity: Double?
    let adult: Bool?
    let productionCompanies: [TMDBCompanyDTO]?
}

struct TMDBGenreDTO: Decodable, Sendable {
    let id: Int
    let name: String
}

/// `/genre/movie/list`
struct TMDBGenreListDTO: Decodable, Sendable {
    let genres: [TMDBGenreDTO]
}

struct TMDBCompanyDTO: Decodable, Sendable {
    let id: Int
    let name: String
    let logoPath: String?
    let originCountry: String?
}

/// `/movie/{movie_id}/credits`
struct TMDBCreditsDTO: Decodable, Sendable {
    let id: Int
    let cast: [TMDBCastDTO]?
    let crew: [TMDBCrewDTO]?
}

struct TMDBCastDTO: Decodable, Sendable {
    let id: Int
    let name: String
    let character: String?
    let profilePath: String?
    let order: Int?
}

struct TMDBCrewDTO: Decodable, Sendable {
    let id: Int
    let creditId: String?
    let name: String
    let job: String?
    let department: String?
    let profilePath: String?
}

/// `/movie/{movie_id}/videos`
struct TMDBVideoListDTO: Decodable, Sendable {
    let id: Int
    let results: [TMDBVideoDTO]
}

struct TMDBVideoDTO: Decodable, Sendable {
    let id: String
    let name: String
    let key: String
    let site: String
    let type: String
    let official: Bool?
    let publishedAt: String?
}

/// Item de serviço de streaming, usado nas duas rotas de watch providers.
struct TMDBWatchProviderDTO: Decodable, Sendable {
    let providerId: Int
    let providerName: String
    let logoPath: String?
    let displayPriority: Int?
    /// Só em `/watch/providers/movie`: prioridade por país.
    let displayPriorities: [String: Int]?
}

/// `/watch/providers/movie`
struct TMDBWatchProviderListDTO: Decodable, Sendable {
    let results: [TMDBWatchProviderDTO]
}

/// `/movie/{movie_id}/watch/providers` (resultados por país, chave ISO 3166-1).
struct TMDBMovieWatchProvidersDTO: Decodable, Sendable {
    struct Region: Decodable, Sendable {
        let link: String?
        let flatrate: [TMDBWatchProviderDTO]?
        let free: [TMDBWatchProviderDTO]?
        let ads: [TMDBWatchProviderDTO]?
        let rent: [TMDBWatchProviderDTO]?
        let buy: [TMDBWatchProviderDTO]?
    }

    let id: Int
    // Chaves são códigos de país (`BR`, `US`), não snake_case.
    let results: [String: Region]
}

/// Corpo de erro do TMDB, ex.: `{"status_code": 7, "status_message": "Invalid API key", "success": false}`.
struct TMDBErrorDTO: Decodable, Sendable {
    let statusCode: Int?
    let statusMessage: String?
}

extension JSONDecoder {
    static func tmdb() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
