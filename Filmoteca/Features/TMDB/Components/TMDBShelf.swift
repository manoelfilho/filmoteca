import DesignSystem
import MovieDomain
import SwiftUI

/// Título de seção com subtítulo ("eyebrow") e ícone/logo opcionais.
struct TMDBSectionHeader<Leading: View>: View {
    let title: String
    var eyebrow: String?
    @ViewBuilder var leading: Leading

    var body: some View {
        HStack(spacing: DSSpacing.sm) {
            leading
            VStack(alignment: .leading, spacing: 0) {
                if let eyebrow {
                    Text(eyebrow)
                        .font(DSFont.caption.weight(.semibold))
                        .foregroundStyle(DSColor.textSecondary)
                        .textCase(.uppercase)
                }
                Text(title)
                    .font(DSFont.title)
                    .foregroundStyle(DSColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

extension TMDBSectionHeader where Leading == EmptyView {
    init(title: String, eyebrow: String? = nil) {
        self.init(title: title, eyebrow: eyebrow) { EmptyView() }
    }
}

/// Prateleira horizontal de filmes, com "snap" nos cards.
struct TMDBMovieShelf: View {
    let movies: [Movie]
    var provider: WatchProvider?
    var showsProvider = true

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: DSSpacing.sm) {
                ForEach(movies) { movie in
                    NavigationLink(value: movie) {
                        TMDBMovieCard(movie: movie, provider: provider, showsProvider: showsProvider)
                    }
                    .buttonStyle(.tmdbCard)
                    .containerRelativeFrame(.horizontal) { length, _ in
                        Self.cardWidth(for: length)
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, DSSpacing.md, for: .scrollContent)
    }

    /// iPhone: 1,6 card por tela (o próximo aparece cortado). Telas largas: 3,5 cards.
    static func cardWidth(for length: CGFloat) -> CGFloat {
        let visibleCards: CGFloat = length > 600 ? 3.5 : 1.6
        return (length - DSSpacing.sm * visibleCards.rounded(.down)) / visibleCards
    }
}
