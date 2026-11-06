import SwiftUI

/// Campo de texto com rótulo.
public struct DSTextField: View {
    private let label: String
    private let placeholder: String
    @Binding private var text: String

    public init(_ label: String, placeholder: String = "", text: Binding<String>) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            Text(label)
                .font(DSFont.callout)
                .foregroundStyle(DSColor.textSecondary)

            TextField(label, text: $text, prompt: Text(placeholder))
                .labelsHidden()
                .textFieldStyle(.plain)
                .font(DSFont.body)
                .foregroundStyle(DSColor.textPrimary)
                .padding(DSSpacing.sm)
                .background(DSColor.surface, in: RoundedRectangle(cornerRadius: DSRadius.sm))
                .overlay {
                    RoundedRectangle(cornerRadius: DSRadius.sm)
                        .stroke(DSColor.border)
                }
        }
    }
}
