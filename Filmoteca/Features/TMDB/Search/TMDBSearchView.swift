import DesignSystem
import FactoryKit
import MovieDomain
import SwiftUI

struct TMDBSearchView: View {
    @InjectedObservable(\.tmdbSearchViewModel) private var viewModel
    @InjectedObservable(\.tmdbGenreCatalog) private var genres

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DSColor.background)
            .searchable(text: $viewModel.query, prompt: Text(String(localized: "tmdb_search_prompt")))
            .autocorrectionDisabled()
            .tmdbTopBar {
                if !viewModel.results.isEmpty {
                    TMDBGenreChips(genres: genres.genres(in: viewModel.results), selection: genreSelection)
                        .padding(.bottom, DSSpacing.xs)
                }
            }
            // Cada mudança do texto cancela a busca anterior e agenda uma nova (com debounce).
            .task(id: viewModel.query) { await viewModel.queryChanged() }
            .navigationDestination(for: Movie.self) { movie in
                TMDBMovieDetailView(movie: movie)
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableView(
                String(localized: "tmdb_search_empty_title"),
                systemImage: "magnifyingglass",
                description: Text(String(localized: "tmdb_search_empty_description"))
            )
        case .loading:
            ProgressView()
                .controlSize(.large)
                .accessibilityLabel(Text(String(localized: "tmdb_loading")))
        case .failed(let error):
            errorView(error)
        case .loaded where viewModel.results.isEmpty:
            ContentUnavailableView.search(text: viewModel.searchText)
        case .loaded:
            results
        }
    }

    // MARK: - Resultados

    private var genreSelection: Binding<Genre.ID?> {
        Binding(
            get: { viewModel.activeGenreID },
            set: { viewModel.selectedGenreID = $0 }
        )
    }

    private var results: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DSSpacing.md) {
                TMDBSectionHeader(
                    title: String(localized: "tmdb_search_results_title \(viewModel.searchText)"),
                    eyebrow: String(localized: "tmdb_search_results_count \(viewModel.totalResults)")
                ) {
                    if viewModel.isSearching {
                        ProgressView()
                    }
                }

                TMDBMovieGrid(movies: viewModel.visibleResults)

                if viewModel.hasNextPage {
                    // Aparece ao chegar no fim da lista e dispara a próxima página.
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DSSpacing.md)
                        .task(id: viewModel.results.count) { await viewModel.loadNextPage() }
                }
            }
            .padding(DSSpacing.md)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    // MARK: - Erro

    private func errorView(_ error: DataSourceError) -> some View {
        ContentUnavailableView {
            Label(String(localized: "tmdb_error_title"), systemImage: "wifi.exclamationmark")
        } description: {
            Text(error.localizedMessage)
        } actions: {
            Button(String(localized: "common_retry")) {
                Task { await viewModel.retry() }
            }
            .buttonStyle(.ds(.primary))
            .frame(maxWidth: 240)
        }
    }
}

#Preview {
    NavigationStack {
        TMDBSearchView()
            .navigationTitle(String(localized: "tmdb_tab_search"))
    }
}
