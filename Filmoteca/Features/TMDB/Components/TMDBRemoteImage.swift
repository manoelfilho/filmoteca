import DesignSystem
import MovieDomain
import SwiftUI

/// Imagem remota que preenche o espaço dado pelo pai, com placeholder e fade-in.
struct TMDBRemoteImage: View {
    let image: RemoteImage?
    var size: RemoteImage.Size = .medium
    var placeholderSymbol = "film"

    var body: some View {
        Rectangle()
            .fill(DSColor.surface)
            .overlay {
                if let url = image?.url(for: size) {
                    AsyncImage(url: url, transaction: Transaction(animation: DSMotion.standard)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .transition(.opacity)
                        case .failure:
                            placeholder
                        default:
                            Color.clear
                        }
                    }
                } else {
                    placeholder
                }
            }
            .clipped()
            .accessibilityHidden(true)
    }

    private var placeholder: some View {
        Image(systemName: placeholderSymbol)
            .font(DSFont.title)
            .foregroundStyle(DSColor.textSecondary.opacity(0.5))
    }
}
