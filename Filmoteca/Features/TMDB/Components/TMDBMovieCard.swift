import DesignSystem
import MovieDomain
import SwiftUI

/// Card retangular das prateleiras e da busca: imagem 16:9 e, abaixo, título, votos e serviço.
struct TMDBMovieCard: View {
    let movie: Movie
    var provider: WatchProvider?
    var showsProvider = true
    /// Ajuda a diferenciar filmes homônimos (ex.: refilmagens) na busca.
    var showsReleaseYear = false

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            TMDBRemoteImage(image: movie.backdrop ?? movie.poster, size: .medium)
                .aspectRatio(16 / 9, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
                .dsShadow(.sm)

            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text(movie.title)
                    .font(DSFont.headline)
                    .foregroundStyle(DSColor.textPrimary)
                    .lineLimit(1)

                if showsReleaseYear, let year = movie.releaseYear {
                    Text(year)
                        .font(DSFont.caption)
                        .foregroundStyle(DSColor.textSecondary)
                }

                TMDBRatingLabel(movie: movie)
                    .font(DSFont.caption)
                    .foregroundStyle(DSColor.textSecondary)

                if showsProvider {
                    TMDBProviderBadge(provider: provider)
                }
            }
            .padding(.horizontal, DSSpacing.xxs)
        }
        .accessibilityElement(children: .combine)
    }
}
