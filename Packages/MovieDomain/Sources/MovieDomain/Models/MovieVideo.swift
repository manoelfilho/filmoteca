import Foundation

public struct MovieVideo: Identifiable, Hashable, Sendable {
    public enum Kind: Hashable, Sendable {
        case trailer
        case teaser
        case clip
        case featurette
        case behindTheScenes
        case bloopers
        case other(String)
    }

    public let id: String
    public let name: String
    public let kind: Kind
    public let isOfficial: Bool
    public let publishedAt: Date?
    /// URL para assistir (ex.: YouTube). `nil` quando o site não é suportado.
    public let url: URL?
    public let thumbnail: URL?

    public init(
        id: String,
        name: String,
        kind: Kind,
        isOfficial: Bool = false,
        publishedAt: Date? = nil,
        url: URL? = nil,
        thumbnail: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.isOfficial = isOfficial
        self.publishedAt = publishedAt
        self.url = url
        self.thumbnail = thumbnail
    }
}
