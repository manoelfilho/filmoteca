import Foundation
import MovieDomain

/// Critério e quantidade usados para montar o carrossel e as prateleiras da Home.
struct TMDBHomeFilter: Hashable {
    enum Ranking: String, CaseIterable, Identifiable, Hashable {
        /// Interesse recente (visualizações, votos e listas dos últimos dias).
        case popularity
        /// Maior quantidade de votos acumulados.
        case mostVoted

        var id: String { rawValue }

        var title: String {
            switch self {
            case .popularity: String(localized: "tmdb_home_ranking_popularity")
            case .mostVoted: String(localized: "tmdb_home_shelf_most_voted")
            }
        }

        var systemImage: String {
            switch self {
            case .popularity: "flame"
            case .mostVoted: "hand.thumbsup"
            }
        }

        var sort: MovieSort {
            switch self {
            case .popularity: .popularity
            case .mostVoted: .mostVoted
            }
        }
    }

    /// O TMDB devolve 20 filmes por página; ficar dentro de uma página evita requisições extras.
    static let limitOptions = [5, 10, 15, 20]

    var ranking: Ranking = .popularity
    var limit = 10
    /// Gênero escolhido no carrossel de tipos; `nil` mostra todos.
    var genreID: Genre.ID?

    /// Gêneros enviados ao `discover/movie`.
    var genreIDs: [Genre.ID] { genreID.map { [$0] } ?? [] }
}
