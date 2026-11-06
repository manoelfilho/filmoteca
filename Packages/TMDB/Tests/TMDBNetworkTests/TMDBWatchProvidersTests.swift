import Foundation
import MovieDomain
import NetworkCore
import Testing
@testable import TMDBNetwork

@Suite("TMDB watch providers")
struct TMDBWatchProvidersTests {
    let client = StubHTTPClient()

    func makeRepository(region: String? = "BR") -> TMDBMovieRepository {
        TMDBMovieRepository(
            configuration: TMDBConfiguration(authentication: .apiKey("KEY"), defaultLanguage: "pt-BR", defaultRegion: region),
            client: client
        )
    }

    @Test("Disponibilidade do filme: filtra a região e ordena por relevância")
    func movieWatchProviders() async throws {
        client.stub(path: "movie/550/watch/providers", json: #"""
        {
          "id": 550,
          "results": {
            "BR": {
              "link": "https://www.themoviedb.org/movie/550-fight-club/watch?locale=BR",
              "flatrate": [
                {"logo_path": "/prime.png", "provider_id": 119, "provider_name": "Amazon Prime Video", "display_priority": 1},
                {"logo_path": "/netflix.png", "provider_id": 8, "provider_name": "Netflix", "display_priority": 0}
              ],
              "rent": [{"logo_path": "/apple.png", "provider_id": 2, "provider_name": "Apple TV Store", "display_priority": 3}]
            },
            "US": {"flatrate": [{"provider_id": 15, "provider_name": "Hulu", "display_priority": 0}]}
          }
        }
        """#)
        let getProviders: any GetMovieWatchProviders = makeRepository()

        let providers = try await getProviders.getMovieWatchProviders(movieID: 550)

        #expect(providers.region == "BR")
        #expect(providers.primaryStreaming?.name == "Netflix")
        #expect(providers.streaming.map(\.id) == ["8", "119"])
        #expect(providers.rent.map(\.name) == ["Apple TV Store"])
        #expect(providers.link?.host() == "www.themoviedb.org")
        #expect(providers.primaryStreaming?.logo?.small.absoluteString == "https://image.tmdb.org/t/p/w92/netflix.png")
        #expect(client.lastRequest?.query["language"] == nil)
    }

    @Test("Filme sem dados na região devolve disponibilidade vazia")
    func missingRegion() async throws {
        client.stub(path: "movie/1/watch/providers", json: #"{"id": 1, "results": {}}"#)

        let providers = try await makeRepository().getMovieWatchProviders(movieID: 1)

        #expect(providers.isEmpty)
        #expect(providers.primaryStreaming == nil)
    }

    @Test("Serviços da região usam a prioridade do país")
    func listWatchProviders() async throws {
        client.stub(path: "watch/providers/movie", json: #"""
        {
          "results": [
            {"display_priorities": {"BR": 7, "US": 0}, "display_priority": 25, "logo_path": "/max.png", "provider_name": "HBO Max", "provider_id": 1899},
            {"display_priorities": {"BR": 0}, "display_priority": 0, "logo_path": "/netflix.png", "provider_name": "Netflix", "provider_id": 8}
          ]
        }
        """#)
        let listProviders: any ListWatchProviders = makeRepository()

        let providers = try await listProviders.listWatchProviders()

        #expect(providers.map(\.name) == ["Netflix", "HBO Max"])
        #expect(providers.last?.displayPriority == 7)
        #expect(client.lastRequest?.query["watch_region"] == "BR")
    }

    @Test("Discover por streaming envia serviços, região e tipo de disponibilidade")
    func discoverByProvider() async throws {
        client.stub(path: "discover/movie", json: #"{"page": 1, "results": [], "total_pages": 0, "total_results": 0}"#)

        _ = try await makeRepository().discoverMovies(
            MovieDiscoverQuery(
                sort: .mostVoted,
                watchProviderIDs: ["8", "119"],
                watchMonetizationTypes: [.subscription, .ads]
            )
        )

        let query = try #require(client.lastRequest).query
        #expect(query["sort_by"] == "vote_count.desc")
        #expect(query["with_watch_providers"] == "8|119")
        #expect(query["watch_region"] == "BR")
        #expect(query["with_watch_monetization_types"] == "ads|flatrate")
    }

    @Test("Vídeos aceitam trailers em inglês quando o idioma é outro")
    func videoLanguageFallback() async throws {
        client.stub(path: "movie/550/videos", json: #"{"id": 550, "results": []}"#)

        _ = try await makeRepository().listMovieVideos(movieID: 550)

        #expect(client.lastRequest?.query["include_video_language"] == "pt,en,null")
    }
}
