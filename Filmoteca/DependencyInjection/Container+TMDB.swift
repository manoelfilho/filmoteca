import FactoryKit
import Foundation
import MovieDomain

/// Dependências do módulo TMDB (The Movie Database).
///
/// Os ViewModels recebem apenas interfaces de `MovieDomain` (registradas em
/// `Container+Movies.swift`), nunca o provedor concreto.
extension Container {
    @MainActor var tmdbView: Factory<TMDBView> {
        self { @MainActor in TMDBView() }
    }

    @MainActor var tmdbViewModel: Factory<TMDBViewModel> {
        self { @MainActor in TMDBViewModel() }
    }

    @MainActor var tmdbHomeViewModel: Factory<TMDBHomeViewModel> {
        self { @MainActor in
            TMDBHomeViewModel(
                discoverMovies: self.discoverMovies(),
                listWatchProviders: self.listWatchProviders(),
                getMovieWatchProviders: self.getMovieWatchProviders()
            )
        }
    }

    /// Compartilhado por todos os cards, para buscar os gêneros uma única vez.
    @MainActor var tmdbGenreCatalog: Factory<TMDBGenreCatalog> {
        self { @MainActor in TMDBGenreCatalog(listGenres: self.listGenres()) }
            .singleton
    }

    /// Perfil local (nome e foto) mostrado no topo da Home e na tela de edição.
    @MainActor var tmdbUserProfile: Factory<TMDBUserProfile> {
        self { @MainActor in TMDBUserProfile() }
            .singleton
    }

    /// Recebe o filme escolhido como parâmetro; as demais dependências vêm do container.
    @MainActor var tmdbMovieDetailViewModel: ParameterFactory<Movie, TMDBMovieDetailViewModel> {
        self { @MainActor movie in
            TMDBMovieDetailViewModel(
                movie: movie,
                getMovie: self.getMovie(),
                getMovieCredits: self.getMovieCredits(),
                listMovieVideos: self.listMovieVideos(),
                getMovieWatchProviders: self.getMovieWatchProviders(),
                listRelatedMovies: self.listRelatedMovies(),
                checkFavoriteMovie: self.checkFavoriteMovie(),
                saveFavoriteMovie: self.saveFavoriteMovie(),
                removeFavoriteMovie: self.removeFavoriteMovie()
            )
        }
    }

    @MainActor var tmdbFavoritesViewModel: Factory<TMDBFavoritesViewModel> {
        self { @MainActor in
            TMDBFavoritesViewModel(
                observeFavoriteMovies: self.observeFavoriteMovies(),
                removeFavoriteMovie: self.removeFavoriteMovie()
            )
        }
    }

    @MainActor var tmdbSearchViewModel: Factory<TMDBSearchViewModel> {
        self { @MainActor in
            TMDBSearchViewModel(
                searchMovies: self.searchMovies(),
                language: self.contentLanguage()
            )
        }
    }
}

extension Container {
    /// Folha "Assistir na TV": ofertas de streaming do filme e TVs pareadas.
    @MainActor var tmdbWatchOnTVViewModel: ParameterFactory<Movie, TMDBWatchOnTVViewModel> {
        self { @MainActor movie in
            TMDBWatchOnTVViewModel(
                movie: movie,
                listStreamingOffers: self.listStreamingOffers(),
                listPairedTVs: self.listPairedTVs(),
                pairTV: self.pairTV(),
                forgetTV: self.forgetTV(),
                launchOnTV: self.launchOnTV(),
                region: Locale.current.region?.identifier
            )
        }
    }
}
