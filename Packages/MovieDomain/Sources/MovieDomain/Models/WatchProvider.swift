import Foundation

/// Serviço onde um filme pode ser assistido (Netflix, Prime Video...).
public struct WatchProvider: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let logo: RemoteImage?
    /// Relevância na região (menor = mais relevante).
    public let displayPriority: Int

    public init(id: String, name: String, logo: RemoteImage? = nil, displayPriority: Int = .max) {
        self.id = id
        self.name = name
        self.logo = logo
        self.displayPriority = displayPriority
    }
}

/// Como o filme está disponível em um serviço.
public enum WatchMonetizationType: String, Hashable, Sendable, CaseIterable {
    /// Incluído na assinatura.
    case subscription
    case free
    /// Grátis com anúncios.
    case ads
    case rent
    case buy
}

/// Onde um filme está disponível em uma região.
public struct MovieWatchProviders: Hashable, Sendable {
    public let movieID: MovieID
    public let region: String
    /// Página com todas as opções (quando o provedor oferece).
    public let link: URL?
    public let subscription: [WatchProvider]
    public let free: [WatchProvider]
    public let ads: [WatchProvider]
    public let rent: [WatchProvider]
    public let buy: [WatchProvider]

    public init(
        movieID: MovieID,
        region: String,
        link: URL? = nil,
        subscription: [WatchProvider] = [],
        free: [WatchProvider] = [],
        ads: [WatchProvider] = [],
        rent: [WatchProvider] = [],
        buy: [WatchProvider] = []
    ) {
        self.movieID = movieID
        self.region = region
        self.link = link
        self.subscription = subscription
        self.free = free
        self.ads = ads
        self.rent = rent
        self.buy = buy
    }

    /// Serviços de streaming (assinatura, grátis ou com anúncios), sem repetição, por relevância.
    public var streaming: [WatchProvider] {
        var seen = Set<String>()
        return (subscription + free + ads)
            .sorted { $0.displayPriority < $1.displayPriority }
            .filter { seen.insert($0.id).inserted }
    }

    /// Serviço principal para exibir em destaque.
    public var primaryStreaming: WatchProvider? { streaming.first }

    public var isEmpty: Bool {
        subscription.isEmpty && free.isEmpty && ads.isEmpty && rent.isEmpty && buy.isEmpty
    }
}
