import DesignSystem
import FactoryKit
import SwiftUI

/// Raiz do módulo TMDB: uma TabView com Início, Favoritos, Busca e Sobre.
///
/// Cada aba tem a sua própria `NavigationStack`, para que a navegação
/// de uma aba não interfira nas outras.
struct TMDBView: View {
    @InjectedObservable(\.tmdbViewModel) private var viewModel
    @InjectedObservable(\.tmdbGenreCatalog) private var genres

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            ForEach(viewModel.tabs) { tab in
                NavigationStack {
                    content(for: tab)
                        .navigationTitle(tab.title)
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.systemImage)
                }
                .tag(tab)
            }
        }
        .tint(DSColor.primary)
        .task { await genres.loadIfNeeded() }
    }

    @ViewBuilder
    private func content(for tab: TMDBTab) -> some View {
        switch tab {
        case .home: TMDBHomeView()
        case .favorites: TMDBFavoritesView()
        case .search: TMDBSearchView()
        case .about: TMDBAboutView()
        }
    }
}

#Preview {
    Container.shared.tmdbView()
}
