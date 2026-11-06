import Foundation
import MovieDomain
import MoviePersistence
import Testing

@Suite("Favoritos no SwiftData")
struct SwiftDataMovieStoreTests {
    let store: SwiftDataMovieStore

    init() throws {
        store = try SwiftDataMovieStore.make(inMemory: true)
    }

    static func movie(_ id: Int, title: String = "Filme", withImages: Bool = true) -> Movie {
        let image = RemoteImage(
            small: URL(string: "https://img.test/\(id)/s.jpg")!,
            medium: URL(string: "https://img.test/\(id)/m.jpg")!,
            large: URL(string: "https://img.test/\(id)/l.jpg")!,
            original: URL(string: "https://img.test/\(id)/o.jpg")!
        )
        return Movie(
            id: MovieID(id),
            title: title,
            originalTitle: "Original \(id)",
            originalLanguage: "en",
            overview: "Sinopse \(id)",
            releaseDate: Date(timeIntervalSince1970: 939_945_600),
            poster: withImages ? image : nil,
            backdrop: withImages ? image : nil,
            genreIDs: ["18", "53"],
            voteAverage: 8.4,
            voteCount: 30_000,
            popularity: 61.4,
            isAdult: false
        )
    }

    @Test("Salva e lê de volta o filme completo")
    func roundTrip() async throws {
        let movie = Self.movie(550, title: "Clube da Luta")
        try await store.saveFavoriteMovie(movie)

        #expect(try await store.listFavoriteMovies() == [movie])
        #expect(try await store.isFavoriteMovie(id: 550))
        #expect(try await store.isFavoriteMovie(id: 13) == false)
    }

    @Test("Filme sem imagens continua sem imagens")
    func withoutImages() async throws {
        try await store.saveFavoriteMovie(Self.movie(1, withImages: false))
        let saved = try #require(try await store.listFavoriteMovies().first)
        #expect(saved.poster == nil)
        #expect(saved.backdrop == nil)
    }

    @Test("Lista do mais recente para o mais antigo")
    func ordering() async throws {
        try await store.saveFavoriteMovie(Self.movie(1))
        try await store.saveFavoriteMovie(Self.movie(2))
        try await store.saveFavoriteMovie(Self.movie(3))

        #expect(try await store.listFavoriteMovies().map(\.id) == [3, 2, 1])
    }

    @Test("Salvar de novo atualiza os dados sem duplicar nem mudar a posição")
    func upsert() async throws {
        try await store.saveFavoriteMovie(Self.movie(1, title: "Antigo"))
        try await store.saveFavoriteMovie(Self.movie(2))
        try await store.saveFavoriteMovie(Self.movie(1, title: "Novo"))

        let favorites = try await store.listFavoriteMovies()
        #expect(favorites.map(\.id) == [2, 1])
        #expect(favorites.last?.title == "Novo")
    }

    @Test("Remove o filme; remover de novo não é erro")
    func remove() async throws {
        try await store.saveFavoriteMovie(Self.movie(1))
        try await store.removeFavoriteMovie(id: 1)
        try await store.removeFavoriteMovie(id: 1)

        #expect(try await store.listFavoriteMovies().isEmpty)
        #expect(try await store.isFavoriteMovie(id: 1) == false)
    }

    @Test("Observação entrega a lista atual e cada mudança")
    func observe() async throws {
        try await store.saveFavoriteMovie(Self.movie(1))

        var updates = await store.observeFavoriteMovies().makeAsyncIterator()
        #expect(await updates.next()?.map(\.id) == [1])

        try await store.saveFavoriteMovie(Self.movie(2))
        #expect(await updates.next()?.map(\.id) == [2, 1])

        try await store.removeFavoriteMovie(id: 1)
        #expect(await updates.next()?.map(\.id) == [2])
    }
}
