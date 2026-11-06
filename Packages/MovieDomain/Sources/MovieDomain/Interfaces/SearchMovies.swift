/// Busca filmes por texto (título original, traduzido ou alternativo).
public protocol SearchMovies: Sendable {
    func searchMovies(_ query: MovieSearchQuery) async throws -> PaginatedResult<Movie>
}

public struct MovieSearchQuery: Hashable, Sendable {
    public var text: String
    public var page: Int
    public var language: String?
    public var region: String?
    /// Filtra por qualquer data de lançamento no ano.
    public var year: Int?
    /// Filtra pelo ano da estreia principal.
    public var primaryReleaseYear: Int?
    public var includeAdult: Bool

    public init(
        text: String,
        page: Int = 1,
        language: String? = nil,
        region: String? = nil,
        year: Int? = nil,
        primaryReleaseYear: Int? = nil,
        includeAdult: Bool = false
    ) {
        self.text = text
        self.page = page
        self.language = language
        self.region = region
        self.year = year
        self.primaryReleaseYear = primaryReleaseYear
        self.includeAdult = includeAdult
    }
}

extension SearchMovies {
    public func searchMovies(_ text: String, page: Int = 1) async throws -> PaginatedResult<Movie> {
        try await searchMovies(MovieSearchQuery(text: text, page: page))
    }
}
