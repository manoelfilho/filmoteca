import DesignSystem
import MovieDomain
import SwiftUI

/// Logo + nome do serviço de streaming.
struct TMDBProviderBadge: View {
    enum Style {
        /// Sobre imagens: cápsula escura translúcida.
        case media
        /// Sobre o fundo do app: sem cápsula.
        case plain
    }

    let provider: WatchProvider?
    var style: Style = .plain

    var body: some View {
        HStack(spacing: DSSpacing.xs) {
            if let provider {
                TMDBProviderLogo(provider: provider, size: 20)
                Text(provider.name)
            } else {
                Image(systemName: "tv.slash")
                Text(String(localized: "tmdb_streaming_unavailable"))
            }
        }
        .font(DSFont.caption.weight(.semibold))
        .lineLimit(1)
        .modifier(BadgeBackground(style: style))
    }

    private struct BadgeBackground: ViewModifier {
        let style: Style

        func body(content: Content) -> some View {
            switch style {
            case .media:
                content
                    .foregroundStyle(DSColor.onMedia)
                    .padding(.vertical, DSSpacing.xxs)
                    .padding(.leading, DSSpacing.xxs)
                    .padding(.trailing, DSSpacing.sm)
                    .background(DSColor.scrim.opacity(0.45), in: Capsule())
            case .plain:
                content
                    .foregroundStyle(DSColor.textSecondary)
            }
        }
    }
}

struct TMDBProviderLogo: View {
    let provider: WatchProvider
    var size: CGFloat = 32

    var body: some View {
        TMDBRemoteImage(image: provider.logo, size: .small, placeholderSymbol: "tv")
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.25, style: .continuous))
    }
}
