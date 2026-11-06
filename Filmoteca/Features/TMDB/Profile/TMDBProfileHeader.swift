import DesignSystem
import FactoryKit
import SwiftUI

/// Foto e nome do usuário, com o dia atual logo abaixo. Toque para editar.
struct TMDBProfileHeader: View {
    @InjectedObservable(\.tmdbUserProfile) private var profile
    @State private var isEditing = false

    var body: some View {
        // Não usa `Button`: na barra de navegação ele mostraria só a imagem do conteúdo.
        HStack(spacing: DSSpacing.xs) {
                TMDBProfileAvatar(profile: profile, size: 36)

                VStack(alignment: .leading, spacing: 0) {
                    Text(profile.displayName.isEmpty ? String(localized: "tmdb_profile_add_name") : profile.displayName)
                        .font(DSFont.headline)
                        .foregroundStyle(DSColor.textPrimary)
                        .lineLimit(1)

                    // Atualiza sozinho na virada do dia.
                    TimelineView(.everyMinute) { context in
                        Text(context.date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                            .font(DSFont.caption)
                            .foregroundStyle(DSColor.textSecondary)
                            .lineLimit(1)
                    }
                }
        }
        .fixedSize()
        .contentShape(Rectangle())
        .onTapGesture { isEditing = true }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { isEditing = true }
        .accessibilityHint(Text(String(localized: "tmdb_profile_edit_hint")))
        .sheet(isPresented: $isEditing) {
            TMDBProfileEditSheet()
        }
    }
}

/// Foto do perfil em círculo; sem foto, mostra as iniciais ou um ícone.
struct TMDBProfileAvatar: View {
    let profile: TMDBUserProfile
    let size: CGFloat

    var body: some View {
        ZStack {
            if let photo = profile.photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
            } else {
                DSColor.primary
                if profile.initials.isEmpty {
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.45))
                        .foregroundStyle(DSColor.onPrimary)
                } else {
                    Text(profile.initials)
                        .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                        .foregroundStyle(DSColor.onPrimary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay { Circle().strokeBorder(DSColor.border) }
        .accessibilityHidden(true)
    }
}
