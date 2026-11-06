import Foundation

/// TV pareada com o app.
public struct TVDevice: Identifiable, Hashable, Sendable, Codable {
    /// Identificador estável da TV para a implementação que a controla.
    public let id: String
    /// Nome para exibir (ex.: "LG OLED55C1").
    public var name: String
    /// Endereço na rede local (IP ou nome).
    public var host: String
    /// Plataforma da TV (ex.: "webOS").
    public var platform: String

    public init(id: String, name: String, host: String, platform: String) {
        self.id = id
        self.name = name
        self.host = host
        self.platform = platform
    }
}
