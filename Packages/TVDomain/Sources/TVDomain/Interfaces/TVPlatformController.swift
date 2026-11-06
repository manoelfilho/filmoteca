/// Implementação de uma marca/plataforma de TV (LG webOS, Samsung Tizen...).
///
/// Cada marca atende as interfaces de TV para as suas próprias TVs e sabe dizer
/// se um endereço é uma TV dela. `TVControllerGroup` junta várias marcas.
public protocol TVPlatformController: PairTV, ListPairedTVs, ForgetTV, LaunchOnTV {
    /// Valor de `TVDevice.platform` das TVs desta implementação (ex.: "webOS").
    nonisolated var platform: String { get }

    /// Verifica, sem pedir pareamento, se no endereço há uma TV desta plataforma.
    func recognizesTV(at host: String) async -> Bool
}
