import MovieDomain
import Observation

@Observable
final class TMDBMovieDetailViewModel {
    /// Resumo vindo da lista: permite desenhar a tela antes dos detalhes chegarem.
    let movie: Movie

    private(set) var details: MovieDetails?
    private(set) var credits: MovieCredits?
    private(set) var trailer: MovieVideo?
    private(set) var watchProviders: MovieWatchProviders?
    private(set) var recommendations: [Movie] = []
    private(set) var isLoading = false
    private(set) var error: DataSourceError?
    private(set) var isFavorite = false

    @ObservationIgnored private let getMovie: any GetMovie
    @ObservationIgnored private let getMovieCredits: any GetMovieCredits
    @ObservationIgnored private let listMovieVideos: any ListMovieVideos
    @ObservationIgnored private let getMovieWatchProviders: any GetMovieWatchProviders
    @ObservationIgnored private let listRelatedMovies: any ListRelatedMovies
    @ObservationIgnored private let checkFavoriteMovie: any CheckFavoriteMovie
    @ObservationIgnored private let saveFavoriteMovie: any SaveFavoriteMovie
    @ObservationIgnored private let removeFavoriteMovie: any RemoveFavoriteMovie

    init(
        movie: Movie,
        getMovie: any GetMovie,
        getMovieCredits: any GetMovieCredits,
        listMovieVideos: any ListMovieVideos,
        getMovieWatchProviders: any GetMovieWatchProviders,
        listRelatedMovies: any ListRelatedMovies,
        checkFavoriteMovie: any CheckFavoriteMovie,
        saveFavoriteMovie: any SaveFavoriteMovie,
        removeFavoriteMovie: any RemoveFavoriteMovie
    ) {
        self.movie = movie
        self.getMovie = getMovie
        self.getMovieCredits = getMovieCredits
        self.listMovieVideos = listMovieVideos
        self.getMovieWatchProviders = getMovieWatchProviders
        self.listRelatedMovies = listRelatedMovies
        self.checkFavoriteMovie = checkFavoriteMovie
        self.saveFavoriteMovie = saveFavoriteMovie
        self.removeFavoriteMovie = removeFavoriteMovie
    }

    /// Dados exibidos: detalhes quando já carregaram, senão o resumo da lista.
    var displayedMovie: Movie { details?.movie ?? movie }

    func loadIfNeeded() async {
        guard details == nil, !isLoading else { return }
        await load()
    }

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let id = movie.id
        let getMovie = getMovie
        let getMovieCredits = getMovieCredits
        let listMovieVideos = listMovieVideos
        let getMovieWatchProviders = getMovieWatchProviders
        let listRelatedMovies = listRelatedMovies

        // Tudo em paralelo. Só os detalhes são obrigatórios; o resto é complemento.
        async let details = getMovie.getMovie(id: id)
        async let credits = try? getMovieCredits.getMovieCredits(movieID: id)
        async let videos = try? listMovieVideos.listMovieVideos(movieID: id)
        async let providers = try? getMovieWatchProviders.getMovieWatchProviders(movieID: id)
        async let related = try? listRelatedMovies.listRelatedMovies(RelatedMoviesQuery(movieID: id))

        do {
            self.details = try await details
        } catch {
            self.error = error as? DataSourceError ?? .unknown(String(describing: error))
        }

        self.credits = await credits
        self.trailer = Self.bestTrailer(in: await videos ?? [])
        self.watchProviders = await providers
        self.recommendations = await related?.items ?? []
    }

    // MARK: - Favorito

    /// Lê do armazenamento local se o filme é favorito (a cada vez que a tela aparece).
    func refreshFavorite() async {
        isFavorite = (try? await checkFavoriteMovie.isFavoriteMovie(id: movie.id)) ?? false
    }

    /// Marca ou desmarca o filme. A tela muda na hora e volta atrás se a gravação falhar.
    func toggleFavorite() async {
        let shouldFavorite = !isFavorite
        isFavorite = shouldFavorite
        do {
            if shouldFavorite {
                // Guarda a versão mais completa disponível (com detalhes, quando já carregaram).
                try await saveFavoriteMovie.saveFavoriteMovie(displayedMovie)
            } else {
                try await removeFavoriteMovie.removeFavoriteMovie(id: movie.id)
            }
        } catch {
            isFavorite = !shouldFavorite
        }
    }

    /// Trailer oficial primeiro, depois qualquer trailer, depois teaser.
    private static func bestTrailer(in videos: [MovieVideo]) -> MovieVideo? {
        let playable = videos.filter { $0.url != nil }
        return playable.first { $0.kind == .trailer && $0.isOfficial }
            ?? playable.first { $0.kind == .trailer }
            ?? playable.first { $0.kind == .teaser }
    }
}
