//
//  GWDungeonScreen.swift
//  GAMELIFE
//
//  06 · DUNGEON (focus timer) — title strip, ringed timer, pulse status,
//  ABANDON / PAUSE buttons. Ported from screens-combat.jsx (GWDungeon).
//

import SwiftUI

struct GWDungeonScreen: View {
    private let min = 24
    private let sec = 13
    private let total: Double = 45 * 60

    var body: some View {
        let remaining = Double(min * 60 + sec)
        let pct = 1 - remaining / total

        ZStack(alignment: .top) {
            GW.bg.ignoresSafeArea()

            // Aurora variant — cyan top, pink bottom
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
                make(CGPoint(x: w * 0.5, y: h * 0.4), w * 0.7, h * 0.5, GW.cyan.opacity(0.13))
                make(CGPoint(x: w * 0.5, y: h * 1.0), w * 0.5, h * 0.4, GW.pink.opacity(0.13))
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
                VStack(spacing: 6) {
                    Text("[ DUNGEON · DEEP FOCUS ]")
                        .font(GW.mono(10, weight: .medium))
                        .tracking(3)
                        .foregroundStyle(GW.cyan)
                    Text("Ship one PR review")
                        .font(GW.display(22, weight: .semibold))
                        .tracking(-0.3)
                        .foregroundStyle(GW.ink)
                    Text("INT · 45-MIN SESSION · NO PHONE")
                        .font(GW.mono(10))
                        .tracking(1)
                        .foregroundStyle(GW.mute)
                }
                .padding(.top, 8)

                Spacer().frame(height: 38)

                timerRing(pct: pct)

                Spacer().frame(height: 28)

                GWCard(paddingX: 14, paddingY: 12) {
                    HStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(GW.good)
                                .frame(width: 8, height: 8)
                                .shadow(color: GW.good, radius: 4)
                            Text("Phone face-down · 12 min")
                                .font(GW.sans(12))
                                .foregroundStyle(GW.inkSoft)
                        }
                        Spacer()
                        Text("BONUS ACTIVE")
                            .font(GW.mono(10, weight: .medium))
                            .tracking(1)
                            .foregroundStyle(GW.good)
                    }
                }
                .padding(.horizontal, 22)

                Spacer()

                HStack(spacing: 10) {
                    GWButton(label: "ABANDON", variant: .ghost)
                    GWButton(label: "PAUSE",
                             variant: .primary,
                             icon: "❚❚")
                        .layoutPriority(1.6)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 32)
            }
        }
        .foregroundStyle(GW.ink)
        .preferredColorScheme(.dark)
    }

    private func timerRing(pct: Double) -> some View {
        let R: CGFloat = 96
        return ZStack {
            Circle()
                .stroke(Color.white.opacity(0.07), lineWidth: 3)
                .frame(width: R * 2, height: R * 2)
            Circle()
                .trim(from: 0, to: pct)
                .stroke(
                    LinearGradient(colors: [GW.cyan, GW.pink],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: R * 2, height: R * 2)
                .rotationEffect(.degrees(-90))

            // Tick marks (60 around)
            Canvas { ctx, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                for i in 0..<60 {
                    let a = CGFloat(i) / 60 * .pi * 2 - .pi / 2
                    let r1: CGFloat = 80
                    let r2: CGFloat = (i % 5 == 0) ? 73 : 76
                    let start = CGPoint(x: center.x + cos(a) * r1, y: center.y + sin(a) * r1)
                    let end   = CGPoint(x: center.x + cos(a) * r2, y: center.y + sin(a) * r2)
                    var p = Path()
                    p.move(to: start)
                    p.addLine(to: end)
                    ctx.stroke(p,
                               with: .color(i % 5 == 0
                                            ? Color.white.opacity(0.3)
                                            : Color.white.opacity(0.1)),
                               lineWidth: 1)
                }
            }
            .frame(width: 240, height: 240)

            VStack(spacing: 4) {
                Text("REMAINING")
                    .font(GW.mono(10, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(GW.mute)
                HStack(spacing: 0) {
                    Text("\(String(format: "%02d", min))")
                        .font(GW.display(56, weight: .semibold))
                        .tracking(-2)
                        .foregroundStyle(GW.ink)
                    Text(":")
                        .font(GW.display(56, weight: .semibold))
                        .foregroundStyle(GW.cyan)
                    Text("\(String(format: "%02d", sec))")
                        .font(GW.display(56, weight: .semibold))
                        .tracking(-2)
                        .foregroundStyle(GW.ink)
                }
                Text("+675 XP ON CLEAR")
                    .font(GW.mono(9, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(GW.mute)
                    .padding(.top, 4)
            }
        }
        .frame(width: 240, height: 240)
    }
}

#Preview {
    GWDungeonScreen()
}
