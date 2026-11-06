import Foundation
import TVDomain

/// App instalado na TV.
struct SamsungTizenApp: Hashable, Sendable {
    let id: String
    let name: String
    /// 2 = app Tizen (abre com `DEEP_LINK`), 4 = app nativo (`NATIVE_LAUNCH`).
    var appType: Int?

    var actionType: String { appType == 4 ? "NATIVE_LAUNCH" : "DEEP_LINK" }
}

enum SamsungTizenAppResolver {
    /// IDs de apps Tizen conhecidos. Servem quando o nome na TV não bate e quando a TV
    /// não informa a lista de apps (alguns modelos recentes não respondem a ela).
    static let knownAppIDs: [String: [String]] = [
        "netflix": ["3201907018807", "11101200001"],
        "primevideo": ["3201910019365", "org.tizen.ignition"],
        "amazonprimevideo": ["3201910019365", "org.tizen.ignition"],
        "amazonprime": ["3201910019365", "org.tizen.ignition"],
        "amazonvideo": ["3201910019365", "org.tizen.ignition"],
        "disneyplus": ["3201901017640"],
        "youtube": ["111299001912"],
        "appletv": ["3201807016597"],
        "appletvplus": ["3201807016597"],
        "max": ["3202301029760", "3201601007230"],
        "hbomax": ["3202301029760", "3201601007230"],
    ]

    static func app(for serviceName: String, in apps: [SamsungTizenApp]) -> SamsungTizenApp? {
        TVAppMatcher.bestMatch(for: serviceName, in: apps, title: \.name, id: \.id, knownIDs: knownAppIDs)
    }

    /// IDs conhecidos para o serviço, na ordem em que devem ser tentados.
    static func knownIDs(for serviceName: String) -> [String] {
        TVAppMatcher.candidateNames(for: serviceName)
            .flatMap { knownAppIDs[TVAppMatcher.normalize($0)] ?? [] }
    }

    /// Dado para abrir o título direto no app (`metaTag`), quando o formato do app é conhecido.
    static func metaTag(appID: String, webURL: URL?) -> String? {
        if knownAppIDs["netflix"]?.contains(appID) == true {
            return TVAppMatcher.netflixTitleID(from: webURL).map { "m=\($0)&source_type=4" }
        }
        if knownAppIDs["youtube"]?.contains(appID) == true {
            return TVAppMatcher.youTubeVideoID(from: webURL).map { "v=\($0)" }
        }
        return nil
    }
}
