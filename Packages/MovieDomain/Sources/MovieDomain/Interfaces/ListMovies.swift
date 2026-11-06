/// Lista filmes de uma categoria curada (populares, em cartaz etc.).
public protocol ListMovies: Sendable {
    func listMovies(_ query: MovieListQuery) async throws -> PaginatedResult<Movie>
}

public enum MovieListCategory: String, Hashable, Sendable, CaseIterable {
    case nowPlaying
    case popular
    case topRated
    case upcoming
}

public struct MovieListQuery: Hashable, Sendable {
    public var category: MovieListCategory
    public var page: Int
    /// Idioma no formato BCP 47 (ex.: `pt-BR`). `nil` usa o padrão do provedor.
    public var language: String?
    /// País no formato ISO 3166-1 (ex.: `BR`). Afeta datas de estreia e "em cartaz".
    public var region: String?

    public init(category: MovieListCategory, page: Int = 1, language: String? = nil, region: String? = nil) {
        self.category = category
        self.page = page
        self.language = language
        self.region = region
    }
}

extension ListMovies {
    public func listMovies(_ category: MovieListCategory, page: Int = 1) async throws -> PaginatedResult<Movie> {
        try await listMovies(MovieListQuery(category: category, page: page))
    }
}
