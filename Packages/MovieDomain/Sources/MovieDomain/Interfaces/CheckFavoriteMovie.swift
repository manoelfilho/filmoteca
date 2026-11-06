/// Informa se um filme está entre os favoritos.
public protocol CheckFavoriteMovie: Sendable {
    func isFavoriteMovie(id: MovieID) async throws -> Bool
}
