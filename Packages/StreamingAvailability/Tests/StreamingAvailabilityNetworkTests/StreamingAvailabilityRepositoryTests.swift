import Foundation
import MovieDomain
import NetworkCore
import Testing
@testable import StreamingAvailabilityNetwork

@Suite("Streaming Availability: ofertas de streaming")
struct StreamingAvailabilityRepositoryTests {
    let client = StubHTTPClient()

    func makeRepository(format: StreamingAvailabilityConfiguration.MovieIDFormat = .tmdb, region: String? = "BR") -> StreamingAvailabilityRepository {
        StreamingAvailabilityRepository(
            configuration: StreamingAvailabilityConfiguration(apiKey: " KEY ", movieIDFormat: format, defaultRegion: region),
            client: client
        )
    }

    /// Formato de `GET /shows/movie/550`, resumido (campos que o app não usa foram cortados).
    static let showJSON = #"""
    {
      "itemType": "show", "showType": "movie", "id": "82", "imdbId": "tt0137523", "tmdbId": "movie/550",
      "title": "Fight Club",
      "streamingOptions": {
        "br": [
          {"service": {"id": "netflix", "name": "Netflix", "homePage": "https://www.netflix.com/"},
           "type": "subscription",
           "link": "https://www.netflix.com/title/26004747",
           "videoLink": "https://www.netflix.com/watch/26004747",
           "quality": "hd", "audios": [], "subtitles": [], "expiresSoon": false},
          {"service": {"id": "prime", "name": "Prime Video"},
           "type": "addon",
           "addon": {"id": "paramountplusbr", "name": "Paramount+"},
           "link": "https://app.primevideo.com/detail?gti=amzn1.dv.gti.84aa074e",
           "quality": "uhd"},
          {"service": {"id": "apple", "name": "Apple TV"},
           "type": "rent",
           "link": "https://tv.apple.com/br/movie/clube-da-luta/umc.cmc.1",
           "quality": "hd",
           "price": {"amount": "14.90", "currency": "BRL", "formatted": "14.90 BRL"}},
          {"service": {"id": "x", "name": "Desconhecido"}, "type": "cinema", "link": "https://x.com"}
        ],
        "us": [
          {"service": {"id": "hulu", "name": "Hulu"}, "type": "subscription", "link": "https://www.hulu.com/movie/1"}
        ]
      }
    }
    """#

    @Test("Monta a rota com o ID do TMDB, o país padrão e a chave no header")
    func request() async throws {
        client.stub(path: "shows/movie/550", json: #"{"streamingOptions": {}}"#)
        _ = try await makeRepository().listStreamingOffers(movieID: 550)

        let request = try #require(client.lastRequest)
        #expect(request.url.absoluteString == "https://api.movieofthenight.com/v4/shows/movie/550")
        #expect(request.query == ["country": "br"])
        #expect(request.headers["X-API-Key"] == "KEY")
    }

    @Test("IDs do IMDb vão como estão")
    func imdbFormat() async throws {
        client.stub(path: "shows/tt0137523", json: #"{"streamingOptions": {}}"#)
        _ = try await makeRepository(format: .imdb).listStreamingOffers(movieID: "tt0137523")
        #expect(client.lastRequest?.path == "shows/tt0137523")
    }

    @Test("Converte as ofertas do país e ignora modos de acesso desconhecidos")
    func mapping() async throws {
        client.stub(path: "shows/movie/550", json: Self.showJSON)
        let offers = try await makeRepository().listStreamingOffers(
            StreamingOffersQuery(movieID: 550, regions: ["BR"])
        )

        #expect(offers.map(\.serviceName) == ["Netflix", "Paramount+ (Via Prime Video)", "Apple TV"])

        let netflix = offers[0]
        #expect(netflix.serviceID == "netflix")
        #expect(netflix.kind == .subscription)
        #expect(netflix.region == "BR")
        #expect(netflix.webURL == URL(string: "https://www.netflix.com/title/26004747"))
        #expect(netflix.playURL == URL(string: "https://www.netflix.com/watch/26004747"))
        #expect(netflix.quality == "HD")

        let addon = offers[1]
        #expect(addon.serviceID == "prime.addon.paramountplusbr")
        #expect(addon.kind == .addon)
        #expect(addon.quality == "4K")
        #expect(addon.playURL == nil)

        let apple = offers[2]
        #expect(apple.kind == .rent)
        #expect(apple.price == Decimal(string: "14.90"))
        #expect(apple.currency == "BRL")
    }

    @Test("Vários países: pede todos e fica só com os pedidos")
    func multipleRegions() async throws {
        client.stub(path: "shows/movie/550", json: Self.showJSON)
        let offers = try await makeRepository().listStreamingOffers(
            StreamingOffersQuery(movieID: 550, regions: ["us", "de"])
        )
        #expect(client.lastRequest?.query == [:])
        #expect(offers.map(\.serviceName) == ["Hulu"])
        #expect(offers.first?.region == "US")
    }

    @Test("Filtra pelos modos de acesso pedidos")
    func kindsFilter() async throws {
        client.stub(path: "shows/movie/550", json: Self.showJSON)
        let offers = try await makeRepository().listStreamingOffers(
            StreamingOffersQuery(movieID: 550, kinds: [.rent])
        )
        #expect(offers.map(\.serviceName) == ["Apple TV"])
    }

    @Test("Filme sem ofertas ou desconhecido vira lista vazia")
    func notFound() async throws {
        client.stub(path: "shows/movie/1", status: 404, json: #"{"message":"show not found"}"#)
        #expect(try await makeRepository().listStreamingOffers(movieID: 1).isEmpty)

        client.stub(path: "shows/movie/2", json: #"{"title": "Sem ofertas"}"#)
        #expect(try await makeRepository().listStreamingOffers(movieID: 2).isEmpty)
    }

    @Test("Chave inválida vira unauthorized com a mensagem da API")
    func unauthorized() async throws {
        client.stub(path: "shows/movie/550", status: 401, json: #"{"message":"Invalid API key"}"#)
        await #expect(throws: DataSourceError.unauthorized(message: "Invalid API key")) {
            try await makeRepository().listStreamingOffers(movieID: 550)
        }
    }

    @Test("Cota do plano estourada vira rateLimited")
    func rateLimited() async throws {
        client.stub(path: "shows/movie/550", status: 429, json: #"{"message":"Too many requests"}"#)
        await #expect(throws: DataSourceError.rateLimited) {
            try await makeRepository().listStreamingOffers(movieID: 550)
        }
    }

    @Test("Sem chave, nem chega a chamar a API")
    func missingKey() async throws {
        let repository = StreamingAvailabilityRepository(configuration: StreamingAvailabilityConfiguration(apiKey: ""), client: client)
        await #expect(throws: DataSourceError.self) {
            try await repository.listStreamingOffers(movieID: 550)
        }
        #expect(client.requests.isEmpty)
    }
}
