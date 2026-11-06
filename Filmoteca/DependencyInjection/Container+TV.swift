import FactoryKit
import LGWebOS
import SamsungTizen
import TVDomain

/// Conexão com TVs.
///
/// Só este arquivo conhece as implementações (LG webOS e Samsung Tizen). O resto do app
/// usa as interfaces de `TVDomain`, atendidas por um grupo que descobre a marca da TV
/// pelo endereço. Para outra marca: um pacote que implemente `TVPlatformController`
/// e uma linha a mais em `tvControllerGroup`.
extension Container {
    var lgWebOSController: Factory<LGWebOSTVController> {
        self { LGWebOSTVController() }
            .singleton
    }

    var samsungTizenController: Factory<SamsungTizenTVController> {
        self { SamsungTizenTVController(httpClient: self.httpClient()) }
            .singleton
    }

    var tvControllerGroup: Factory<TVControllerGroup> {
        self { TVControllerGroup([self.lgWebOSController(), self.samsungTizenController()]) }
            .singleton
    }

    var pairTV: Factory<any PairTV> {
        self { self.tvControllerGroup() }
    }

    var listPairedTVs: Factory<any ListPairedTVs> {
        self { self.tvControllerGroup() }
    }

    var forgetTV: Factory<any ForgetTV> {
        self { self.tvControllerGroup() }
    }

    var launchOnTV: Factory<any LaunchOnTV> {
        self { self.tvControllerGroup() }
    }
}
