import Foundation
import MovieDomain

// Conversão dos DTOs do TMDB para os modelos de domínio.

extension TMDBMovieDTO {
    func toDomain(images: TMDBImageURLBuilder) -> Movie {
        Movie(
            id: MovieID(id),
            title: title ?? originalTitle ?? "",
            originalTitle: originalTitle ?? title ?? "",
            originalLanguage: originalLanguage,
            overview: overview ?? "",
            releaseDate: TMDBDate.day(from: releaseDate),
            poster: images.image(posterPath, kind: .poster),
            backdrop: images.image(backdropPath, kind: .backdrop),
            genreIDs: (genreIds ?? []).map(String.init),
            voteAverage: voteAverage ?? 0,
            voteCount: voteCount ?? 0,
            popularity: popularity ?? 0,
            isAdult: adult ?? false
        )
    }
}

extension TMDBPageDTO where Item == TMDBMovieDTO {
    func toDomain(images: TMDBImageURLBuilder) -> PaginatedResult<Movie> {
        PaginatedResult(
            items: results.map { $0.toDomain(images: images) },
            page: page,
            totalPages: totalPages ?? page,
            totalResults: totalResults ?? results.count
        )
    }
}

extension TMDBMovieDetailsDTO {
    func toDomain(images: TMDBImageURLBuilder) -> MovieDetails {
        let genres = (genres ?? []).map { $0.toDomain() }
        let movie = Movie(
            id: MovieID(id),
            title: title ?? originalTitle ?? "",
            originalTitle: originalTitle ?? title ?? "",
            originalLanguage: originalLanguage,
            overview: overview ?? "",
            releaseDate: TMDBDate.day(from: releaseDate),
            poster: images.image(posterPath, kind: .poster),
            backdrop: images.image(backdropPath, kind: .backdrop),
            genreIDs: genres.map(\.id),
            voteAverage: voteAverage ?? 0,
            voteCount: voteCount ?? 0,
            popularity: popularity ?? 0,
            isAdult: adult ?? false
        )

        return MovieDetails(
            movie: movie,
            tagline: tagline.flatMap { $0.isEmpty ? nil : $0 },
            // O TMDB devolve 0 quando não sabe a duração, o orçamento ou a receita.
            runtime: runtime.flatMap { $0 > 0 ? $0 : nil },
            genres: genres,
            status: MovieStatus(tmdbValue: status),
            budget: budget.flatMap { $0 > 0 ? $0 : nil },
            revenue: revenue.flatMap { $0 > 0 ? $0 : nil },
            homepage: homepage.flatMap { $0.isEmpty ? nil : URL(string: $0) },
            imdbID: imdbId.flatMap { $0.isEmpty ? nil : $0 },
            productionCompanies: (productionCompanies ?? []).map { $0.toDomain(images: images) }
        )
    }
}

extension TMDBGenreDTO {
    func toDomain() -> Genre {
        Genre(id: String(id), name: name)
    }
}

extension TMDBCompanyDTO {
    func toDomain(images: TMDBImageURLBuilder) -> ProductionCompany {
        ProductionCompany(
            id: String(id),
            name: name,
            logo: images.image(logoPath, kind: .logo),
            originCountry: originCountry.flatMap { $0.isEmpty ? nil : $0 }
        )
    }
}

extension TMDBCreditsDTO {
    func toDomain(images: TMDBImageURLBuilder) -> MovieCredits {
        MovieCredits(
            movieID: MovieID(id),
            cast: (cast ?? [])
                .map { member in
                    CastMember(
                        id: String(member.id),
                        name: member.name,
                        character: member.character ?? "",
                        profile: images.image(member.profilePath, kind: .profile),
                        order: member.order ?? .max
                    )
                }
                .sorted { $0.order < $1.order },
            crew: (crew ?? []).map { member in
                let job = member.job ?? ""
                return CrewMember(
                    id: member.creditId ?? "\(member.id)-\(job)",
                    personID: String(member.id),
                    name: member.name,
                    job: job,
                    department: member.department ?? "",
                    profile: images.image(member.profilePath, kind: .profile)
                )
            }
        )
    }
}

extension TMDBVideoDTO {
    func toDomain() -> MovieVideo {
        MovieVideo(
            id: id,
            name: name,
            kind: MovieVideo.Kind(tmdbValue: type),
            isOfficial: official ?? false,
            publishedAt: TMDBDate.dateTime(from: publishedAt),
            url: watchURL,
            thumbnail: thumbnailURL
        )
    }

    private var isYouTube: Bool { site.caseInsensitiveCompare("YouTube") == .orderedSame }
    private var isVimeo: Bool { site.caseInsensitiveCompare("Vimeo") == .orderedSame }

    private var watchURL: URL? {
        if isYouTube { return URL(string: "https://www.youtube.com/watch?v=\(key)") }
        if isVimeo { return URL(string: "https://vimeo.com/\(key)") }
        return nil
    }

    private var thumbnailURL: URL? {
        isYouTube ? URL(string: "https://img.youtube.com/vi/\(key)/hqdefault.jpg") : nil
    }
}

extension MovieStatus {
    init(tmdbValue: String?) {
        switch tmdbValue {
        case "Rumored": self = .rumored
        case "Planned": self = .planned
        case "In Production": self = .inProduction
        case "Post Production": self = .postProduction
        case "Released": self = .released
        case "Canceled": self = .canceled
        default: self = .unknown
        }
    }
}

extension MovieVideo.Kind {
    init(tmdbValue: String) {
        switch tmdbValue {
        case "Trailer": self = .trailer
        case "Teaser": self = .teaser
        case "Clip": self = .clip
        case "Featurette": self = .featurette
        case "Behind the Scenes": self = .behindTheScenes
        case "Bloopers": self = .bloopers
        default: self = .other(tmdbValue)
        }
    }
}

extension TMDBWatchProviderDTO {
    func toDomain(images: TMDBImageURLBuilder, region: String? = nil) -> WatchProvider {
        WatchProvider(
            id: String(providerId),
            name: providerName,
            logo: images.image(logoPath, kind: .logo),
            displayPriority: region.flatMap { displayPriorities?[$0] } ?? displayPriority ?? .max
        )
    }
}

extension TMDBMovieWatchProvidersDTO {
    func toDomain(region: String, images: TMDBImageURLBuilder) -> MovieWatchProviders {
        guard let entry = results[region] else {
            return MovieWatchProviders(movieID: MovieID(id), region: region)
        }

        func providers(_ list: [TMDBWatchProviderDTO]?) -> [WatchProvider] {
            (list ?? [])
                .map { $0.toDomain(images: images) }
                .sorted { $0.displayPriority < $1.displayPriority }
        }

        return MovieWatchProviders(
            movieID: MovieID(id),
            region: region,
            link: entry.link.flatMap(URL.init(string:)),
            subscription: providers(entry.flatrate),
            free: providers(entry.free),
            ads: providers(entry.ads),
            rent: providers(entry.rent),
            buy: providers(entry.buy)
        )
    }
}
