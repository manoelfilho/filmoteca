import Foundation
import MovieDomain

extension WatchmodeSourceDTO {
    /// `nil` para modos de acesso que o domínio não conhece.
    func toDomain() -> StreamingOffer? {
        guard let kind = StreamingOffer.Kind(watchmodeType: type) else { return nil }
        return StreamingOffer(
            serviceID: String(sourceID),
            serviceName: name,
            kind: kind,
            region: region,
            webURL: Self.link(webURL),
            appURL: Self.link(iosURL),
            quality: format,
            price: price.flatMap { Decimal(string: String($0)) }
        )
    }

    /// Só aceita endereços de verdade. No plano gratuito, os campos de deep link
    /// trazem um aviso em texto ("Deeplinks available for paid plans only.").
    static func link(_ value: String?) -> URL? {
        guard let value, !value.contains(" "),
              let url = URL(string: value), let scheme = url.scheme, !scheme.isEmpty,
              url.host() != nil || scheme != "https" && scheme != "http"
        else { return nil }
        return url
    }
}

extension StreamingOffer.Kind {
    init?(watchmodeType: String) {
        switch watchmodeType {
        case "sub": self = .subscription
        case "free": self = .free
        case "rent": self = .rent
        case "buy": self = .buy
        case "tve": self = .tvProvider
        default: return nil
        }
    }
}
