/// Desfaz o pareamento de uma TV no app. Esquecer uma TV desconhecida não é erro.
public protocol ForgetTV: Sendable {
    func forgetTV(id: TVDevice.ID) async throws
}
