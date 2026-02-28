//
//  StatusView.swift
//  GAMELIFE
//
//  [SYSTEM]: Status window activated.
//  Your power level is now visible.
//

import SwiftUI

enum StatusStatDisplayMode: String, CaseIterable {
    case radar
    case grid
}

enum StatusDashboardTab: String, CaseIterable {
    case activity
    case achievements
}

// MARK: - Status View

/// Tab 1: Player profile with compact radar chart, stats, and recent activity.
/// Designed to fit on-screen without vertical scrolling.
@MainActor
struct StatusView: View {

    @EnvironmentObject var gameEngine: GameEngine
    @State private var showTrophyRoom = false
    @AppStorage("statusStatDisplayMode") private var statDisplayModeRaw = StatusStatDisplayMode.radar.rawValue
    @AppStorage("statusDashboardTab") private var dashboardTabRaw = StatusDashboardTab.activity.rawValue

    private var statDisplayModeBinding: Binding<StatusStatDisplayMode> {
        Binding(
            get: { StatusStatDisplayMode(rawValue: statDisplayModeRaw) ?? .radar },
            set: { statDisplayModeRaw = $0.rawValue }
        )
    }

    private var dashboardTabBinding: Binding<StatusDashboardTab> {
        Binding(
            get: { StatusDashboardTab(rawValue: dashboardTabRaw) ?? .activity },
            set: { dashboardTabRaw = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                // Geometry inside TabView already reflects available content space.
                // Use that directly so we don't double-subtract tab bar/safe areas.
                let availableHeight = max(420, geometry.size.height)
                let isCompactHeight = availableHeight < 720
                let isLargeHeight = availableHeight >= 860

                let stackSpacing = isCompactHeight ? 10.0 : (isLargeHeight ? 18.0 : 14.0)
                let headerHeight = max(82, min(availableHeight * (isCompactHeight ? 0.15 : 0.165), isLargeHeight ? 136 : 124))
                let statModuleHeight = max(196, min(availableHeight * (isCompactHeight ? 0.39 : 0.42), isLargeHeight ? 382 : 338))
                let bottomPadding = isCompactHeight ? 8.0 : 12.0
                let remainingBottomHeight = availableHeight - headerHeight - statModuleHeight - (stackSpacing * 2) - bottomPadding
                let bottomSectionHeight = max(0, remainingBottomHeight)
                VStack(spacing: stackSpacing) {
                    CompactHeaderView(player: gameEngine.player, isCompact: isCompactHeight)
                        .onTapGesture {
                            showTrophyRoom = true
                        }
                        .frame(height: headerHeight)

                    StatusStatModule(
                        stats: gameEngine.player.statArray,
                        isCompact: isCompactHeight,
                        isLargeHeight: isLargeHeight,
                        containerHeight: statModuleHeight,
                        displayMode: statDisplayModeBinding
                    )
                    .frame(height: statModuleHeight)
                    .padding(.horizontal, SystemSpacing.md)

                    StatusTabbedBottomSection(
                        recentAchievements: recentUnlockedAchievements,
                        activities: gameEngine.recentActivity,
                        isCompact: isCompactHeight,
                        isLargeHeight: isLargeHeight,
                        containerHeight: bottomSectionHeight,
                        selectedTab: dashboardTabBinding,
                        onOpenTrophyRoom: {
                            showTrophyRoom = true
                        }
                    )
                    .frame(height: bottomSectionHeight, alignment: .top)
                }
                .padding(.bottom, bottomPadding)
            }
            .background(SystemTheme.backgroundPrimary)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(SystemTheme.textSecondary)
                    }
                }
            }
            .toolbarBackground(SystemTheme.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(isPresented: $showTrophyRoom) {
                TrophyRoomView()
                    .environmentObject(gameEngine)
            }
        }
    }

    private var recentUnlockedAchievements: [AchievementDefinition] {
        let unlockedIDs = gameEngine.player.unlockedAchievements
            .sorted(by: { $0.unlockedAt > $1.unlockedAt })
            .map(\.id)
        let recentIDs = Array(unlockedIDs.prefix(5))
        return recentIDs.compactMap(AchievementCatalog.definition(for:))
    }
}

// MARK: - Compact Header View

struct CompactHeaderView: View {
    let player: Player
    let isCompact: Bool

