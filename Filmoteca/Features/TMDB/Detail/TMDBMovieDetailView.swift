import DesignSystem
import FactoryKit
import MovieDomain
import SwiftUI

struct TMDBMovieDetailView: View {
    @State private var viewModel: TMDBMovieDetailViewModel
    @Environment(\.openURL) private var openURL
    @State private var isShowingWatchOnTV = false

    init(movie: Movie) {
        // ViewModel com parâmetro: resolvido pela ParameterFactory do container.
        _viewModel = State(initialValue: Container.shared.tmdbMovieDetailViewModel(movie))
    }

    private var movie: Movie { viewModel.displayedMovie }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                hero

                VStack(alignment: .leading, spacing: DSSpacing.xl) {
                    actions
                    availability
                    overview
                    if let error = viewModel.error, viewModel.details == nil {
                        inlineError(error)
                    }
                    cast
                    information
                }
                .padding(.horizontal, DSSpacing.md)

                recommendations
            }
            .padding(.bottom, DSSpacing.xxl)
        }
        .ignoresSafeArea(edges: .top)
        .background(DSColor.background)
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                watchOnTVButton
            }
            ToolbarItem(placement: .primaryAction) {
                favoriteButton
            }
        }
        .sheet(isPresented: $isShowingWatchOnTV) {
            TMDBWatchOnTVSheet(movie: movie, providers: availableProviders)
        }
        .task { await viewModel.loadIfNeeded() }
        .task { await viewModel.refreshFavorite() }
    }

    // MARK: - Assistir na TV

    private var watchOnTVButton: some View {
        Button {
            isShowingWatchOnTV = true
        } label: {
            Label(String(localized: "tmdb_tv_title"), systemImage: "tv.badge.wifi")
                .labelStyle(.iconOnly)
        }
        .tint(DSColor.textPrimary)
    }

    /// Serviços do TMDB para a folha mostrar os logos.
    private var availableProviders: [WatchProvider] {
        guard let providers = viewModel.watchProviders else { return [] }
        return uniqueProviders(providers.streaming + providers.rent + providers.buy)
    }

    // MARK: - Favorito

    private var favoriteButton: some View {
        Button {
            Task { await viewModel.toggleFavorite() }
        } label: {
            Label(
                String(localized: viewModel.isFavorite ? "tmdb_detail_unfavorite" : "tmdb_detail_favorite"),
                systemImage: viewModel.isFavorite ? "heart.fill" : "heart"
            )
            .labelStyle(.iconOnly)
            .contentTransition(.symbolEffect(.replace))
            .symbolEffect(.bounce, value: viewModel.isFavorite)
        }
        // Na barra, a cor do ícone vem do tint (foregroundStyle é ignorado).
        .tint(viewModel.isFavorite ? DSColor.destructive : DSColor.textPrimary)
        .sensoryFeedback(.selection, trigger: viewModel.isFavorite)
    }

    // MARK: - Destaque

    private var hero: some View {
        Color.clear
            .containerRelativeFrame(.vertical) { length, _ in length * 0.62 }
            .frame(maxWidth: .infinity)
            .overlay {
                GeometryReader { proxy in
                    // Tela alta (iPhone): pôster. Tela larga: imagem de fundo 16:9.
                    let isWide = proxy.size.width > proxy.size.height * 1.2
                    TMDBRemoteImage(
                        image: isWide ? (movie.backdrop ?? movie.poster) : (movie.poster ?? movie.backdrop),
                        size: .large
                    )
                    // Pôsteres costumam ter o título impresso embaixo: ancora no topo e corta o rodapé.
                    .frame(width: proxy.size.width, height: proxy.size.height * (isWide ? 1 : 1.15))
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
                }
            }
            .overlay {
                LinearGradient(
                    stops: [
                        .init(color: DSColor.background.opacity(0), location: 0.4),
                        .init(color: DSColor.background.opacity(0.92), location: 0.72),
                        .init(color: DSColor.background, location: 0.85),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .overlay(alignment: .bottom) {
                heroTitle
                    .padding(.horizontal, DSSpacing.md)
            }
            .clipped()
    }

    private var heroTitle: some View {
        VStack(spacing: DSSpacing.xs) {
            Text(movie.title)
                .font(DSFont.display)
                .multilineTextAlignment(.center)
                .foregroundStyle(DSColor.textPrimary)
                .lineLimit(3)
                .minimumScaleFactor(0.7)

            Text(metadataLine)
                .font(DSFont.callout)
                .foregroundStyle(DSColor.textSecondary)
                .multilineTextAlignment(.center)

            TMDBRatingLabel(movie: movie, showsGenre: false)
                .font(DSFont.callout)
                .foregroundStyle(DSColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    /// "1999 · Drama, Thriller · 2 h 19 min"
    private var metadataLine: String {
        [movie.releaseYear, viewModel.details?.genresText, viewModel.details?.runtimeText]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    // MARK: - Ações

    @ViewBuilder
    private var actions: some View {
        let trailerURL = viewModel.trailer?.url
        let watchURL = viewModel.watchProviders?.link

        if trailerURL != nil || watchURL != nil {
            HStack(spacing: DSSpacing.sm) {
                if let trailerURL {
                    Button {
                        openURL(trailerURL)
                    } label: {
                        Label(String(localized: "tmdb_detail_watch_trailer"), systemImage: "play.fill")
                    }
                    .buttonStyle(.ds(.primary))
                }

                if let watchURL {
                    Button {
                        openURL(watchURL)
                    } label: {
                        Label(String(localized: "tmdb_detail_where_to_watch"), systemImage: "tv")
                    }
                    .buttonStyle(.ds(.secondary))
                }
            }
        }
    }

    // MARK: - Onde assistir

    @ViewBuilder
    private var availability: some View {
        if let providers = viewModel.watchProviders {
            let streaming = providers.streaming
            let rentOrBuy = uniqueProviders(providers.rent + providers.buy)

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                if !streaming.isEmpty {
                    providerRow(title: String(localized: "tmdb_detail_available_on"), providers: streaming)
                }
                if !rentOrBuy.isEmpty {
                    providerRow(title: String(localized: "tmdb_detail_rent_or_buy"), providers: rentOrBuy)
                }
                if streaming.isEmpty, rentOrBuy.isEmpty {
                    TMDBProviderBadge(provider: nil)
                }
            }
        }
    }

    private func providerRow(title: String, providers: [WatchProvider]) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            Text(title)
                .font(DSFont.headline)
                .foregroundStyle(DSColor.textPrimary)

            ScrollView(.horizontal) {
                HStack(spacing: DSSpacing.sm) {
                    ForEach(providers) { provider in
                        HStack(spacing: DSSpacing.xs) {
                            TMDBProviderLogo(provider: provider, size: 20)
                            Text(provider.name)
                                .font(DSFont.callout)
                                .foregroundStyle(DSColor.textPrimary)
                                .lineLimit(1)
                        }
                        .padding(.vertical, DSSpacing.xxs)
                        .padding(.leading, DSSpacing.xxs)
                        .padding(.trailing, DSSpacing.sm)
                        .background(DSColor.surface, in: Capsule())
                        .overlay(Capsule().strokeBorder(DSColor.border))
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private func uniqueProviders(_ providers: [WatchProvider]) -> [WatchProvider] {
        var seen = Set<WatchProvider.ID>()
        return providers.filter { seen.insert($0.id).inserted }
    }

    // MARK: - Sinopse

    private var overview: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            TMDBSectionHeader(title: String(localized: "tmdb_detail_overview"))

            if let tagline = viewModel.details?.tagline {
                Text(tagline)
                    .font(DSFont.callout.italic())
                    .foregroundStyle(DSColor.textSecondary)
            }

            Text(movie.overview.isEmpty ? String(localized: "tmdb_detail_no_overview") : movie.overview)
                .font(DSFont.body)
                .foregroundStyle(DSColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if viewModel.isLoading, viewModel.details == nil {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, DSSpacing.md)
            }
        }
    }

    private func inlineError(_ error: DataSourceError) -> some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Label(error.localizedMessage, systemImage: "exclamationmark.triangle")
                    .font(DSFont.callout)
                    .foregroundStyle(DSColor.textPrimary)
                Button(String(localized: "common_retry")) {
                    Task { await viewModel.load() }
                }
                .buttonStyle(.ds(.secondary))
            }
        }
    }

    // MARK: - Elenco

    @ViewBuilder
    private var cast: some View {
        if let credits = viewModel.credits, !credits.cast.isEmpty {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                TMDBSectionHeader(title: String(localized: "tmdb_detail_cast"))

                let directors = credits.directors.map(\.name)
                if !directors.isEmpty {
                    Text(String(localized: "tmdb_detail_directed_by \(directors.formatted(.list(type: .and)))"))
                        .font(DSFont.callout)
                        .foregroundStyle(DSColor.textSecondary)
                }

                ScrollView(.horizontal) {
                    LazyHStack(alignment: .top, spacing: DSSpacing.md) {
                        ForEach(credits.cast.prefix(20)) { member in
                            castMember(member)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                // A linha ocupa a largura toda, mas começa alinhada ao conteúdo.
                .padding(.horizontal, -DSSpacing.md)
                .contentMargins(.horizontal, DSSpacing.md, for: .scrollContent)
            }
        }
    }

    private func castMember(_ member: CastMember) -> some View {
        VStack(spacing: DSSpacing.xs) {
            TMDBRemoteImage(image: member.profile, size: .medium, placeholderSymbol: "person.fill")
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(DSColor.border))

            VStack(spacing: 2) {
                Text(member.name)
                    .font(DSFont.caption.weight(.semibold))
                    .foregroundStyle(DSColor.textPrimary)
                Text(member.character)
                    .font(DSFont.caption)
                    .foregroundStyle(DSColor.textSecondary)
            }
            .multilineTextAlignment(.center)
            .lineLimit(2)
        }
        .frame(width: 92)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Informações

    @ViewBuilder
    private var information: some View {
        if let details = viewModel.details {
            let rows: [(String, String?)] = [
                (String(localized: "tmdb_detail_original_title"), details.movie.originalTitle),
                (String(localized: "tmdb_detail_release_date"), details.movie.releaseDateText),
                (String(localized: "tmdb_detail_runtime"), details.runtimeText),
                (String(localized: "tmdb_detail_status"), details.status.localizedName),
                (String(localized: "tmdb_detail_original_language"), details.movie.originalLanguageName),
                (String(localized: "tmdb_detail_budget"), details.budgetText),
                (String(localized: "tmdb_detail_revenue"), details.revenueText),
                (
                    String(localized: "tmdb_detail_production"),
                    details.productionCompanies.isEmpty
                        ? nil
                        : details.productionCompanies.prefix(3).map(\.name).joined(separator: ", ")
                ),
            ]

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                TMDBSectionHeader(title: String(localized: "tmdb_detail_info"))

                DSCard {
                    Grid(alignment: .topLeading, horizontalSpacing: DSSpacing.md, verticalSpacing: DSSpacing.sm) {
                        ForEach(rows.filter { $0.1 != nil }, id: \.0) { label, value in
                            GridRow {
                                Text(label)
                                    .foregroundStyle(DSColor.textSecondary)
                                Text(value ?? "")
                                    .foregroundStyle(DSColor.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .font(DSFont.callout)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recomendações

    @ViewBuilder
    private var recommendations: some View {
        if !viewModel.recommendations.isEmpty {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                TMDBSectionHeader(title: String(localized: "tmdb_detail_recommendations"))
                    .padding(.horizontal, DSSpacing.md)

                TMDBMovieShelf(movies: viewModel.recommendations, showsProvider: false)
            }
        }
    }
}

#Preview {
    NavigationStack {
        TMDBMovieDetailView(
            movie: Movie(id: 550, title: "Clube da Luta", originalTitle: "Fight Club")
        )
    }
}
