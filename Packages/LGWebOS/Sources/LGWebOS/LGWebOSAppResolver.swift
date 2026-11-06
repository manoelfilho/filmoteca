import Foundation
import TVDomain

/// App instalado na TV.
struct LGWebOSApp: Hashable, Sendable {
    let id: String
    let title: String
}

/// Escolhe o app da TV que corresponde a um serviço de streaming e, quando possível,
/// o ID do título dentro do app.
enum LGWebOSAppResolver {
    /// IDs de apps webOS conhecidos, para quando o nome na TV não bate com o do serviço.
    static let knownAppIDs: [String: [String]] = [
        "netflix": ["netflix"],
        "primevideo": ["amazon"],
        "amazonprimevideo": ["amazon"],
        "amazonprime": ["amazon"],
        "amazonvideo": ["amazon"],
        "disneyplus": ["com.disney.disneyplus-prod"],
        "max": ["com.wbd.stream", "com.hbo.hbomax"],
        "hbomax": ["com.wbd.stream", "com.hbo.hbomax"],
        "youtube": ["youtube.leanback.v4"],
        "appletv": ["com.apple.appletv"],
        "appletvplus": ["com.apple.appletv"],
    ]

    static func app(for serviceName: String, in apps: [LGWebOSApp]) -> LGWebOSApp? {
        TVAppMatcher.bestMatch(for: serviceName, in: apps, title: \.title, id: \.id, knownIDs: knownAppIDs)
    }

    /// ID para abrir o título direto no app, quando o formato do app é conhecido.
    static func contentID(appID: String, webURL: URL?) -> String? {
        switch appID {
        case "netflix":
            TVAppMatcher.netflixTitleID(from: webURL).map { "m=https://www.netflix.com/watch/\($0)&source_type=4" }
        case "youtube.leanback.v4":
            TVAppMatcher.youTubeVideoID(from: webURL)
        default:
            nil
        }
    }
}
