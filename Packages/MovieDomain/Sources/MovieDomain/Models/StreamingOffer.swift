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
        /// Canal assinado à parte dentro de outro serviço (ex.: Paramount+ dentro do Prime Video).
        case addon
    }

    /// Identificador do serviço no provedor de dados. Canais têm um ID próprio,
    /// diferente do serviço que os hospeda.
    public let serviceID: String
    /// Nome para exibir. Num canal, indica também o serviço que o hospeda:
    /// "Paramount+ (Via Prime Video)".
    public let serviceName: String
    public let kind: Kind
    /// País da oferta (ex.: `BR`).
    public let region: String?
    /// Página do filme no site do serviço. É dela que se tira o ID do filme no serviço.
    public let webURL: URL?
    /// Link que começa a reprodução direto, quando o provedor fornece.
    /// Costuma ser um universal link: no iPhone, abre o app do serviço se estiver instalado.
    public let playURL: URL?
    /// Qualidade (ex.: `HD`, `4K`).
    public let quality: String?
    /// Preço para aluguel ou compra.
    public let price: Decimal?
    /// Moeda do preço (ISO 4217, ex.: `BRL`).
    public let currency: String?

    public var id: String { "\(serviceID)-\(kind.rawValue)-\(region ?? "")" }

    public init(
        serviceID: String,
        serviceName: String,
        kind: Kind,
        region: String? = nil,
        webURL: URL? = nil,
        playURL: URL? = nil,
        quality: String? = nil,
        price: Decimal? = nil,
        currency: String? = nil
    ) {
        self.serviceID = serviceID
        self.serviceName = serviceName
        self.kind = kind
        self.region = region
        self.webURL = webURL
        self.playURL = playURL
        self.quality = quality
        self.price = price
        self.currency = currency
    }
}
