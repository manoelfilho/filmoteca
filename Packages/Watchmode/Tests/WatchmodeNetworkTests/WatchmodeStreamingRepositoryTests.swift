import Foundation
import MovieDomain
import NetworkCore
import Testing
@testable import WatchmodeNetwork

@Suite("Watchmode: ofertas de streaming")
struct WatchmodeStreamingRepositoryTests {
    let client = StubHTTPClient()

    func makeRepository(format: WatchmodeConfiguration.MovieIDFormat = .tmdb, region: String? = "BR") -> WatchmodeStreamingRepository {
        WatchmodeStreamingRepository(
            configuration: WatchmodeConfiguration(apiKey: " KEY ", movieIDFormat: format, defaultRegion: region),
            client: client
        )
    }

    /// Resposta real do plano gratuito (Clube da Luta no Brasil), resumida.
    static let freePlanJSON = #"""
    [
      {"source_id": 203, "name": "Netflix", "type": "sub", "region": "BR",
       "ios_url": "Deeplinks available for paid plans only.",
       "android_url": "Deeplinks available for paid plans only.",
       "web_url": "https://www.netflix.com/title/26004747",
       "format": "HD", "price": null, "seasons": null, "episodes": null,
       "tvos_url": "TV links available for paid plans only.",
       "android_tv_url": "TV links available for paid plans only.",
       "roku_url": "TV links available for paid plans only."},
      {"source_id": 26, "name": "Prime Video", "type": "sub", "region": "BR",
       "ios_url": "aiv://aiv/detail?gti=amzn1.dv.gti.84aa074e",
       "web_url": "https://app.primevideo.com/detail?gti=amzn1.dv.gti.84aa074e",
       "format": "4K", "price": null},
      {"source_id": 349, "name": "Apple TV", "type": "rent", "region": "BR",
       "web_url": "https://tv.apple.com/br/movie/clube-da-luta/umc.cmc.1", "format": "HD", "price": 14.9},
      {"source_id": 1, "name": "Desconhecido", "type": "cinema", "region": "BR", "web_url": null}
    ]
    """#

    @Test("Monta a rota com o ID do TMDB, a região padrão e a chave no header")
    func request() async throws {
        client.stub(path: "title/movie-550/sources/", json: "[]")
        _ = try await makeRepository().listStreamingOffers(movieID: 550)

        let request = try #require(client.lastRequest)
        #expect(request.url.absoluteString == "https://api.watchmode.com/v1/title/movie-550/sources/")
        #expect(request.query == ["regions": "BR"])
        #expect(request.headers["X-API-Key"] == "KEY")
    }

    @Test("Regiões da consulta substituem a padrão; IDs do Watchmode vão como estão")
    func regionsAndFormat() async throws {
        client.stub(path: "title/3173903/sources/", json: "[]")
        _ = try await makeRepository(format: .watchmode).listStreamingOffers(
            StreamingOffersQuery(movieID: "3173903", regions: ["br", "us"])
        )
        #expect(client.lastRequest?.query == ["regions": "BR,US"])
    }

    @Test("Converte as fontes e ignora os avisos de plano gratuito no lugar dos links")
    func mapping() async throws {
        client.stub(path: "title/movie-550/sources/", json: Self.freePlanJSON)
        let offers = try await makeRepository().listStreamingOffers(movieID: 550)

        #expect(offers.map(\.serviceName) == ["Netflix", "Prime Video", "Apple TV"])

        let netflix = offers[0]
        #expect(netflix.serviceID == "203")
        #expect(netflix.kind == .subscription)
        #expect(netflix.region == "BR")
        #expect(netflix.webURL == URL(string: "https://www.netflix.com/title/26004747"))
        #expect(netflix.appURL == nil)
        #expect(netflix.quality == "HD")

        #expect(offers[1].appURL == URL(string: "aiv://aiv/detail?gti=amzn1.dv.gti.84aa074e"))
        #expect(offers[2].kind == .rent)
        #expect(offers[2].price == Decimal(string: "14.9"))
    }

    @Test("Filtra pelos modos de acesso pedidos")
    func kindsFilter() async throws {
        client.stub(path: "title/movie-550/sources/", json: Self.freePlanJSON)
        let offers = try await makeRepository().listStreamingOffers(
            StreamingOffersQuery(movieID: 550, kinds: [.rent])
        )
        #expect(offers.map(\.serviceName) == ["Apple TV"])
    }

    @Test("Filme desconhecido pelo Watchmode vira lista vazia")
    func notFound() async throws {
        client.stub(path: "title/movie-1/sources/", status: 404, json: #"{"success":false,"statusCode":404,"statusMessage":"Not found"}"#)
        #expect(try await makeRepository().listStreamingOffers(movieID: 1).isEmpty)
    }

    @Test("Chave inválida vira unauthorized com a mensagem legada")
    func unauthorized() async throws {
        client.stub(path: "title/movie-550/sources/", status: 401, json: #"{"success":false,"errorMessage":"Invalid API key"}"#)
        await #expect(throws: DataSourceError.unauthorized(message: "Invalid API key")) {
            try await makeRepository().listStreamingOffers(movieID: 550)
        }
    }

    @Test("Sem chave, nem chega a chamar a API")
    func missingKey() async throws {
        let repository = WatchmodeStreamingRepository(configuration: WatchmodeConfiguration(apiKey: ""), client: client)
        await #expect(throws: DataSourceError.self) {
            try await repository.listStreamingOffers(movieID: 550)
        }
        #expect(client.requests.isEmpty)
    }
}
