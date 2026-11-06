import DesignSystem
import FactoryKit
import MovieDomain
import SwiftUI

struct TMDBFavoritesView: View {
    @InjectedObservable(\.tmdbFavoritesViewModel) private var viewModel
    @InjectedObservable(\.tmdbGenreCatalog) private var genres

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DSColor.background)
            .animation(DSMotion.standard, value: viewModel.visibleMovies)
            .tmdbTopBar {
                if !viewModel.movies.isEmpty {
                    TMDBGenreChips(genres: genres.genres(in: viewModel.movies), selection: genreSelection)
                        .padding(.bottom, DSSpacing.xs)
                }
            }
            .navigationDestination(for: Movie.self) { movie in
                TMDBMovieDetailView(movie: movie)
            }
            .task { await viewModel.observe() }
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.hasLoaded {
            ProgressView()
                .controlSize(.large)
                .accessibilityLabel(Text(String(localized: "tmdb_loading")))
        } else if viewModel.movies.isEmpty {
            ContentUnavailableView(
                String(localized: "tmdb_favorites_empty_title"),
                systemImage: "heart",
                description: Text(String(localized: "tmdb_favorites_empty_description"))
            )
        } else {
            favorites
        }
    }

    private var genreSelection: Binding<Genre.ID?> {
        Binding(
            get: { viewModel.activeGenreID },
            set: { viewModel.selectedGenreID = $0 }
        )
    }

    private var favorites: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                Text(String(localized: "tmdb_favorites_count \(viewModel.visibleMovies.count)"))
                    .font(DSFont.caption.weight(.semibold))
                    .foregroundStyle(DSColor.textSecondary)
                    .textCase(.uppercase)

                TMDBMovieGrid(movies: viewModel.visibleMovies) { movie in
                    Button(role: .destructive) {
                        Task { await viewModel.remove(movie) }
                    } label: {
                        Label(String(localized: "tmdb_detail_unfavorite"), systemImage: "heart.slash")
                    }
                }
            }
            .padding(DSSpacing.md)
        }
    }
}

#Preview {
    NavigationStack {
        TMDBFavoritesView()
            .navigationTitle(String(localized: "tmdb_tab_favorites"))
    }
}
