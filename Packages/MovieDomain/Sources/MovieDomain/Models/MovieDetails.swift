import Foundation

/// Detalhes completos de um filme.
public struct MovieDetails: Identifiable, Hashable, Sendable {
    public let movie: Movie
    public let tagline: String?
    /// Duração em minutos.
    public let runtime: Int?
    public let genres: [Genre]
    public let status: MovieStatus
    public let budget: Int?
    public let revenue: Int?
    public let homepage: URL?
    public let imdbID: String?
    public let productionCompanies: [ProductionCompany]

    public var id: MovieID { movie.id }

    public init(
        movie: Movie,
        tagline: String? = nil,
        runtime: Int? = nil,
        genres: [Genre] = [],
        status: MovieStatus = .unknown,
        budget: Int? = nil,
        revenue: Int? = nil,
        homepage: URL? = nil,
        imdbID: String? = nil,
        productionCompanies: [ProductionCompany] = []
    ) {
        self.movie = movie
        self.tagline = tagline
        self.runtime = runtime
        self.genres = genres
        self.status = status
        self.budget = budget
        self.revenue = revenue
        self.homepage = homepage
        self.imdbID = imdbID
        self.productionCompanies = productionCompanies
    }
}

public enum MovieStatus: String, Hashable, Sendable, CaseIterable {
    case rumored
    case planned
    case inProduction
    case postProduction
    case released
    case canceled
    case unknown
}

public struct ProductionCompany: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let logo: RemoteImage?
    public let originCountry: String?

    public init(id: String, name: String, logo: RemoteImage? = nil, originCountry: String? = nil) {
        self.id = id
        self.name = name
        self.logo = logo
        self.originCountry = originCountry
    }
}
