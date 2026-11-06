/// Abre um título de streaming em uma TV pareada.
public protocol LaunchOnTV: Sendable {
    func launchOnTV(_ request: TVLaunchRequest, on device: TVDevice) async throws -> TVLaunchResult
}
