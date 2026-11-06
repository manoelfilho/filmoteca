/// Busca elenco e equipe técnica de um filme.
public protocol GetMovieCredits: Sendable {
    func getMovieCredits(_ query: MovieCreditsQuery) async throws -> MovieCredits
}

public struct MovieCreditsQuery: Hashable, Sendable {
    public var movieID: MovieID
    public var language: String?

    public init(movieID: MovieID, language: String? = nil) {
        self.movieID = movieID
        self.language = language
    }
}

extension GetMovieCredits {
    public func getMovieCredits(movieID: MovieID) async throws -> MovieCredits {
        try await getMovieCredits(MovieCreditsQuery(movieID: movieID))
    }
}
