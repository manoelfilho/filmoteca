/// Junta as implementações de várias marcas atrás das mesmas interfaces.
///
/// - Parear: descobre a marca da TV no endereço e usa a implementação dela.
/// - Abrir conteúdo: usa a implementação da plataforma da TV (`TVDevice.platform`).
/// - Listar: junta as TVs pareadas de todas as marcas.
///
/// Quem usa as interfaces não sabe quantas marcas existem nem qual é a TV.
public final class TVControllerGroup: Sendable {
    private let controllers: [any TVPlatformController]

    /// - Parameter controllers: em ordem de preferência, para o caso raro de duas reconhecerem o mesmo endereço.
    public init(_ controllers: [any TVPlatformController]) {
        self.controllers = controllers
    }

    private func controller(for device: TVDevice) throws -> any TVPlatformController {
        guard let controller = controllers.first(where: { $0.platform == device.platform }) else {
            throw TVError.notPaired
        }
        return controller
    }

    /// Pergunta a todas as marcas ao mesmo tempo; fica a primeira (na ordem de preferência) que reconhecer.
    private func controller(recognizing host: String) async -> (any TVPlatformController)? {
        let recognized = await withTaskGroup(of: (Int, Bool).self) { group in
            for (index, controller) in controllers.enumerated() {
                group.addTask { (index, await controller.recognizesTV(at: host)) }
            }
            var recognized: Set<Int> = []
            for await (index, isRecognized) in group where isRecognized {
                recognized.insert(index)
            }
            return recognized
        }
        return recognized.min().map { controllers[$0] }
    }
}

extension TVControllerGroup: PairTV {
    public func pairTV(host input: String) async throws -> TVDevice {
        guard let host = TVHost.normalize(input) else { throw TVError.invalidHost }
        guard let controller = await controller(recognizing: host) else { throw TVError.unreachable }
        return try await controller.pairTV(host: host)
    }
}

extension TVControllerGroup: ListPairedTVs {
    public func listPairedTVs() async throws -> [TVDevice] {
        var devices: [TVDevice] = []
        for controller in controllers {
            devices += try await controller.listPairedTVs()
        }
        return devices
    }
}

extension TVControllerGroup: ForgetTV {
    public func forgetTV(id: TVDevice.ID) async throws {
        for controller in controllers {
            try await controller.forgetTV(id: id)
        }
    }
}

extension TVControllerGroup: LaunchOnTV {
    public func launchOnTV(_ request: TVLaunchRequest, on device: TVDevice) async throws -> TVLaunchResult {
        try await controller(for: device).launchOnTV(request, on: device)
    }
}
