/// Acompanha a lista de favoritos.
///
/// A sequência entrega a lista atual logo de início e uma nova lista a cada
/// mudança, venha ela de qualquer tela. Termina quando quem observa é cancelado.
public protocol ObserveFavoriteMovies: Sendable {
    func observeFavoriteMovies() async -> AsyncStream<[Movie]>
}
