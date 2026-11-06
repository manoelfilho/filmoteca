import SwiftUI

/// Animações padrão.
public enum DSMotion {
    public static let standard = Animation.easeOut(duration: 0.4)
    public static let spring = Animation.spring(response: 0.6, dampingFraction: 0.7)
}
