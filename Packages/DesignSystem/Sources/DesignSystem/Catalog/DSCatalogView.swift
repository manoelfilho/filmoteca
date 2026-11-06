import SwiftUI

/// Mostra os tokens e componentes do Design System.
public struct DSCatalogView: View {
    @State private var text = ""

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                section("Paleta") {
                    swatch("Smart Blue", DSPalette.smartBlue)
                    swatch("French Blue", DSPalette.frenchBlue)
                    swatch("Light Gold", DSPalette.lightGold)
                    swatch("Tangerine Dream", DSPalette.tangerineDream)
                    swatch("Vibrant Coral", DSPalette.vibrantCoral)
                }

                section("Cores semânticas") {
                    swatch("primary", DSColor.primary)
                    swatch("secondary", DSColor.secondary)
                    swatch("accent", DSColor.accent)
                    swatch("highlight", DSColor.highlight)
                    swatch("destructive", DSColor.destructive)
                    swatch("surface", DSColor.surface)
                    swatch("border", DSColor.border)
                    swatch("onMedia", DSColor.onMedia)
                    swatch("scrim", DSColor.scrim)
                }

                section("Tipografia") {
                    Text("Display").font(DSFont.display)
                    Text("Title").font(DSFont.title)
                    Text("Headline").font(DSFont.headline)
                    Text("Body").font(DSFont.body)
                    Text("Callout").font(DSFont.callout)
                    Text("Caption").font(DSFont.caption)
                }

                section("Espaçamentos") {
                    spacing("xxs", DSSpacing.xxs)
                    spacing("xs", DSSpacing.xs)
                    spacing("sm", DSSpacing.sm)
                    spacing("md", DSSpacing.md)
                    spacing("lg", DSSpacing.lg)
                    spacing("xl", DSSpacing.xl)
                    spacing("xxl", DSSpacing.xxl)
                }

                section("Componentes") {
                    Button("Primary") {}.buttonStyle(.ds(.primary))
                    Button("Secondary") {}.buttonStyle(.ds(.secondary))
                    Button("Destructive") {}.buttonStyle(.ds(.destructive))
                    Button("Disabled") {}.buttonStyle(.ds(.primary)).disabled(true)
                    DSTextField("Rótulo", placeholder: "Digite aqui", text: $text)
                    DSCard {
                        Text("Card").font(DSFont.headline)
                    }
                }
            }
            .foregroundStyle(DSColor.textPrimary)
            .padding(DSSpacing.md)
        }
        .background(DSColor.background)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text(title).font(DSFont.title)
            content()
        }
    }

    private func swatch(_ name: String, _ color: Color) -> some View {
        HStack(spacing: DSSpacing.sm) {
            RoundedRectangle(cornerRadius: DSRadius.sm)
                .fill(color)
                .overlay {
                    RoundedRectangle(cornerRadius: DSRadius.sm).stroke(DSColor.border)
                }
                .frame(width: 44, height: 44)
            Text(name).font(DSFont.body)
        }
    }

    private func spacing(_ name: String, _ value: CGFloat) -> some View {
        HStack(spacing: DSSpacing.sm) {
            Text(name)
                .font(DSFont.callout)
                .frame(width: 44, alignment: .leading)
            Rectangle()
                .fill(DSColor.accent)
                .frame(width: value, height: DSSpacing.md)
        }
    }
}

#Preview("Light") {
    DSCatalogView().preferredColorScheme(.light)
}

#Preview("Dark") {
    DSCatalogView().preferredColorScheme(.dark)
}
