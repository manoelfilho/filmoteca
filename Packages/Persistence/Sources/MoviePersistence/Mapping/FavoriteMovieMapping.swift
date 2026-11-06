import Foundation
import MovieDomain

extension FavoriteMovieEntity {
    convenience init(movie: Movie, savedAt: Date) {
        self.init(
            movieID: movie.id.rawValue,
            title: movie.title,
            originalTitle: movie.originalTitle,
            originalLanguage: movie.originalLanguage,
            overview: movie.overview,
            releaseDate: movie.releaseDate,
            genreIDs: movie.genreIDs,
            voteAverage: movie.voteAverage,
            voteCount: movie.voteCount,
            popularity: movie.popularity,
            isAdult: movie.isAdult,
            savedAt: savedAt
        )
        setImages(from: movie)
    }

    /// Atualiza os dados guardados mantendo a data em que foi favoritado.
    func update(from movie: Movie) {
        title = movie.title
        originalTitle = movie.originalTitle
        originalLanguage = movie.originalLanguage
        overview = movie.overview
        releaseDate = movie.releaseDate
        genreIDs = movie.genreIDs
        voteAverage = movie.voteAverage
        voteCount = movie.voteCount
        popularity = movie.popularity
        isAdult = movie.isAdult
        setImages(from: movie)
    }

    func toDomain() -> Movie {
        Movie(
            id: MovieID(rawValue: movieID),
            title: title,
            originalTitle: originalTitle,
            originalLanguage: originalLanguage,
            overview: overview,
            releaseDate: releaseDate,
            poster: RemoteImage(
                small: posterSmallURL,
                medium: posterMediumURL,
                large: posterLargeURL,
                original: posterOriginalURL
            ),
            backdrop: RemoteImage(
                small: backdropSmallURL,
                medium: backdropMediumURL,
                large: backdropLargeURL,
                original: backdropOriginalURL
            ),
            genreIDs: genreIDs,
            voteAverage: voteAverage,
            voteCount: voteCount,
            popularity: popularity,
            isAdult: isAdult
        )
    }

    private func setImages(from movie: Movie) {
        posterSmallURL = movie.poster?.small
        posterMediumURL = movie.poster?.medium
        posterLargeURL = movie.poster?.large
        posterOriginalURL = movie.poster?.original

        backdropSmallURL = movie.backdrop?.small
        backdropMediumURL = movie.backdrop?.medium
        backdropLargeURL = movie.backdrop?.large
        backdropOriginalURL = movie.backdrop?.original
    }
}

private extension RemoteImage {
    /// Só existe imagem quando todos os tamanhos foram gravados.
    init?(small: URL?, medium: URL?, large: URL?, original: URL?) {
        guard let small, let medium, let large, let original else { return nil }
        self.init(small: small, medium: medium, large: large, original: original)
    }
}
