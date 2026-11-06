import DesignSystem
import SwiftUI

/// Aba "Sobre": como funcionam as notas, as APIs usadas e o controle de TVs.
struct TMDBAboutView: View {
    private struct Section: Identifiable {
        let systemImage: String
        let title: String
        let body: String

        var id: String { systemImage }
    }

    // Chaves escritas por extenso: montadas com interpolação, viram chaves com `%@`
    // (ex.: "tmdb_about_%@_title"), que não existem no catálogo.
    private let sections = [
        Section(
            systemImage: "film.stack",
            title: String(localized: "tmdb_about_app_title"),
            body: String(localized: "tmdb_about_app_body")
        ),
        Section(
            systemImage: "star.leadinghalf.filled",
            title: String(localized: "tmdb_about_ratings_title"),
            body: String(localized: "tmdb_about_ratings_body")
        ),
        Section(
            systemImage: "key",
            title: String(localized: "tmdb_about_apis_title"),
            body: String(localized: "tmdb_about_apis_body")
        ),
        Section(
            systemImage: "tv",
            title: String(localized: "tmdb_about_tv_title"),
            body: String(localized: "tmdb_about_tv_body")
        ),
        Section(
            systemImage: "lock",
            title: String(localized: "tmdb_about_privacy_title"),
            body: String(localized: "tmdb_about_privacy_body")
        ),
    ]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DSSpacing.md) {
                ForEach(sections) { section in
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.sm) {
                            Label {
                                Text(section.title)
                                    .font(DSFont.headline)
                                    .foregroundStyle(DSColor.textPrimary)
                            } icon: {
                                Image(systemName: section.systemImage)
                                    .foregroundStyle(DSColor.accent)
                            }
                            .accessibilityAddTraits(.isHeader)

                            Text(section.body)
                                .font(DSFont.body)
                                .foregroundStyle(DSColor.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Text(String(localized: "tmdb_about_footer \(appVersion)"))
                    .font(DSFont.caption)
                    .foregroundStyle(DSColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, DSSpacing.sm)
            }
            .padding(DSSpacing.md)
        }
        .background(DSColor.background)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

#Preview {
    NavigationStack {
        TMDBAboutView()
            .navigationTitle(String(localized: "tmdb_tab_about"))
    }
}
