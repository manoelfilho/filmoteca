import Foundation

/// Encontra, entre os apps instalados numa TV, o que corresponde a um serviço de streaming.
///
/// Os nomes variam entre fontes ("Disney Plus" no Watchmode, "Disney+" na TV), por isso a
/// comparação ignora maiúsculas, acentos, espaços e trata "+" como "plus". Cada marca
/// informa os IDs conhecidos dos seus apps para quando o nome não basta.
public enum TVAppMatcher {
    public static func bestMatch<App>(
        for serviceName: String,
        in apps: [App],
        title: (App) -> String,
        id: (App) -> String,
        knownIDs: [String: [String]] = [:]
    ) -> App? {
        for candidate in candidateNames(for: serviceName) {
            let name = normalize(candidate)
            guard !name.isEmpty else { continue }

            if let app = apps.first(where: { normalize(title($0)) == name }) {
                return app
            }
            if let ids = knownIDs[name], let app = apps.first(where: { ids.contains(id($0)) }) {
                return app
            }
            if name.count >= 4, let app = apps.first(where: {
                let appTitle = normalize(title($0))
                return appTitle.count >= 4 && (appTitle.hasPrefix(name) || name.hasPrefix(appTitle))
            }) {
                return app
            }
        }
        return nil
    }

    /// "Paramount+ (Via Amazon Prime)" é um canal assistido dentro do app da Amazon:
    /// tenta primeiro o app indicado no "via", depois o nome sem o parêntese.
    public static func candidateNames(for serviceName: String) -> [String] {
        guard let open = serviceName.firstIndex(of: "("), let close = serviceName.lastIndex(of: ")"), open < close else {
            return [serviceName]
        }
        let inside = serviceName[serviceName.index(after: open)..<close].trimmingCharacters(in: .whitespaces)
        let outside = serviceName[..<open].trimmingCharacters(in: .whitespaces)
        var names: [String] = []
        if inside.lowercased().hasPrefix("via ") {
            names.append(String(inside.dropFirst(4)))
        }
        names.append(outside)
        return names
    }

    /// "Disney Plus", "Disney+" e "disney plus" viram "disneyplus".
    public static func normalize(_ name: String) -> String {
        name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .replacingOccurrences(of: "+", with: "plus")
            .filter { $0.isLetter || $0.isNumber }
    }

    /// ID do título na Netflix a partir da página (`/title/26004747` ou `/watch/26004747`).
    public static func netflixTitleID(from webURL: URL?) -> String? {
        guard let parts = webURL?.pathComponents,
              let index = parts.firstIndex(where: { $0 == "title" || $0 == "watch" }),
              parts.indices.contains(index + 1),
              parts[index + 1].allSatisfy(\.isNumber)
        else { return nil }
        return parts[index + 1]
    }

    /// ID do vídeo no YouTube (`watch?v=abc123`).
    public static func youTubeVideoID(from webURL: URL?) -> String? {
        guard let webURL else { return nil }
        return URLComponents(url: webURL, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "v" }?.value
    }
}
