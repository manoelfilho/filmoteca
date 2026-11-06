import Foundation

/// O que abrir na TV: um título em um serviço de streaming.
///
/// Descreve o conteúdo de forma neutra (nome do serviço e página do título).
/// Cada implementação decide qual app da TV corresponde ao serviço e se
/// consegue abrir o título direto ou só o app.
public struct TVLaunchRequest: Hashable, Sendable {
    public var serviceName: String
    /// Página do título no site do serviço (ex.: `https://www.netflix.com/title/26004747`).
    public var webURL: URL?
    /// Nome do título, para mensagens.
    public var title: String?

    public init(serviceName: String, webURL: URL? = nil, title: String? = nil) {
        self.serviceName = serviceName
        self.webURL = webURL
        self.title = title
    }
}

/// Resultado de abrir conteúdo na TV.
public enum TVLaunchResult: Hashable, Sendable {
    /// O app do serviço abriu direto no título.
    case openedContent
    /// Só o app do serviço abriu; o usuário escolhe o título na TV.
    case openedApp
}
