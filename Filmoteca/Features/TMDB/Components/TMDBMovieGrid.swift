import DesignSystem
import MovieDomain
import SwiftUI

/// Grade de cards de filme usada pela Busca e pelos Favoritos.
///
/// iPhone: duas colunas. Telas largas: quantas couberem.
/// Cada card abre os detalhes (`navigationDestination(for: Movie.self)` de quem usa a grade).
struct TMDBMovieGrid<Menu: View>: View {
    let movies: [Movie]
    /// Ações do menu de contexto de cada card (toque longo / clique secundário).
    @ViewBuilder var menu: (Movie) -> Menu

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 320), spacing: DSSpacing.sm, alignment: .top),
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: DSSpacing.lg) {
            ForEach(movies) { movie in
                NavigationLink(value: movie) {
                    TMDBMovieCard(movie: movie, showsProvider: false, showsReleaseYear: true)
                }
                .buttonStyle(.tmdbCard)
                .contextMenu { menu(movie) }
            }
        }
    }
}

extension TMDBMovieGrid where Menu == EmptyView {
    init(movies: [Movie]) {
        self.init(movies: movies) { _ in EmptyView() }
    }
}
