/// Erros que qualquer implementação de TV pode lançar.
public enum TVError: Error, Hashable, Sendable {
    /// Endereço vazio ou inválido.
    case invalidHost
    /// A TV não respondeu (desligada, em outra rede ou com IP errado).
    case unreachable
    /// O app não tem permissão para acessar a rede local.
    case localNetworkDenied
    /// O pedido de pareamento foi recusado na TV.
    case pairingRejected
    /// Ninguém aceitou o pedido de pareamento na TV a tempo.
    case pairingTimedOut
    /// A TV não reconhece mais o app (pareamento desfeito na TV). É preciso parear de novo.
    case notPaired
    /// O app do serviço não está instalado na TV.
    case appNotInstalled(serviceName: String)
    case commandFailed(String)
}
