/// Desmarca um filme como favorito. Remover um filme que não está salvo não é erro.
public protocol RemoveFavoriteMovie: Sendable {
    func removeFavoriteMovie(id: MovieID) async throws
}
