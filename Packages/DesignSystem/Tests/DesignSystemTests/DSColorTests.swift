import Foundation
import SwiftUI
import Testing
@testable import DesignSystem

/// Contraste WCAG entre duas cores sRGB.
private func contrast(_ first: UInt32, _ second: UInt32) -> Double {
    func luminance(_ hex: UInt32) -> Double {
        func linear(_ channel: CGFloat) -> Double {
            let value = Double(channel)
            return value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        let (red, green, blue) = hex.rgbComponents
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }
    let (a, b) = (luminance(first), luminance(second))
    return (max(a, b) + 0.05) / (min(a, b) + 0.05)
}

@Suite struct DSColorTests {
    @Test func paletteMatchesBrandValues() {
        #expect(DSPalette.Hex.smartBlue == 0x586BA4)
        #expect(DSPalette.Hex.frenchBlue == 0x324376)
        #expect(DSPalette.Hex.lightGold == 0xF5DD90)
        #expect(DSPalette.Hex.tangerineDream == 0xF68E5F)
        #expect(DSPalette.Hex.vibrantCoral == 0xF76C5E)
    }

    // Resolver uma cor dinâmica do AppKit fora da thread principal trava o teste.
    @MainActor @Test func semanticColorsFollowColorScheme() {
        func expectResolved(_ color: Color, _ hex: UInt32, _ scheme: ColorScheme) {
            var environment = EnvironmentValues()
            environment.colorScheme = scheme
            let resolved = color.resolve(in: environment)
            let expected = Color(hex: hex).resolve(in: environment)
            #expect(abs(resolved.red - expected.red) < 0.001, "\(scheme)")
            #expect(abs(resolved.green - expected.green) < 0.001, "\(scheme)")
            #expect(abs(resolved.blue - expected.blue) < 0.001, "\(scheme)")
        }

        expectResolved(DSColor.primary, DSPalette.Hex.frenchBlue, .light)
        expectResolved(DSColor.primary, DSPalette.Hex.smartBlue, .dark)
        expectResolved(DSColor.background, 0xF7F8FB, .light)
        expectResolved(DSColor.background, 0x121624, .dark)
    }

    @Test(arguments: [
        ("onPrimary/primary", DSColor.Pairs.onPrimary, DSColor.Pairs.primary),
        ("onPrimary/secondary", DSColor.Pairs.onPrimary, DSColor.Pairs.secondary),
        ("onAccent/accent", DSColor.Pairs.onAccent, DSColor.Pairs.accent),
        ("onHighlight/highlight", DSColor.Pairs.onHighlight, DSColor.Pairs.highlight),
        ("onDestructive/destructive", DSColor.Pairs.onDestructive, DSColor.Pairs.destructive),
        ("textPrimary/background", DSColor.Pairs.textPrimary, DSColor.Pairs.background),
        ("textPrimary/surface", DSColor.Pairs.textPrimary, DSColor.Pairs.surface),
        ("textSecondary/background", DSColor.Pairs.textSecondary, DSColor.Pairs.background),
        ("textSecondary/surface", DSColor.Pairs.textSecondary, DSColor.Pairs.surface),
    ])
    func textPairsMeetAA(name: String, foreground: DSColor.Pair, background: DSColor.Pair) {
        #expect(contrast(foreground.light, background.light) >= 4.5, "\(name) light")
        #expect(contrast(foreground.dark, background.dark) >= 4.5, "\(name) dark")
    }
}
