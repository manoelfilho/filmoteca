import DesignSystem
import FactoryKit
import MovieDomain
import SwiftUI
import TVDomain

/// Folha "Assistir na TV": escolhe a TV e o streaming onde abrir o filme.
struct TMDBWatchOnTVSheet: View {
    @State private var viewModel: TMDBWatchOnTVViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isHostFieldFocused: Bool

    /// Serviços do TMDB, só para mostrar os logos ao lado de cada oferta.
    private let providers: [WatchProvider]

    init(movie: Movie, providers: [WatchProvider] = []) {
        _viewModel = State(initialValue: Container.shared.tmdbWatchOnTVViewModel(movie))
        self.providers = providers
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DSSpacing.xl) {
                    tvSection
                    offersSection
                }
                .padding(DSSpacing.md)
            }
            .background(DSColor.background)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(String(localized: "tmdb_tv_title"))
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common_close")) { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task { await viewModel.load() }
        .onDisappear { viewModel.cancelPendingWork() }
    }

    // MARK: - TV

    @ViewBuilder
    private var tvSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            TMDBSectionHeader(title: String(localized: "tmdb_tv_section_tv"))

            if let tv = viewModel.selectedTV {
                selectedTV(tv)
            }
            if viewModel.showsPairingForm {
                pairingForm
            }
        }
    }

    private func selectedTV(_ tv: TVDevice) -> some View {
        DSCard {
            HStack(spacing: DSSpacing.sm) {
                Image(systemName: "tv.badge.wifi")
                    .font(.title2)
                    .foregroundStyle(DSColor.primary)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(tv.name)
                        .font(DSFont.headline)
                        .foregroundStyle(DSColor.textPrimary)
                    Text(tv.host)
                        .font(DSFont.caption)
                        .foregroundStyle(DSColor.textSecondary)
                }

                Spacer(minLength: 0)

                Menu {
                    if viewModel.pairedTVs.count > 1 {
                        Picker(String(localized: "tmdb_tv_switch"), selection: $viewModel.selectedTV) {
                            ForEach(viewModel.pairedTVs) { device in
                                Text(device.name).tag(Optional(device))
                            }
                        }
                    }
                    Button {
                        viewModel.isAddingTV = true
                    } label: {
                        Label(String(localized: "tmdb_tv_add"), systemImage: "plus")
                    }
                    Button(role: .destructive) {
                        Task { await viewModel.forget(tv) }
                    } label: {
                        Label(String(localized: "tmdb_tv_forget"), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(DSColor.textSecondary)
                }
                .accessibilityLabel(Text(String(localized: "tmdb_tv_options")))
            }
        }
    }

    private var pairingForm: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text(String(localized: "tmdb_tv_pair_description"))
                    .font(DSFont.callout)
                    .foregroundStyle(DSColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                DSTextField(
                    String(localized: "tmdb_tv_ip_label"),
                    placeholder: "192.168.0.20",
                    text: $viewModel.hostInput
                )
                .focused($isHostFieldFocused)
                .autocorrectionDisabled()
                #if os(iOS)
                .keyboardType(.numbersAndPunctuation)
                .textInputAutocapitalization(.never)
                #endif
                .submitLabel(.go)
                .onSubmit { viewModel.startPairing() }

                if viewModel.isPairing {
                    Label {
                        Text(String(localized: "tmdb_tv_pairing_prompt"))
                    } icon: {
                        ProgressView()
                    }
                    .font(DSFont.callout)
                    .foregroundStyle(DSColor.textPrimary)
                } else if let error = viewModel.pairingError {
                    Label(error.localizedMessage, systemImage: "exclamationmark.triangle")
                        .font(DSFont.callout)
                        .foregroundStyle(DSColor.destructive)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    isHostFieldFocused = false
                    viewModel.startPairing()
                } label: {
                    Label(String(localized: "tmdb_tv_connect"), systemImage: "link")
                }
                .buttonStyle(.ds(.primary))
                .disabled(viewModel.isPairing || viewModel.hostInput.trimmingCharacters(in: .whitespaces).isEmpty)

                Text(String(localized: "tmdb_tv_ip_hint"))
                    .font(DSFont.caption)
                    .foregroundStyle(DSColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Streamings

    @ViewBuilder
    private var offersSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            TMDBSectionHeader(
                title: String(localized: "tmdb_tv_section_streaming"),
                eyebrow: viewModel.movie.title
            )

            switch viewModel.offersState {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DSSpacing.lg)
            case .failed(let error):
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Label(error.localizedMessage, systemImage: "exclamationmark.triangle")
                            .font(DSFont.callout)
                            .foregroundStyle(DSColor.textPrimary)
                        Button(String(localized: "common_retry")) {
                            Task { await viewModel.loadOffers() }
                        }
                        .buttonStyle(.ds(.secondary))
                    }
                }
            case .loaded where viewModel.offers.isEmpty:
                Label(String(localized: "tmdb_tv_no_offers"), systemImage: "tv.slash")
                    .font(DSFont.callout)
                    .foregroundStyle(DSColor.textSecondary)
                    .padding(.vertical, DSSpacing.sm)
            case .loaded:
                if viewModel.selectedTV == nil {
                    Text(String(localized: "tmdb_tv_pair_first"))
                        .font(DSFont.caption)
                        .foregroundStyle(DSColor.textSecondary)
                }
                VStack(spacing: DSSpacing.xs) {
                    ForEach(viewModel.offers) { offer in
                        offerRow(offer)
                    }
                }
            }
        }
    }

    private func offerRow(_ offer: StreamingOffer) -> some View {
        let state = viewModel.launchState.offerID == offer.id ? viewModel.launchState : .idle

        return Button {
            viewModel.startWatching(offer)
        } label: {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                HStack(spacing: DSSpacing.sm) {
                    offerLogo(offer)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(offer.serviceName)
                            .font(DSFont.headline)
                            .foregroundStyle(DSColor.textPrimary)
                            .lineLimit(1)
                        Text(offer.accessDescription)
                            .font(DSFont.caption)
                            .foregroundStyle(DSColor.textSecondary)
                    }

                    Spacer(minLength: 0)
                    launchIndicator(state)
                }

                if let message = launchMessage(state, offer: offer) {
                    Text(message)
                        .font(DSFont.caption)
                        .foregroundStyle(isFailure(state) ? DSColor.destructive : DSColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(DSSpacing.sm)
            .background(DSColor.surface, in: RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                    .strokeBorder(DSColor.border)
            }
            .contentShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.selectedTV == nil)
        .opacity(viewModel.selectedTV == nil ? 0.5 : 1)
        .accessibilityHint(Text(String(localized: "tmdb_tv_open_hint")))
    }

    @ViewBuilder
    private func offerLogo(_ offer: StreamingOffer) -> some View {
        if let provider = matchingProvider(for: offer) {
            TMDBProviderLogo(provider: provider, size: 40)
        } else {
            Image(systemName: "play.tv")
                .font(.title3)
                .foregroundStyle(DSColor.textSecondary)
                .frame(width: 40, height: 40)
                .background(DSColor.background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    @ViewBuilder
    private func launchIndicator(_ state: TMDBWatchOnTVViewModel.LaunchState) -> some View {
        switch state {
        case .launching:
            ProgressView()
        case .launched:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(DSColor.primary)
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(DSColor.destructive)
        case .idle:
            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundStyle(DSColor.primary)
        }
    }

    private func launchMessage(_ state: TMDBWatchOnTVViewModel.LaunchState, offer: StreamingOffer) -> String? {
        switch state {
        case .idle, .launching:
            nil
        case .launched(_, .openedContent):
            String(localized: "tmdb_tv_opened_content \(offer.serviceName)")
        case .launched(_, .openedApp):
            String(localized: "tmdb_tv_opened_app \(offer.serviceName) \(viewModel.movie.title)")
        case .failed(_, let error):
            error.localizedMessage
        }
    }

    private func isFailure(_ state: TMDBWatchOnTVViewModel.LaunchState) -> Bool {
        if case .failed = state { true } else { false }
    }

    /// Mesmo serviço com nomes diferentes nas APIs ("Disney Plus" x "Disney+").
    private func matchingProvider(for offer: StreamingOffer) -> WatchProvider? {
        let name = offer.serviceName.normalizedServiceName
        return providers.first { $0.name.normalizedServiceName == name }
            ?? providers.first { $0.name.normalizedServiceName.hasPrefix(name) || name.hasPrefix($0.name.normalizedServiceName) }
    }
}

private extension String {
    var normalizedServiceName: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .replacingOccurrences(of: "+", with: "plus")
            .filter { $0.isLetter || $0.isNumber }
    }
}
