import Foundation

/// Onde e como assistir a um filme em um serviço de streaming, com os links para abri-lo.
///
/// Diferente de `WatchProvider` (só o serviço), uma oferta traz o modo de acesso
/// (assinatura, aluguel...) e os endereços do filme dentro do serviço.
public struct StreamingOffer: Identifiable, Hashable, Sendable {
    public enum Kind: String, Hashable, Sendable, CaseIterable {
        case subscription
        case free
        case rent
        case buy
        /// Liberado com login de operadora de TV.
        case tvProvider
    }

    /// Identificador do serviço no provedor de dados.
    public let serviceID: String
    public let serviceName: String
    public let kind: Kind
    /// País da oferta (ex.: `BR`).
    public let region: String?
    /// Página do filme no site do serviço. É dela que se tira o ID do filme no serviço.
    public let webURL: URL?
    /// Link que abre o filme direto no app do serviço no iPhone, quando o provedor fornece.
    public let appURL: URL?
    /// Qualidade (ex.: `HD`, `4K`).
    public let quality: String?
    /// Preço para aluguel ou compra.
    public let price: Decimal?

    public var id: String { "\(serviceID)-\(kind.rawValue)-\(region ?? "")" }

    public init(
        serviceID: String,
        serviceName: String,
        kind: Kind,
        region: String? = nil,
        webURL: URL? = nil,
        appURL: URL? = nil,
        quality: String? = nil,
        price: Decimal? = nil
    ) {
        self.serviceID = serviceID
        self.serviceName = serviceName
        self.kind = kind
        self.region = region
        self.webURL = webURL
        self.appURL = appURL
        self.quality = quality
        self.price = price
    }
}
