import FactoryKit
import Foundation
import NetworkCore
import StreamingAvailabilityNetwork
import TMDBNetwork

/// Infraestrutura de rede e provedores de dados concretos.
///
/// Só este arquivo conhece as implementações (Alamofire, TMDB, Streaming Availability).
/// O resto do app usa as interfaces registradas em `Container+Movies.swift`.
extension Container {
    var httpClient: Factory<any HTTPClient> {
        self { AlamofireHTTPClient() }
            .singleton
    }

    var tmdbProviderConfiguration: Factory<TMDBConfiguration> {
        self {
            let api = self.tmdbConfiguration()
            return TMDBConfiguration(
                authentication: .init(credential: api.apiKey ?? ""),
                baseURL: api.baseURL,
                // Mesmo idioma da interface do app (pt-BR ou en-US).
                defaultLanguage: self.contentLanguage(),
                defaultRegion: Locale.current.region?.identifier,
                timeout: api.timeout
            )
        }
        .singleton
    }

    var tmdbMovieRepository: Factory<TMDBMovieRepository> {
        self {
            TMDBMovieRepository(
                configuration: self.tmdbProviderConfiguration(),
                client: self.httpClient()
            )
        }
        .singleton
    }

    var streamingAvailabilityProviderConfiguration: Factory<StreamingAvailabilityConfiguration> {
        self {
            let api = self.streamingAvailabilityConfiguration()
            return StreamingAvailabilityConfiguration(
                apiKey: api.apiKey ?? "",
                baseURL: api.baseURL,
                // Os filmes do app vêm do TMDB; a API aceita esses IDs diretamente.
                movieIDFormat: .tmdb,
                defaultRegion: Locale.current.region?.identifier,
                timeout: api.timeout
            )
        }
        .singleton
    }

    var streamingAvailabilityRepository: Factory<StreamingAvailabilityRepository> {
        self {
            StreamingAvailabilityRepository(
                configuration: self.streamingAvailabilityProviderConfiguration(),
                client: self.httpClient()
            )
        }
        .singleton
    }
}
