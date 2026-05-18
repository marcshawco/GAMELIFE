//
//  GlassworkComponents.swift
//  GAMELIFE
//
//  Reusable primitives for the Glasswork screens. Direct ports of the
//  React/JSX components in the design package (system.jsx).
//

import SwiftUI

// MARK: - Aurora background block

struct GWAurora: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Soft radial gradients overlaid like CSS radial-gradient stack.
            // Dark: pink/cyan washes pop on velvet. Light: softer pastels.
            Canvas { ctx, size in
                let w = size.width, h = size.height
                let dark = colorScheme == .dark
                let pinkA = dark ? 0.20 : 0.07
                let cyanA = dark ? 0.12 : 0.06
                let pinkB = dark ? 0.11 : 0.05
                func auroraEllipse(_ center: CGPoint, _ rx: CGFloat, _ ry: CGFloat, _ c: Color) {
                    let rect = CGRect(x: center.x - rx, y: center.y - ry, width: rx * 2, height: ry * 2)
                    let g = Gradient(colors: [c, c.opacity(0)])
                    ctx.fill(Path(ellipseIn: rect),
                             with: .radialGradient(g,
                                                   center: center,
                                                   startRadius: 0,
                                                   endRadius: max(rx, ry)))
                }
                auroraEllipse(CGPoint(x: w * 0.20, y: h * 0.00), w * 0.60, h * 0.40, GW.pink.opacity(pinkA))
                auroraEllipse(CGPoint(x: w * 1.00, y: h * 0.30), w * 0.70, h * 0.50, GW.cyan.opacity(cyanA))
                auroraEllipse(CGPoint(x: w * 0.50, y: h * 1.00), w * 0.90, h * 0.60, GW.pink.opacity(pinkB))
            }
            // Dotted noise grid — adapts to mode so it stays visible without
            // burning into the surface.
            Canvas { ctx, size in
                let step: CGFloat = 14
                let dark = colorScheme == .dark
                let dot = dark
                    ? Color.white.opacity(0.05)
                    : Color.black.opacity(0.05)
                let rows = Int(size.height / step) + 1
                let cols = Int(size.width / step) + 1
                for r in 0..<rows {
                    for c in 0..<cols {
                        let p = CGPoint(x: CGFloat(c) * step, y: CGFloat(r) * step)
                        ctx.fill(Path(ellipseIn: CGRect(x: p.x - 0.6, y: p.y - 0.6, width: 1.2, height: 1.2)),
                                 with: .color(dot))
                    }
                }
            }
            .opacity(0.6)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Frosted glass card

struct GWCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    var padding: EdgeInsets = EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
    var corner: CGFloat = 18
    var accent: Color? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        let dark = colorScheme == .dark
        // Glass overlay: faint white in dark mode, faint dark tint in light.
        let topTint    = dark ? Color.white.opacity(0.07) : Color.black.opacity(0.025)
        let bottomTint = dark ? Color.white.opacity(0.02) : Color.black.opacity(0.01)
        // Top-edge highlight (subtle inner glow): white in dark, very faint
        // light tint in light mode.
        let edgeTint   = dark ? Color.white.opacity(0.06) : Color.white.opacity(0.5)
        // Outer shadow: darker on dark velvet, gentler on ivory.
        let shadowTint = dark ? Color.black.opacity(0.35) : Color.black.opacity(0.10)

        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    LinearGradient(colors: [topTint, bottomTint],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .stroke(GW.hairline, lineWidth: 1)
                )
                .overlay(
                    // Top edge highlight
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .stroke(edgeTint, lineWidth: 1)
                        .mask(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .center))
                )
                .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                .shadow(color: shadowTint, radius: dark ? 20 : 12, x: 0, y: dark ? 16 : 8)

            if let accent = accent {
                Rectangle()
                    .fill(LinearGradient(colors: [.clear, accent, .clear],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(height: 1)
                    .padding(.horizontal, 14)
                    .offset(y: -0.5)
            }

            content().padding(padding)
        }
    }
}

