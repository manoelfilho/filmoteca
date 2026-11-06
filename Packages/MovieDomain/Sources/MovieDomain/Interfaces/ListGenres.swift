/// Lista os gêneros de filmes disponíveis.
public protocol ListGenres: Sendable {
    func listGenres(_ query: GenreListQuery) async throws -> [Genre]
}

public struct GenreListQuery: Hashable, Sendable {
    public var language: String?

    public init(language: String? = nil) {
        self.language = language
    }
}

extension ListGenres {
    public func listGenres() async throws -> [Genre] {
        try await listGenres(GenreListQuery())
    }
}
