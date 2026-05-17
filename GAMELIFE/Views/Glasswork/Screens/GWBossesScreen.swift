//
//  GWBossesScreen.swift
//  GAMELIFE
//
//  04 · BOSS LIST — centered title + boss cards with big sigil, HP bar, pills.
//  Ported from glasswork/screens-combat.jsx (GWBosses).
//

import SwiftUI

struct GWBossesScreen: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            GWScreen(padBottom: 90) {
                VStack(spacing: 6) {
                    Text("BOSSES · 3 ENGAGED")
                        .font(GW.mono(10, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(GW.mute)
                    Text("Long Fights")
                        .font(GW.display(28, weight: .semibold))
                        .tracking(-0.5)
                        .foregroundStyle(GW.ink)
                    Text("Multi-week boss fights. Daily quests damage them.")
                        .font(GW.sans(12))
                        .foregroundStyle(GW.mute)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280)
                }
                .frame(maxWidth: .infinity)

                ForEach(Array(GW_BOSSES.enumerated()), id: \.element.id) { i, b in
                    bossCard(b, index: i)
                }

                summonCard

                Spacer(minLength: 0)
            }

            GWTabDock(active: .bosses)
                .padding(.horizontal, 14)
                .padding(.bottom, 18)
        }
    }

    @ViewBuilder
    private func bossCard(_ b: GWBoss, index i: Int) -> some View {
        let glow = Color.hsl(b.hue, 80, 60)
        let damaged = 1 - b.hp
        let tier = i == 0 ? "II" : "I"
        let day = [18, 7, 42][i]

        GWCard(padding: EdgeInsets(top: 16, leading: 16, bottom: 14, trailing: 16),
               accent: glow) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [Color.hsl(b.hue, 70, 55), Color.hsl(b.hue, 60, 22)],
                                center: UnitPoint(x: 0.3, y: 0.3),
                                startRadius: 4,
                                endRadius: 80
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .shadow(color: glow.opacity(0.4), radius: 18)
                    Text(String(b.name.prefix(1)))
                        .font(GW.display(36, weight: .bold))
                        .foregroundStyle(GW.ink)
                        .shadow(color: .black.opacity(0.5), radius: 2, y: 2)
                }
                .frame(width: 84, height: 84)
                .padding(.bottom, 6)

                Text("TIER \(tier) · DAY \(day)")
                    .font(GW.mono(9, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(glow)
                Text(b.name)
                    .font(GW.display(18, weight: .semibold))
                    .tracking(-0.4)
                    .foregroundStyle(GW.ink)
                Text(b.sub)
                    .font(GW.sans(12))
                    .foregroundStyle(GW.mute)

                HStack(spacing: 10) {
                    Text("HP")
                        .font(GW.mono(9))
                        .tracking(1)
                        .foregroundStyle(GW.mute)
                    GWBar(pct: b.hp,
                          height: 6,
                          gradient: AnyShapeStyle(
                              LinearGradient(colors: [glow, GW.pink],
                                             startPoint: .leading, endPoint: .trailing)
                          ),
                          glow: false)
                    Text("\(Int(b.hp * 100))/100")
                        .font(GW.mono(10))
                        .foregroundStyle(GW.ink)
                        .frame(minWidth: 44, alignment: .trailing)
                }
                .padding(.top, 8)

                HStack(spacing: 6) {
                    GWPill(text: "−\(Int(damaged * 100))% DEALT")
                    if i == 0 {
                        GWPill(text: "FOCUSED",
                               color: GW.cyan,
                               bg: GW.cyan.opacity(0.07),
                               border: GW.cyan.opacity(0.33))
                    }
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var summonCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                .foregroundStyle(GW.hairline)
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [3]))
                        .foregroundStyle(GW.mute)
                    Text("+").font(GW.mono(16)).foregroundStyle(GW.mute)
                }
                .frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Summon a new boss")
                        .font(GW.sans(13, weight: .medium))
                        .foregroundStyle(GW.ink)
                    Text("A LONG-FORM GOAL · 30–90 DAYS")
                        .font(GW.mono(9))
                        .tracking(0.5)
                        .foregroundStyle(GW.mute)
                }
            }
            .padding(14)
        }
    }
}

#Preview {
    GWBossesScreen()
}
