//
//  GlassworkLevelUpView.swift
//  GAMELIFE
//
//  Ceremonial overlay shown when GameEngine.showLevelUpAlert flips true.
//  Mirrors the gallery's GWLevelUp design — gold/cyan/pink aurora, vertical
//  ray streaks, [SYSTEM ANNOUNCEMENT] header, prev → new level numerals,
//  UNLOCKED rewards card, STATS / CLAIM & CONTINUE buttons.
//

import SwiftUI

struct GlassworkLevelUpView: View {
    let data: LevelUpData
    let onDismiss: () -> Void

    @State private var bigNumberScale: CGFloat = 0.2
    @State private var bigNumberOpacity: Double = 0
    @State private var raysOpacity: Double = 0

    var body: some View {
        ZStack(alignment: .top) {
            GW.bg.ignoresSafeArea()

            heavyAurora.ignoresSafeArea()
            goldRays.opacity(raysOpacity).ignoresSafeArea()
            dotGrid.ignoresSafeArea()

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
                    Text("\(data.previousLevel)")
                        .font(GW.display(60, weight: .bold))
                        .tracking(-2)
                        .foregroundStyle(GW.mute)
                    Text("→")
                        .font(GW.display(30))
                        .foregroundStyle(GW.gold)
                    Text("\(data.newLevel)")
                        .font(GW.display(72, weight: .heavy))
                        .tracking(-3)
                        .foregroundStyle(GW.gradGold)
                        .shadow(color: GW.gold.opacity(0.5), radius: 18)
                        .scaleEffect(bigNumberScale)
                        .opacity(bigNumberOpacity)
                }
            }
            .padding(.top, 80)

            unlockedCard
                .padding(.horizontal, 22)
                .frame(maxHeight: .infinity, alignment: .center)
                .offset(y: 60)

            HStack(spacing: 10) {
                GWButton(label: "STATS", variant: .ghost) { onDismiss() }
                GWButton(label: "CLAIM & CONTINUE", variant: .gold) { onDismiss() }
                    .layoutPriority(1.6)
            }
            .padding(.horizontal, 22)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 32)
        }
        .foregroundStyle(GW.ink)
        
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { raysOpacity = 1 }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.55).delay(0.15)) {
                bigNumberScale = 1
                bigNumberOpacity = 1
            }
        }
    }

    // MARK: cards

    private var unlockedCard: some View {
        let levelsGained = max(1, data.newLevel - data.previousLevel)
        let statPool = levelsGained * 5
        let newStats = data.statsUnlocked.map { $0.rawValue }.joined(separator: " · ")

        return GWCard(paddingX: 18, paddingY: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("UNLOCKED")
                    .font(GW.mono(9, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(GW.mute)
                unlockRow("Stat pool", "+\(statPool) free points", GW.cyan)
                if !data.statsUnlocked.isEmpty {
                    unlockRow("Stats unlocked", newStats, GW.pink)
                }
                unlockRow("Rank", rankLabel,
                          data.rankUp ? GW.gold : GW.amber)
                unlockRow("Level gain", "+\(levelsGained)", GW.cyan)
            }
        }
    }

    private var rankLabel: String {
        if data.rankUp {
            return "\(data.previousRank.rawValue) → \(data.newRank.rawValue)"
        }
        return data.newRank.rawValue
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
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    // MARK: backdrops

    private var heavyAurora: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            func ellipse(_ c: CGPoint, _ rx: CGFloat, _ ry: CGFloat, _ color: Color) {
                let rect = CGRect(x: c.x - rx, y: c.y - ry, width: rx * 2, height: ry * 2)
                let g = Gradient(colors: [color, color.opacity(0)])
                ctx.fill(Path(ellipseIn: rect),
                         with: .radialGradient(g, center: c,
                                               startRadius: 0,
                                               endRadius: max(rx, ry)))
            }
            ellipse(CGPoint(x: w * 0.5, y: h * 0.3), w * 0.8, h * 0.5, GW.gold.opacity(0.2))
            ellipse(CGPoint(x: w * 0.2, y: h * 0.8), w * 0.7, h * 0.5, GW.pink.opacity(0.27))
            ellipse(CGPoint(x: w * 0.8, y: h * 0.6), w * 0.7, h * 0.5, GW.cyan.opacity(0.2))
        }
    }

    private var goldRays: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let center = size.width / 2
                let g = Gradient(stops: [
                    .init(color: GW.gold.opacity(0),     location: 0),
                    .init(color: GW.gold.opacity(0.11),  location: 0.5),
                    .init(color: GW.gold.opacity(0),     location: 1),
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
    }

    private var dotGrid: some View {
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
    }
}
