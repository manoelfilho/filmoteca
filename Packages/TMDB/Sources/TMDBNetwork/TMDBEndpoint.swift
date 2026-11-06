import Foundation
import MovieDomain
import NetworkCore

/// Rotas da API do TMDB usadas pelo app.
/// Referência: https://developer.themoviedb.org/reference
enum TMDBEndpoint: Hashable, Sendable {
    case list(MovieListQuery)
    case details(MovieDetailsQuery)
    case search(MovieSearchQuery)
    case discover(MovieDiscoverQuery)
    case genres(GenreListQuery)
    case credits(MovieCreditsQuery)
    case videos(MovieVideosQuery)
    case related(RelatedMoviesQuery)
    case movieWatchProviders(MovieWatchProvidersQuery)
    case watchProviders(WatchProviderListQuery)

    var path: String {
        switch self {
        case .list(let query):
            switch query.category {
            case .nowPlaying: "movie/now_playing"
            case .popular: "movie/popular"
            case .topRated: "movie/top_rated"
            case .upcoming: "movie/upcoming"
            }
        case .details(let query): "movie/\(query.id.rawValue)"
        case .search: "search/movie"
        case .discover: "discover/movie"
        case .genres: "genre/movie/list"
        case .credits(let query): "movie/\(query.movieID.rawValue)/credits"
        case .videos(let query): "movie/\(query.movieID.rawValue)/videos"
        case .related(let query):
            switch query.relation {
            case .recommendations: "movie/\(query.movieID.rawValue)/recommendations"
            case .similar: "movie/\(query.movieID.rawValue)/similar"
            }
        case .movieWatchProviders(let query): "movie/\(query.movieID.rawValue)/watch/providers"
        case .watchProviders: "watch/providers/movie"
        }
    }

    /// Parâmetros próprios da rota. Idioma e região usam o padrão da configuração quando ausentes.
    func parameters(configuration: TMDBConfiguration) -> [String: String] {
        var parameters = QueryParameters()

        switch self {
        case .list(let query):
            parameters["page"] = query.page
            parameters["language"] = query.language ?? configuration.defaultLanguage
            parameters["region"] = query.region ?? configuration.defaultRegion

        case .details(let query):
            parameters["language"] = query.language ?? configuration.defaultLanguage

        case .search(let query):
            parameters["query"] = query.text
            parameters["page"] = query.page
            parameters["language"] = query.language ?? configuration.defaultLanguage
            parameters["region"] = query.region ?? configuration.defaultRegion
            parameters["year"] = query.year
            parameters["primary_release_year"] = query.primaryReleaseYear
            parameters["include_adult"] = query.includeAdult

        case .discover(let query):
            parameters["page"] = query.page
            parameters["language"] = query.language ?? configuration.defaultLanguage
            parameters["region"] = query.region ?? configuration.defaultRegion
            parameters["sort_by"] = query.sort.tmdbValue
            parameters["include_adult"] = query.includeAdult
            parameters["include_video"] = false
            parameters["primary_release_year"] = query.primaryReleaseYear
            parameters["primary_release_date.gte"] = query.releasedAfter.map(TMDBDate.string(from:))
            parameters["primary_release_date.lte"] = query.releasedBefore.map(TMDBDate.string(from:))
            parameters["vote_average.gte"] = query.minimumVoteAverage
            parameters["vote_count.gte"] = query.minimumVoteCount
            parameters["with_original_language"] = query.originalLanguage
            if !query.genreIDs.isEmpty {
                // No TMDB, vírgula = E (todos) e barra vertical = OU (qualquer um).
                let separator = query.genreMatch == .all ? "," : "|"
                parameters["with_genres"] = query.genreIDs.joined(separator: separator)
            }
            if !query.excludedGenreIDs.isEmpty {
                parameters["without_genres"] = query.excludedGenreIDs.joined(separator: ",")
            }
            if !query.watchProviderIDs.isEmpty {
                // O TMDB exige `watch_region` junto com `with_watch_providers`.
                parameters["with_watch_providers"] = query.watchProviderIDs.joined(separator: "|")
                parameters["watch_region"] = query.watchRegion ?? query.region ?? configuration.defaultRegion
                if !query.watchMonetizationTypes.isEmpty {
                    parameters["with_watch_monetization_types"] = query.watchMonetizationTypes
                        .map(\.tmdbValue)
                        .sorted()
                        .joined(separator: "|")
                }
            }

        case .genres(let query):
            parameters["language"] = query.language ?? configuration.defaultLanguage

        case .credits(let query):
            parameters["language"] = query.language ?? configuration.defaultLanguage

        case .videos(let query):
            let language = query.language ?? configuration.defaultLanguage
            parameters["language"] = language
            // Muitos filmes só têm trailer em inglês: aceita o idioma pedido, inglês e vídeos sem idioma.
            if let code = language?.split(separator: "-").first, code != "en" {
                parameters["include_video_language"] = "\(code),en,null"
            }

        case .related(let query):
            parameters["page"] = query.page
            parameters["language"] = query.language ?? configuration.defaultLanguage

        case .movieWatchProviders:
            // A rota devolve todas as regiões; o filtro é feito no repositório.
            break

        case .watchProviders(let query):
            parameters["watch_region"] = query.region ?? configuration.defaultRegion
            parameters["language"] = query.language ?? configuration.defaultLanguage
        }

        return parameters.values
    }

    func request(configuration: TMDBConfiguration) -> HTTPRequest {
        var query = parameters(configuration: configuration)
        var headers = ["Accept": "application/json"]

        switch configuration.authentication {
        case .apiKey(let key):
            query["api_key"] = key
        case .bearerToken(let token):
            headers["Authorization"] = "Bearer \(token)"
        }

        return HTTPRequest(
            baseURL: configuration.baseURL,
            path: path,
            query: query,
            headers: headers,
            timeout: configuration.timeout
        )
    }
}

/// Dicionário de query que ignora valores `nil` e converte tipos simples em `String`.
private struct QueryParameters {
    private(set) var values: [String: String] = [:]

    subscript(key: String) -> String? {
        get { values[key] }
        set { values[key] = newValue }
    }

    subscript(key: String) -> Int? {
        get { nil }
        set { values[key] = newValue.map(String.init) }
    }

    subscript(key: String) -> Double? {
        get { nil }
        set { values[key] = newValue.map { String($0) } }
    }

    subscript(key: String) -> Bool? {
        get { nil }
        set { values[key] = newValue.map { $0 ? "true" : "false" } }
    }
}

private extension WatchMonetizationType {
    var tmdbValue: String {
        switch self {
        case .subscription: "flatrate"
        case .free: "free"
        case .ads: "ads"
        case .rent: "rent"
        case .buy: "buy"
        }
    }
}

private extension MovieSort {
    var tmdbValue: String {
        let field = switch field {
        case .popularity: "popularity"
        case .releaseDate: "primary_release_date"
        case .voteAverage: "vote_average"
        case .voteCount: "vote_count"
        case .revenue: "revenue"
        case .title: "title"
        }
        return "\(field).\(order == .ascending ? "asc" : "desc")"
    }
}
