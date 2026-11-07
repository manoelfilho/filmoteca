import Foundation

/// Configuração do provedor Streaming Availability (Movie of the Night).
public struct StreamingAvailabilityConfiguration: Sendable {
    /// De qual catálogo vêm os `MovieID` do app.
    ///
    /// A API aceita IDs do TMDB e do IMDb, então o app não precisa converter nada:
    /// basta dizer de onde vêm os IDs.
    public enum MovieIDFormat: Hashable, Sendable {
        /// IDs do TMDB (`550`), enviados como `movie/550`.
        case tmdb
        /// IDs do IMDb (`tt0137523`), enviados como estão.
        case imdb
    }

    public static let defaultBaseURL = URL(string: "https://api.movieofthenight.com/v4")!

    public var apiKey: String
    public var baseURL: URL
    public var movieIDFormat: MovieIDFormat
    /// País usado quando a consulta não informa um (ex.: `BR`).
    public var defaultRegion: String?
    public var timeout: TimeInterval

    public init(
        apiKey: String,
        baseURL: URL = StreamingAvailabilityConfiguration.defaultBaseURL,
        movieIDFormat: MovieIDFormat = .tmdb,
        defaultRegion: String? = nil,
        timeout: TimeInterval = 30
    ) {
        self.apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        self.baseURL = baseURL
        self.movieIDFormat = movieIDFormat
        self.defaultRegion = defaultRegion
        self.timeout = timeout
    }
}
