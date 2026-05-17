//
//  GlassworkBossesView.swift
//  GAMELIFE
//
//  Live Glasswork Bosses tab — wired to gameEngine.activeBossFights.
//  Boss cards (sigil · tier · HP · status pills) push into the
//  GlassworkBossFightView detail.
//

import SwiftUI

struct GlassworkBossesView: View {
    @EnvironmentObject var gameEngine: GameEngine
    @State private var showSummonSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                GW.bg.ignoresSafeArea()
                GWAurora().ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        header
                        if gameEngine.activeBossFights.isEmpty {
                            emptyCard
                        } else {
                            ForEach(Array(gameEngine.activeBossFights.enumerated()), id: \.element.id) { idx, boss in
                                NavigationLink {
                                    GlassworkBossFightView(bossID: boss.id, hue: hue(for: idx, total: gameEngine.activeBossFights.count))
                                } label: {
                                    bossCard(boss, index: idx, total: gameEngine.activeBossFights.count)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        summonCard
                        Color.clear.frame(height: 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 110)
                }
            }
            .foregroundStyle(GW.ink)
            .preferredColorScheme(.dark)
            .toolbar(.hidden)
        }
        .sheet(isPresented: $showSummonSheet) {
            BossFormSheet()
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 6) {
            Text("BOSSES · \(gameEngine.activeBossFights.count) ENGAGED")
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
    }

    // MARK: Empty state

    private var emptyCard: some View {
        GWCard(paddingX: 14, paddingY: 18) {
            VStack(spacing: 6) {
                Text("No bosses summoned")
                    .font(GW.sans(14, weight: .semibold))
                    .foregroundStyle(GW.ink)
                Text("Summon your first boss below — pick a goal that takes weeks, not minutes.")
                    .font(GW.sans(12))
                    .foregroundStyle(GW.mute)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var summonCard: some View {
        Button { showSummonSheet = true } label: {
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
                    Spacer()
                }
                .padding(14)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Boss card

    @ViewBuilder
    private func bossCard(_ b: BossFight, index: Int, total: Int) -> some View {
        let h = hue(for: index, total: total)
        let glow = Color.hsl(h, 80, 60)
        let pct = b.hpPercentage
        let damaged = b.damageDealtPercentage
        let focused = (index == 0)
        let daysActive = max(0, Calendar.current.dateComponents([.day], from: b.createdAt, to: Date()).day ?? 0)

        GWCard(padding: EdgeInsets(top: 16, leading: 16, bottom: 14, trailing: 16),
               accent: glow) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [Color.hsl(h, 70, 55), Color.hsl(h, 60, 22)],
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
                    Text(String(b.title.prefix(1)).uppercased())
                        .font(GW.display(36, weight: .bold))
                        .foregroundStyle(GW.ink)
                        .shadow(color: .black.opacity(0.5), radius: 2, y: 2)
                }
                .frame(width: 84, height: 84)
                .padding(.bottom, 6)

                Text("DAY \(daysActive)")
                    .font(GW.mono(9, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(glow)
                Text(b.title)
                    .font(GW.display(18, weight: .semibold))
                    .tracking(-0.4)
                    .foregroundStyle(GW.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text(b.description)
                    .font(GW.sans(12))
                    .foregroundStyle(GW.mute)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                HStack(spacing: 10) {
                    Text("HP")
                        .font(GW.mono(9))
                        .tracking(1)
                        .foregroundStyle(GW.mute)
                    GWBar(pct: pct,
                          height: 6,
                          gradient: AnyShapeStyle(
                              LinearGradient(colors: [glow, GW.pink],
                                             startPoint: .leading, endPoint: .trailing)
                          ),
                          glow: false)
                    Text("\(b.remainingHP.formatted())/\(b.maxHP.formatted())")
                        .font(GW.mono(10))
                        .foregroundStyle(GW.ink)
                        .frame(minWidth: 64, alignment: .trailing)
                }
                .padding(.top, 8)

                HStack(spacing: 6) {
                    GWPill(text: "−\(Int(damaged * 100))% DEALT")
                    if focused {
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

    // Deterministic hue per boss index so colors stay stable across renders.
    private func hue(for index: Int, total: Int) -> Double {
        let palette: [Double] = [14, 264, 200, 46, 152, 320]
        return palette[index % palette.count]
    }
}
