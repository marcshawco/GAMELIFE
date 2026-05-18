//
//  GlassworkTheme.swift
//  GAMELIFE
//
//  GLASSWORK design system — adaptive light + dark variants of the
//  "aurora on velvet" direction. Surfaces, ink, and hairlines resolve
//  through UIColor's trait closure so a single token works in both modes
//  and individual screens don't need to force a colorScheme.
//

import SwiftUI
import UIKit

enum GW {
    // MARK: Hex / adaptive helpers

    /// Static hex → Color (no trait awareness). Used for accents that read
    /// the same in both modes (cyan, pink, gold, danger, etc.).
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

    /// Adaptive hex token — resolves to `light` or `dark` based on the
    /// trait collection at render time.
    static func adaptive(light: String, dark: String, opacity: Double = 1) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(hexString: hex).withAlphaComponent(opacity)
        })
    }

    /// Adaptive monochrome (uses white channel in dark, black channel in
    /// light) — useful for hairlines and surface tints.
    static func adaptiveMono(lightOpacity: Double, darkOpacity: Double) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 1, alpha: darkOpacity)
                : UIColor(white: 0, alpha: lightOpacity)
        })
    }

    // MARK: Surfaces (adaptive)

    /// Primary surface — velvet indigo (dark) or warm ivory (light).
    static let bg          = adaptive(light: "FAF6FF", dark: "0B0717")
    /// Raised surface — one step lighter/darker than `bg`.
    static let bg2         = adaptive(light: "F1EAFA", dark: "150D26")
    /// Subtle tint applied over glass / surfaces.
    static let surface     = adaptiveMono(lightOpacity: 0.04, darkOpacity: 0.05)
    static let surface2    = adaptiveMono(lightOpacity: 0.06, darkOpacity: 0.08)
    /// Hairline borders — readable on both palettes.
    static let hairline    = adaptiveMono(lightOpacity: 0.10, darkOpacity: 0.08)
    static let hairlineHi  = adaptiveMono(lightOpacity: 0.18, darkOpacity: 0.18)

    // MARK: Ink (adaptive)

    /// Headlines, stat values — inverts cleanly between modes.
    static let ink         = adaptive(light: "1A1233", dark: "F5F1FF")
    static let inkSoft     = adaptive(light: "3D2F5A", dark: "D7CFEC")
    static let mute        = adaptive(light: "7A6890", dark: "A89DC8")

    // MARK: Accents — same in both modes by design

    static let cyan        = col("3DE8E0")
    static let pink        = col("FF5BB0")
    static let amber       = col("FFB347")
    static let good        = col("5BE38E")
    static let danger      = col("FF4D6D")
    static let gold        = col("F4C557")

    // MARK: Gradients — fixed (Signal gradient is brand)

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

    // MARK: Aurora intensities — pulled in by GWAurora so the wash reads
    // differently per mode (heavier on dark velvet, softer on ivory).

    static let auroraPink: Color  = adaptive(light: "FF5BB0", dark: "FF5BB0", opacity: 1)
    static let auroraCyan: Color  = adaptive(light: "3DE8E0", dark: "3DE8E0", opacity: 1)
    /// Opacity used by GWAurora's radial washes per mode.
    static func auroraOpacity(_ darkValue: Double) -> Color {
        adaptive(light: "FF5BB0", dark: "FF5BB0").opacity(darkValue * 0.55)
    }

    /// True when the trait collection at render time is dark.
    /// Useful inside Canvas closures where the trait closure of UIColor
    /// doesn't help (Canvas paints with concrete colors).
    @MainActor
    static var isDark: Bool {
        UITraitCollection.current.userInterfaceStyle == .dark
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

// MARK: - UIColor hex helper (private to this file)

private extension UIColor {
    convenience init(hexString hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var i: UInt64 = 0
        Scanner(string: s).scanHexInt64(&i)
        self.init(
            red:   CGFloat((i >> 16) & 0xFF) / 255,
            green: CGFloat((i >>  8) & 0xFF) / 255,
            blue:  CGFloat( i        & 0xFF) / 255,
            alpha: 1
        )
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
