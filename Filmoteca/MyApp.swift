import DesignSystem
import FactoryKit
import SwiftUI

@main
struct MyApp: App {
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                Container.shared.tmdbView()
                if showSplash {
                    SplashView {
                        withAnimation(DSMotion.standard) {
                            showSplash = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
        }
    }
}
