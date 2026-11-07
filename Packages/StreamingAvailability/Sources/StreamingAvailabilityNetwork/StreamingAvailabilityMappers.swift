import Foundation
import MovieDomain

extension StreamingAvailabilityOptionDTO {
    /// `nil` para modos de acesso que o domínio não conhece.
    func toDomain(country: String) -> StreamingOffer? {
        guard let kind = StreamingOffer.Kind(streamingAvailabilityType: type) else { return nil }

        // Canal: o app que abre na TV é o do serviço que o hospeda. O "(Via ...)" é o
        // formato que `TVAppMatcher` entende para escolher esse app.
        let (serviceID, serviceName): (String, String) = if let addon {
            ("\(service.id).addon.\(addon.id)", "\(addon.name) (Via \(service.name))")
        } else {
            (service.id, service.name)
        }

        return StreamingOffer(
            serviceID: serviceID,
            serviceName: serviceName,
            kind: kind,
            region: country.uppercased(),
            webURL: Self.link(link),
            playURL: Self.link(videoLink),
            quality: quality.map(Self.qualityLabel),
            price: price.flatMap { Decimal(string: $0.amount, locale: Locale(identifier: "en_US_POSIX")) },
            currency: price?.currency
        )
    }

    static func link(_ value: String?) -> URL? {
        guard let value, let url = URL(string: value), url.scheme != nil, url.host() != nil else { return nil }
        return url
    }

    /// `uhd` → `4K`, `hd` → `HD`.
    static func qualityLabel(_ value: String) -> String {
        switch value.lowercased() {
        case "uhd": "4K"
        case "qhd": "QHD"
        default: value.uppercased()
        }
    }
}

extension StreamingOffer.Kind {
    init?(streamingAvailabilityType: String) {
        switch streamingAvailabilityType {
        case "subscription": self = .subscription
        case "free": self = .free
        case "rent": self = .rent
        case "buy": self = .buy
        case "addon": self = .addon
        default: return nil
        }
    }
}
