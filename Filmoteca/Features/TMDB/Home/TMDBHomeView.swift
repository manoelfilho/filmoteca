import DesignSystem
import FactoryKit
import MovieDomain
import SwiftUI

struct TMDBHomeView: View {
    @InjectedObservable(\.tmdbHomeViewModel) private var viewModel
    @InjectedObservable(\.tmdbGenreCatalog) private var genres
    @State private var currentFeaturedID: MovieID?

    /// Tempo até o carrossel avançar sozinho.
    private let autoAdvanceInterval: Duration = .seconds(6)

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DSColor.background)
            .navigationDestination(for: Movie.self) { movie in
                TMDBMovieDetailView(movie: movie)
            }
            // Fica logo abaixo do título da navegação.
            .tmdbTopBar {
                TMDBGenreChips(genres: genres.genres, selection: $viewModel.filter.genreID)
                    .padding(.bottom, DSSpacing.xs)
            }
            .toolbar {
                if #available(iOS 26, *) {
                    // Sem a cápsula de vidro: foto e nome ficam soltos, como um cabeçalho.
                    ToolbarItem(placement: .topBarLeading) {
                        TMDBProfileHeader()
                    }
                    .sharedBackgroundVisibility(.hidden)
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        TMDBProfileHeader()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    filterMenu
                }
            }
            // Recarrega quando o filtro muda; um carregamento em andamento é cancelado.
            .task(id: viewModel.filter) {
                currentFeaturedID = nil
                await viewModel.loadIfNeeded()
            }
    }

    // MARK: - Filtro

    private var filterMenu: some View {
        Menu {
            Section(String(localized: "tmdb_home_filter_sort")) {
                Picker(String(localized: "tmdb_home_filter_sort"), selection: $viewModel.filter.ranking) {
                    ForEach(TMDBHomeFilter.Ranking.allCases) { ranking in
                        Label(ranking.title, systemImage: ranking.systemImage)
                            .tag(ranking)
                    }
                }
                .pickerStyle(.inline)
            }

            Section(String(localized: "tmdb_home_filter_limit")) {
                Picker(String(localized: "tmdb_home_filter_limit"), selection: $viewModel.filter.limit) {
                    ForEach(TMDBHomeFilter.limitOptions, id: \.self) { limit in
                        Text(String(localized: "tmdb_home_filter_limit_option \(limit)"))
                            .tag(limit)
                    }
                }
                .pickerStyle(.inline)
            }
        } label: {
            Label(String(localized: "tmdb_home_filter"), systemImage: "line.3.horizontal.decrease.circle")
        }
        .accessibilityValue(Text("\(viewModel.filter.ranking.title), \(viewModel.filter.limit)"))
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            TMDBHomeSkeleton()
        case .failed(let error):
            errorView(error)
        case .loaded where viewModel.featured.isEmpty && viewModel.shelves.isEmpty:
            ContentUnavailableView(
                String(localized: "tmdb_genre_empty_title"),
                systemImage: "film.stack",
                description: Text(String(localized: "tmdb_genre_empty_description"))
            )
        case .loaded:
            loadedContent
        }
    }

    /// "Em alta" ou "Mais votados", com o gênero quando há um escolhido (ex.: "Em alta · Drama").
    private var shelfEyebrow: String {
        let ranking = viewModel.filter.ranking.title
        guard let genreID = viewModel.filter.genreID, let genre = genres.names[genreID] else { return ranking }
        return "\(ranking) · \(genre)"
    }

    private var loadedContent: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: DSSpacing.xl) {
                if !viewModel.featured.isEmpty {
                    featuredCarousel
                }

                ForEach(viewModel.shelves) { shelf in
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        TMDBSectionHeader(
                            title: shelf.provider.name,
                            eyebrow: shelfEyebrow
                        ) {
                            TMDBProviderLogo(provider: shelf.provider, size: 40)
                        }
                        .padding(.horizontal, DSSpacing.md)

                        TMDBMovieShelf(movies: shelf.movies, provider: shelf.provider)
                    }
                }
            }
            .padding(.vertical, DSSpacing.md)
        }
        .refreshable { await viewModel.load() }
    }

    // MARK: - Carrossel

    private var featuredCarousel: some View {
        VStack(spacing: DSSpacing.sm) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: DSSpacing.sm) {
                    ForEach(viewModel.featured) { item in
                        NavigationLink(value: item.movie) {
                            TMDBFeaturedCard(item: item)
                        }
                        .buttonStyle(.tmdbCard)
                        .containerRelativeFrame(.horizontal) { length, _ in
                            // Telas largas mostram dois destaques lado a lado.
                            length > 700 ? (length - DSSpacing.sm) / 2 : length
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $currentFeaturedID)
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, DSSpacing.md, for: .scrollContent)

            pageIndicator
        }
        .task(id: currentFeaturedID) {
            try? await Task.sleep(for: autoAdvanceInterval)
            guard !Task.isCancelled else { return }
            withAnimation(DSMotion.standard) {
                currentFeaturedID = nextFeaturedID()
            }
        }
    }

    private var pageIndicator: some View {
        let selectedID = currentFeaturedID ?? viewModel.featured.first?.id

        return HStack(spacing: DSSpacing.xxs + 2) {
            ForEach(viewModel.featured) { item in
                let isSelected = item.id == selectedID
                Capsule()
                    .fill(isSelected ? DSColor.textPrimary : DSColor.border)
                    .frame(width: isSelected ? 18 : 6, height: 6)
            }
        }
        .animation(DSMotion.spring, value: selectedID)
        .accessibilityHidden(true)
    }

    private func nextFeaturedID() -> MovieID? {
        let items = viewModel.featured
        guard !items.isEmpty else { return nil }
        let currentIndex = items.firstIndex { $0.id == currentFeaturedID } ?? 0
        return items[(currentIndex + 1) % items.count].id
    }

    // MARK: - Erro

    private func errorView(_ error: DataSourceError) -> some View {
        ContentUnavailableView {
            Label(String(localized: "tmdb_error_title"), systemImage: "wifi.exclamationmark")
        } description: {
            Text(error.localizedMessage)
        } actions: {
            Button(String(localized: "common_retry")) {
                Task { await viewModel.load() }
            }
            .buttonStyle(.ds(.primary))
            .frame(maxWidth: 240)
        }
    }
}

/// Esqueleto exibido no primeiro carregamento, com o mesmo formato da tela final.
private struct TMDBHomeSkeleton: View {
    @State private var isPulsing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                RoundedRectangle(cornerRadius: DSRadius.lg, style: .continuous)
                    .fill(DSColor.surface)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .padding(.horizontal, DSSpacing.md)

                ForEach(0..<2, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        RoundedRectangle(cornerRadius: DSRadius.sm)
                            .fill(DSColor.surface)
                            .frame(width: 200, height: 24)
                        HStack(spacing: DSSpacing.sm) {
                            ForEach(0..<2, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                                    .fill(DSColor.surface)
                                    .aspectRatio(16 / 9, contentMode: .fit)
                            }
                        }
                    }
                    .padding(.horizontal, DSSpacing.md)
                }
            }
            .padding(.vertical, DSSpacing.md)
        }
        .scrollDisabled(true)
        .opacity(isPulsing ? 0.5 : 1)
        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: isPulsing)
        .onAppear { isPulsing = true }
        .accessibilityLabel(Text(String(localized: "tmdb_loading")))
    }
}

#Preview {
    NavigationStack {
        TMDBHomeView()
            .navigationTitle(String(localized: "tmdb_tab_home"))
    }
}
