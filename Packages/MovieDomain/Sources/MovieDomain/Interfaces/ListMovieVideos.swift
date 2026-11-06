/// Lista trailers, teasers e outros vídeos de um filme.
public protocol ListMovieVideos: Sendable {
    func listMovieVideos(_ query: MovieVideosQuery) async throws -> [MovieVideo]
}

public struct MovieVideosQuery: Hashable, Sendable {
    public var movieID: MovieID
    public var language: String?

    public init(movieID: MovieID, language: String? = nil) {
        self.movieID = movieID
        self.language = language
    }
}

extension ListMovieVideos {
    public func listMovieVideos(movieID: MovieID) async throws -> [MovieVideo] {
        try await listMovieVideos(MovieVideosQuery(movieID: movieID))
    }
}
