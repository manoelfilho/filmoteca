import Foundation

/// Identificador de filme independente do provedor de dados.
///
/// Cada API tem o seu formato (o TMDB usa `Int`, outras usam `String` como `tt0111161`),
/// por isso o domínio guarda sempre o valor bruto como `String`.
public struct MovieID: RawRepresentable, Hashable, Sendable, Codable, CustomStringConvertible,
    ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {
    public let rawValue: String

    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ value: String) { self.rawValue = value }
    public init(_ value: Int) { self.rawValue = String(value) }
    public init(stringLiteral value: String) { self.rawValue = value }
    public init(integerLiteral value: Int) { self.rawValue = String(value) }

    public var description: String { rawValue }
}

/// Resumo de um filme, como aparece em listas, buscas e recomendações.
public struct Movie: Identifiable, Hashable, Sendable {
    public let id: MovieID
    public let title: String
    public let originalTitle: String
    public let originalLanguage: String?
    public let overview: String
    public let releaseDate: Date?
    public let poster: RemoteImage?
    public let backdrop: RemoteImage?
    public let genreIDs: [Genre.ID]
    /// Nota média de 0 a 10.
    public let voteAverage: Double
    public let voteCount: Int
    public let popularity: Double
    public let isAdult: Bool

    public init(
        id: MovieID,
        title: String,
        originalTitle: String,
        originalLanguage: String? = nil,
        overview: String = "",
        releaseDate: Date? = nil,
        poster: RemoteImage? = nil,
        backdrop: RemoteImage? = nil,
        genreIDs: [Genre.ID] = [],
        voteAverage: Double = 0,
        voteCount: Int = 0,
        popularity: Double = 0,
        isAdult: Bool = false
    ) {
        self.id = id
        self.title = title
        self.originalTitle = originalTitle
        self.originalLanguage = originalLanguage
        self.overview = overview
        self.releaseDate = releaseDate
        self.poster = poster
        self.backdrop = backdrop
        self.genreIDs = genreIDs
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.popularity = popularity
        self.isAdult = isAdult
    }
}
