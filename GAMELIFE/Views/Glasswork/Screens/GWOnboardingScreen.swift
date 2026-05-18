//
//  GWOnboardingScreen.swift
//  GAMELIFE
//
//  10 · ONBOARDING (rank assessment) — step indicator, copy, hexagonal rank
//  reveal with "B", starting attributes grid, BACK / ACCEPT buttons.
//  Ported from glasswork/screens-meta.jsx (GWOnboarding).
//

import SwiftUI

struct GWOnboardingScreen: View {
    var body: some View {
        ZStack(alignment: .top) {
            GW.bg.ignoresSafeArea()

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
                make(CGPoint(x: w * 0.5, y: h * 0.2), w * 0.7, h * 0.5, GW.cyan.opacity(0.2))
                make(CGPoint(x: w * 0.5, y: h * 0.9), w * 0.7, h * 0.5, GW.pink.opacity(0.2))
            }
            .ignoresSafeArea()

            Canvas { ctx, size in
                let step: CGFloat = 14
                let rows = Int(size.height / step) + 1
                let cols = Int(size.width / step) + 1
                for r in 0..<rows {
                    for c in 0..<cols {
                        let p = CGPoint(x: CGFloat(c) * step, y: CGFloat(r) * step)
                        ctx.fill(Path(ellipseIn: CGRect(x: p.x - 0.5, y: p.y - 0.5,
                                                        width: 1, height: 1)),
                                 with: .color(Color.white.opacity(0.05)))
                    }
                }
            }
            .opacity(0.55)
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Step indicator
                HStack {
                    Text("STEP 3 / 5")
                        .font(GW.mono(10, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(GW.mute)
                    Spacer()
                    Text("SKIP")
                        .font(GW.mono(10, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(GW.mute)
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)

                HStack(spacing: 4) {
                    ForEach(0..<5) { i in
                        Capsule()
                            .fill(i < 3
                                  ? AnyShapeStyle(GW.grad)
                                  : AnyShapeStyle(Color.white.opacity(0.08)))
                            .frame(height: 3)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 6)

                // Title + copy
                VStack(alignment: .leading, spacing: 6) {
                    Text("[ ASSESSMENT ]")
                        .font(GW.mono(10, weight: .medium))
                        .tracking(3)
                        .foregroundStyle(GW.cyan)
                    Text("The System has\ndetermined your\nstarting rank.")
                        .font(GW.display(28, weight: .semibold))
                        .tracking(-0.7)
                        .foregroundStyle(GW.ink)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)
                    Text("Based on 12 weeks of activity, sleep, and focus signals. Your rank will rise as you complete quests.")
                        .font(GW.sans(13))
                        .foregroundStyle(GW.mute)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 22)
                .padding(.top, 22)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Hex rank reveal
                rankBadge
                    .padding(.top, 36)

                // Starting attributes
                GWCard(paddingX: 14, paddingY: 12) {
                    VStack(spacing: 10) {
                        Text("STARTING ATTRIBUTES")
                            .font(GW.mono(9, weight: .medium))
                            .tracking(2)
                            .foregroundStyle(GW.mute)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3),
                                  spacing: 10) {
                            ForEach(GW_STATS) { s in
                                VStack(spacing: 2) {
                                    Text(s.key)
                                        .font(GW.mono(9, weight: .medium))
                                        .tracking(1.4)
                                        .foregroundStyle(GW.mute)
                                    Text("\(s.value)")
                                        .font(GW.display(18, weight: .bold))
                                        .foregroundStyle(GW.ink)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 24)

                Spacer()

                HStack(spacing: 10) {
                    GWButton(label: "BACK", variant: .ghost)
                    GWButton(label: "ACCEPT RANK", variant: .primary)
                        .layoutPriority(1.6)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 32)
            }
        }
        .foregroundStyle(GW.ink)
        
    }

    private var rankBadge: some View {
        ZStack {
            // Outer hex
            HexagonShape()
                .stroke(
                    LinearGradient(colors: [GW.cyan, GW.pink],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing),
                    lineWidth: 2
                )
            // Inner hex
            HexagonShape(inset: 0.08)
                .fill(GW.bg2.opacity(0.6))
                .overlay(
                    HexagonShape(inset: 0.08)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )

            VStack(spacing: -4) {
                Text("RANK")
                    .font(GW.mono(10, weight: .medium))
                    .tracking(3)
                    .foregroundStyle(GW.mute)
                Text("B")
                    .font(GW.display(96, weight: .heavy))
                    .tracking(-5)
                    .foregroundStyle(GW.grad)
                    .shadow(color: GW.pink.opacity(0.45), radius: 18)
                Text("TIER II HUNTER")
                    .font(GW.mono(9, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(GW.mute)
            }
        }
        .frame(width: 200, height: 200)
    }
}

private struct HexagonShape: Shape {
    var inset: CGFloat = 0
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let i = inset
        // Six-point hexagon (matches polygon points in design)
        let pts: [CGPoint] = [
            CGPoint(x: w * 0.5,         y: h * (0.04 + i)),
            CGPoint(x: w * (0.89 - i),  y: h * (0.275 + i)),
            CGPoint(x: w * (0.89 - i),  y: h * (0.725 - i)),
            CGPoint(x: w * 0.5,         y: h * (0.96 - i)),
            CGPoint(x: w * (0.11 + i),  y: h * (0.725 - i)),
            CGPoint(x: w * (0.11 + i),  y: h * (0.275 + i)),
        ]
        var p = Path()
        p.move(to: pts[0])
        for pt in pts.dropFirst() { p.addLine(to: pt) }
        p.closeSubpath()
        return p
    }
}

#Preview {
    GWOnboardingScreen()
}
