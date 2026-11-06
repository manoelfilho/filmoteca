/// Informa onde um filme está disponível (streaming, aluguel, compra).
public protocol GetMovieWatchProviders: Sendable {
    func getMovieWatchProviders(_ query: MovieWatchProvidersQuery) async throws -> MovieWatchProviders
}

public struct MovieWatchProvidersQuery: Hashable, Sendable {
    public var movieID: MovieID
    /// País no formato ISO 3166-1 (ex.: `BR`). `nil` usa o padrão do provedor.
    public var region: String?

    public init(movieID: MovieID, region: String? = nil) {
        self.movieID = movieID
        self.region = region
    }
}

extension GetMovieWatchProviders {
    public func getMovieWatchProviders(movieID: MovieID) async throws -> MovieWatchProviders {
        try await getMovieWatchProviders(MovieWatchProvidersQuery(movieID: movieID))
    }
}
