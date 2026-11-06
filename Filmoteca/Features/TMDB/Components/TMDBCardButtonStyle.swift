import DesignSystem
import SwiftUI

/// Leve redução ao tocar, como nos cards do Apple TV.
struct TMDBCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(DSMotion.spring, value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

extension ButtonStyle where Self == TMDBCardButtonStyle {
    static var tmdbCard: TMDBCardButtonStyle { TMDBCardButtonStyle() }
}
