import DesignSystem
import MovieDomain
import SwiftUI

/// Carrossel horizontal de gêneros ("Todos", "Ação", "Drama"…) para filtrar filmes.
///
/// Usado na Home, nos Favoritos e na Busca. `nil` em `selection` significa "Todos".
struct TMDBGenreChips: View {
    let genres: [Genre]
    @Binding var selection: Genre.ID?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: DSSpacing.xs) {
                    chip(String(localized: "tmdb_genre_all"), id: nil)
                    ForEach(genres) { genre in
                        chip(genre.name, id: genre.id)
                    }
                }
                .padding(.vertical, DSSpacing.xxs)
            }
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, DSSpacing.md, for: .scrollContent)
            .onChange(of: selection) { _, id in
                withAnimation(DSMotion.standard) {
                    proxy.scrollTo(id ?? "all", anchor: .center)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func chip(_ title: String, id: Genre.ID?) -> some View {
        let isSelected = selection == id

        return Button {
            withAnimation(DSMotion.standard) { selection = id }
        } label: {
            Text(title)
                .font(DSFont.callout.weight(.semibold))
                .foregroundStyle(isSelected ? DSColor.onPrimary : DSColor.textPrimary)
                .padding(.horizontal, DSSpacing.sm)
                .padding(.vertical, DSSpacing.xs)
                .background(isSelected ? DSColor.primary : DSColor.surface, in: Capsule())
                .overlay {
                    Capsule().strokeBorder(isSelected ? Color.clear : DSColor.border)
                }
        }
        .buttonStyle(.plain)
        .id(id ?? "all")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

extension View {
    /// Barra fixa logo abaixo do título da navegação (usada pelo carrossel de tipos).
    ///
    /// No iOS 26 ou mais novo acompanha o efeito de rolagem da barra; antes disso, fica como inset.
    func tmdbTopBar<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        modifier(TMDBTopBarModifier(bar: content()))
    }
}

private struct TMDBTopBarModifier<Bar: View>: ViewModifier {
    let bar: Bar

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.safeAreaBar(edge: .top) { bar }
        } else {
            content.safeAreaInset(edge: .top) {
                bar.background(DSColor.background)
            }
        }
    }
}
