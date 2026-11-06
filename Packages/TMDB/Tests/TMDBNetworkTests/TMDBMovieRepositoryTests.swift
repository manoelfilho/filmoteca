import Foundation
import MovieDomain
import NetworkCore
import Testing
@testable import TMDBNetwork

@Suite("TMDBMovieRepository")
struct TMDBMovieRepositoryTests {
    let client = StubHTTPClient()

    func makeRepository(
        authentication: TMDBConfiguration.Authentication = .apiKey("KEY"),
        language: String? = "pt-BR",
        region: String? = "BR"
    ) -> TMDBMovieRepository {
        TMDBMovieRepository(
            configuration: TMDBConfiguration(
                authentication: authentication,
                defaultLanguage: language,
                defaultRegion: region
            ),
            client: client
        )
    }

    @Test("Lista populares: monta a rota e converte para o domínio")
    func listPopular() async throws {
        client.stub(path: "movie/popular", json: Fixtures.moviePage)
        let listMovies: any ListMovies = makeRepository()

        let result = try await listMovies.listMovies(MovieListQuery(category: .popular, page: 2))

        let request = try #require(client.lastRequest)
        #expect(request.url.absoluteString == "https://api.themoviedb.org/3/movie/popular")
        #expect(request.query == ["page": "2", "language": "pt-BR", "region": "BR", "api_key": "KEY"])

        #expect(result.page == 1)
        #expect(result.totalPages == 3)
        #expect(result.hasNextPage)

        let movie = try #require(result.items.first)
        #expect(movie.id == 550)
        #expect(movie.title == "Clube da Luta")
        #expect(movie.originalTitle == "Fight Club")
        #expect(movie.genreIDs == ["18", "53"])
        #expect(movie.poster?.medium.absoluteString == "https://image.tmdb.org/t/p/w342/poster.jpg")
        #expect(movie.backdrop == nil)
        #expect(movie.releaseDate == Date(timeIntervalSince1970: 939_945_600)) // 1999-10-15
    }

    @Test("Token v4 vai no header Authorization, não na query")
    func bearerToken() async throws {
        client.stub(path: "genre/movie/list", json: #"{"genres":[{"id":28,"name":"Ação"}]}"#)
        let repository = makeRepository(authentication: TMDBConfiguration.Authentication(credential: "eyJhbGci.token"))

        let genres = try await repository.listGenres()

        let request = try #require(client.lastRequest)
        #expect(request.headers["Authorization"] == "Bearer eyJhbGci.token")
        #expect(request.query["api_key"] == nil)
        #expect(genres == [Genre(id: "28", name: "Ação")])
    }

    @Test("Detalhes: converte duração, gêneros, status e zera valores desconhecidos")
    func details() async throws {
        client.stub(path: "movie/550", json: Fixtures.movieDetails)
        let getMovie: any GetMovie = makeRepository()

        let details = try await getMovie.getMovie(id: 550)

        #expect(details.id == 550)
        #expect(details.runtime == 139)
        #expect(details.status == .released)
        #expect(details.genres.map(\.name) == ["Drama"])
        #expect(details.budget == 63_000_000)
        #expect(details.revenue == nil)
        #expect(details.tagline == nil)
        #expect(details.imdbID == "tt0137523")
        #expect(details.productionCompanies.first?.logo?.small.absoluteString == "https://image.tmdb.org/t/p/w92/logo.png")
    }

    @Test("Busca: envia os filtros e ignora texto em branco")
    func search() async throws {
        client.stub(path: "search/movie", json: Fixtures.moviePage)
        let searchMovies: any SearchMovies = makeRepository(language: nil, region: nil)

        let empty = try await searchMovies.searchMovies("   ")
        #expect(empty.items.isEmpty)
        #expect(client.requests.isEmpty)

        _ = try await searchMovies.searchMovies(MovieSearchQuery(text: " fight club ", year: 1999))
        let request = try #require(client.lastRequest)
        #expect(request.query == ["query": "fight club", "page": "1", "year": "1999", "include_adult": "false", "api_key": "KEY"])
    }

    @Test("Discover: converte ordenação, gêneros e filtros")
    func discover() async throws {
        client.stub(path: "discover/movie", json: Fixtures.moviePage)
        let discover: any DiscoverMovies = makeRepository(language: nil, region: nil)

        _ = try await discover.discoverMovies(
            MovieDiscoverQuery(
                sort: .bestRated,
                genreIDs: ["28", "12"],
                genreMatch: .any,
                excludedGenreIDs: ["27"],
                releasedAfter: Date(timeIntervalSince1970: 946_684_800), // 2000-01-01
                minimumVoteAverage: 7.5,
                minimumVoteCount: 200
            )
        )

        let query = try #require(client.lastRequest).query
        #expect(query["sort_by"] == "vote_average.desc")
        #expect(query["with_genres"] == "28|12")
        #expect(query["without_genres"] == "27")
        #expect(query["primary_release_date.gte"] == "2000-01-01")
        #expect(query["vote_average.gte"] == "7.5")
        #expect(query["vote_count.gte"] == "200")
    }

    @Test("Créditos: elenco ordenado e diretores")
    func credits() async throws {
        client.stub(path: "movie/550/credits", json: Fixtures.credits)
        let repository = makeRepository()

        let credits = try await repository.getMovieCredits(movieID: 550)

        #expect(credits.cast.map(\.name) == ["Edward Norton", "Brad Pitt"])
        #expect(credits.directors.map(\.name) == ["David Fincher"])
        #expect(credits.cast.first?.profile?.large.absoluteString == "https://image.tmdb.org/t/p/h632/norton.jpg")
    }

    @Test("Vídeos: monta URL do YouTube")
    func videos() async throws {
        client.stub(path: "movie/550/videos", json: Fixtures.videos)
        let repository = makeRepository()

        let videos = try await repository.listMovieVideos(movieID: 550)

        let trailer = try #require(videos.first)
        #expect(trailer.kind == .trailer)
        #expect(trailer.isOfficial)
        #expect(trailer.url?.absoluteString == "https://www.youtube.com/watch?v=SUXWAEX2jlg")
        #expect(trailer.publishedAt != nil)
        #expect(videos.last?.kind == .other("Opening Credits"))
        #expect(videos.last?.url == nil)
    }

    @Test("Relacionados: escolhe a rota pela relação")
    func related() async throws {
        client.stub(path: "movie/550/similar", json: Fixtures.moviePage)
        let repository = makeRepository()

        _ = try await repository.listRelatedMovies(RelatedMoviesQuery(movieID: 550, relation: .similar))

        #expect(client.lastRequest?.path == "movie/550/similar")
    }

    @Test("Erros HTTP viram DataSourceError com a mensagem do TMDB")
    func errors() async throws {
        client.stub(
            path: "movie/popular",
            status: 401,
            json: #"{"status_code":7,"status_message":"Invalid API key: You must be granted a valid key.","success":false}"#
        )
        client.stub(path: "movie/1", status: 404, json: #"{"status_code":34,"success":false}"#)
        let repository = makeRepository()

        await #expect(throws: DataSourceError.unauthorized(message: "Invalid API key: You must be granted a valid key.")) {
            try await repository.listMovies(.popular)
        }
        await #expect(throws: DataSourceError.notFound) {
            try await repository.getMovie(id: 1)
        }
        await #expect(throws: DataSourceError.connectivity) {
            try await repository.listGenres()
        }
    }
}

