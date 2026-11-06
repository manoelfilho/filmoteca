import SwiftUI

/// Estilos de texto. Todos usam text styles do sistema para respeitar o Dynamic Type.
public enum DSFont {
    public static let display = Font.largeTitle.bold()
    public static let title = Font.title2.bold()
    public static let headline = Font.headline
    public static let body = Font.body
    public static let callout = Font.callout
    public static let caption = Font.caption
}
