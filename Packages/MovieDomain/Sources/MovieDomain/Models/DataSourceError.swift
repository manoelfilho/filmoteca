/// Erros que qualquer provedor de dados (remoto ou local) pode lançar.
///
/// Quem consome as interfaces trata apenas este tipo, sem conhecer
/// Alamofire, códigos HTTP ou o formato de erro de cada API.
public enum DataSourceError: Error, Hashable, Sendable {
    /// Credencial ausente ou inválida.
    case unauthorized(message: String?)
    case notFound
    case rateLimited
    case connectivity
    case timeout
    case cancelled
    case invalidQuery(String)
    case server(statusCode: Int, message: String?)
    case invalidResponse
    case decoding(String)
    /// Falha ao ler ou gravar dados locais.
    case storage(String)
    case unknown(String)
}
