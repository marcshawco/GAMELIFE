//
//  GWLevelUpScreen.swift
//  GAMELIFE
//
//  09 · LEVEL UP CELEBRATION — heavy aurora + gold light rays + 47→48 +
//  unlocked card (vertically centered) + STATS / CLAIM buttons.
//  Ported from glasswork/screens-meta.jsx (GWLevelUp).
//

import SwiftUI

struct GWLevelUpScreen: View {
    var body: some View {
        ZStack(alignment: .top) {
            GW.bg.ignoresSafeArea()

            // Heavy aurora — gold + cyan + pink
            Canvas { ctx, size in
                let w = size.width, h = size.height
                func make(_ c: CGPoint, _ rx: CGFloat, _ ry: CGFloat, _ color: Color) {
                    let rect = CGRect(x: c.x - rx, y: c.y - ry, width: rx * 2, height: ry * 2)
                    let g = Gradient(colors: [color, color.opacity(0)])
                    ctx.fill(Path(ellipseIn: rect),
                             with: .radialGradient(g, center: c,
                                                   startRadius: 0,
                                                   endRadius: max(rx, ry)))
                }
                make(CGPoint(x: w * 0.5, y: h * 0.3), w * 0.8, h * 0.5, GW.gold.opacity(0.2))
                make(CGPoint(x: w * 0.2, y: h * 0.8), w * 0.7, h * 0.5, GW.pink.opacity(0.27))
                make(CGPoint(x: w * 0.8, y: h * 0.6), w * 0.7, h * 0.5, GW.cyan.opacity(0.2))
            }
            .ignoresSafeArea()

            // Vertical gold rays
            GeometryReader { geo in
                Canvas { ctx, size in
                    let center = size.width / 2
                    let g = Gradient(stops: [
                        .init(color: GW.gold.opacity(0), location: 0),
                        .init(color: GW.gold.opacity(0.11), location: 0.5),
                        .init(color: GW.gold.opacity(0), location: 1)
                    ])
                    for i in 0..<9 {
                        let x = center + CGFloat(i - 4) * 30
                        var p = Path()
                        p.move(to: CGPoint(x: x, y: 0))
                        p.addLine(to: CGPoint(x: x - 30, y: size.height))
                        p.addLine(to: CGPoint(x: x + 30, y: size.height))
                        p.closeSubpath()
                        ctx.fill(p, with: .linearGradient(g,
                                                          startPoint: CGPoint(x: x, y: 0),
                                                          endPoint: CGPoint(x: x, y: size.height)))
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .ignoresSafeArea()

            // Dotted noise
            Canvas { ctx, size in
                let step: CGFloat = 14
                let rows = Int(size.height / step) + 1
                let cols = Int(size.width / step) + 1
                for r in 0..<rows {
                    for c in 0..<cols {
                        let p = CGPoint(x: CGFloat(c) * step, y: CGFloat(r) * step)
                        ctx.fill(Path(ellipseIn: CGRect(x: p.x - 0.6, y: p.y - 0.6,
                                                        width: 1.2, height: 1.2)),
                                 with: .color(Color.white.opacity(0.08)))
                    }
                }
            }
            .opacity(0.55)
            .ignoresSafeArea()

            // Top headline
            VStack(spacing: 10) {
                Text("[ SYSTEM ANNOUNCEMENT ]")
                    .font(GW.mono(10, weight: .medium))
                    .tracking(4)
                    .foregroundStyle(GW.gold)
                Text("LEVEL UP")
                    .font(GW.display(38, weight: .bold))
                    .tracking(-1.5)
                    .foregroundStyle(GW.ink)
                HStack(spacing: 12) {
                    Text("47")
                        .font(GW.display(60, weight: .bold))
                        .tracking(-2)
                        .foregroundStyle(GW.mute)
                    Text("→")
                        .font(GW.display(30))
                        .foregroundStyle(GW.gold)
                    Text("48")
                        .font(GW.display(72, weight: .heavy))
                        .tracking(-3)
                        .foregroundStyle(GW.gradGold)
                        .shadow(color: GW.gold.opacity(0.5), radius: 18)
                }
            }
            .padding(.top, 38)

            // Unlocked card — centered vertically
            unlockedCard
                .padding(.horizontal, 22)
                .frame(maxHeight: .infinity, alignment: .center)
                .offset(y: 40)

            // Buttons
            HStack(spacing: 10) {
                GWButton(label: "STATS", variant: .ghost)
                GWButton(label: "CLAIM & CONTINUE", variant: .gold)
                    .layoutPriority(1.6)
            }
            .padding(.horizontal, 22)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 32)
        }
        .foregroundStyle(GW.ink)
        .preferredColorScheme(.dark)
    }

    private var unlockedCard: some View {
        GWCard(paddingX: 18, paddingY: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("UNLOCKED")
                    .font(GW.mono(9, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(GW.mute)
                VStack(spacing: 12) {
                    unlockRow("Stat pool",     "+5 free points",    GW.cyan)
                    unlockRow("New title",     "\"Diligent Hunter\"", GW.pink)
                    unlockRow("Boss tier",     "Tier II bosses",    GW.gold)
                    unlockRow("Rank progress", "B → A · 3 levels",  GW.amber)
                }
            }
        }
    }

    private func unlockRow(_ label: String, _ value: String, _ tint: Color) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(GW.sans(13))
                .foregroundStyle(GW.inkSoft)
            Spacer()
            Text(value)
                .font(GW.display(14, weight: .semibold))
                .foregroundStyle(tint)
        }
    }
}

#Preview {
    GWLevelUpScreen()
}
