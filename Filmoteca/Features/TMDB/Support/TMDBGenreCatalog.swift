import Foundation
import MovieDomain
import Observation

/// Gêneros do TMDB, carregados uma vez e compartilhados pelos cards e filtros.
///
/// As listas do TMDB trazem só os IDs dos gêneros (`genre_ids`); os nomes vêm de `genre/movie/list`.
@Observable
final class TMDBGenreCatalog {
    /// Todos os gêneros, na ordem alfabética do idioma do app.
    private(set) var genres: [Genre] = []
    private(set) var names: [Genre.ID: String] = [:]

    @ObservationIgnored private let listGenres: any ListGenres
    @ObservationIgnored private var isLoading = false

    init(listGenres: any ListGenres) {
        self.listGenres = listGenres
    }

    func loadIfNeeded() async {
        guard genres.isEmpty, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        guard let loaded = try? await listGenres.listGenres() else { return }
        genres = loaded.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        names = Dictionary(loaded.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
    }

    /// Gênero principal do filme (o primeiro da lista do TMDB).
    func primaryGenre(of movie: Movie) -> String? {
        movie.genreIDs.lazy.compactMap { self.names[$0] }.first
    }

    /// Só os gêneros que aparecem em `movies`, para o filtro não oferecer opções vazias.
    func genres(in movies: [Movie]) -> [Genre] {
        let present = Set(movies.flatMap(\.genreIDs))
        return genres.filter { present.contains($0.id) }
    }
}

extension Array where Element == Movie {
    /// Filmes do gênero escolhido; `nil` devolve todos.
    func filtered(byGenre genreID: Genre.ID?) -> [Movie] {
        guard let genreID else { return self }
        return filter { $0.genreIDs.contains(genreID) }
    }
}
