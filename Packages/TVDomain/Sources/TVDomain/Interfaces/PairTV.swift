/// Pareia uma TV pela rede local. A TV costuma pedir confirmação na tela.
///
/// O pareamento fica salvo: depois dele, a TV aparece em `ListPairedTVs`.
public protocol PairTV: Sendable {
    func pairTV(host: String) async throws -> TVDevice
}