extension GWCard {
    init(padding paddingValue: CGFloat,
         corner: CGFloat = 18,
         accent: Color? = nil,
         @ViewBuilder content: @escaping () -> Content) {
        self.init(padding: EdgeInsets(top: paddingValue, leading: paddingValue,
                                      bottom: paddingValue, trailing: paddingValue),
                  corner: corner,
                  accent: accent,
                  content: content)
    }

    init(paddingX: CGFloat,
         paddingY: CGFloat,
         corner: CGFloat = 18,
         accent: Color? = nil,
         @ViewBuilder content: @escaping () -> Content) {
        self.init(padding: EdgeInsets(top: paddingY, leading: paddingX,
                                      bottom: paddingY, trailing: paddingX),
                  corner: corner,
                  accent: accent,
                  content: content)
    }
}

// MARK: - Mono pill / chip

struct GWPill: View {
    let text: String
    var color: Color = GW.mute
    var bg: Color? = nil
    var border: Color? = nil
    var glow: Color? = nil
    var leadingDot: Color? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let d = leadingDot {
                Circle().fill(d).frame(width: 6, height: 6)
            }
            Text(text)
                .font(GW.mono(10, weight: .medium))
                .tracking(1.4)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(
            Capsule()
                .fill(bg ?? Color.white.opacity(0.05))
                .overlay(Capsule().stroke(border ?? GW.hairline, lineWidth: 1))
                .shadow(color: glow ?? .clear, radius: glow == nil ? 0 : 6)
        )
    }
}

// MARK: - Primary gradient button

enum GWButtonVariant { case primary, ghost, danger, gold }

struct GWButton: View {
    let label: String
    var variant: GWButtonVariant = .primary
    var size: GWButtonSize = .md
    var icon: String? = nil
    var action: () -> Void = {}

    enum GWButtonSize { case sm, md }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Text(icon).font(GW.mono(11, weight: .bold))
                }
                Text(label).tracking(0.2)
            }
            .font(GW.sans(size == .sm ? 12 : 14, weight: .semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, size == .sm ? 14 : 18)
            .padding(.vertical, size == .sm ? 8 : 12)
            .frame(maxWidth: .infinity)
            .background(background)
            .clipShape(Capsule())
            .shadow(color: shadowColor, radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var background: some View {
        switch variant {
        case .primary: GW.grad
        case .danger:  GW.gradDanger
        case .gold:    GW.gradGold
        case .ghost:
            ZStack {
                Color.white.opacity(0.06)
                Capsule().stroke(GW.hairline, lineWidth: 1)
            }
        }
    }

    private var foreground: Color {
        switch variant {
        case .primary, .danger: return GW.bg
        case .gold:             return GW.col("3A2A05")
        case .ghost:            return GW.ink
        }
    }

    private var shadowColor: Color {
        switch variant {
        case .primary: return GW.pink.opacity(0.35)
        case .danger:  return GW.danger.opacity(0.35)
        case .gold:    return GW.gold.opacity(0.35)
        case .ghost:   return .clear
        }
    }
}

// MARK: - Bar (XP / HP / progress)

struct GWBar: View {
    let pct: Double
    var height: CGFloat = 5
    var gradient: AnyShapeStyle = AnyShapeStyle(GW.grad)
    var glow: Bool = true

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.06))
                Capsule()
                    .fill(gradient)
                    .frame(width: max(0, min(1, pct)) * geo.size.width)
                    .shadow(color: glow ? GW.pink.opacity(0.55) : .clear,
                            radius: glow ? 6 : 0)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Section label strip

struct GWSectionLabel: View {
    let left: String
    var right: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(left)
                .font(GW.mono(10, weight: .medium))
                .tracking(2)
                .foregroundStyle(GW.mute)
            Spacer()
            if let r = right {
                Text(r)
                    .font(GW.mono(10, weight: .medium))
                    .tracking(1.2)
                    .foregroundStyle(GW.mute)
            }
        }
    }
}

