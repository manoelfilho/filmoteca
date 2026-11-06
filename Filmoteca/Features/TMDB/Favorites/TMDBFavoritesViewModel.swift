import MovieDomain
import Observation

/// Estado da aba Favoritos.
///
/// Depende só das interfaces de favoritos: não sabe que por trás está o SwiftData.
/// A lista acompanha o armazenamento, então favoritar ou desfavoritar em qualquer
/// tela (ex.: nos detalhes) atualiza esta aba sozinho.
@Observable
final class TMDBFavoritesViewModel {
    private(set) var movies: [Movie] = []
    /// Falso até a primeira leitura do armazenamento, para não piscar a tela vazia.
    private(set) var hasLoaded = false
    /// Gênero escolhido no carrossel de tipos; `nil` mostra todos.
    var selectedGenreID: Genre.ID?

    /// O gênero escolhido, se ainda houver favoritos dele (desfavoritar o último o desfaz).
    var activeGenreID: Genre.ID? {
        guard let selectedGenreID, movies.contains(where: { $0.genreIDs.contains(selectedGenreID) }) else { return nil }
        return selectedGenreID
    }

    var visibleMovies: [Movie] { movies.filtered(byGenre: activeGenreID) }

    @ObservationIgnored private let observeFavoriteMovies: any ObserveFavoriteMovies
    @ObservationIgnored private let removeFavoriteMovie: any RemoveFavoriteMovie

    init(observeFavoriteMovies: any ObserveFavoriteMovies, removeFavoriteMovie: any RemoveFavoriteMovie) {
        self.observeFavoriteMovies = observeFavoriteMovies
        self.removeFavoriteMovie = removeFavoriteMovie
    }

    /// Acompanha os favoritos até a tarefa ser cancelada (a view sai da tela).
    func observe() async {
        for await favorites in await observeFavoriteMovies.observeFavoriteMovies() {
            movies = favorites
            hasLoaded = true
        }
    }

    func remove(_ movie: Movie) async {
        // A lista atualiza pela observação; aqui só some na hora, sem esperar a gravação.
        movies.removeAll { $0.id == movie.id }
        try? await removeFavoriteMovie.removeFavoriteMovie(id: movie.id)
    }
}
