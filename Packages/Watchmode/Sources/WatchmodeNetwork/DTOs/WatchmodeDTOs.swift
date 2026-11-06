import Foundation

/// Item de `GET /title/{title_id}/sources/`.
struct WatchmodeSourceDTO: Decodable, Sendable {
    let sourceID: Int
    let name: String
    let type: String
    let region: String?
    let iosURL: String?
    let webURL: String?
    let format: String?
    let price: Double?

    enum CodingKeys: String, CodingKey {
        case sourceID = "source_id"
        case name
        case type
        case region
        case iosURL = "ios_url"
        case webURL = "web_url"
        case format
        case price
    }
}

/// Erro da API: `statusMessage` (atual) ou `errorMessage` (legado).
struct WatchmodeErrorDTO: Decodable, Sendable {
    let statusMessage: String?
    let errorMessage: String?

    var message: String? { statusMessage ?? errorMessage }
}
