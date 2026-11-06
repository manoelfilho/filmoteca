/// Lista os serviços de streaming disponíveis em uma região, por relevância.
public protocol ListWatchProviders: Sendable {
    func listWatchProviders(_ query: WatchProviderListQuery) async throws -> [WatchProvider]
}

public struct WatchProviderListQuery: Hashable, Sendable {
    public var region: String?
    public var language: String?

    public init(region: String? = nil, language: String? = nil) {
        self.region = region
        self.language = language
    }
}

extension ListWatchProviders {
    public func listWatchProviders() async throws -> [WatchProvider] {
        try await listWatchProviders(WatchProviderListQuery())
    }
}
