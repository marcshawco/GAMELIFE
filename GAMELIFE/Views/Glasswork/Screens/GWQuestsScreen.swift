//
//  GWQuestsScreen.swift
//  GAMELIFE
//
//  02 · QUESTS LIST — header + day progress + filter chips + quest cards + FAB.
//  Ported from glasswork/screens-loop.jsx (GWQuests).
//

import SwiftUI

struct GWQuestsScreen: View {
    var body: some View {
        let dailyDone = GW_QUESTS.filter { $0.status == .done }.count
        let dailyTotal = GW_QUESTS.count
        let totalPct = Double(dailyDone) / Double(dailyTotal)

        ZStack(alignment: .bottom) {
            GWScreen(padBottom: 110) {
                // Header
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("QUEST LOG")
                            .font(GW.mono(10, weight: .medium))
                            .tracking(2)
                            .foregroundStyle(GW.mute)
                        Text("Today")
                            .font(GW.display(26, weight: .semibold))
                            .tracking(-0.5)
                            .foregroundStyle(GW.ink)
                    }
                    Spacer()
                    GWPill(text: "\(dailyDone)/\(dailyTotal) CLEARED",
                           color: GW.cyan,
                           bg: GW.cyan.opacity(0.07),
                           border: GW.cyan.opacity(0.33))
                }

                // Day progress card
                GWCard(paddingX: 14, paddingY: 12) {
                    VStack(spacing: 10) {
                        HStack {
                            Text("DAY PROGRESS")
                                .font(GW.mono(10))
                                .tracking(1)
                                .foregroundStyle(GW.mute)
                            Spacer()
                            Text("\(Int(totalPct * 100))%")
                                .font(GW.mono(10))
                                .tracking(1)
                                .foregroundStyle(GW.mute)
                        }
                        GWBar(pct: totalPct, height: 6)
                        HStack(spacing: 6) {
                            GWPill(text: "DAILY · 5")
                            GWPill(text: "WEEKLY · 1")
                            GWPill(text: "BOSS · ENGAGED",
                                   color: GW.amber,
                                   border: GW.amber.opacity(0.27))
                            Spacer()
                        }
                    }
                }

                // Filter strip
                HStack(spacing: 6) {
                    ForEach(Array(["ALL", "DAILY", "WEEKLY", "BOSS", "DUNGEON"].enumerated()),
                            id: \.element) { i, t in
                        GWFilterChip(label: t, active: i == 0)
                    }
                    Spacer()
                }

                // Quest cards
                ForEach(GW_QUESTS) { q in
                    questCard(q)
                }

                Spacer(minLength: 0)
            }

            // FAB
            HStack {
                Spacer()
                Button(action: {}) {
                    Text("+")
                        .font(GW.display(28, weight: .regular))
                        .foregroundStyle(GW.bg)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(GW.grad))
                        .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .shadow(color: GW.pink.opacity(0.4), radius: 14, x: 0, y: 8)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 18)
                .padding(.bottom, 86)
            }

            GWTabDock(active: .quests)
                .padding(.horizontal, 14)
                .padding(.bottom, 18)
        }
    }

    @ViewBuilder
    private func questCard(_ q: GWQuest) -> some View {
        let done = q.status == .done
        let active = q.status == .active

        GWCard(paddingX: 14, paddingY: 12) {
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    questBadge(q, done: done, active: active)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(q.title)
                            .font(GW.sans(13, weight: .medium))
                            .foregroundStyle(done ? GW.mute : GW.ink)
                            .strikethrough(done)
                        Text(q.sub.uppercased())
                            .font(GW.mono(9))
                            .tracking(0.5)
                            .foregroundStyle(GW.mute)
                    }
                    Spacer(minLength: 6)
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("+\(q.xp)")
                            .font(GW.mono(10))
                            .foregroundStyle(GW.cyan)
                        Text("+\(q.gold)g")
                            .font(GW.mono(9))
                            .foregroundStyle(GW.amber)
                    }
                }

                if active && q.progress > 0 {
                    GWBar(pct: q.progress, height: 3, glow: false)
                }
            }
        }
        .opacity(done ? 0.55 : 1)
    }

    @ViewBuilder
    private func questBadge(_ q: GWQuest, done: Bool, active: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(done ? AnyShapeStyle(GW.grad)
                      : active ? AnyShapeStyle(GW.cyan.opacity(0.08))
                      : AnyShapeStyle(Color.clear))
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(done ? GW.cyan
                        : active ? GW.cyan.opacity(0.53)
                        : Color.white.opacity(0.18),
                        lineWidth: 1.5)
            if done {
                Text("✓").font(GW.mono(10, weight: .bold)).foregroundStyle(GW.bg)
            } else if active {
                Text("\(Int(q.progress * 100))")
                    .font(GW.mono(10, weight: .bold))
                    .foregroundStyle(GW.cyan)
            }
        }
        .frame(width: 28, height: 28)
    }
}

#Preview {
    GWQuestsScreen()
}
