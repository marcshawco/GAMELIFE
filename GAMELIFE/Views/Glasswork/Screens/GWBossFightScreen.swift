//
//  GWBossFightScreen.swift
//  GAMELIFE
//
//  05 · BOSS FIGHT — boss-tinted aurora, big ringed sigil with damage chip,
//  boss meta, HP bar, strike log, RETREAT / STRIKE NOW pinned bottom.
//  Ported from glasswork/screens-combat.jsx (GWBossFight).
//

import SwiftUI

struct GWBossFightScreen: View {
    private let b = GW_BOSSES[0]

    var body: some View {
        let glow = Color.hsl(b.hue, 80, 60)

        ZStack(alignment: .top) {
            GW.bg.ignoresSafeArea()

            // Boss-tinted background
            Canvas { ctx, size in
                let w = size.width, h = size.height
                func auroraEllipse(_ c: CGPoint, _ rx: CGFloat, _ ry: CGFloat, _ color: Color) {
                    let rect = CGRect(x: c.x - rx, y: c.y - ry, width: rx * 2, height: ry * 2)
                    let g = Gradient(colors: [color, color.opacity(0)])
                    ctx.fill(Path(ellipseIn: rect),
                             with: .radialGradient(g, center: c,
                                                   startRadius: 0,
                                                   endRadius: max(rx, ry)))
                }
                auroraEllipse(CGPoint(x: w * 0.5, y: h * 0.3), w * 0.8, h * 0.5,
                              Color.hsl(b.hue, 70, 35))
                auroraEllipse(CGPoint(x: w * 0.8, y: h * 1.0), w * 0.6, h * 0.4,
                              GW.pink.opacity(0.2))
            }
            .ignoresSafeArea()

            // Dotted grid noise
            Canvas { ctx, size in
                let step: CGFloat = 14
                let dot = Color.white.opacity(0.06)
                let rows = Int(size.height / step) + 1
                let cols = Int(size.width / step) + 1
                for r in 0..<rows {
                    for c in 0..<cols {
                        let p = CGPoint(x: CGFloat(c) * step, y: CGFloat(r) * step)
                        ctx.fill(Path(ellipseIn: CGRect(x: p.x - 0.5, y: p.y - 0.5,
                                                        width: 1, height: 1)),
                                 with: .color(dot))
                    }
                }
            }
            .opacity(0.55)
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header bar
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(GW.hairline))
                        Text("‹").font(GW.mono(18)).foregroundStyle(GW.mute)
                    }
                    .frame(width: 36, height: 36)
                    Spacer()
                    Text("BOSS · DAY 18 / 30")
                        .font(GW.mono(9, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(GW.mute)
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer().frame(height: 56)

                // Sigil ring with damage chip
                sigilRing(glow: glow)

                // Boss meta
                VStack(spacing: 4) {
                    Text("FINANCIAL TRIAL · TIER II")
                        .font(GW.mono(10, weight: .medium))
                        .tracking(3)
                        .foregroundStyle(glow)
                    Text(b.name)
                        .font(GW.display(26, weight: .bold))
                        .tracking(-0.5)
                        .foregroundStyle(GW.ink)
                    Text(b.sub)
                        .font(GW.sans(12))
                        .foregroundStyle(GW.mute)
                }
                .padding(.top, 22)
                .padding(.horizontal, 16)

                // HP bar
                VStack(spacing: 6) {
                    HStack {
                        Text("BOSS HP")
                            .font(GW.mono(10))
                            .tracking(1)
                            .foregroundStyle(GW.mute)
                        Spacer()
                        Text("\(Int(b.hp * 100)) / 100")
                            .font(GW.mono(10))
                            .tracking(1)
                            .foregroundStyle(glow)
                    }
                    GWBar(pct: b.hp,
                          height: 8,
                          gradient: AnyShapeStyle(
                              LinearGradient(colors: [glow, GW.pink],
                                             startPoint: .leading, endPoint: .trailing)
                          ),
                          glow: false)
                }
                .padding(.top, 16)
                .padding(.horizontal, 22)

                Spacer()
            }

            // Strike log + buttons
            VStack(spacing: 0) {
                Spacer()
                strikeLog
                    .padding(.horizontal, 22)
                    .padding(.bottom, 14)
                HStack(spacing: 10) {
                    GWButton(label: "RETREAT", variant: .ghost)
                    GWButton(label: "STRIKE NOW", variant: .danger)
                        .layoutPriority(1.6)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 32)
            }
        }
        .foregroundStyle(GW.ink)
        
    }

    private func sigilRing(glow: Color) -> some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 1.5)
                .frame(width: 200, height: 200)
            // HP arc
            Circle()
                .trim(from: 0, to: b.hp)
                .stroke(
                    LinearGradient(colors: [glow, GW.pink],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
            // Tick marks
            Canvas { ctx, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                for i in 0..<60 {
                    let a = CGFloat(i) / 60 * .pi * 2 - .pi / 2
                    let r1: CGFloat = 86, r2: CGFloat = 90
                    let start = CGPoint(x: center.x + cos(a) * r1, y: center.y + sin(a) * r1)
                    let end   = CGPoint(x: center.x + cos(a) * r2, y: center.y + sin(a) * r2)
                    var p = Path()
                    p.move(to: start)
                    p.addLine(to: end)
                    ctx.stroke(p, with: .color(Color.white.opacity(0.15)), lineWidth: 1)
                }
            }
            .frame(width: 220, height: 220)

            // Inner sigil
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.hsl(b.hue, 65, 50), Color.hsl(b.hue, 60, 18)],
                            center: UnitPoint(x: 0.3, y: 0.3),
                            startRadius: 4,
                            endRadius: 140
                        )
                    )
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                    .shadow(color: glow.opacity(0.45), radius: 40)
                Text(String(b.name.prefix(1)))
                    .font(GW.display(64, weight: .bold))
                    .foregroundStyle(GW.ink)
                    .shadow(color: .black.opacity(0.6), radius: 4, y: 2)
            }
            .frame(width: 144, height: 144)

            // Damage burst chip
            Text("−4 HP")
                .font(GW.mono(11, weight: .bold))
                .foregroundStyle(GW.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(GW.gradDanger))
                .shadow(color: GW.danger.opacity(0.45), radius: 12)
                .rotationEffect(.degrees(8))
                .offset(x: 100, y: -100)
        }
        .frame(width: 220, height: 220)
    }

    private var strikeLog: some View {
        GWCard(paddingX: 14, paddingY: 12) {
            VStack(spacing: 10) {
                HStack {
                    Text("STRIKE LOG · TODAY")
                        .font(GW.mono(9, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(GW.mute)
                    Spacer()
                    Text("−4 HP")
                        .font(GW.mono(9, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(GW.danger)
                }
                VStack(spacing: 8) {
                    strikeRow("08:42", "Run 5 km", "−1.5 HP")
                    strikeRow("09:11", "Saved $40", "−1.5 HP")
                    strikeRow("09:30", "Resisted purchase", "−1 HP")
                }
            }
        }
    }

    private func strikeRow(_ t: String, _ label: String, _ delta: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(t)
                .font(GW.mono(9))
                .foregroundStyle(GW.mute)
                .frame(width: 36, alignment: .leading)
            Text(label)
                .font(GW.sans(12))
                .foregroundStyle(GW.inkSoft)
            Spacer(minLength: 6)
            Text(delta)
                .font(GW.mono(11))
                .foregroundStyle(GW.danger)
        }
    }
}

#Preview {
    GWBossFightScreen()
}
