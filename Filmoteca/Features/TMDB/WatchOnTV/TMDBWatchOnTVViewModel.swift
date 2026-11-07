import Foundation
import MovieDomain
import Observation
import TVDomain

/// Estado da folha "Assistir na TV".
///
/// Junta duas fontes, ambas por interface: onde o filme está (`ListStreamingOffers`,
/// hoje o Streaming Availability) e a TV que vai abri-lo (`PairTV`, `LaunchOnTV`...,
/// hoje LG webOS e Samsung Tizen).
@Observable
final class TMDBWatchOnTVViewModel {
    enum OffersState: Equatable {
        case loading
        case loaded
        case failed(DataSourceError)
    }

    enum LaunchState: Equatable {
        case idle
        case launching(offerID: StreamingOffer.ID)
        case launched(offerID: StreamingOffer.ID, result: TVLaunchResult)
        case failed(offerID: StreamingOffer.ID, error: TVError)

        var offerID: StreamingOffer.ID? {
            switch self {
            case .idle: nil
            case .launching(let id), .launched(let id, _), .failed(let id, _): id
            }
        }
    }

    let movie: Movie

    private(set) var offersState: OffersState = .loading
    /// Uma oferta por serviço, das mais acessíveis (assinatura, grátis) para as pagas.
    private(set) var offers: [StreamingOffer] = []

    private(set) var pairedTVs: [TVDevice] = []
    var selectedTV: TVDevice?
    /// Mostra o formulário de pareamento mesmo com TV já pareada (para adicionar outra).
    var isAddingTV = false
    var hostInput = ""
    private(set) var isPairing = false
    private(set) var pairingError: TVError?

    private(set) var launchState: LaunchState = .idle

    @ObservationIgnored private let listStreamingOffers: any ListStreamingOffers
    @ObservationIgnored private let listPairedTVs: any ListPairedTVs
    @ObservationIgnored private let pairTV: any PairTV
    @ObservationIgnored private let forgetTV: any ForgetTV
    @ObservationIgnored private let launchOnTV: any LaunchOnTV
    @ObservationIgnored private let region: String?
    @ObservationIgnored private let launchTimeout: Duration
    @ObservationIgnored private var pairTask: Task<Void, Never>?
    @ObservationIgnored private var launchTask: Task<Void, Never>?

    init(
        movie: Movie,
        listStreamingOffers: any ListStreamingOffers,
        listPairedTVs: any ListPairedTVs,
        pairTV: any PairTV,
        forgetTV: any ForgetTV,
        launchOnTV: any LaunchOnTV,
        region: String?,
        launchTimeout: Duration = .seconds(30)
    ) {
        self.movie = movie
        self.listStreamingOffers = listStreamingOffers
        self.listPairedTVs = listPairedTVs
        self.pairTV = pairTV
        self.forgetTV = forgetTV
        self.launchOnTV = launchOnTV
        self.region = region
        self.launchTimeout = launchTimeout
    }

    var showsPairingForm: Bool { selectedTV == nil || isAddingTV }

    func load() async {
        await refreshTVs()
        await loadOffers()
    }

    func loadOffers() async {
        offersState = .loading
        do {
            let query = StreamingOffersQuery(movieID: movie.id, regions: [region].compactMap { $0 })
            offers = Self.bestOfferPerService(try await listStreamingOffers.listStreamingOffers(query))
            offersState = .loaded
        } catch {
            offersState = .failed(error as? DataSourceError ?? .unknown(String(describing: error)))
        }
    }

    // MARK: - TV

    /// Cancela pareamento e abertura em andamento (ex.: a folha foi fechada).
    func cancelPendingWork() {
        pairTask?.cancel()
        launchTask?.cancel()
    }

    func startPairing() {
        guard !isPairing else { return }
        pairTask = Task { await pair() }
    }

    func startWatching(_ offer: StreamingOffer) {
        guard launchState != .launching(offerID: offer.id) else { return }
        launchTask?.cancel()
        launchTask = Task { await watch(offer) }
    }

    func pair() async {
        guard !isPairing else { return }
        isPairing = true
        pairingError = nil
        defer { isPairing = false }

        do {
            let device = try await pairTV.pairTV(host: hostInput)
            await refreshTVs()
            selectedTV = pairedTVs.first { $0.id == device.id } ?? device
            isAddingTV = false
            hostInput = ""
        } catch is CancellationError {
            pairingError = nil
        } catch {
            pairingError = Task.isCancelled ? nil : error as? TVError ?? .commandFailed(String(describing: error))
        }
    }

    func forget(_ device: TVDevice) async {
        try? await forgetTV.forgetTV(id: device.id)
        await refreshTVs()
        if selectedTV?.id == device.id {
            selectedTV = pairedTVs.first
        }
        launchState = .idle
    }

    func watch(_ offer: StreamingOffer) async {
        guard let selectedTV, launchState != .launching(offerID: offer.id) else { return }
        launchState = .launching(offerID: offer.id)

        let request = TVLaunchRequest(serviceName: offer.serviceName, webURL: offer.webURL, title: movie.title)
        let launchOnTV = launchOnTV
        do {
            // Prazo geral: o spinner nunca fica girando para sempre, responda a TV ou não.
            let result = try await withThrowingTaskGroup(of: TVLaunchResult.self) { group in
                group.addTask { try await launchOnTV.launchOnTV(request, on: selectedTV) }
                group.addTask { [launchTimeout] in
                    try await Task.sleep(for: launchTimeout)
                    throw TVError.unreachable
                }
                defer { group.cancelAll() }
                return try await group.next()!
            }
            launchState = .launched(offerID: offer.id, result: result)
        } catch is CancellationError {
            launchState = .idle
        } catch where Task.isCancelled {
            launchState = .idle
        } catch {
            let tvError = error as? TVError ?? .commandFailed(String(describing: error))
            launchState = .failed(offerID: offer.id, error: tvError)
            if tvError == .notPaired {
                // A TV esqueceu o app: some da lista e volta o formulário de pareamento.
                hostInput = selectedTV.host
                await forget(selectedTV)
                launchState = .failed(offerID: offer.id, error: tvError)
            }
        }
    }

    private func refreshTVs() async {
        pairedTVs = (try? await listPairedTVs.listPairedTVs()) ?? []
        if selectedTV == nil || !pairedTVs.contains(where: { $0.id == selectedTV?.id }) {
            selectedTV = pairedTVs.first
        }
    }

    // MARK: - Ofertas

    /// O provedor lista o mesmo serviço várias vezes (HD, 4K, aluguel e compra).
    /// Fica uma por serviço, priorizando o que o usuário já pode assistir.
    static func bestOfferPerService(_ offers: [StreamingOffer]) -> [StreamingOffer] {
        var best: [String: StreamingOffer] = [:]
        var order: [String] = []
        for offer in offers {
            guard let current = best[offer.serviceID] else {
                best[offer.serviceID] = offer
                order.append(offer.serviceID)
                continue
            }
            if offer.kind.rank < current.kind.rank {
                best[offer.serviceID] = offer
            }
        }
        // Ordem estável: modo de acesso e, depois, a ordem da API.
        return order.enumerated()
            .compactMap { index, id in best[id].map { (index, $0) } }
            .sorted { ($0.1.kind.rank, $0.0) < ($1.1.kind.rank, $1.0) }
            .map(\.1)
    }
}

extension StreamingOffer.Kind {
    /// Menor = mais acessível para quem quer assistir agora.
    fileprivate var rank: Int {
        switch self {
        case .subscription: 0
        case .free: 1
        case .addon: 2
        case .rent: 3
        case .buy: 4
        }
    }
}
