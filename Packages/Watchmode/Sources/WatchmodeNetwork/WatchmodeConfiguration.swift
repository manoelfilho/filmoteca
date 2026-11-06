import Foundation

/// Configuração do provedor Watchmode.
public struct WatchmodeConfiguration: Sendable {
    /// De qual catálogo vêm os `MovieID` do app.
    ///
    /// O Watchmode aceita IDs de outros catálogos, então o app não precisa
    /// converter nada: basta dizer de onde vêm os IDs.
    public enum MovieIDFormat: Hashable, Sendable {
        /// IDs do TMDB (`550`), enviados como `movie-550`. Custa 2 créditos por consulta.
        case tmdb
        /// IDs do IMDb (`tt0137523`). Custa 2 créditos por consulta.
        case imdb
        /// IDs do próprio Watchmode. Custa 1 crédito por consulta.
        case watchmode
    }

    public static let defaultBaseURL = URL(string: "https://api.watchmode.com/v1")!

    public var apiKey: String
    public var baseURL: URL
    public var movieIDFormat: MovieIDFormat
    /// País usado quando a consulta não informa um (ex.: `BR`).
    public var defaultRegion: String?
    public var timeout: TimeInterval

    public init(
        apiKey: String,
        baseURL: URL = WatchmodeConfiguration.defaultBaseURL,
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
