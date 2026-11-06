/// Lista filmes relacionados a outro (recomendações ou similares).
public protocol ListRelatedMovies: Sendable {
    func listRelatedMovies(_ query: RelatedMoviesQuery) async throws -> PaginatedResult<Movie>
}

public enum MovieRelation: Hashable, Sendable, CaseIterable {
    /// Sugestões baseadas no que outros usuários assistiram.
    case recommendations
    /// Filmes com gêneros e palavras-chave parecidos.
    case similar
}

public struct RelatedMoviesQuery: Hashable, Sendable {
    public var movieID: MovieID
    public var relation: MovieRelation
    public var page: Int
    public var language: String?

    public init(movieID: MovieID, relation: MovieRelation = .recommendations, page: Int = 1, language: String? = nil) {
        self.movieID = movieID
        self.relation = relation
        self.page = page
        self.language = language
    }
}
