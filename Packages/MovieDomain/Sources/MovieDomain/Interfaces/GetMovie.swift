/// Busca os detalhes completos de um filme.
public protocol GetMovie: Sendable {
    func getMovie(_ query: MovieDetailsQuery) async throws -> MovieDetails
}

public struct MovieDetailsQuery: Hashable, Sendable {
    public var id: MovieID
    public var language: String?

    public init(id: MovieID, language: String? = nil) {
        self.id = id
        self.language = language
    }
}

extension GetMovie {
    public func getMovie(id: MovieID) async throws -> MovieDetails {
        try await getMovie(MovieDetailsQuery(id: id))
    }
}
