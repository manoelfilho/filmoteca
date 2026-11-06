import SwiftUI

/// Sombras de elevação. Aplique com `.dsShadow(_:)`.
public struct DSShadow: Sendable {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat

    public static let sm = DSShadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    public static let md = DSShadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
}

extension View {
    public func dsShadow(_ shadow: DSShadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}
