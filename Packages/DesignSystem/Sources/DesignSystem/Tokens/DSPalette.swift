import SwiftUI

/// Cores da marca. Nas views, prefira as cores semânticas de `DSColor`.
public enum DSPalette {
    enum Hex {
        static let smartBlue: UInt32 = 0x586BA4
        static let frenchBlue: UInt32 = 0x324376
        static let lightGold: UInt32 = 0xF5DD90
        static let tangerineDream: UInt32 = 0xF68E5F
        static let vibrantCoral: UInt32 = 0xF76C5E
    }

    public static let smartBlue = Color(hex: Hex.smartBlue)
    public static let frenchBlue = Color(hex: Hex.frenchBlue)
    public static let lightGold = Color(hex: Hex.lightGold)
    public static let tangerineDream = Color(hex: Hex.tangerineDream)
    public static let vibrantCoral = Color(hex: Hex.vibrantCoral)
}
