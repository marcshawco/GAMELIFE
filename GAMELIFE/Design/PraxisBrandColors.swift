// PRAXIS · Brand color tokens (SwiftUI)
import SwiftUI

extension Color {
    /// Primary surface — 70% of any screen
    static let pxVelvet = Color(red: 0.043, green: 0.027, blue: 0.090)
    /// Cards, raised UI — 15%
    static let pxSurface = Color(red: 0.082, green: 0.051, blue: 0.149)
    /// Headlines, stat values
    static let pxInk = Color(red: 0.961, green: 0.945, blue: 1.000)
    /// Body copy on dark
    static let pxInkSoft = Color(red: 0.843, green: 0.812, blue: 0.925)
    /// Labels, mono, secondary
    static let pxMute = Color(red: 0.659, green: 0.616, blue: 0.784)
    /// System voice, gradient L
    static let pxCyan = Color(red: 0.239, green: 0.910, blue: 0.878)
    /// Energy, gradient R
    static let pxPink = Color(red: 1.000, green: 0.357, blue: 0.690)
    /// Loot, value, ceremony
    static let pxGold = Color(red: 0.957, green: 0.773, blue: 0.341)
    /// XP gain, warning soft
    static let pxAmber = Color(red: 1.000, green: 0.702, blue: 0.278)
    /// Streaks, positive only
    static let pxGood = Color(red: 0.357, green: 0.890, blue: 0.557)
    /// HP loss, destructive
    static let pxDanger = Color(red: 1.000, green: 0.302, blue: 0.427)
}

extension LinearGradient {
    static let pxSystem = LinearGradient(
        colors: [.pxCyan, .pxPink],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}
