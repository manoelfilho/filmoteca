import Foundation

/// Resposta de `GET /shows/{id}`, só com o que o app usa.
struct StreamingAvailabilityShowDTO: Decodable, Sendable {
    /// Ofertas por país, com o código em minúsculas (`"br"`).
    let streamingOptions: [String: [StreamingAvailabilityOptionDTO]]

    enum CodingKeys: String, CodingKey {
        case streamingOptions
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        streamingOptions = try container.decodeIfPresent([String: [StreamingAvailabilityOptionDTO]].self, forKey: .streamingOptions) ?? [:]
    }
}

struct StreamingAvailabilityOptionDTO: Decodable, Sendable {
    let service: StreamingAvailabilityServiceDTO
    /// `subscription`, `free`, `rent`, `buy` ou `addon`.
    let type: String
    /// Presente quando `type` é `addon`: o canal dentro do serviço.
    let addon: StreamingAvailabilityServiceDTO?
    let link: String?
    let videoLink: String?
    /// `sd`, `hd`, `qhd` ou `uhd`.
    let quality: String?
    let price: StreamingAvailabilityPriceDTO?
}

struct StreamingAvailabilityServiceDTO: Decodable, Sendable {
    let id: String
    let name: String
}

struct StreamingAvailabilityPriceDTO: Decodable, Sendable {
    /// Texto decimal (ex.: `"14.90"`).
    let amount: String
    let currency: String
}

struct StreamingAvailabilityErrorDTO: Decodable, Sendable {
    let message: String?
}