    @State private var glowIntensity: Double = 0.5

    private var xpProgress: Double {
        min(1, max(0, player.xpProgress))
    }

    var body: some View {
        HStack(spacing: isCompact ? SystemSpacing.sm : SystemSpacing.md) {
            ZStack {
                Circle()
                    .fill(player.rank.glowColor.opacity(0.2))
                    .frame(width: isCompact ? 44 : 50, height: isCompact ? 44 : 50)

                Circle()
                    .stroke(player.rank.glowColor, lineWidth: 2)
                    .frame(width: isCompact ? 44 : 50, height: isCompact ? 44 : 50)
                    .glow(color: player.rank.glowColor, radius: 6 * glowIntensity)

                Text(player.rank.rawValue)
                    .font(SystemTypography.mono(isCompact ? 14 : 16, weight: .bold))
                    .foregroundStyle(player.rank.glowColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(isCompact ? SystemTypography.bodySmall : SystemTypography.headline)
                    .foregroundStyle(SystemTheme.textPrimary)
                    .lineLimit(1)
                    .layoutPriority(1)

                HStack(spacing: 6) {
                    Text("Lv. \(player.level)")
                        .font(SystemTypography.mono(isCompact ? 12 : 13, weight: .bold))
                        .foregroundStyle(SystemTheme.primaryBlue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: true, vertical: false)
                        .layoutPriority(2)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(SystemTheme.backgroundSecondary)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(SystemTheme.xpGradient)
                                .frame(width: geo.size.width * xpProgress)
                        }
                    }
                    .frame(width: isCompact ? 68 : 80, height: 6)
                    .layoutPriority(0)
                }

                Text("\(player.currentXP)/\(player.xpRequiredForNextLevel) XP")
                    .font(SystemTypography.captionSmall)
                    .foregroundStyle(SystemTheme.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: isCompact ? 13 : 14))
                        .foregroundStyle(SystemTheme.goldColor)

                    Text("\(player.gold)")
                        .font(SystemTypography.mono(isCompact ? 13 : 14, weight: .bold))
                        .foregroundStyle(SystemTheme.goldColor)
                }

                if player.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(SystemTheme.warningOrange)

                        Text("\(player.currentStreak)d")
                            .font(SystemTypography.mono(12, weight: .semibold))
                            .foregroundStyle(SystemTheme.warningOrange)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: isCompact ? 11 : 12))
                        .foregroundStyle(SystemTheme.criticalRed)

                    Text("\(player.currentHP)/\(player.maxHP)")
                        .font(SystemTypography.mono(isCompact ? 11 : 12, weight: .semibold))
                        .foregroundStyle(SystemTheme.criticalRed)
                }
            }
        }
        .padding(.horizontal, SystemSpacing.md)
        .padding(.vertical, isCompact ? SystemSpacing.xs : SystemSpacing.sm)
        .background(SystemTheme.backgroundSecondary)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowIntensity = 1.0
            }
        }
    }
}

// MARK: - Stat Module

struct StatusStatModule: View {
    let stats: [Stat]
    let isCompact: Bool
    let isLargeHeight: Bool
    let containerHeight: CGFloat
    @Binding var displayMode: StatusStatDisplayMode

    var body: some View {
        let cardPadding = isCompact ? SystemSpacing.sm : SystemSpacing.md
        let headerHeight: CGFloat = isCompact ? 28 : 32
        let contentHeight = max(100, containerHeight - (cardPadding * 2) - headerHeight - 4)

        VStack(alignment: .leading, spacing: isCompact ? 8 : 10) {
            HStack {
                Text("Attributes")
                    .font(SystemTypography.mono(isCompact ? 12 : 13, weight: .bold))
                    .foregroundStyle(SystemTheme.primaryBlue)

                Spacer()

                HStack(spacing: 6) {
                    StatusToggleChip(
                        icon: "hexagon",
                        isSelected: displayMode == .radar
                    ) {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            displayMode = .radar
                        }
                    }

                    StatusToggleChip(
                        icon: "list.bullet.rectangle",
                        isSelected: displayMode == .grid
                    ) {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            displayMode = .grid
                        }
                    }
                }
            }

