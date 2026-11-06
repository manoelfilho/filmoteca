import SwiftUI

/// Superfície elevada para agrupar conteúdo.
public struct DSCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DSSpacing.md)
            .background(DSColor.surface, in: RoundedRectangle(cornerRadius: DSRadius.lg))
            .dsShadow(.sm)
    }
}
