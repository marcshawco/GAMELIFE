//
//  GlassworkQuestsView.swift
//  GAMELIFE
//
//  Live Glasswork Quests tab — wired to GameEngine. Mirrors the Praxis Demo
//  prototype: header + day progress + filter chips + tappable quest cards
//  with checkbox completion → triggers the Quest Cleared modal with the
//  real reward payload. FAB opens the existing QuestFormSheet for create.
//

import SwiftUI

struct GlassworkQuestsView: View {
    @EnvironmentObject var gameEngine: GameEngine
    @State private var showAddSheet = false
    @State private var clearedPayload: ClearedQuestPayload?

    struct ClearedQuestPayload: Identifiable {
        let id = UUID()
        let title: String
        let primaryStat: String
        let xpAwarded: Int
        let goldAwarded: Int
        let statGains: [(StatType, Int)]
    }

    var body: some View {
        let quests = gameEngine.dailyQuests
        let doneCount = quests.filter { $0.status == .completed }.count
        let totalCount = quests.count
        let dayPct = totalCount == 0 ? 0 : Double(doneCount) / Double(totalCount)

        ZStack(alignment: .bottom) {
            ZStack {
                GW.bg.ignoresSafeArea()
                GWAurora().ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        header(doneCount: doneCount, totalCount: totalCount)
                        dayProgressCard(pct: dayPct)
                        filterStrip
                        questList(quests: quests)
                        Color.clear.frame(height: 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 130)
                }
            }

            // FAB
            HStack {
                Spacer()
                Button { showAddSheet = true } label: {
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
                .padding(.bottom, 16)
            }
        }
        .foregroundStyle(GW.ink)
        
        .sheet(isPresented: $showAddSheet) {
            QuestFormSheet(mode: .add)
        }
        .fullScreenCover(item: $clearedPayload) { payload in
            GlassworkQuestClearedModal(
                questTitle: payload.title,
                primaryStat: payload.primaryStat,
                xpAwarded: payload.xpAwarded,
                goldAwarded: payload.goldAwarded,
                statGains: payload.statGains,
                onClose: { clearedPayload = nil }
            )
            .presentationBackground(.clear)
        }
    }

    // MARK: - Header

    private func header(doneCount: Int, totalCount: Int) -> some View {
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
            GWPill(text: totalCount == 0 ? "NO QUESTS" : "\(doneCount)/\(totalCount) CLEARED",
                   color: GW.cyan,
                   bg: GW.cyan.opacity(0.07),
                   border: GW.cyan.opacity(0.33))
        }
    }

    private func dayProgressCard(pct: Double) -> some View {
        GWCard(paddingX: 14, paddingY: 12) {
            VStack(spacing: 8) {
                HStack {
                    Text("DAY PROGRESS")
                        .font(GW.mono(10))
                        .tracking(1)
                        .foregroundStyle(GW.mute)
                    Spacer()
                    Text("\(Int(pct * 100))%")
                        .font(GW.mono(10))
                        .tracking(1)
                        .foregroundStyle(GW.mute)
                }
                GWBar(pct: pct, height: 6)
            }
        }
    }

    private var filterStrip: some View {
        HStack(spacing: 6) {
            ForEach(Array(["ALL", "DAILY", "WEEKLY", "BOSS"].enumerated()),
                    id: \.element) { i, t in
                GWFilterChip(label: t, active: i == 0)
            }
            Spacer()
        }
    }

    // MARK: - Quest list

    @ViewBuilder
    private func questList(quests: [DailyQuest]) -> some View {
        if quests.isEmpty {
            GWCard(paddingX: 14, paddingY: 18) {
                VStack(spacing: 6) {
                    Text("No quests yet")
                        .font(GW.sans(14, weight: .semibold))
                        .foregroundStyle(GW.ink)
                    Text("Tap the + button to summon your first one.")
                        .font(GW.sans(12))
                        .foregroundStyle(GW.mute)
                }
                .frame(maxWidth: .infinity)
            }
        } else {
            ForEach(quests, id: \.id) { q in
                questCard(q)
            }
        }
    }

    private func questCard(_ q: DailyQuest) -> some View {
        let done = q.status == .completed
        let progress = q.normalizedProgress
        let active = !done && progress > 0
        let primaryStat = q.targetStats.first?.rawValue ?? "—"

        return GWCard(paddingX: 14, paddingY: 12) {
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    completionBadge(done: done, active: active, progress: progress)
                        .onTapGesture { tapComplete(q) }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(q.title)
                            .font(GW.sans(13, weight: .medium))
                            .foregroundStyle(done ? GW.mute : GW.ink)
                            .strikethrough(done)
                        Text(q.description.uppercased())
                            .font(GW.mono(9))
                            .tracking(0.5)
                            .foregroundStyle(GW.mute)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 6)
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("+\(q.xpReward)")
                            .font(GW.mono(10))
                            .foregroundStyle(GW.cyan)
                        Text("+\(q.goldReward)g")
                            .font(GW.mono(9))
                            .foregroundStyle(GW.amber)
                    }
                }
                if active {
                    GWBar(pct: progress, height: 3, glow: false)
                }
                Text("\(primaryStat) primary")
                    .font(GW.mono(8))
                    .tracking(1)
                    .foregroundStyle(GW.mute)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .opacity(done ? 0.55 : 1)
    }

    private func completionBadge(done: Bool, active: Bool, progress: Double) -> some View {
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
                Text("\(Int(progress * 100))")
                    .font(GW.mono(10, weight: .bold))
                    .foregroundStyle(GW.cyan)
            } else {
                Text("◇").font(GW.mono(10, weight: .bold)).foregroundStyle(GW.cyan)
            }
        }
        .frame(width: 28, height: 28)
        .contentShape(Rectangle())
    }

    // MARK: - Actions

    private func tapComplete(_ q: DailyQuest) {
        guard q.status != .completed else { return }
        let result = gameEngine.completeQuest(q)
        guard result.success else { return }

        HapticManager.shared.success()
        clearedPayload = ClearedQuestPayload(
            title: q.title,
            primaryStat: q.targetStats.first?.rawValue ?? "—",
            xpAwarded: result.xpAwarded,
            goldAwarded: result.goldAwarded,
            statGains: result.statGains
        )
    }
}
