//
//  BrandGuidelinesView.swift
//  GAMELIFE
//
//  In-app rendering of PRAXIS Brand Guidelines v1.0 (direction 02 Glasswork).
//  Built from the design's brand-guidelines.jsx — cover, palette with usage
//  proportions, type stack, voice samples, Prism colorways, and application
//  rules. Reachable from Settings → Design Preview → PRAXIS Brand Guidelines.
//

import SwiftUI

struct BrandGuidelinesView: View {
    var body: some View {
        ZStack {
            GW.bg.ignoresSafeArea()
            GWAurora().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    cover
                    paletteSection
                    typeSection
                    voiceSection
                    prismSection
                    rulesSection
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 36)
            }
        }
        .foregroundStyle(GW.ink)
        
        .navigationTitle("Brand Guidelines")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Cover

    private var cover: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BRAND GUIDELINES · v1.0 · 16 MAY 2026")
                .font(GW.mono(10, weight: .medium))
                .tracking(3)
                .foregroundStyle(GW.mute)
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("PRA")
                    .font(GW.display(44, weight: .bold))
                    .tracking(-1.5)
                Text("X")
                    .font(GW.display(44, weight: .bold))
                    .tracking(-1.5)
                    .foregroundStyle(GW.grad)
                Text("IS")
                    .font(GW.display(44, weight: .bold))
                    .tracking(-1.5)
            }
            .foregroundStyle(GW.ink)
            Text("The system sees you.")
                .font(GW.display(20, weight: .medium))
                .tracking(-0.3)
                .foregroundStyle(GW.inkSoft)
            Text("Direction 02 Glasswork. Frosted dark UI with a cyan→pink system gradient. The Prism is the mark; the System is the voice.")
                .font(GW.sans(13))
                .foregroundStyle(GW.mute)
                .padding(.top, 6)
                .lineSpacing(3)
            motifBar
                .padding(.top, 10)
        }
    }

    private var motifBar: some View {
        HStack(spacing: 0) {
            Rectangle().fill(GW.cyan).frame(width: 60, height: 4)
            Rectangle().fill(GW.grad).frame(width: 80, height: 4)
            Rectangle().fill(GW.pink).frame(width: 60, height: 4)
            Rectangle().fill(GW.gold).frame(width: 24, height: 4)
            Rectangle().fill(Color.white.opacity(0.1)).frame(height: 4)
        }
        .clipShape(Capsule())
    }

    // MARK: Palette

    private struct PaletteToken {
        let label: String
        let hex: String
        let color: Color
        let ink: Color
        let usage: String
        let proportion: String
    }

    private var paletteTokens: [PaletteToken] {
        [
            PaletteToken(label: "VELVET",   hex: "#0B0717", color: GW.bg,        ink: .white,   usage: "Primary surface",       proportion: "70%"),
            PaletteToken(label: "SURFACE",  hex: "#150D26", color: GW.bg2,       ink: .white,   usage: "Cards, raised UI",      proportion: "15%"),
            PaletteToken(label: "INK",      hex: "#F5F1FF", color: GW.ink,       ink: GW.bg,    usage: "Headlines, stat values", proportion: "—"),
            PaletteToken(label: "MUTE",     hex: "#A89DC8", color: GW.mute,      ink: GW.bg,    usage: "Labels, secondary",      proportion: "—"),
            PaletteToken(label: "CYAN",     hex: "#3DE8E0", color: GW.cyan,      ink: GW.bg,    usage: "System voice · grad L",  proportion: "accent"),
            PaletteToken(label: "PINK",     hex: "#FF5BB0", color: GW.pink,      ink: GW.bg,    usage: "Energy · grad R",        proportion: "accent"),
            PaletteToken(label: "GOLD",     hex: "#F4C557", color: GW.gold,      ink: GW.bg,    usage: "Loot, value, ceremony",  proportion: "rare"),
            PaletteToken(label: "AMBER",    hex: "#FFB347", color: GW.amber,     ink: GW.bg,    usage: "XP gain · soft warning", proportion: "rare"),
            PaletteToken(label: "GOOD",     hex: "#5BE38E", color: GW.good,      ink: GW.bg,    usage: "Streaks, positive only", proportion: "status"),
            PaletteToken(label: "DANGER",   hex: "#FF4D6D", color: GW.danger,    ink: GW.ink,   usage: "HP loss, destructive",   proportion: "status"),
        ]
    }

    private var paletteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("01 · PALETTE", "Aurora on velvet")
            Text("Velvet indigo is 70% of any surface. Cyan→pink is the system gradient and only one element per screen should wear it. Gold and danger only when status demands.")
                .font(GW.sans(13))
                .foregroundStyle(GW.mute)
                .lineSpacing(3)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8)],
                      spacing: 8) {
                ForEach(paletteTokens, id: \.label) { swatch($0) }
            }

            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(GW.grad)
                Text("SYSTEM GRADIENT · CYAN → PINK")
                    .font(GW.mono(11, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(GW.bg)
            }
            .frame(height: 36)
            .padding(.top, 4)
        }
    }

    private func swatch(_ s: PaletteToken) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(s.color)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(GW.hairline, lineWidth: 1))
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(s.label)
                        .font(GW.mono(10, weight: .bold))
                        .tracking(1.4)
                    Spacer()
                    Text(s.proportion)
                        .font(GW.mono(9))
                        .opacity(0.7)
                }
                Spacer()
                Text(s.hex)
                    .font(GW.mono(9))
                    .opacity(0.85)
                Text(s.usage)
                    .font(GW.mono(8))
                    .opacity(0.7)
            }
            .foregroundStyle(s.ink)
            .padding(10)
        }
        .aspectRatio(1.4, contentMode: .fit)
    }

    // MARK: Type

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionHeader("02 · TYPE", "Three voices")
            typeRow(label: "DISPLAY · SPACE GROTESK",
                    body: AnyView(
                        Text("Level Up")
                            .font(GW.display(44, weight: .semibold))
                            .tracking(-1)
                            .foregroundStyle(GW.ink)
                    ),
                    footer: "600 weight · negative tracking · headlines & numerals")
            typeRow(label: "BODY · INTER TIGHT",
                    body: AnyView(
                        Text("The System recognizes you, Hunter. Each cleared quest deals damage to one of your boss fights.")
                            .font(GW.sans(14))
                            .foregroundStyle(GW.inkSoft)
                    ),
                    footer: nil)
            typeRow(label: "SYSTEM LABEL · JETBRAINS MONO",
                    body: AnyView(
                        Text("[ SYSTEM · STR +12 · LV 47 → 48 ]")
                            .font(GW.mono(11))
                            .tracking(2)
                            .foregroundStyle(GW.cyan)
                    ),
                    footer: "UPPERCASE · tracking +200")
        }
    }

    private func typeRow(label: String, body: AnyView, footer: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(GW.mono(9, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(GW.mute)
            body
            if let f = footer {
                Text(f).font(GW.mono(9)).foregroundStyle(GW.mute)
            }
        }
    }

    // MARK: Voice

    private var voiceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("03 · VOICE", "The System is the narrator")
            Text("Not a friend, not a coach. It notices, records, announces. Brackets wrap runtime messages. Numbers wear display face; units wear mono. Past tense for cleared events, future for prompts. The user is *Hunter* or referred to by handle.")
                .font(GW.sans(13))
                .foregroundStyle(GW.mute)
                .lineSpacing(3)
            VStack(spacing: 8) {
                voiceLine("[ SYSTEM · Quest cleared. STR +12. LV 47 → 48. ]")
                voiceLine("[ SYSTEM · A boss approaches. Will you face Ironwork? ]")
                voiceLine("[ SYSTEM · Streak extended. 24 days. ]", tint: GW.good)
                voiceLine("[ SYSTEM · −4 HP. The Late Wolf stirs. ]", tint: GW.danger)
            }
        }
    }

    private func voiceLine(_ text: String, tint: Color = GW.cyan) -> some View {
        Text(text)
            .font(GW.mono(11))
            .tracking(1.4)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(GW.hairline, lineWidth: 1))
            )
    }

    // MARK: Prism — three colorways

    private struct Colorway {
        let id: String
        let name: String
        let badge: String
        let a: Color
        let b: Color
        let aHex: String
        let bHex: String
        let desc: String
    }

    private var colorways: [Colorway] {
        [
            Colorway(id: "signal",  name: "Signal",  badge: "PRIMARY", a: GW.cyan,                b: GW.pink,                aHex: "#3DE8E0", bHex: "#FF5BB0", desc: "Original. Cyan refracts into pink. The signature direction."),
            Colorway(id: "solar",   name: "Solar",   badge: "WARM",    a: GW.col("F4C557"),       b: GW.col("FF6B8A"),       aHex: "#F4C557", bHex: "#FF6B8A", desc: "Gold split into crimson. Reads premium, optimistic."),
            Colorway(id: "verdant", name: "Verdant", badge: "COOL",    a: GW.col("5BE3A0"),       b: GW.col("7AB8FF"),       aHex: "#5BE3A0", bHex: "#7AB8FF", desc: "Mint into periwinkle. Reads as growth, calm."),
        ]
    }

    private var prismSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("04 · THE PRISM", "Three colorways · same geometry")
            Text("The Prism is the chosen mark. Wordless. A four-facet diamond that refracts the system gradient. Signal ships as the default app icon. Solar and Verdant are alternates, switchable in Settings → App Icon.")
                .font(GW.sans(13))
                .foregroundStyle(GW.mute)
                .lineSpacing(3)
            VStack(spacing: 12) {
                ForEach(colorways, id: \.id) { cw in
                    HStack(spacing: 14) {
                        PrismIconView(a: cw.a, b: cw.b, variant: .light)
                            .frame(width: 86, height: 86)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(cw.badge)
                                    .font(GW.mono(9, weight: .bold))
                                    .tracking(1.4)
                                    .foregroundStyle(cw.a)
                                    .padding(.horizontal, 7).padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(cw.a.opacity(0.07))
                                            .overlay(Capsule().stroke(cw.a.opacity(0.33), lineWidth: 1))
                                    )
                                Text(cw.name)
                                    .font(GW.display(18, weight: .semibold))
                                    .tracking(-0.3)
                                    .foregroundStyle(GW.ink)
                            }
                            Text(cw.desc)
                                .font(GW.sans(12))
                                .foregroundStyle(GW.mute)
                                .lineSpacing(2)
                            HStack(spacing: 6) {
                                colorChip(cw.a, label: cw.aHex)
                                colorChip(cw.b, label: cw.bHex)
                            }
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(GW.hairline, lineWidth: 1))
                    )
                }
            }
        }
    }

    private func colorChip(_ c: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(c).frame(width: 8, height: 8)
                .shadow(color: c.opacity(0.5), radius: 3)
            Text(label).font(GW.mono(9)).foregroundStyle(GW.mute)
        }
        .padding(.horizontal, 7).padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.02))
                .overlay(Capsule().stroke(GW.hairline, lineWidth: 1))
        )
    }

    // MARK: Rules — do / don't

    private struct Rule {
        let kind: Kind
        let text: String
        enum Kind { case do_, dont }
    }

    private var rules: [Rule] {
        [
            Rule(kind: .do_,  text: "Velvet indigo at 70% of any surface. Anchor everything in dark."),
            Rule(kind: .do_,  text: "One gradient element per screen. The cyan→pink reads as System energy."),
            Rule(kind: .do_,  text: "Numbers in display face. Units in mono. UPPERCASE for System messages."),
            Rule(kind: .dont, text: "Never re-tint the Prism facets. Use the official colorway sets."),
            Rule(kind: .dont, text: "Don't stack the gradient on two competing elements in the same frame."),
            Rule(kind: .dont, text: "No serifs anywhere. The system speaks in geometric sans."),
        ]
    }

    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("05 · APPLICATION", "Do · Don't")
            VStack(spacing: 8) {
                ForEach(Array(rules.enumerated()), id: \.offset) { _, rule in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(rule.kind == .do_ ? "✓ DO" : "✕ DON'T")
                            .font(GW.mono(9, weight: .bold))
                            .tracking(1.4)
                            .foregroundStyle(rule.kind == .do_ ? GW.good : GW.danger)
                            .frame(width: 56, alignment: .leading)
                        Text(rule.text)
                            .font(GW.sans(13))
                            .foregroundStyle(GW.inkSoft)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke((rule.kind == .do_ ? GW.good : GW.danger).opacity(0.2),
                                        lineWidth: 1))
                    )
                }
            }
        }
    }

    // MARK: helpers

    private func sectionHeader(_ tag: String, _ title: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(tag)
                .font(GW.mono(10, weight: .bold))
                .tracking(2)
                .foregroundStyle(GW.cyan)
            Text(title)
                .font(GW.display(22, weight: .semibold))
                .tracking(-0.4)
                .foregroundStyle(GW.ink)
        }
    }
}

