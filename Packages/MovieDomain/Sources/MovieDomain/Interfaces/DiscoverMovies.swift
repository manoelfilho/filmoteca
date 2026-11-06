import Foundation

/// Descobre filmes combinando filtros e ordenação.
public protocol DiscoverMovies: Sendable {
    func discoverMovies(_ query: MovieDiscoverQuery) async throws -> PaginatedResult<Movie>
}

public struct MovieSort: Hashable, Sendable {
    public enum Field: Hashable, Sendable, CaseIterable {
        case popularity
        case releaseDate
        case voteAverage
        case voteCount
        case revenue
        case title
    }

    public enum Order: Hashable, Sendable {
        case ascending
        case descending
    }

    public var field: Field
    public var order: Order

    public init(_ field: Field, _ order: Order = .descending) {
        self.field = field
        self.order = order
    }

    public static let popularity = MovieSort(.popularity)
    public static let newest = MovieSort(.releaseDate)
    public static let bestRated = MovieSort(.voteAverage)
    public static let mostVoted = MovieSort(.voteCount)
}

public struct MovieDiscoverQuery: Hashable, Sendable {
    /// Como combinar vários gêneros.
    public enum GenreMatch: Hashable, Sendable {
        /// O filme precisa ter todos os gêneros.
        case all
        /// O filme precisa ter pelo menos um dos gêneros.
        case any
    }

    public var page: Int
    public var language: String?
    public var region: String?
    public var sort: MovieSort
    public var genreIDs: [Genre.ID]
    public var genreMatch: GenreMatch
    public var excludedGenreIDs: [Genre.ID]
    public var primaryReleaseYear: Int?
    public var releasedAfter: Date?
    public var releasedBefore: Date?
    /// Nota mínima, de 0 a 10.
    public var minimumVoteAverage: Double?
    /// Evita filmes com poucos votos ao ordenar por nota.
    public var minimumVoteCount: Int?
    /// Idioma original no formato ISO 639-1 (ex.: `pt`).
    public var originalLanguage: String?
    public var includeAdult: Bool
    /// Filmes disponíveis em qualquer um destes serviços.
    public var watchProviderIDs: [WatchProvider.ID]
    /// Formas de disponibilidade aceitas em `watchProviderIDs`. Vazio = qualquer uma.
    public var watchMonetizationTypes: Set<WatchMonetizationType>
    /// Região usada no filtro de serviços. `nil` usa `region` ou o padrão do provedor.
    public var watchRegion: String?

    public init(
        page: Int = 1,
        language: String? = nil,
        region: String? = nil,
        sort: MovieSort = .popularity,
        genreIDs: [Genre.ID] = [],
        genreMatch: GenreMatch = .all,
        excludedGenreIDs: [Genre.ID] = [],
        primaryReleaseYear: Int? = nil,
        releasedAfter: Date? = nil,
        releasedBefore: Date? = nil,
        minimumVoteAverage: Double? = nil,
        minimumVoteCount: Int? = nil,
        originalLanguage: String? = nil,
        includeAdult: Bool = false,
        watchProviderIDs: [WatchProvider.ID] = [],
        watchMonetizationTypes: Set<WatchMonetizationType> = [],
        watchRegion: String? = nil
    ) {
        self.page = page
        self.language = language
        self.region = region
        self.sort = sort
        self.genreIDs = genreIDs
        self.genreMatch = genreMatch
        self.excludedGenreIDs = excludedGenreIDs
        self.primaryReleaseYear = primaryReleaseYear
        self.releasedAfter = releasedAfter
        self.releasedBefore = releasedBefore
        self.minimumVoteAverage = minimumVoteAverage
        self.minimumVoteCount = minimumVoteCount
        self.originalLanguage = originalLanguage
        self.includeAdult = includeAdult
        self.watchProviderIDs = watchProviderIDs
        self.watchMonetizationTypes = watchMonetizationTypes
        self.watchRegion = watchRegion
    }
}
