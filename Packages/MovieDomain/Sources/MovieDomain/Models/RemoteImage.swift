import Foundation

/// Imagem remota já resolvida em URLs absolutas, em tamanhos genéricos.
///
/// Cada provedor decide quais tamanhos reais correspondem a `small`, `medium` e `large`,
/// assim a UI escolhe o tamanho sem conhecer as regras da API.
public struct RemoteImage: Hashable, Sendable {
    public enum Size: Sendable, CaseIterable {
        case small
        case medium
        case large
        case original
    }

    public let small: URL
    public let medium: URL
    public let large: URL
    public let original: URL

    public init(small: URL, medium: URL, large: URL, original: URL) {
        self.small = small
        self.medium = medium
        self.large = large
        self.original = original
    }

    /// Para provedores que só têm uma URL.
    public init(url: URL) {
        self.init(small: url, medium: url, large: url, original: url)
    }

    public func url(for size: Size) -> URL {
        switch size {
        case .small: small
        case .medium: medium
        case .large: large
        case .original: original
        }
    }
}