            Group {
                if displayMode == .radar {
                    HStack {
                        Spacer(minLength: 0)
                        RadarChartView(stats: stats)
                            .frame(maxWidth: contentHeight * 1.05)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    let rowSpacing = isCompact ? SystemSpacing.xs : SystemSpacing.sm
                    let maxRowHeight: CGFloat = isCompact ? 54 : (isLargeHeight ? 60 : 56)
                    let minRowHeight: CGFloat = isCompact ? 38 : 42
                    let computedRowHeight = (contentHeight - (rowSpacing * 2)) / 3
                    let rowHeight = max(minRowHeight, min(maxRowHeight, computedRowHeight))

                    CompactAttributeGrid(
                        stats: stats,
                        isCompact: isCompact,
                        rowHeight: rowHeight
                    )
                    .frame(maxHeight: contentHeight)
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(cardPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(SystemTheme.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: SystemRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: SystemRadius.medium)
                .stroke(SystemTheme.borderSecondary, lineWidth: 1)
        )
    }
}

private struct StatusToggleChip: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isSelected ? SystemTheme.backgroundPrimary : SystemTheme.textSecondary)
                .frame(width: 30, height: 24)
                .background(isSelected ? SystemTheme.primaryBlue : SystemTheme.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tabbed Bottom Section

struct StatusTabbedBottomSection: View {
    let recentAchievements: [AchievementDefinition]
    let activities: [ActivityLogEntry]
    let isCompact: Bool
    let isLargeHeight: Bool
    let containerHeight: CGFloat
    @Binding var selectedTab: StatusDashboardTab
    let onOpenTrophyRoom: () -> Void

    var body: some View {
        let verticalPadding = isCompact ? SystemSpacing.xs : SystemSpacing.sm
        let cardPadding = isCompact ? SystemSpacing.sm : SystemSpacing.md
        let innerHeight = max(0, containerHeight - (verticalPadding * 2))
        let contentHeight = max(0, innerHeight - (cardPadding * 2) - (isCompact ? 30 : 34))
        let maxActivityRows = isCompact ? 2 : (isLargeHeight ? 4 : 3)

        VStack(alignment: .leading, spacing: isCompact ? 8 : 10) {
            HStack(spacing: 8) {
                StatusTabChip(
                    title: "Activity Log",
                    isSelected: selectedTab == .activity
                ) {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedTab = .activity
                    }
                }

                StatusTabChip(
                    title: "Achievements",
                    isSelected: selectedTab == .achievements
                ) {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedTab = .achievements
                    }
                }

                Spacer()

                if selectedTab == .achievements {
                    Button("View All") {
                        onOpenTrophyRoom()
                    }
                    .font(SystemTypography.caption)
                    .foregroundStyle(SystemTheme.accentCyan)
                }
            }

            Group {
                if selectedTab == .activity {
                    if activities.isEmpty {
                        Text("No recent activity yet. Complete a quest to populate your log.")
                            .font(SystemTypography.captionSmall)
                            .foregroundStyle(SystemTheme.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        VStack(alignment: .leading, spacing: isCompact ? 6 : SystemSpacing.xs) {
                            ForEach(Array(activities.prefix(maxActivityRows))) { entry in
                                ActivityRow(entry: entry, isCompact: isCompact)
                            }
                        }
                    }
                } else {
                    if recentAchievements.isEmpty {
                        Text("No badges unlocked yet. Complete quests and boss fights to earn your first trophy.")
                            .font(SystemTypography.captionSmall)
                            .foregroundStyle(SystemTheme.textSecondary)
                            .lineLimit(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(recentAchievements.prefix(isCompact ? 4 : 6)) { achievement in
                                    HStack(spacing: 6) {
                                        Image(systemName: achievement.icon)
                                            .font(.system(size: isCompact ? 12 : 13, weight: .bold))
                                        Text(achievement.title)
                                            .font(SystemTypography.captionSmall)
                                            .lineLimit(1)
                                    }
                                    .foregroundStyle(achievement.rarity.color)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(SystemTheme.backgroundSecondary.opacity(0.6))
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: contentHeight, alignment: .topLeading)
        }
        .padding(cardPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(SystemTheme.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: SystemRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: SystemRadius.medium)
                .stroke(SystemTheme.borderSecondary, lineWidth: 1)
        )
        .padding(.horizontal, SystemSpacing.md)
        .padding(.vertical, verticalPadding)
    }
}

private struct StatusTabChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(SystemTypography.mono(11, weight: .bold))
                .foregroundStyle(isSelected ? SystemTheme.primaryBlue : SystemTheme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? SystemTheme.backgroundSecondary : Color.clear)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? SystemTheme.borderSecondary : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bottom Section

struct StatusBottomSection: View {
    let stats: [Stat]
    let recentAchievements: [AchievementDefinition]
    let activities: [ActivityLogEntry]
    let isCompact: Bool
    let isLargeHeight: Bool
    let containerHeight: CGFloat
    let isActivityLogExpanded: Bool
    let onOpenTrophyRoom: () -> Void
    let onToggleActivityLog: () -> Void

    var body: some View {
        let sectionSpacing = isCompact ? SystemSpacing.sm : (isLargeHeight ? SystemSpacing.md : SystemSpacing.sm)
        let verticalPadding = isCompact ? SystemSpacing.xs : SystemSpacing.sm
        let innerHeight = max(0, containerHeight - (verticalPadding * 2))
        let achievementsHeight: CGFloat = isCompact ? 72 : 86
        let collapsedActivityHeight: CGFloat = isCompact ? 56 : 64
        let minGridHeight: CGFloat = isCompact ? 148 : 176
        let preferredExpandedHeight = innerHeight * (isCompact ? 0.34 : 0.38)
        let maxExpandedHeight = max(collapsedActivityHeight, innerHeight - minGridHeight - (sectionSpacing * 2) - achievementsHeight)
        let expandedActivityHeight = min(maxExpandedHeight, preferredExpandedHeight)
        let activityHeight = isActivityLogExpanded ? max(collapsedActivityHeight, expandedActivityHeight) : collapsedActivityHeight
        let gridHeight = max(0, innerHeight - activityHeight - achievementsHeight - (sectionSpacing * 2))

        let rowSpacing = isCompact ? SystemSpacing.xs : SystemSpacing.sm
        let maxRowHeight: CGFloat = isCompact ? 54 : (isLargeHeight ? 60 : 56)
        let minRowHeight: CGFloat = isCompact ? 38 : 42
        let computedRowHeight = (gridHeight - (rowSpacing * 2)) / 3
        let rowHeight = max(minRowHeight, min(maxRowHeight, computedRowHeight))
        VStack(spacing: sectionSpacing) {
            CompactAttributeGrid(
                stats: stats,
                isCompact: isCompact,
                rowHeight: rowHeight
            )
                .frame(height: gridHeight)
                .clipped()

            RecentAchievementsStrip(
                achievements: recentAchievements,
                isCompact: isCompact,
                onOpenTrophyRoom: onOpenTrophyRoom
            )
            .frame(height: achievementsHeight)

            RecentActivityLogCard(
                entries: activities,
                isCompact: isCompact,
                isExpanded: isActivityLogExpanded,
                onToggle: onToggleActivityLog,
                expandedContentMaxHeight: max(0, activityHeight - (isCompact ? 54 : 60))
            )
                .frame(height: activityHeight, alignment: .top)
                .clipped()
        }
        .padding(.horizontal, SystemSpacing.md)
        .padding(.vertical, verticalPadding)
    }
}

// MARK: - Compact Attribute Grid

struct CompactAttributeGrid: View {
    let stats: [Stat]
    let isCompact: Bool
    let rowHeight: CGFloat

    private let columns = [
        GridItem(.flexible(), spacing: SystemSpacing.sm),
        GridItem(.flexible(), spacing: SystemSpacing.sm)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: isCompact ? SystemSpacing.xs : SystemSpacing.sm) {
            ForEach(stats) { stat in
                CompactStatRow(
                    stat: stat,
                    isCompact: isCompact,
                    rowHeight: rowHeight
                )
            }
        }
    }
}

// MARK: - Compact Stat Row

struct CompactStatRow: View {
    let stat: Stat
    let isCompact: Bool
    let rowHeight: CGFloat

    private var normalizedProgress: Double {
        min(1.0, max(0.0, Double(stat.totalValue) / 100.0))
    }

    var body: some View {
        HStack(spacing: SystemSpacing.xs) {
            Image(systemName: stat.type.icon)
                .font(.system(size: isCompact ? 14 : 16))
                .foregroundStyle(stat.type.color)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(stat.type.rawValue)
                        .font(SystemTypography.mono(isCompact ? 11 : 12, weight: .bold))
                        .foregroundStyle(stat.type.color)

                    Spacer()

                    Text("\(stat.totalValue)")
                        .font(SystemTypography.mono(isCompact ? 13 : 14, weight: .bold))
                        .foregroundStyle(SystemTheme.textPrimary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(SystemTheme.backgroundSecondary)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(stat.type.color.opacity(0.7))
                            .frame(width: max(0, geo.size.width * normalizedProgress))
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(.horizontal, isCompact ? SystemSpacing.xs : SystemSpacing.sm)
        .padding(.vertical, isCompact ? 7 : SystemSpacing.xs)
        .frame(height: rowHeight, alignment: .center)
        .background(SystemTheme.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: SystemRadius.small))
    }
}

// MARK: - Recent Activity

struct RecentActivityLogCard: View {
    let entries: [ActivityLogEntry]
    let isCompact: Bool
    let isExpanded: Bool
    let onToggle: () -> Void
    let expandedContentMaxHeight: CGFloat

    private var emptyStateText: String {
        "No recent activity yet. Complete a quest to populate your log."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 6 : SystemSpacing.sm) {
            Button(action: onToggle) {
                HStack(spacing: SystemSpacing.xs) {
                    Text("Recent Activity Log")
                        .font(SystemTypography.mono(isCompact ? 12 : 13, weight: .bold))
                        .foregroundStyle(SystemTheme.primaryBlue)

                    Spacer()

                    if !entries.isEmpty {
                        Text("\(entries.count)")
                            .font(SystemTypography.mono(isCompact ? 11 : 12, weight: .semibold))
                            .foregroundStyle(SystemTheme.textSecondary)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: isCompact ? 11 : 12, weight: .semibold))
                        .foregroundStyle(SystemTheme.primaryBlue)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                if entries.isEmpty {
                    Text(emptyStateText)
                        .font(SystemTypography.captionSmall)
                        .foregroundStyle(SystemTheme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(alignment: .leading, spacing: isCompact ? 6 : SystemSpacing.xs) {
                            ForEach(entries) { entry in
                                ActivityRow(entry: entry, isCompact: isCompact)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: expandedContentMaxHeight)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(isCompact ? SystemSpacing.sm : SystemSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SystemTheme.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: SystemRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: SystemRadius.medium)
                .stroke(SystemTheme.borderSecondary, lineWidth: 1)
        )
    }
}

struct ActivityRow: View {
    let entry: ActivityLogEntry
    let isCompact: Bool

    var body: some View {
        HStack(alignment: .top, spacing: SystemSpacing.xs) {
            Image(systemName: entry.type.icon)
                .font(.system(size: isCompact ? 11 : 12, weight: .semibold))
                .foregroundStyle(entry.type.color)
                .frame(width: 16, height: 16)
                .padding(4)
                .background(entry.type.color.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(SystemTypography.bodySmall)
                    .foregroundStyle(SystemTheme.textPrimary)
                    .lineLimit(1)

                Text(entry.detail)
                    .font(SystemTypography.captionSmall)
                    .foregroundStyle(SystemTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            Text(entry.timestamp, style: .relative)
                .font(SystemTypography.captionSmall)
                .foregroundStyle(SystemTheme.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

// MARK: - Achievements

struct RecentAchievementsStrip: View {
    let achievements: [AchievementDefinition]
    let isCompact: Bool
    let onOpenTrophyRoom: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 6 : 8) {
            HStack {
                Text("Recent Achievements")
                    .font(SystemTypography.mono(isCompact ? 12 : 13, weight: .bold))
                    .foregroundStyle(SystemTheme.primaryBlue)

                Spacer()

                Button("View All") {
                    onOpenTrophyRoom()
                }
                .font(SystemTypography.caption)
                .foregroundStyle(SystemTheme.accentCyan)
            }

            if achievements.isEmpty {
                Text("No badges unlocked yet. Complete quests and boss fights to earn your first trophy.")
                    .font(SystemTypography.captionSmall)
                    .foregroundStyle(SystemTheme.textSecondary)
                    .lineLimit(2)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(achievements) { achievement in
                            HStack(spacing: 6) {
                                Image(systemName: achievement.icon)
                                    .font(.system(size: isCompact ? 12 : 13, weight: .bold))
                                Text(achievement.title)
                                    .font(SystemTypography.captionSmall)
                                    .lineLimit(1)
                            }
                            .foregroundStyle(achievement.rarity.color)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(SystemTheme.backgroundSecondary.opacity(0.6))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(isCompact ? 10 : 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SystemTheme.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: SystemRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: SystemRadius.medium)
                .stroke(SystemTheme.borderSecondary, lineWidth: 1)
        )
    }
}

struct TrophyRoomView: View {
    @EnvironmentObject private var gameEngine: GameEngine
    @State private var selectedDefinition: AchievementDefinition?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var unlockedSet: Set<String> {
        Set(gameEngine.player.unlockedAchievements.map(\.id))
    }

    private var unlockedCount: Int {
        unlockedSet.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Trophy Room")
                    .font(SystemTypography.titleSmall)
                    .foregroundStyle(SystemTheme.textPrimary)

                Text("\(unlockedCount)/\(AchievementCatalog.all.count) unlocked")
                    .font(SystemTypography.caption)
                    .foregroundStyle(SystemTheme.textSecondary)

                ForEach(AchievementCategory.allCases) { category in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(category.title)
                            .font(SystemTypography.headline)
                            .foregroundStyle(SystemTheme.textPrimary)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(AchievementCatalog.all.filter { $0.category == category }) { achievement in
                                let unlocked = unlockedSet.contains(achievement.id)
                                let progress = gameEngine.achievementProgress(for: achievement.id)

                                Button {
                                    selectedDefinition = achievement
                                } label: {
                                    TrophyBadgeCell(
                                        achievement: achievement,
                                        unlocked: unlocked,
                                        progress: progress
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(SystemSpacing.md)
        }
        .background(SystemTheme.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Trophies")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $selectedDefinition) { achievement in
            let progress = gameEngine.achievementProgress(for: achievement.id)
            let unlocked = unlockedSet.contains(achievement.id)

            return Alert(
                title: Text(achievement.title),
                message: Text(
                    unlocked
                    ? "\(achievement.description)\n\nUnlocked."
                    : "\(achievement.description)\n\n\(achievement.requirementText)\nProgress: \(progress.current)/\(progress.target)"
                ),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

private struct TrophyBadgeCell: View {
    let achievement: AchievementDefinition
    let unlocked: Bool
    let progress: AchievementProgress

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Hexagon()
                    .fill(
                        unlocked
                        ? achievement.rarity.color.opacity(0.18)
                        : SystemTheme.backgroundSecondary.opacity(0.6)
                    )
                    .overlay(
                        Hexagon()
                            .stroke(
                                unlocked ? achievement.rarity.color : SystemTheme.textTertiary.opacity(0.4),
                                lineWidth: unlocked ? 2 : 1
                            )
                    )
                    .frame(width: 78, height: 84)

                Image(systemName: achievement.icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(unlocked ? achievement.rarity.color : SystemTheme.textTertiary)
            }

            Text(achievement.title)
                .font(SystemTypography.captionSmall)
                .foregroundStyle(unlocked ? SystemTheme.textPrimary : SystemTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity)

            if unlocked {
                Text(achievement.rarity.displayName)
                    .font(SystemTypography.mono(10, weight: .bold))
                    .foregroundStyle(achievement.rarity.color)
            } else {
                Text("\(progress.current)/\(progress.target)")
                    .font(SystemTypography.mono(10, weight: .semibold))
                    .foregroundStyle(SystemTheme.textTertiary)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 148)
        .background(SystemTheme.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: SystemRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: SystemRadius.medium)
                .stroke(SystemTheme.borderSecondary, lineWidth: 1)
        )
    }
}

private struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let points = [
            CGPoint(x: 0.5 * w, y: 0),
            CGPoint(x: w, y: 0.25 * h),
            CGPoint(x: w, y: 0.75 * h),
            CGPoint(x: 0.5 * w, y: h),
            CGPoint(x: 0, y: 0.75 * h),
            CGPoint(x: 0, y: 0.25 * h)
        ]

        var path = Path()
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    StatusView()
        .environmentObject(GameEngine.shared)
}
