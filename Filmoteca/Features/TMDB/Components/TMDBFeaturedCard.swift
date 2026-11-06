import DesignSystem
import MovieDomain
import SwiftUI

/// Card retangular grande do carrossel: imagem de fundo, serviço, título e votos.
struct TMDBFeaturedCard: View {
    let item: TMDBFeaturedMovie

    var body: some View {
        TMDBRemoteImage(image: item.movie.backdrop ?? item.movie.poster, size: .large)
            .aspectRatio(16 / 9, contentMode: .fit)
            .overlay {
                LinearGradient(
                    stops: [
                        .init(color: DSColor.scrim.opacity(0), location: 0.35),
                        .init(color: DSColor.scrim.opacity(0.85), location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .overlay(alignment: .topLeading) {
                TMDBProviderBadge(provider: item.provider, style: .media)
                    .padding(DSSpacing.sm)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                    Text(item.movie.title)
                        .font(DSFont.title)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    TMDBRatingLabel(movie: item.movie)
                        .font(DSFont.callout)
                        .opacity(0.9)
                }
                .foregroundStyle(DSColor.onMedia)
                .padding(DSSpacing.md)
            }
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DSRadius.lg, style: .continuous)
                    .strokeBorder(DSColor.onMedia.opacity(0.08))
            }
            .dsShadow(.md)
            .accessibilityElement(children: .combine)
    }
}
