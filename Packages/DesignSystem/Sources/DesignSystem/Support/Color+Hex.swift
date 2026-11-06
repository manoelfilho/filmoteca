import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Color {
    /// Cria uma cor sRGB a partir de um valor como `0x324376`.
    init(hex: UInt32) {
        let (red, green, blue) = hex.rgbComponents
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }

    /// Cria uma cor que acompanha o modo claro ou escuro do sistema.
    init(light: UInt32, dark: UInt32) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor { traits in
            let (red, green, blue) = (traits.userInterfaceStyle == .dark ? dark : light).rgbComponents
            return UIColor(red: red, green: green, blue: blue, alpha: 1)
        })
        #elseif canImport(AppKit)
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let (red, green, blue) = (isDark ? dark : light).rgbComponents
            return NSColor(srgbRed: red, green: green, blue: blue, alpha: 1)
        })
        #endif
    }
}

extension UInt32 {
    var rgbComponents: (red: CGFloat, green: CGFloat, blue: CGFloat) {
        (
            CGFloat((self >> 16) & 0xFF) / 255,
            CGFloat((self >> 8) & 0xFF) / 255,
            CGFloat(self & 0xFF) / 255
        )
    }
}
