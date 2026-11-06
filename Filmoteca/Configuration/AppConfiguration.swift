import Foundation

struct AppConfiguration {

    let tmdb: APIConfiguration
    let watchmode: APIConfiguration

    init(bundle: Bundle = .main) {
        self.tmdb = APIConfiguration(
            baseURL: URL(string: "https://api.themoviedb.org/3")!,
            apiKey: bundle.object(forInfoDictionaryKey: "TMDB_KEY") as? String,
            timeout: 30
        )
        self.watchmode = APIConfiguration(
            baseURL: Self.url(bundle, key: "WATCH_MODE_URL") ?? URL(string: "https://api.watchmode.com/v1")!,
            apiKey: bundle.object(forInfoDictionaryKey: "WATCH_MODE_KEY") as? String,
            timeout: 30
        )
    }

    /// URL do Info.plist; vazia ou inválida usa o padrão.
    private static func url(_ bundle: Bundle, key: String) -> URL? {
        guard let value = bundle.object(forInfoDictionaryKey: key) as? String, !value.isEmpty,
              let url = URL(string: value), url.host() != nil
        else { return nil }
        return url
    }
}
