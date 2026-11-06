import Foundation
import MovieDomain

/// Monta URLs de imagem no formato `{base}/{tamanho}{caminho}`,
/// ex.: `https://image.tmdb.org/t/p/w342/abc.jpg`.
///
/// Tamanhos válidos: https://developer.themoviedb.org/reference/configuration-details
struct TMDBImageURLBuilder: Sendable {
    enum Kind: Sendable {
        case poster
        case backdrop
        case profile
        case logo

        /// Tamanhos do TMDB para small, medium e large.
        var sizes: (small: String, medium: String, large: String) {
            switch self {
            case .poster: ("w185", "w342", "w780")
            case .backdrop: ("w300", "w780", "w1280")
            case .profile: ("w45", "w185", "h632")
            case .logo: ("w92", "w185", "w500")
            }
        }
    }

    let baseURL: URL

    func image(_ path: String?, kind: Kind) -> RemoteImage? {
        guard let path, !path.isEmpty else { return nil }
        let sizes = kind.sizes
        return RemoteImage(
            small: url(path, size: sizes.small),
            medium: url(path, size: sizes.medium),
            large: url(path, size: sizes.large),
            original: url(path, size: "original")
        )
    }

    private func url(_ path: String, size: String) -> URL {
        let relativePath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return baseURL.appending(path: size).appending(path: relativePath)
    }
}
