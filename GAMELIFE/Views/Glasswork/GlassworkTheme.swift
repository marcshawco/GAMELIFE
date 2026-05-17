//
//  GlassworkTheme.swift
//  GAMELIFE
//
//  GLASSWORK design system — frosted dark UI with cyan→pink gradient
//  and an aurora background. Lives alongside SystemTheme; gallery only.
//

import SwiftUI

enum GW {
    // Hex helper local to GW so the design system has no cross-file dependency.
    static func col(_ hex: String, _ a: Double = 1) -> Color {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var i: UInt64 = 0
        Scanner(string: h).scanHexInt64(&i)
        return Color(
            red:   Double((i >> 16) & 0xFF) / 255,
            green: Double((i >>  8) & 0xFF) / 255,
            blue:  Double( i        & 0xFF) / 255,
            opacity: a
        )
    }

    // MARK: Surfaces
    static let bg          = col("0B0717")
    static let bg2         = col("150D26")
    static let surface     = Color.white.opacity(0.05)
    static let surface2    = Color.white.opacity(0.08)
    static let hairline    = Color.white.opacity(0.08)
    static let hairlineHi  = Color.white.opacity(0.18)

    // MARK: Ink
    static let ink         = col("F5F1FF")
    static let inkSoft     = col("D7CFEC")
    static let mute        = col("A89DC8")

    // MARK: Accents
    static let cyan        = col("3DE8E0")
    static let pink        = col("FF5BB0")
    static let amber       = col("FFB347")
    static let good        = col("5BE38E")
    static let danger      = col("FF4D6D")
    static let gold        = col("F4C557")

    // MARK: Gradients
    static let grad = LinearGradient(
        colors: [cyan, pink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradGold = LinearGradient(
        colors: [col("FFE08A"), col("F4C557")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradDanger = LinearGradient(
        colors: [col("FF6B8A"), col("B8336A")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func gradBarHP(_ tint: Color) -> LinearGradient {
        LinearGradient(colors: [tint, pink], startPoint: .leading, endPoint: .trailing)
    }

    // MARK: Type — system stand-ins for Inter Tight / Space Grotesk / JetBrains Mono
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - HSL helper for boss sigil hues
extension Color {
    static func hsl(_ hue: Double, _ saturation: Double, _ lightness: Double, opacity: Double = 1) -> Color {
        let s = saturation / 100
        let l = lightness / 100
        let c = (1 - abs(2 * l - 1)) * s
        let hPrime = (hue.truncatingRemainder(dividingBy: 360)) / 60
        let x = c * (1 - abs(hPrime.truncatingRemainder(dividingBy: 2) - 1))
        let (r1, g1, b1): (Double, Double, Double)
        switch hPrime {
        case 0..<1: (r1, g1, b1) = (c, x, 0)
        case 1..<2: (r1, g1, b1) = (x, c, 0)
        case 2..<3: (r1, g1, b1) = (0, c, x)
        case 3..<4: (r1, g1, b1) = (0, x, c)
        case 4..<5: (r1, g1, b1) = (x, 0, c)
        case 5..<6: (r1, g1, b1) = (c, 0, x)
        default:    (r1, g1, b1) = (0, 0, 0)
        }
        let m = l - c / 2
        return Color(red: r1 + m, green: g1 + m, blue: b1 + m, opacity: opacity)
    }
}
