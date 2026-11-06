import SwiftUI

/// Estilo de botão do Design System. Uso: `.buttonStyle(.ds(.primary))`.
public struct DSButtonStyle: ButtonStyle {
    public enum Variant: Sendable {
        case primary
        case secondary
        case destructive
    }

    let variant: Variant

    @Environment(\.isEnabled) private var isEnabled

    public init(_ variant: Variant) {
        self.variant = variant
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DSFont.headline)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.sm)
            .padding(.horizontal, DSSpacing.md)
            .background(background, in: RoundedRectangle(cornerRadius: DSRadius.md))
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.5)
    }

    private var foreground: Color {
        switch variant {
        case .primary, .secondary: DSColor.onPrimary
        case .destructive: DSColor.onDestructive
        }
    }

    private var background: Color {
        switch variant {
        case .primary: DSColor.primary
        case .secondary: DSColor.secondary
        case .destructive: DSColor.destructive
        }
    }
}

extension ButtonStyle where Self == DSButtonStyle {
    public static func ds(_ variant: DSButtonStyle.Variant) -> DSButtonStyle {
        DSButtonStyle(variant)
    }
}
