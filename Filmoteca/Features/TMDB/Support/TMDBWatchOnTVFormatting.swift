import Foundation
import MovieDomain
import TVDomain

extension StreamingOffer {
    /// "Assinatura · 4K" ou "Aluguel · R$ 14,90".
    var accessDescription: String {
        let kindName: String = switch kind {
        case .subscription: String(localized: "tmdb_offer_subscription")
        case .free: String(localized: "tmdb_offer_free")
        case .rent: String(localized: "tmdb_offer_rent")
        case .buy: String(localized: "tmdb_offer_buy")
        case .tvProvider: String(localized: "tmdb_offer_tv_provider")
        }
        let priceText = price.map { $0.formatted(.currency(code: Self.currencyCode(for: region))) }
        return [kindName, priceText ?? quality].compactMap { $0 }.joined(separator: " · ")
    }

    private static func currencyCode(for region: String?) -> String {
        guard let region else { return Locale.current.currency?.identifier ?? "USD" }
        return Locale(identifier: "und_\(region)").currency?.identifier ?? "USD"
    }
}

extension TVError {
    var localizedMessage: String {
        switch self {
        case .invalidHost: String(localized: "tmdb_tv_error_invalid_host")
        case .unreachable, .localNetworkDenied: String(localized: "tmdb_tv_error_unreachable")
        case .pairingRejected: String(localized: "tmdb_tv_error_rejected")
        case .pairingTimedOut: String(localized: "tmdb_tv_error_timeout")
        case .notPaired: String(localized: "tmdb_tv_error_not_paired")
        case .appNotInstalled(let serviceName): String(localized: "tmdb_tv_error_app_missing \(serviceName)")
        case .commandFailed: String(localized: "tmdb_tv_error_generic")
        }
    }
}