// MARK: - Prism icon (vector, matches prism-variants.jsx IconPrismV3)

struct PrismIconView: View {
    enum Variant { case light, dark, tint }

    let a: Color
    let b: Color
    var variant: Variant = .light
    var tint: Color = .white

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                Rectangle().fill(bg)
                if variant != .tint {
                    Rectangle().fill(
                        RadialGradient(colors: [b.opacity(0.32), .clear],
                                       center: .center,
                                       startRadius: 0,
                                       endRadius: s * 0.5)
                    )
                }
                facets(size: s)
                seams(size: s)
                cornerSpark(size: s)
                if variant != .tint {
                    Rectangle().fill(
                        RadialGradient(colors: [Color.white.opacity(0.5), .clear],
                                       center: UnitPoint(x: 0.5, y: 0.4),
                                       startRadius: 0,
                                       endRadius: s * 0.4)
                    )
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var bg: Color {
        switch variant {
        case .light: return GW.col("15102A")
        case .dark:  return GW.col("070411")
        case .tint:  return GW.col("0A0612")
        }
    }

    private var gradA: LinearGradient {
        let stopA = variant == .tint ? tint : a
        let stopB = variant == .tint ? tint : b
        return LinearGradient(stops: [
            .init(color: stopA, location: 0),
            .init(color: stopB.opacity(variant == .tint ? 0.55 : 1), location: 1)
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var gradB: LinearGradient {
        let stopA = variant == .tint ? tint.opacity(0.45) : b
        let stopB = variant == .tint ? tint.opacity(0.20) : a.opacity(0.7)
        return LinearGradient(stops: [
            .init(color: stopA, location: 0),
            .init(color: stopB, location: 1)
        ], startPoint: .topTrailing, endPoint: .bottomLeading)
    }

    private func facets(size s: CGFloat) -> some View {
        let c = CGPoint(x: s / 2, y: s / 2)
        let h = s * (58.0 / 180.0)  // vertical half-axis
        let w = s * (50.0 / 180.0)  // horizontal half-axis

        return ZStack {
            // outline
            DiamondPath(center: c, w: w, h: h)
                .fill(Color.white.opacity(0.04))
            DiamondPath(center: c, w: w, h: h)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)

            // facet TL
            FacetTriangle(c: c, p1: CGPoint(x: 0, y: -h), p2: .zero, p3: CGPoint(x: -w, y: 0))
                .fill(gradB)
                .opacity(variant == .tint ? 0.7 : 0.65)
            // facet TR — brightest
            FacetTriangle(c: c, p1: CGPoint(x: 0, y: -h), p2: CGPoint(x: w, y: 0), p3: .zero)
                .fill(gradA)
                .opacity(variant == .tint ? 1 : 0.95)
            // facet BL
            FacetTriangle(c: c, p1: CGPoint(x: -w, y: 0), p2: .zero, p3: CGPoint(x: 0, y: h))
                .fill(gradA)
                .opacity(variant == .tint ? 0.85 : 0.85)
            // facet BR
            FacetTriangle(c: c, p1: CGPoint(x: w, y: 0), p2: CGPoint(x: 0, y: h), p3: .zero)
                .fill(gradB)
                .opacity(variant == .tint ? 0.55 : 0.55)
        }
    }

    private func seams(size s: CGFloat) -> some View {
        let c = CGPoint(x: s / 2, y: s / 2)
        let h = s * (58.0 / 180.0)
        let w = s * (50.0 / 180.0)
        return ZStack {
            Path { p in
                p.move(to: CGPoint(x: c.x, y: c.y - h))
                p.addLine(to: CGPoint(x: c.x, y: c.y + h))
            }
            .stroke(Color.white.opacity(0.22), lineWidth: 0.6)
            Path { p in
                p.move(to: CGPoint(x: c.x - w, y: c.y))
                p.addLine(to: CGPoint(x: c.x + w, y: c.y))
            }
            .stroke(Color.white.opacity(0.22), lineWidth: 0.6)
        }
    }

    private func cornerSpark(size s: CGFloat) -> some View {
        Circle()
            .fill(Color.white.opacity(0.95))
            .frame(width: 2, height: 2)
            .position(x: s / 2, y: s / 2 - s * (58.0 / 180.0))
    }
}

private struct DiamondPath: Shape {
    let center: CGPoint
    let w: CGFloat
    let h: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to:    CGPoint(x: center.x,     y: center.y - h))
        p.addLine(to: CGPoint(x: center.x + w, y: center.y))
        p.addLine(to: CGPoint(x: center.x,     y: center.y + h))
        p.addLine(to: CGPoint(x: center.x - w, y: center.y))
        p.closeSubpath()
        return p
    }
}

private struct FacetTriangle: Shape {
    let c: CGPoint
    let p1: CGPoint
    let p2: CGPoint
    let p3: CGPoint
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to:    CGPoint(x: c.x + p1.x, y: c.y + p1.y))
        p.addLine(to: CGPoint(x: c.x + p2.x, y: c.y + p2.y))
        p.addLine(to: CGPoint(x: c.x + p3.x, y: c.y + p3.y))
        p.closeSubpath()
        return p
    }
}

#Preview {
    NavigationStack {
        BrandGuidelinesView()
    }
}
