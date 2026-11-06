import MovieDomain
import Observation

/// Filme do carrossel, com o serviço de streaming onde está disponível.
struct TMDBFeaturedMovie: Identifiable, Hashable {
    let movie: Movie
    let provider: WatchProvider?

    var id: MovieID { movie.id }
}

/// Prateleira com os filmes de um serviço de streaming, ordenados pelo critério do filtro.
struct TMDBStreamingShelf: Identifiable, Hashable {
    let provider: WatchProvider
    let movies: [Movie]

    var id: WatchProvider.ID { provider.id }
}

@Observable
final class TMDBHomeViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case failed(DataSourceError)
    }

    private(set) var state: State = .idle
    private(set) var featured: [TMDBFeaturedMovie] = []
    private(set) var shelves: [TMDBStreamingShelf] = []

    /// Ordenação e quantidade escolhidas no seletor da barra de navegação.
    var filter: TMDBHomeFilter

    /// Filtro do conteúdo que está na tela.
    @ObservationIgnored private var loadedFilter: TMDBHomeFilter?

    @ObservationIgnored private let discoverMovies: any DiscoverMovies
    @ObservationIgnored private let listWatchProviders: any ListWatchProviders
    @ObservationIgnored private let getMovieWatchProviders: any GetMovieWatchProviders

    private let shelfCount: Int

    init(
        discoverMovies: any DiscoverMovies,
        listWatchProviders: any ListWatchProviders,
        getMovieWatchProviders: any GetMovieWatchProviders,
        filter: TMDBHomeFilter = TMDBHomeFilter(),
        shelfCount: Int = 6
    ) {
        self.discoverMovies = discoverMovies
        self.listWatchProviders = listWatchProviders
        self.getMovieWatchProviders = getMovieWatchProviders
        self.filter = filter
        self.shelfCount = shelfCount
    }

    /// Carrega na primeira vez e sempre que o filtro mudar.
    func loadIfNeeded() async {
        guard loadedFilter != filter else { return }
        await load()
    }

    func load() async {
        let filter = filter
        let isNewFilter = loadedFilter != filter
        if featured.isEmpty || isNewFilter { state = .loading }

        async let featuredResult = loadFeatured(filter)
        async let shelvesResult = loadShelves(filter)

        let featuredMovies: Result<[TMDBFeaturedMovie], Error>
        do {
            featuredMovies = .success(try await featuredResult)
        } catch {
            featuredMovies = .failure(error)
        }
        let newShelves = await shelvesResult

        // O filtro mudou durante o carregamento: o resultado já não serve.
        guard !Task.isCancelled else { return }

        shelves = newShelves
        loadedFilter = filter

        switch featuredMovies {
        case .success(let movies):
            featured = movies
            state = .loaded
        case .failure(let error):
            // Com conteúdo do mesmo filtro já na tela (pull to refresh), mantém o que havia.
            if featured.isEmpty || isNewFilter {
                featured = []
                loadedFilter = nil
                state = .failed(error as? DataSourceError ?? .unknown(String(describing: error)))
            } else {
                state = .loaded
            }
        }
    }

    // MARK: - Carrossel

    /// Os primeiros filmes no critério escolhido, cada um com o seu serviço de streaming principal.
    private func loadFeatured(_ filter: TMDBHomeFilter) async throws -> [TMDBFeaturedMovie] {
        let query = MovieDiscoverQuery(sort: filter.ranking.sort, genreIDs: filter.genreIDs)
        let movies = Array(try await discoverMovies.discoverMovies(query).items.prefix(filter.limit))
        let getMovieWatchProviders = getMovieWatchProviders

        let providers = await withTaskGroup(of: (MovieID, WatchProvider?).self) { group in
            for movie in movies {
                group.addTask {
                    let availability = try? await getMovieWatchProviders.getMovieWatchProviders(movieID: movie.id)
                    return (movie.id, availability?.primaryStreaming)
                }
            }

            var providers: [MovieID: WatchProvider] = [:]
            for await (id, provider) in group {
                providers[id] = provider
            }
            return providers
        }

        return movies.map { TMDBFeaturedMovie(movie: $0, provider: providers[$0.id]) }
    }

    // MARK: - Prateleiras por streaming

    /// Filmes de cada serviço relevante na região, no critério escolhido.
    /// Falhas aqui não impedem a tela: a prateleira simplesmente não aparece.
    private func loadShelves(_ filter: TMDBHomeFilter) async -> [TMDBStreamingShelf] {
        guard let providers = try? await listWatchProviders.listWatchProviders() else { return [] }

        // Busca alguns serviços a mais: lojas (aluguel/compra) não têm catálogo por assinatura e voltam vazias.
        let candidates = Array(providers.prefix(shelfCount + 4))
        let discoverMovies = discoverMovies
        // Lidos aqui, no MainActor, para as tarefas do grupo receberem só valores.
        let sort = filter.ranking.sort
        let genreIDs = filter.genreIDs
        let limit = filter.limit

        let results = await withTaskGroup(of: (Int, [Movie]).self) { group in
            for (index, provider) in candidates.enumerated() {
                group.addTask {
                    let query = MovieDiscoverQuery(
                        sort: sort,
                        genreIDs: genreIDs,
                        watchProviderIDs: [provider.id],
                        watchMonetizationTypes: [.subscription, .free, .ads]
                    )
                    let page = try? await discoverMovies.discoverMovies(query)
                    return (index, Array((page?.items ?? []).prefix(limit)))
                }
            }

            var results: [Int: [Movie]] = [:]
            for await (index, movies) in group {
                results[index] = movies
            }
            return results
        }

        return candidates.enumerated()
            .compactMap { index, provider in
                guard let movies = results[index], !movies.isEmpty else { return nil }
                return TMDBStreamingShelf(provider: provider, movies: movies)
            }
            .prefix(shelfCount)
            .map { $0 }
    }
}
