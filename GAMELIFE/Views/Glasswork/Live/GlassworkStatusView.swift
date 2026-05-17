//
//  GlassworkStatusView.swift
//  GAMELIFE
//
//  Live Glasswork Status tab — wired to GameEngine instead of mock data.
//  Replaces the SystemTheme-based StatusView when Glasswork is the active
//  visual direction. Keeps the design's structure (radar + level card,
//  HP+streak strip, next-up quests, top chip) but pulls from gameEngine.
//

import SwiftUI

struct GlassworkStatusView: View {
    @EnvironmentObject var gameEngine: GameEngine
    @State private var showActivityLog = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ZStack {
                    GW.bg.ignoresSafeArea()
                    GWAurora().ignoresSafeArea()
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            topChip
                            radarCard
                            hpStreakStrip
                            nextUpCard
                            momentsCard
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 110)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(GW.mute)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
        }
        .foregroundStyle(GW.ink)
        .preferredColorScheme(.dark)
        .accentColor(GW.cyan)
        .sheet(isPresented: $showActivityLog) {
            NavigationStack {
                GlassworkActivityLogView()
            }
            .preferredColorScheme(.dark)
        }
    }

    // MARK: subviews

    private var topChip: some View {
        HStack {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(GW.grad)
                        .frame(width: 36, height: 36)
                        .shadow(color: GW.pink.opacity(0.35), radius: 10)
                    Text(gameEngine.player.rank.rawValue)
                        .font(GW.mono(16, weight: .black))
                        .foregroundStyle(GW.bg)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(gameEngine.player.name.split(separator: " ").first.map(String.init) ?? gameEngine.player.name)
                        .font(GW.sans(14, weight: .semibold))
                        .tracking(-0.2)
                        .foregroundStyle(GW.ink)
                    Text("LV \(gameEngine.player.level)")
                        .font(GW.mono(10))
                        .tracking(1)
                        .foregroundStyle(GW.mute)
                }
            }
            Spacer()
            GWPill(text: gameEngine.player.gold.formatted(),
                   color: GW.amber,
                   border: GW.amber.opacity(0.35),
                   glow: GW.amber.opacity(0.35),
                   leadingDot: GW.amber)
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 4)
    }

    private var radarCard: some View {
        let xpPct = gameEngine.player.xpProgress
        let liveStats = gameEngine.player.statArray.map { stat -> GWStat in
            GWStat(
                key: stat.type.rawValue,
                name: stat.type.displayName,
                value: stat.totalValue,
                max: 200,
                hue: stat.type.hue,
                tint: stat.type.glassworkTint
            )
        }
        return GWCard(paddingX: 14, paddingY: 14) {
            VStack(spacing: 0) {
                GWSectionLabel(left: "ATTRIBUTES", right: "RADAR")
                HStack {
                    Spacer()
                    GWRadar(stats: liveStats, size: 196)
                    Spacer()
                }
                .padding(.top, 4)
                VStack(spacing: 6) {
                    HStack {
                        Text("LV \(gameEngine.player.level) → \(gameEngine.player.level + 1)")
                            .font(GW.mono(10))
                            .tracking(1)
                            .foregroundStyle(GW.mute)
                        Spacer()
                        Text("\(gameEngine.player.currentXP.formatted()) / \(gameEngine.player.xpRequiredForNextLevel.formatted()) XP")
                            .font(GW.mono(10))
                            .tracking(1)
                            .foregroundStyle(GW.mute)
                    }
                    GWBar(pct: xpPct)
                }
                .padding(.top, 6)
            }
        }
    }

    private var hpStreakStrip: some View {
        // `.frame(maxWidth: .infinity)` on each card lets the HStack split
        // width evenly *before* the inner GWBar (which uses GeometryReader)
        // can claim it all. Cards stay short via `.fixedSize` on vertical.
        HStack(alignment: .top, spacing: 10) {
            GWCard(paddingX: 14, paddingY: 10) {
                VStack(spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("HP")
                            .font(GW.mono(10, weight: .medium))
                            .tracking(1.5)
                            .foregroundStyle(GW.mute)
                        Spacer()
                        Text("\(gameEngine.player.currentHP)/\(gameEngine.player.maxHP)")
                            .font(GW.mono(11))
                            .foregroundStyle(GW.ink)
                    }
                    GWBar(pct: gameEngine.player.hpProgress,
                          gradient: AnyShapeStyle(
                              LinearGradient(colors: [GW.pink, GW.amber],
                                             startPoint: .leading, endPoint: .trailing)
                          ),
                          glow: false)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)

            GWCard(paddingX: 14, paddingY: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("STREAK")
                        .font(GW.mono(10, weight: .medium))
                        .tracking(1.5)
                        .foregroundStyle(GW.mute)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(gameEngine.player.currentStreak)")
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
            .frame(maxWidth: .infinity)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var nextUpCard: some View {
        let pending = gameEngine.dailyQuests.filter { $0.status != .completed }
        let total = gameEngine.dailyQuests.count
        let done = total - pending.count
        let preview = Array(pending.prefix(2))

        return GWCard(paddingX: 14, paddingY: 12) {
            VStack(spacing: 10) {
                GWSectionLabel(left: "NEXT UP",
                               right: total == 0 ? "NO QUESTS" : "\(done)/\(total) TODAY")
                if preview.isEmpty {
                    HStack {
                        Text(total == 0
                             ? "Create your first quest in the Quests tab."
                             : "All quests cleared. Take a breath, Hunter.")
                            .font(GW.sans(13))
                            .foregroundStyle(GW.mute)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                } else {
                    ForEach(preview, id: \.id) { q in
                        questRow(q)
                    }
                }
            }
        }
    }

    private var momentsCard: some View {
        let recent = Array(gameEngine.recentActivity.sorted { $0.timestamp > $1.timestamp }.prefix(3))
        return GWCard(paddingX: 14, paddingY: 12) {
            VStack(spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text("SYSTEM · MOMENTS")
                        .font(GW.mono(10, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(GW.mute)
                    Spacer()
                    Button { showActivityLog = true } label: {
                        Text("VIEW ALL")
                            .font(GW.mono(10, weight: .medium))
                            .tracking(1.5)
                            .foregroundStyle(GW.cyan)
                    }
                    .buttonStyle(.plain)
                }
                if recent.isEmpty {
                    Text("Complete a quest to populate your log.")
                        .font(GW.sans(12))
                        .foregroundStyle(GW.mute)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(recent) { entry in
                        momentRow(entry)
                    }
                }
            }
        }
    }

    private func momentRow(_ e: ActivityLogEntry) -> some View {
        let tint = momentTint(for: e.type)
        return HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(timeLabel(e.timestamp))
                .font(GW.mono(9))
                .foregroundStyle(GW.mute)
                .frame(width: 40, alignment: .leading)
            Text(e.title)
                .font(GW.sans(12))
                .foregroundStyle(GW.inkSoft)
                .lineLimit(1)
            Spacer(minLength: 6)
            Circle().fill(tint).frame(width: 6, height: 6)
                .shadow(color: tint, radius: 3)
        }
    }

    private func momentTint(for type: ActivityLogType) -> Color {
        switch type {
        case .questCompleted:      return GW.cyan
        case .bossDefeated:        return GW.danger
        case .rewardConsumed:      return GW.amber
        case .achievementUnlocked: return GW.gold
        }
    }

    private func timeLabel(_ d: Date) -> String {
        let cal = Calendar.current
        let f = DateFormatter()
        if cal.isDateInToday(d) {
            f.dateFormat = "HH:mm"
            return f.string(from: d)
        } else if cal.isDateInYesterday(d) {
            return "Yest."
        } else {
            f.dateFormat = "d MMM"
            return f.string(from: d)
        }
    }

    private func questRow(_ q: DailyQuest) -> some View {
        let progress = q.normalizedProgress
        let primaryStat = q.targetStats.first?.rawValue ?? "—"
        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(progress > 0 ? GW.cyan.opacity(0.07) : .clear)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(progress > 0 ? GW.cyan.opacity(0.67) : Color.white.opacity(0.12),
                            lineWidth: 1)
                Text("\(Int(progress * 100))")
                    .font(GW.mono(9, weight: .medium))
                    .foregroundStyle(progress > 0 ? GW.cyan : GW.mute)
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(q.title)
                    .font(GW.sans(13, weight: .medium))
                    .foregroundStyle(GW.ink)
                    .lineLimit(1)
                Text("\(primaryStat) · +\(q.xpReward) XP · +\(q.goldReward)g")
                    .font(GW.mono(9))
                    .tracking(0.5)
                    .foregroundStyle(GW.mute)
            }
            Spacer(minLength: 6)
            GWPill(text: progress > 0 ? "RESUME" : "RUN",
                   color: GW.cyan,
                   bg: GW.cyan.opacity(0.07),
                   border: GW.cyan.opacity(0.33))
        }
    }
}

// MARK: - Bridges StatType → Glasswork radar

private extension StatType {
    var displayName: String {
        switch self {
        case .strength:     return "Strength"
        case .intelligence: return "Intelligence"
        case .agility:      return "Agility"
        case .vitality:     return "Vitality"
        case .willpower:    return "Willpower"
        case .spirit:       return "Spirit"
        }
    }

    /// Hue used for boss-style tinting in Glasswork; matches the design's stat hues.
    var hue: Double {
        switch self {
        case .strength:     return 8
        case .intelligence: return 200
        case .agility:      return 152
        case .vitality:     return 24
        case .willpower:    return 280
        case .spirit:       return 46
        }
    }

    /// Solid tint per stat — used in places where a swatch is needed.
    var glassworkTint: Color {
        switch self {
        case .strength:     return GW.col("EF4444")
        case .intelligence: return GW.col("38BDF8")
        case .agility:      return GW.col("10B981")
        case .vitality:     return GW.col("FB923C")
        case .willpower:    return GW.col("A855F7")
        case .spirit:       return GW.col("EAB308")
        }
    }
}
