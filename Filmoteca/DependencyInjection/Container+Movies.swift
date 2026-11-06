import FactoryKit
import MovieDomain

/// Interfaces de dados de filmes consumidas pelo app.
///
/// ViewModels dependem destes protocolos, nunca de `TMDBMovieRepository` ou `SwiftDataMovieStore`.
/// Para trocar de provedor (outra API, cache local, mock), mude só o lado direito:
///
///     var listMovies: Factory<any ListMovies> { self { self.outroRepository() } }
///
/// Em testes e previews, sobrescreva pontualmente:
///
///     Container.shared.listMovies.register { MockListMovies() }
extension Container {
    var listMovies: Factory<any ListMovies> {
        self { self.tmdbMovieRepository() }
    }

    var getMovie: Factory<any GetMovie> {
        self { self.tmdbMovieRepository() }
    }

    var searchMovies: Factory<any SearchMovies> {
        self { self.tmdbMovieRepository() }
    }

    var discoverMovies: Factory<any DiscoverMovies> {
        self { self.tmdbMovieRepository() }
    }

    var listGenres: Factory<any ListGenres> {
        self { self.tmdbMovieRepository() }
    }

    var getMovieCredits: Factory<any GetMovieCredits> {
        self { self.tmdbMovieRepository() }
    }

    var listMovieVideos: Factory<any ListMovieVideos> {
        self { self.tmdbMovieRepository() }
    }

    var listRelatedMovies: Factory<any ListRelatedMovies> {
        self { self.tmdbMovieRepository() }
    }

    var getMovieWatchProviders: Factory<any GetMovieWatchProviders> {
        self { self.tmdbMovieRepository() }
    }

    var listWatchProviders: Factory<any ListWatchProviders> {
        self { self.tmdbMovieRepository() }
    }

    var listStreamingOffers: Factory<any ListStreamingOffers> {
        self { self.watchmodeStreamingRepository() }
    }

    // MARK: - Favoritos (armazenamento local)

    var listFavoriteMovies: Factory<any ListFavoriteMovies> {
        self { self.movieStore() }
    }

    var observeFavoriteMovies: Factory<any ObserveFavoriteMovies> {
        self { self.movieStore() }
    }

    var saveFavoriteMovie: Factory<any SaveFavoriteMovie> {
        self { self.movieStore() }
    }

    var removeFavoriteMovie: Factory<any RemoveFavoriteMovie> {
        self { self.movieStore() }
    }

    var checkFavoriteMovie: Factory<any CheckFavoriteMovie> {
        self { self.movieStore() }
    }
}
