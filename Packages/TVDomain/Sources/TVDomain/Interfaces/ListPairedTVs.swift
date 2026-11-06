/// Lista as TVs já pareadas, da mais recente para a mais antiga.
public protocol ListPairedTVs: Sendable {
    func listPairedTVs() async throws -> [TVDevice]
}
