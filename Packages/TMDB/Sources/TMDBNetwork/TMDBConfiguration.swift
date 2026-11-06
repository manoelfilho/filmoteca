import Foundation

/// Configuração do provedor TMDB.
public struct TMDBConfiguration: Sendable {
    /// O TMDB aceita dois tipos de credencial.
    public enum Authentication: Hashable, Sendable {
        /// Chave da API v3, enviada como query `api_key`.
        case apiKey(String)
        /// Token de leitura da API (v4), enviado no header `Authorization: Bearer`.
        case bearerToken(String)

        /// Detecta o tipo pela forma da credencial: tokens v4 são JWT (começam com `eyJ`).
        public init(credential: String) {
            let trimmed = credential.trimmingCharacters(in: .whitespacesAndNewlines)
            self = trimmed.hasPrefix("eyJ") ? .bearerToken(trimmed) : .apiKey(trimmed)
        }
    }

    public static let defaultBaseURL = URL(string: "https://api.themoviedb.org/3")!
    public static let defaultImageBaseURL = URL(string: "https://image.tmdb.org/t/p")!

    public var baseURL: URL
    public var imageBaseURL: URL
    public var authentication: Authentication
    /// Idioma usado quando a consulta não informa um (ex.: `pt-BR`).
    public var defaultLanguage: String?
    /// País usado quando a consulta não informa um (ex.: `BR`).
    public var defaultRegion: String?
    public var timeout: TimeInterval

    public init(
        authentication: Authentication,
        baseURL: URL = TMDBConfiguration.defaultBaseURL,
        imageBaseURL: URL = TMDBConfiguration.defaultImageBaseURL,
        defaultLanguage: String? = nil,
        defaultRegion: String? = nil,
        timeout: TimeInterval = 30
    ) {
        self.authentication = authentication
        self.baseURL = baseURL
        self.imageBaseURL = imageBaseURL
        self.defaultLanguage = defaultLanguage
        self.defaultRegion = defaultRegion
        self.timeout = timeout
    }
}