// MARK: - Top chip (avatar + name + handle)

struct GWTopChip<Trailing: View>: View {
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(GW.grad)
                        .frame(width: 36, height: 36)
                        .shadow(color: GW.pink.opacity(0.35), radius: 10)
                    Text(GW_PLAYER.rank)
                        .font(GW.mono(16, weight: .black))
                        .foregroundStyle(GW.bg)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(GW_PLAYER.name.split(separator: " ").first.map(String.init) ?? GW_PLAYER.name)
                        .font(GW.sans(14, weight: .semibold))
                        .tracking(-0.2)
                        .foregroundStyle(GW.ink)
                    Text("\(GW_PLAYER.handle.uppercased()) · LV \(GW_PLAYER.level)")
                        .font(GW.mono(10))
                        .tracking(1)
                        .foregroundStyle(GW.mute)
                }
            }
            Spacer()
            trailing()
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 4)
    }
}

extension GWTopChip where Trailing == EmptyView {
    init() { self.init { EmptyView() } }
}

// MARK: - Tab dock

struct GWTabDock: View {
    enum Tab: String, CaseIterable {
        case status, quests, bosses, train, shop
        var glyph: String {
            switch self {
            case .status: return "◉"
            case .quests: return "◇"
            case .bosses: return "▷"
            case .train:  return "✦"
            case .shop:   return "✕"
            }
        }
        var label: String { rawValue.uppercased() }
    }

    var active: Tab = .status

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                let on = tab == active
                HStack(spacing: 5) {
                    Text(tab.glyph)
                        .font(GW.mono(11, weight: .medium))
                        .foregroundStyle(on ? GW.bg : GW.mute)
                    if on {
                        Text(tab.label)
                            .font(GW.mono(9, weight: .bold))
                            .tracking(1.2)
                            .foregroundStyle(GW.bg)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(on ? AnyShapeStyle(GW.grad) : AnyShapeStyle(Color.clear))
                )
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(GW.bg2.opacity(0.6))
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(GW.hairline, lineWidth: 1))
        )
    }
}

// MARK: - Big numeric

struct GWStatNum: View {
    let value: String
    var label: String? = nil
    var color: Color = GW.ink
    var size: CGFloat = 28
    var alignment: TextAlignment = .leading

    var body: some View {
        VStack(alignment: alignment.horizontal, spacing: 2) {
            if let label = label {
                Text(label)
                    .font(GW.mono(10, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(GW.mute)
            }
            Text(value)
                .font(GW.display(size, weight: .semibold))
                .tracking(-0.5)
                .foregroundStyle(color)
        }
    }
}

private extension TextAlignment {
    var horizontal: HorizontalAlignment {
        switch self {
        case .leading: return .leading
        case .center:  return .center
        case .trailing: return .trailing
        }
    }
}

// MARK: - Screen scaffold

struct GWScreen<Content: View>: View {
    var padBottom: CGFloat = 95
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack(alignment: .top) {
            GW.bg.ignoresSafeArea()
            GWAurora().ignoresSafeArea()
            VStack(spacing: 14) {
                content()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, padBottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .foregroundStyle(GW.ink)
        
    }
}

// MARK: - Filter chip strip

struct GWFilterChip: View {
    let label: String
    let active: Bool

    var body: some View {
        Text(label)
            .font(GW.mono(9, weight: .medium))
            .tracking(1.4)
            .foregroundStyle(active ? GW.cyan : GW.mute)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(active ? GW.cyan.opacity(0.07) : Color.clear)
                    .overlay(
                        Capsule().stroke(active ? GW.cyan.opacity(0.33) : GW.hairline,
                                         lineWidth: 1)
                    )
            )
    }
}
