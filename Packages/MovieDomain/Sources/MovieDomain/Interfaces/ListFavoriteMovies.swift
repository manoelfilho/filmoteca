/// Lista os filmes marcados como favoritos, do mais recente para o mais antigo.
public protocol ListFavoriteMovies: Sendable {
    func listFavoriteMovies() async throws -> [Movie]
}
