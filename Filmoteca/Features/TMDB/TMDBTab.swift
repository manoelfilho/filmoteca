import Foundation

/// Abas do módulo TMDB.
enum TMDBTab: String, CaseIterable, Identifiable, Hashable {
    case home
    case favorites
    case search
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: String(localized: "tmdb_tab_home")
        case .favorites: String(localized: "tmdb_tab_favorites")
        case .search: String(localized: "tmdb_tab_search")
        case .about: String(localized: "tmdb_tab_about")
        }
    }

    var systemImage: String {
        switch self {
        case .home: "film"
        case .favorites: "heart"
        case .search: "magnifyingglass"
        case .about: "info.circle"
        }
    }
}
