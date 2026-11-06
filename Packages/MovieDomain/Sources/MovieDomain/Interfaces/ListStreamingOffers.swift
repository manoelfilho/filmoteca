/// Lista as ofertas de streaming de um filme: em quais serviços está e como abri-lo em cada um.
public protocol ListStreamingOffers: Sendable {
    func listStreamingOffers(_ query: StreamingOffersQuery) async throws -> [StreamingOffer]
}

public struct StreamingOffersQuery: Hashable, Sendable {
    public var movieID: MovieID
    /// Países (ex.: `["BR"]`). Vazio usa o padrão do provedor.
    public var regions: [String]
    /// Modos de acesso desejados. Vazio traz todos.
    public var kinds: Set<StreamingOffer.Kind>

    public init(movieID: MovieID, regions: [String] = [], kinds: Set<StreamingOffer.Kind> = []) {
        self.movieID = movieID
        self.regions = regions
        self.kinds = kinds
    }
}

extension ListStreamingOffers {
    public func listStreamingOffers(movieID: MovieID) async throws -> [StreamingOffer] {
        try await listStreamingOffers(StreamingOffersQuery(movieID: movieID))
    }
}