enum Fixtures {
    static let moviePage = #"""
    {
      "page": 1,
      "results": [
        {
          "adult": false,
          "backdrop_path": null,
          "genre_ids": [18, 53],
          "id": 550,
          "original_language": "en",
          "original_title": "Fight Club",
          "overview": "Um homem deprimido...",
          "popularity": 61.4,
          "poster_path": "/poster.jpg",
          "release_date": "1999-10-15",
          "title": "Clube da Luta",
          "video": false,
          "vote_average": 8.4,
          "vote_count": 30000
        },
        {
          "id": 999,
          "title": "Sem data",
          "release_date": ""
        }
      ],
      "total_pages": 3,
      "total_results": 60
    }
    """#

    static let movieDetails = #"""
    {
      "adult": false,
      "backdrop_path": "/backdrop.jpg",
      "budget": 63000000,
      "genres": [{"id": 18, "name": "Drama"}],
      "homepage": "",
      "id": 550,
      "imdb_id": "tt0137523",
      "original_language": "en",
      "original_title": "Fight Club",
      "overview": "Um homem deprimido...",
      "popularity": 61.4,
      "poster_path": "/poster.jpg",
      "production_companies": [
        {"id": 508, "logo_path": "/logo.png", "name": "Regency Enterprises", "origin_country": "US"}
      ],
      "release_date": "1999-10-15",
      "revenue": 0,
      "runtime": 139,
      "status": "Released",
      "tagline": "",
      "title": "Clube da Luta",
      "video": false,
      "vote_average": 8.4,
      "vote_count": 30000
    }
    """#

    static let credits = #"""
    {
      "id": 550,
      "cast": [
        {"id": 287, "name": "Brad Pitt", "character": "Tyler Durden", "profile_path": "/pitt.jpg", "order": 1},
        {"id": 819, "name": "Edward Norton", "character": "Narrador", "profile_path": "/norton.jpg", "order": 0}
      ],
      "crew": [
        {"id": 7467, "credit_id": "631f0289568463007bbe28a6", "name": "David Fincher", "job": "Director", "department": "Directing", "profile_path": null},
        {"id": 7467, "credit_id": "52fe4250c3a36847f80149f3", "name": "David Fincher", "job": "Producer", "department": "Production"}
      ]
    }
    """#

    static let videos = #"""
    {
      "id": 550,
      "results": [
        {"id": "64fe1d", "name": "Trailer oficial", "key": "SUXWAEX2jlg", "site": "YouTube", "type": "Trailer", "official": true, "published_at": "2014-10-02T19:20:22.000Z"},
        {"id": "64fe1e", "name": "Abertura", "key": "abc", "site": "Other", "type": "Opening Credits", "official": false}
      ]
    }
    """#
}
