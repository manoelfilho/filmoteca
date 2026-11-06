import DesignSystem
import FactoryKit
import MovieDomain
import SwiftUI

/// "★ 8,4 · 30 mil votos · Drama"
struct TMDBRatingLabel: View {
    let movie: Movie
    /// A tela de detalhes já lista todos os gêneros, então pode ocultar o principal.
    var showsGenre = true

    @InjectedObservable(\.tmdbGenreCatalog) private var genres

    var body: some View {
        HStack(spacing: DSSpacing.xxs) {
            Image(systemName: "star.fill")
                .foregroundStyle(DSColor.accent)
            Text(movie.ratingText)
                .fontWeight(.semibold)
            Text("·")
            Text(movie.votesText)
                .fixedSize()

            if showsGenre, let genre = genres.primaryGenre(of: movie) {
                Text("·")
                // Só o gênero encolhe quando falta espaço.
                Text(genre)
            }
        }
        .lineLimit(1)
        .accessibilityElement(children: .combine)
    }
}
