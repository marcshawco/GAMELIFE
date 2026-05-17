//
//  GWStatusScreen.swift
//  GAMELIFE
//
//  01 · STATUS — radar + level + HP/streak strip + next-up quests.
//  Ported from glasswork/screens-loop.jsx (GWStatus).
//

import SwiftUI

struct GWStatusScreen: View {
    var body: some View {
        let xpPct = Double(GW_PLAYER.xpCurrent) / Double(GW_PLAYER.xpNeeded)
        let hpPct = Double(GW_PLAYER.hp) / Double(GW_PLAYER.hpMax)

        ZStack(alignment: .bottom) {
            GWScreen {
                GWTopChip {
                    GWPill(
                        text: GW_PLAYER.gold.formatted(),
                        color: GW.amber,
                        border: GW.amber.opacity(0.35),
                        glow: GW.amber.opacity(0.35),
                        leadingDot: GW.amber
                    )
                }

                // Radar + level glass card
                GWCard(paddingX: 14, paddingY: 14) {
                    VStack(spacing: 0) {
                        GWSectionLabel(left: "ATTRIBUTES", right: "RADAR")
                        HStack {
                            Spacer()
                            GWRadar(stats: GW_STATS, size: 196)
                            Spacer()
                        }
                        .padding(.top, 4)
                        VStack(spacing: 6) {
                            HStack {
                                Text("LV \(GW_PLAYER.level) → \(GW_PLAYER.level + 1)")
                                    .font(GW.mono(10))
                                    .tracking(1)
                                    .foregroundStyle(GW.mute)
                                Spacer()
                                Text("\(GW_PLAYER.xpCurrent.formatted()) / \(GW_PLAYER.xpNeeded.formatted()) XP")
                                    .font(GW.mono(10))
                                    .tracking(1)
                                    .foregroundStyle(GW.mute)
                            }
                            GWBar(pct: xpPct)
                        }
                        .padding(.top, 6)
                    }
                }

                // HP + streak strip
                HStack(spacing: 10) {
                    GWCard(paddingX: 14, paddingY: 10) {
                        VStack(spacing: 8) {
                            HStack(alignment: .firstTextBaseline) {
                                Text("HP")
                                    .font(GW.mono(10, weight: .medium))
                                    .tracking(1.5)
                                    .foregroundStyle(GW.mute)
                                Spacer()
                                Text("\(GW_PLAYER.hp)/\(GW_PLAYER.hpMax)")
                                    .font(GW.mono(11))
                                    .foregroundStyle(GW.ink)
                            }
                            GWBar(pct: hpPct,
                                  gradient: AnyShapeStyle(
                                      LinearGradient(colors: [GW.pink, GW.amber],
                                                     startPoint: .leading, endPoint: .trailing)
                                  ),
                                  glow: false)
                        }
                    }
                    .layoutPriority(1.4)

                    GWCard(paddingX: 14, paddingY: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("STREAK")
                                .font(GW.mono(10, weight: .medium))
                                .tracking(1.5)
                                .foregroundStyle(GW.mute)
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text("\(GW_PLAYER.streak)")
                                    .font(GW.display(24, weight: .bold))
                                    .tracking(-0.5)
                                    .foregroundStyle(GW.cyan)
                                Text("DAYS")
                                    .font(GW.mono(10))
                                    .foregroundStyle(GW.mute)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // Next-up quests
                GWCard(paddingX: 14, paddingY: 12) {
                    VStack(spacing: 10) {
                        GWSectionLabel(left: "NEXT UP",
                                       right: "\(GW_PLAYER.questsDoneToday)/\(GW_PLAYER.questsTodayTotal) TODAY")
                        ForEach(GW_QUESTS.filter { $0.status != .done }.prefix(2)) { q in
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(q.progress > 0 ? GW.cyan.opacity(0.07) : .clear)
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(q.progress > 0 ? GW.cyan.opacity(0.67) : Color.white.opacity(0.12),
                                                lineWidth: 1)
                                    Text("\(Int(q.progress * 100))")
                                        .font(GW.mono(9, weight: .medium))
                                        .foregroundStyle(q.progress > 0 ? GW.cyan : GW.mute)
                                }
                                .frame(width: 30, height: 30)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(q.title)
                                        .font(GW.sans(13, weight: .medium))
                                        .foregroundStyle(GW.ink)
                                        .lineLimit(1)
                                    Text("\(q.stat) · +\(q.xp) XP · +\(q.gold)g")
                                        .font(GW.mono(9))
                                        .tracking(0.5)
                                        .foregroundStyle(GW.mute)
                                }
                                Spacer(minLength: 6)
                                GWPill(text: "RUN",
                                       color: GW.cyan,
                                       bg: GW.cyan.opacity(0.07),
                                       border: GW.cyan.opacity(0.33))
                            }
                        }
                    }
                }

                Spacer(minLength: 0)
            }

            GWTabDock(active: .status)
                .padding(.horizontal, 14)
                .padding(.bottom, 18)
        }
    }
}

#Preview {
    GWStatusScreen()
}
