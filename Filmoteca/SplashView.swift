import DesignSystem
import SwiftUI

/// Splash animada exibida logo após a launch screen nativa.
/// Ao terminar, chama `onFinish` para o app trocar para a TMDBView.
struct SplashView: View {
    var onFinish: () -> Void

    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0.0

    var body: some View {
        ZStack {
            // Mesma cor da launch screen nativa, para a transição ser invisível
            Color("LaunchBackground")
                .ignoresSafeArea()

            VStack(spacing: DSSpacing.md) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .foregroundStyle(DSColor.onPrimary)

                Text("SuperApp")
                    .font(DSFont.display)
                    .foregroundStyle(DSColor.onPrimary)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .task {
            withAnimation(DSMotion.spring) {
                scale = 1.0
                opacity = 1.0
            }
            // Aqui você pode carregar dados iniciais (sessão, configs etc.)
            try? await Task.sleep(for: .seconds(1.5))
            onFinish()
        }
    }
}

#Preview {
    SplashView(onFinish: {})
}
