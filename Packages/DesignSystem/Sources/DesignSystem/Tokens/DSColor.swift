import SwiftUI

/// Cores semânticas, com variantes para os modos claro e escuro.
public enum DSColor {
    struct Pair {
        let light: UInt32
        let dark: UInt32

        init(light: UInt32, dark: UInt32) {
            self.light = light
            self.dark = dark
        }

        init(_ both: UInt32) {
            self.init(light: both, dark: both)
        }

        var color: Color { Color(light: light, dark: dark) }
    }

    enum Pairs {
        // Neutros: a paleta da marca não define fundo, superfície e texto.
        static let ink: UInt32 = 0x1A1F33
        static let paper: UInt32 = 0xF7F8FB

        static let primary = Pair(light: DSPalette.Hex.frenchBlue, dark: DSPalette.Hex.smartBlue)
        static let onPrimary = Pair(0xFFFFFF)
        static let secondary = Pair(light: DSPalette.Hex.smartBlue, dark: DSPalette.Hex.frenchBlue)
        static let accent = Pair(DSPalette.Hex.tangerineDream)
        static let highlight = Pair(DSPalette.Hex.lightGold)
        static let destructive = Pair(DSPalette.Hex.vibrantCoral)
        // Branco sobre coral e tangerina não atinge o contraste AA.
        static let onAccent = Pair(ink)
        static let onHighlight = Pair(ink)
        static let onDestructive = Pair(ink)
        static let background = Pair(light: paper, dark: 0x121624)
        static let surface = Pair(light: 0xFFFFFF, dark: 0x1C2233)
        static let textPrimary = Pair(light: ink, dark: paper)
        static let textSecondary = Pair(light: 0x5A6175, dark: 0xA9B0C2)
        static let border = Pair(light: 0xDDE1EA, dark: 0x2E3548)

        // Mídia: texto e véu sobre imagens (pôsteres, capas). Iguais nos dois modos,
        // porque o fundo é a própria imagem.
        static let onMedia = Pair(0xFFFFFF)
        static let scrim = Pair(0x000000)
    }

    public static let primary = Pairs.primary.color
    public static let onPrimary = Pairs.onPrimary.color
    public static let secondary = Pairs.secondary.color
    public static let accent = Pairs.accent.color
    public static let onAccent = Pairs.onAccent.color
    public static let highlight = Pairs.highlight.color
    public static let onHighlight = Pairs.onHighlight.color
    public static let destructive = Pairs.destructive.color
    public static let onDestructive = Pairs.onDestructive.color
    public static let background = Pairs.background.color
    public static let surface = Pairs.surface.color
    public static let textPrimary = Pairs.textPrimary.color
    public static let textSecondary = Pairs.textSecondary.color
    public static let border = Pairs.border.color
    /// Texto e ícones sobre imagens, sempre com `scrim` por trás.
    public static let onMedia = Pairs.onMedia.color
    /// Véu escuro para dar contraste a texto sobre imagens. Use com opacidade/gradiente.
    public static let scrim = Pairs.scrim.color
}
