import Foundation
import SwiftData

/// Filme favorito como é gravado no SwiftData.
///
/// É um detalhe desta camada: o app só vê `Movie`. As imagens ficam como URLs
/// soltas para o esquema não depender de tipos do domínio.
@Model
final class FavoriteMovieEntity {
    @Attribute(.unique) var movieID: String
    var title: String
    var originalTitle: String
    var originalLanguage: String?
    var overview: String
    var releaseDate: Date?
    var genreIDs: [String]
    var voteAverage: Double
    var voteCount: Int
    var popularity: Double
    var isAdult: Bool

    var posterSmallURL: URL?
    var posterMediumURL: URL?
    var posterLargeURL: URL?
    var posterOriginalURL: URL?

    var backdropSmallURL: URL?
    var backdropMediumURL: URL?
    var backdropLargeURL: URL?
    var backdropOriginalURL: URL?

    /// Quando o filme foi favoritado; define a ordem da lista.
    var savedAt: Date

    init(
        movieID: String,
        title: String,
        originalTitle: String,
        originalLanguage: String?,
        overview: String,
        releaseDate: Date?,
        genreIDs: [String],
        voteAverage: Double,
        voteCount: Int,
        popularity: Double,
        isAdult: Bool,
        savedAt: Date
    ) {
        self.movieID = movieID
        self.title = title
        self.originalTitle = originalTitle
        self.originalLanguage = originalLanguage
        self.overview = overview
        self.releaseDate = releaseDate
        self.genreIDs = genreIDs
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.popularity = popularity
        self.isAdult = isAdult
        self.savedAt = savedAt
    }
}
