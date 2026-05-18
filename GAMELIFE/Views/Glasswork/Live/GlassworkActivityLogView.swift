//
//  GlassworkActivityLogView.swift
//  GAMELIFE
//
//  Live activity log — summary chips + day-grouped log entries bound to
//  gameEngine.recentActivity. Ported from the gallery's GWActivity but
//  reading real ActivityLogEntry values.
//

import SwiftUI

struct GlassworkActivityLogView: View {
    @EnvironmentObject var gameEngine: GameEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            GW.bg.ignoresSafeArea()
            GWAurora().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    summaryStrip
                    log
                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .foregroundStyle(GW.ink)
        
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .font(GW.sans(14, weight: .semibold))
                    .foregroundStyle(GW.cyan)
            }
        }
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("SYSTEM LOG")
                .font(GW.mono(10, weight: .medium))
                .tracking(2)
                .foregroundStyle(GW.mute)
            Text("Activity")
                .font(GW.display(26, weight: .semibold))
                .tracking(-0.5)
                .foregroundStyle(GW.ink)
        }
    }

    // MARK: summary strip — derived from today's entries

    private var summaryStrip: some View {
        let cal = Calendar.current
        let today = gameEngine.recentActivity.filter { cal.isDateInToday($0.timestamp) }
        let questsToday = today.filter { $0.type == .questCompleted }.count
        let rewards = today.filter { $0.type == .rewardConsumed }.count
        let bosses = today.filter { $0.type == .bossDefeated }.count

        return HStack(spacing: 8) {
            summaryCard("QUESTS TODAY", "\(questsToday)", GW.cyan)
            summaryCard("REWARDS",      "\(rewards)",     GW.amber)
            summaryCard("BOSS HITS",    "\(bosses)",      GW.pink)
        }
    }

    private func summaryCard(_ label: String, _ value: String, _ tint: Color) -> some View {
        GWCard(paddingX: 12, paddingY: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(GW.mono(9, weight: .medium))
                    .tracking(1.4)
                    .foregroundStyle(GW.mute)
                Text(value)
                    .font(GW.display(22, weight: .bold))
                    .foregroundStyle(tint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: log — grouped by day-bucket

    @ViewBuilder
    private var log: some View {
        if gameEngine.recentActivity.isEmpty {
            GWCard(paddingX: 14, paddingY: 18) {
                VStack(spacing: 6) {
                    Text("No activity yet")
                        .font(GW.sans(14, weight: .semibold))
                        .foregroundStyle(GW.ink)
                    Text("Complete a quest, fell a boss, or claim a reward — entries land here in real time.")
                        .font(GW.sans(12))
                        .foregroundStyle(GW.mute)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        } else {
            let grouped = grouping(gameEngine.recentActivity)
            ForEach(grouped, id: \.title) { bucket in
                dayDivider(bucket.title)
                ForEach(bucket.entries) { entry in
                    logRow(entry)
                }
            }
        }
    }

    private struct DayBucket {
        let title: String
        let entries: [ActivityLogEntry]
    }

    private func grouping(_ entries: [ActivityLogEntry]) -> [DayBucket] {
        let cal = Calendar.current
        var todayEntries: [ActivityLogEntry] = []
        var yesterdayEntries: [ActivityLogEntry] = []
        var earlierEntries: [ActivityLogEntry] = []
        let sorted = entries.sorted { $0.timestamp > $1.timestamp }
        for e in sorted {
            if cal.isDateInToday(e.timestamp) {
                todayEntries.append(e)
            } else if cal.isDateInYesterday(e.timestamp) {
                yesterdayEntries.append(e)
            } else {
                earlierEntries.append(e)
            }
        }
        var buckets: [DayBucket] = []
        if !todayEntries.isEmpty {
            buckets.append(DayBucket(title: "TODAY · \(short(Date()))", entries: todayEntries))
        }
        if !yesterdayEntries.isEmpty {
            let y = cal.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            buckets.append(DayBucket(title: "YESTERDAY · \(short(y))", entries: yesterdayEntries))
        }
        if !earlierEntries.isEmpty {
            buckets.append(DayBucket(title: "EARLIER", entries: earlierEntries))
        }
        return buckets
    }

    private func short(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return f.string(from: date).uppercased()
    }

    private func dayDivider(_ label: String) -> some View {
        HStack(spacing: 10) {
            Rectangle().fill(GW.hairline).frame(height: 1)
            Text(label)
                .font(GW.mono(9, weight: .medium))
                .tracking(2)
                .foregroundStyle(GW.mute)
            Rectangle().fill(GW.hairline).frame(height: 1)
        }
        .padding(.top, 8)
    }

    private func logRow(_ e: ActivityLogEntry) -> some View {
        let tint = tint(for: e.type)
        let cat = category(for: e.type)
        return GWCard(paddingX: 12, paddingY: 10) {
            HStack(spacing: 10) {
                Circle()
                    .fill(tint)
                    .frame(width: 6, height: 6)
                    .shadow(color: tint, radius: 4)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(cat)
                            .font(GW.mono(9, weight: .medium))
                            .tracking(1.5)
                            .foregroundStyle(tint)
                        Text(timeLabel(e.timestamp))
                            .font(GW.mono(9))
                            .foregroundStyle(GW.mute)
                    }
                    Text(e.title)
                        .font(GW.sans(12))
                        .foregroundStyle(GW.ink)
                }
                Spacer(minLength: 6)
                Text(e.detail)
                    .font(GW.mono(11))
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }

    private func tint(for type: ActivityLogType) -> Color {
        switch type {
        case .questCompleted:     return GW.cyan
        case .bossDefeated:       return GW.danger
        case .rewardConsumed:     return GW.amber
        case .achievementUnlocked: return GW.gold
        }
    }

    private func category(for type: ActivityLogType) -> String {
        switch type {
        case .questCompleted:     return "QUEST"
        case .bossDefeated:       return "BOSS"
        case .rewardConsumed:     return "SHOP"
        case .achievementUnlocked: return "TROPHY"
        }
    }

    private func timeLabel(_ d: Date) -> String {
        let cal = Calendar.current
        let f = DateFormatter()
        if cal.isDateInToday(d) || cal.isDateInYesterday(d) {
            f.dateFormat = "HH:mm"
        } else {
            f.dateFormat = "d MMM"
        }
        return f.string(from: d)
    }
}
