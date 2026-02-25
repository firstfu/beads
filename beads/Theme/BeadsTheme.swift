import SwiftUI

enum BeadsTheme {
    // MARK: - Colors
    enum Colors {
        static let background = Color.fromHex("F5F0E8")
        static let surfacePrimary = Color.fromHex("EDE5D8")
        static let surfaceSecondary = Color.fromHex("E6DDD0")
        static let accent = Color.fromHex("C4A265")
        static let accentSubtle = Color.fromHex("C4A265").opacity(0.15)
        static let textPrimary = Color.fromHex("3C2A1A")
        static let textSecondary = Color.fromHex("7A6B5D")
        static let textTertiary = Color.fromHex("A89B8C")
        static let divider = Color.fromHex("D4C9BA")
        static let success = Color.fromHex("8B9E6B")

        // Category colors
        static let categoryPureLand = Color.fromHex("C4A265")
        static let categoryMantra = Color.fromHex("9B7BB8")
        static let categoryClassic = Color.fromHex("6B8DB5")
        static let categoryVerse = Color.fromHex("8B9E6B")
    }

    // MARK: - Typography
    enum Typography {
        static let titleLarge = Font.system(size: 24, weight: .semibold, design: .rounded)
        static let titleMedium = Font.system(size: 18, weight: .medium)
        static let bodyLarge = Font.system(size: 16)
        static let bodyMedium = Font.system(size: 14)
        static let caption = Font.system(size: 12)
        static let counter = Font.system(size: 48, weight: .thin, design: .rounded)
        static let counterSubtitle = Font.system(size: 14, weight: .light)
    }

    // MARK: - Layout
    enum Layout {
        static let radiusSmall: CGFloat = 8
        static let radiusMedium: CGFloat = 12
        static let radiusLarge: CGFloat = 16
        static let spacingXS: CGFloat = 4
        static let spacingS: CGFloat = 8
        static let spacingM: CGFloat = 16
        static let spacingL: CGFloat = 24
    }
}
