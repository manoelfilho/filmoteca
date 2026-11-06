import DesignSystem
import FactoryKit
import PhotosUI
import SwiftUI

/// Edição do perfil local: foto da galeria e nome.
struct TMDBProfileEditSheet: View {
    @InjectedObservable(\.tmdbUserProfile) private var profile
    @Environment(\.dismiss) private var dismiss
    @State private var photoItem: PhotosPickerItem?
    @State private var name = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DSSpacing.lg) {
                    VStack(spacing: DSSpacing.sm) {
                        TMDBProfileAvatar(profile: profile, size: 120)

                        HStack(spacing: DSSpacing.sm) {
                            PhotosPicker(selection: $photoItem, matching: .images) {
                                Label(String(localized: "tmdb_profile_choose_photo"), systemImage: "photo")
                            }
                            .buttonStyle(.ds(.secondary))

                            if profile.photo != nil {
                                Button(role: .destructive) {
                                    Task { await profile.setPhoto(nil) }
                                } label: {
                                    Label(String(localized: "tmdb_profile_remove_photo"), systemImage: "trash")
                                }
                                .buttonStyle(.ds(.destructive))
                            }
                        }
                    }

                    DSTextField(
                        String(localized: "tmdb_profile_name"),
                        placeholder: String(localized: "tmdb_profile_name_placeholder"),
                        text: $name
                    )
                    .textContentType(.name)
                    .submitLabel(.done)
                    .onSubmit(save)

                    Text(String(localized: "tmdb_profile_privacy_note"))
                        .font(DSFont.caption)
                        .foregroundStyle(DSColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(DSSpacing.md)
            }
            .background(DSColor.background)
            .navigationTitle(String(localized: "tmdb_profile_title"))
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common_cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common_save"), action: save)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear { name = profile.name }
        .task(id: photoItem) {
            guard let photoItem,
                  let data = try? await photoItem.loadTransferable(type: Data.self)
            else { return }
            await profile.setPhoto(data)
        }
    }

    private func save() {
        profile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        dismiss()
    }
}
