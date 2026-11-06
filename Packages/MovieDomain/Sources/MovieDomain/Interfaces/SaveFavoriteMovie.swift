/// Marca um filme como favorito. Salvar de novo o mesmo filme atualiza os dados guardados.
public protocol SaveFavoriteMovie: Sendable {
    func saveFavoriteMovie(_ movie: Movie) async throws
}
