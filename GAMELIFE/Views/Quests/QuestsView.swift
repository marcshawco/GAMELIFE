//
//  QuestsView.swift
//  GAMELIFE
//
//  [SYSTEM]: Quest log accessed.
//  Complete your missions to grow stronger, Hunter.
//

import SwiftUI
import Combine
import UIKit

// MARK: - Quests View

/// Tab 2: Daily Quests with CRUD operations
struct QuestsView: View {

    // MARK: - Properties

    @EnvironmentObject var gameEngine: GameEngine
    @EnvironmentObject var deepLinkManager: DeepLinkManager
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var permissionManager = PermissionManager.shared
    @State private var showAddSheet = false
    @State private var questToEdit: DailyQuest?
    @State private var showDeleteConfirmation = false
    @State private var questToDelete: DailyQuest?
    @State private var questActionTarget: DailyQuest?
    @State private var showUndoBanner = false
    @State private var undoBannerTitle = ""
    @State private var undoDismissTask: Task<Void, Never>?
    @State private var isRefreshingExternalTracking = false
    @State private var liveProgressTick = Date()
    @State private var highlightedQuestID: UUID?
    @AppStorage("quests.nextUpCollapsed") private var isNextUpCollapsed = false
    @AppStorage("quests.progressGridCollapsed") private var isProgressGridCollapsed = false
    @AppStorage("showQuestCompletionGrid") private var showQuestCompletionGrid = true
    @AppStorage("showQuestNextUpSection") private var showQuestNextUpSection = true

    private var sortedQuests: [DailyQuest] {
        gameEngine.dailyQuests.sorted { lhs, rhs in
            let l = questPriorityScore(lhs)
            let r = questPriorityScore(rhs)
            if l == r {
                return lhs.title < rhs.title
            }
            return l > r
        }
    }

    private var nextUpQuests: [DailyQuest] {
        sortedQuests
            .filter { $0.status != .completed }
            .prefix(3)
            .map { $0 }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                SystemTheme.backgroundPrimary
                    .ignoresSafeArea()

                if gameEngine.dailyQuests.isEmpty {
                    EmptyQuestState(onCreateTapped: { showAddSheet = true })
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: SystemSpacing.sm) {
                                QuestSummaryHeader(
                                    quests: gameEngine.dailyQuests,
                                    questHistory: QuestDataManager.shared.loadQuestHistory(),
                                    showsGrid: showQuestCompletionGrid,
                                    isGridCollapsed: $isProgressGridCollapsed
                                )
                                    .padding(.horizontal)
                                    .padding(.top, SystemSpacing.sm)

                                if showQuestNextUpSection && !nextUpQuests.isEmpty {
                                    NextUpSection(
                                        quests: nextUpQuests,
                                        bossImpactText: bossImpactText(for:),
                                        rewardImpactText: rewardImpactText(for:),
                                        streakImpactText: streakImpactText(for:),
                                        isCollapsed: $isNextUpCollapsed
                                    )
                                    .padding(.horizontal)
                                }

                                ForEach(sortedQuests) { quest in
                                    QuestRowView(
                                        quest: quest,
                                        locationManager: locationManager,
                                        healthKitManager: healthKitManager,
                                        permissionManager: permissionManager,
                                        liveProgressTick: liveProgressTick,
                                        impactBossText: bossImpactText(for: quest),
                                        impactRewardsText: rewardImpactText(for: quest),
                                        impactStreakText: streakImpactText(for: quest),
                                        onComplete: { completeQuest(quest) },
                                        onSubtaskComplete: { subtask in completeSubtask(subtask, in: quest) },
                                        onShowActions: { questActionTarget = quest }
                                    )
                                    .padding(.horizontal)
                                    .id(quest.id)
                                    .overlay {
                                        if highlightedQuestID == quest.id {
                                            RoundedRectangle(cornerRadius: SystemRadius.medium)
                                                .stroke(SystemTheme.primaryBlue, lineWidth: 2)
                                                .padding(.horizontal, SystemSpacing.sm)
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, SystemSpacing.lg)
                        }
                        .refreshable {
                            await refreshExternalTracking()
                        }
                        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { now in
                            liveProgressTick = now
                        }
                        .onChange(of: deepLinkManager.pendingLink) { _, link in
                            guard let link else { return }
                            guard case let .quests(questID) = link.route else { return }
                            guard let questID else { return }

                            highlightedQuestID = questID
                            withAnimation(.easeInOut(duration: 0.25)) {
                                proxy.scrollTo(questID, anchor: .top)
                            }

                            Task {
                                try? await Task.sleep(nanoseconds: 3_000_000_000)
                                await MainActor.run {
                                    if highlightedQuestID == questID {
                                        highlightedQuestID = nil
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Quests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(SystemTheme.primaryBlue)
                    }
                }
            }
            .toolbarBackground(SystemTheme.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showAddSheet) {
                QuestFormSheet(mode: .add)
            }
            .sheet(item: $questToEdit) { quest in
                QuestFormSheet(mode: .edit(quest))
            }
            .alert("Delete Quest?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    questToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let quest = questToDelete {
                        deleteQuest(quest)
                    }
                }
            } message: {
                Text("This action cannot be undone.")
            }
            .confirmationDialog(
                "Quest Actions",
                isPresented: Binding(
                    get: { questActionTarget != nil },
                    set: { isPresented in
                        if !isPresented {
                            questActionTarget = nil
                        }
                    }
                ),
                presenting: questActionTarget
            ) { quest in
                Button("Edit Quest") {
                    questToEdit = quest
                    questActionTarget = nil
                }
                Button("Delete Quest", role: .destructive) {
                    questToDelete = quest
                    showDeleteConfirmation = true
                    questActionTarget = nil
                }
                Button("Cancel", role: .cancel) {
                    questActionTarget = nil
                }
            } message: { quest in
                Text(quest.title)
            }
            .overlay(alignment: .bottom) {
                if showUndoBanner {
                    QuestUndoBanner(
                        title: undoBannerTitle,
                        onUndo: {
                            if gameEngine.undoLastQuestCompletion() {
                                dismissUndoBanner()
                            }
                        },
                        onDismiss: dismissUndoBanner
                    )
                    .padding(.horizontal, SystemSpacing.md)
                    .padding(.bottom, 72)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .onDisappear {
                undoDismissTask?.cancel()
                undoDismissTask = nil
            }
        }
    }

    // MARK: - Actions

    private func completeQuest(_ quest: DailyQuest) {
        let result = gameEngine.completeQuest(quest)
        presentCompletionResult(result, fallbackTitle: quest.title)
    }

    private func completeSubtask(_ subtask: QuestSubtask, in quest: DailyQuest) {
        let result = gameEngine.completeQuestSubtask(questID: quest.id, subtaskID: subtask.id)
        presentCompletionResult(result, fallbackTitle: subtask.title)
    }

    private func presentCompletionResult(_ result: QuestCompletionResult, fallbackTitle: String) {
        if result.success {
            SystemMessageHelper.showQuestComplete(
                title: result.isCritical ? "Critical Success!" : result.message,
                xp: result.xpAwarded,
                gold: result.goldAwarded
            )

            if gameEngine.canUndoLatestQuestCompletion {
                undoBannerTitle = gameEngine.lastUndoQuestTitle ?? fallbackTitle
                withAnimation(.easeInOut(duration: 0.2)) {
                    showUndoBanner = true
                }
                scheduleUndoBannerAutoDismiss()
            }
        } else {
            HapticManager.shared.warning()
            SystemMessageHelper.showWarning(result.message)
        }
    }

    private func deleteQuest(_ quest: DailyQuest) {
        gameEngine.deleteQuest(quest.id)
        questToDelete = nil
    }

    private func dismissUndoBanner() {
        undoDismissTask?.cancel()
        undoDismissTask = nil
        withAnimation(.easeInOut(duration: 0.2)) {
            showUndoBanner = false
        }
    }

    private func scheduleUndoBannerAutoDismiss() {
        undoDismissTask?.cancel()
        undoDismissTask = Task {
            try? await Task.sleep(nanoseconds: 20_000_000_000)
            await MainActor.run {
                dismissUndoBanner()
            }
        }
    }

    @MainActor
    private func refreshExternalTracking() async {
        guard !isRefreshingExternalTracking else { return }
        isRefreshingExternalTracking = true
        defer {
            isRefreshingExternalTracking = false
        }

        locationManager.requestSingleLocationRefresh()

        await runWithTimeout(seconds: 20) {
            await gameEngine.refreshExternalTrackingTransaction()
        }
    }

    @MainActor
    private func runWithTimeout(seconds: TimeInterval, _ operation: @escaping @Sendable () async -> Void) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await operation()
            }

            group.addTask {
                let nanos = UInt64(max(1, seconds) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanos)
            }

            await group.next()
            group.cancelAll()
        }
    }

    private func questPriorityScore(_ quest: DailyQuest) -> Double {
        guard quest.status != .completed else { return -10_000 }

        let now = Date()
        let secondsLeft = max(60, quest.expiresAt.timeIntervalSince(now))
        let dueSoonScore = 250_000 / secondsLeft

        let bossImpact = Double(estimatedBossDamage(for: quest))
        let streakRisk = (!quest.isOptional && quest.resolvedFrequency == .daily)
            ? (1.0 - quest.normalizedProgress) * 40.0
            : 0

        let rewardValue = Double(quest.xpReward) + Double(quest.isOptional ? 0 : quest.goldReward * 3)
        return dueSoonScore + (bossImpact * 1.6) + streakRisk + (rewardValue * 0.3)
    }

    private func estimatedBossDamage(for quest: DailyQuest) -> Int {
        guard let linkedBossID = quest.linkedBossID,
              let boss = gameEngine.activeBossFights.first(where: { $0.id == linkedBossID && !$0.isDefeated }) else {
            return 0
        }
        let baseDamage = GameFormulas.bossDamage(taskDifficulty: quest.difficulty, playerLevel: gameEngine.player.level)
        let estimated = max(1, Int(Double(baseDamage) * 0.8))
        return min(estimated, boss.currentHP)
    }

    private func bossImpactText(for quest: DailyQuest) -> String? {
        guard let linkedBossID = quest.linkedBossID,
              let boss = gameEngine.activeBossFights.first(where: { $0.id == linkedBossID && !$0.isDefeated }) else {
            return nil
        }
        let damage = estimatedBossDamage(for: quest)
        return "Deals \(damage) HP to \(boss.title)"
    }

    private func rewardImpactText(for quest: DailyQuest) -> String {
        if quest.isOptional {
            return "+\(quest.xpReward) XP (Optional)"
        }
        return "+\(quest.xpReward) XP, +\(quest.goldReward) Gold"
    }

    private func streakImpactText(for quest: DailyQuest) -> String {
        if quest.isOptional {
            return "Streak-safe (optional)"
        }
        return "Streak: \(gameEngine.player.currentStreak) days"
    }
}

private func uiSafeUnitProgress(_ value: Double) -> Double {
    guard value.isFinite else { return 0 }
    return min(1, max(0, value))
}

// MARK: - Quest Summary Header

struct QuestSummaryHeader: View {
    let quests: [DailyQuest]
    let questHistory: [QuestHistoryRecord]
    let showsGrid: Bool
    @Binding var isGridCollapsed: Bool

    private struct CompletionDay: Identifiable {
        let date: Date
        let count: Int

        var id: Date { date }
    }

    private struct MonthMarker: Identifiable {
        let id: Int
        let columnIndex: Int
        let label: String
        let xOffset: CGFloat?
    }

    private var completedCount: Int {
        quests.filter { $0.status == .completed }.count
    }

    private var totalCount: Int {
        quests.count
    }

    private var completionPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return min(1, max(0, Double(completedCount) / Double(totalCount)))
    }

    private var safeCompletionPercentage: CGFloat {
        let clamped = completionPercentage
        guard clamped.isFinite else { return 0 }
        return CGFloat(min(1, max(0, clamped)))
    }

    private var completionDays: [CompletionDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let daysToShow = 7 * 26
        let startDate = calendar.date(byAdding: .day, value: -(daysToShow - 1), to: today) ?? today

        let groupedCounts = Dictionary(grouping: questHistory) { record in
            calendar.startOfDay(for: record.completedAt)
        }.mapValues(\.count)

        return (0..<daysToShow).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startDate) else { return nil }
            return CompletionDay(date: date, count: groupedCounts[date, default: 0])
        }
    }

    private var weekColumns: [[CompletionDay]] {
        stride(from: 0, to: completionDays.count, by: 7).map { start in
            Array(completionDays[start..<min(start + 7, completionDays.count)])
        }
    }

    private var monthMarkers: [MonthMarker] {
        weekColumns.enumerated().compactMap { index, week in
            let label = monthLabel(for: week, index: index)
            guard !label.isEmpty else { return nil }
            return MonthMarker(id: index, columnIndex: index, label: label, xOffset: nil)
        }
    }

    private var maxDailyCompletions: Int {
        max(questHistory.map(\.completedAt).isEmpty ? 0 : completionDays.map(\.count).max() ?? 0, 1)
    }

    private var contributionSummaryText: String {
        let total = questHistory.count
        if total == 1 {
            return "1 quest cleared"
        }
        return "\(total) quests cleared"
    }

    var body: some View {
        VStack(spacing: SystemSpacing.sm) {
            if showsGrid {
                VStack(spacing: 0) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isGridCollapsed.toggle()
                        }
                        HapticManager.shared.selection()
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(contributionSummaryText)
                                    .font(SystemTypography.headline)
                                    .foregroundStyle(SystemTheme.textPrimary)

                                Text("Battle record")
                                    .font(SystemTypography.captionSmall)
                                    .foregroundStyle(SystemTheme.textSecondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                            }

                            Spacer()

                            Image(systemName: isGridCollapsed ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(SystemTheme.primaryBlue)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if !isGridCollapsed {
                        VStack(alignment: .leading, spacing: 12) {
                            GeometryReader { geometry in
                                let safeWidth = max(0, geometry.size.width.isFinite ? geometry.size.width : 0)
                                let metrics = heatmapMetrics(for: safeWidth)
                                let visibleMonthMarkers = visibleMonthMarkers(
                                    availableWidth: safeWidth,
                                    cellSize: metrics.cellSize,
                                    columnStride: metrics.columnStride
                                )

                                VStack(alignment: .leading, spacing: 8) {
                                    ZStack(alignment: .leading) {
                                        ForEach(visibleMonthMarkers) { marker in
                                            Text(marker.label)
                                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                                .foregroundStyle(SystemTheme.textTertiary)
                                                .offset(x: marker.xOffset ?? (CGFloat(marker.columnIndex) * metrics.columnStride))
                                        }
                                    }
                                    .frame(height: 14)

                                    HStack(alignment: .top, spacing: metrics.spacing) {
                                        ForEach(weekColumns.indices, id: \.self) { columnIndex in
                                            VStack(spacing: metrics.spacing) {
                                                ForEach(weekColumns[columnIndex]) { day in
                                                    RoundedRectangle(cornerRadius: 3)
                                                        .fill(color(for: day.count))
                                                        .frame(width: metrics.cellSize, height: metrics.cellSize)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 3)
                                                                .stroke(SystemTheme.borderSecondary.opacity(0.35), lineWidth: 0.5)
                                                        )
                                                        .accessibilityLabel(accessibilityLabel(for: day))
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(height: 112)
                            .padding(.vertical, 4)

                            HStack(spacing: 6) {
                                Text("Less")
                                    .font(SystemTypography.captionSmall)
                                    .foregroundStyle(SystemTheme.textTertiary)

                                ForEach(0..<5, id: \.self) { level in
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(legendColor(for: level))
                                        .frame(width: 12, height: 12)
                                }

                                Text("More")
                                    .font(SystemTypography.captionSmall)
                                    .foregroundStyle(SystemTheme.textTertiary)
                            }
                        }
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding()
                .background(SystemTheme.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: SystemRadius.medium))
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Progress")
                        .font(SystemTypography.caption)
                        .foregroundStyle(SystemTheme.textSecondary)

                    Text("\(completedCount)/\(totalCount) Complete")
                        .font(SystemTypography.mono(16, weight: .bold))
                        .foregroundStyle(SystemTheme.textPrimary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(SystemTheme.backgroundSecondary, lineWidth: 4)

                    Circle()
                        .trim(from: 0, to: safeCompletionPercentage)
                        .stroke(SystemTheme.primaryBlue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(safeCompletionPercentage * 100))%")
                        .font(SystemTypography.mono(12, weight: .bold))
                        .foregroundStyle(SystemTheme.primaryBlue)
                }
                .frame(width: 50, height: 50)
            }

            GeometryReader { geometry in
                let safeWidth = max(0, geometry.size.width.isFinite ? geometry.size.width : 0)

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(SystemTheme.backgroundSecondary)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(SystemTheme.xpGradient)
                        .frame(width: safeWidth * safeCompletionPercentage)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(SystemTheme.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: SystemRadius.medium))
    }

    private func monthLabel(for week: [CompletionDay], index: Int) -> String {
        guard let firstDay = week.first?.date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let label = formatter.string(from: firstDay)

        if index == 0 {
            return label
        }

        let previousMonth = Calendar.current.component(.month, from: weekColumns[index - 1].first?.date ?? firstDay)
        let currentMonth = Calendar.current.component(.month, from: firstDay)
        return previousMonth == currentMonth ? "" : label
    }

    private func visibleMonthMarkers(availableWidth: CGFloat, cellSize: CGFloat, columnStride: CGFloat) -> [MonthMarker] {
        guard availableWidth.isFinite, availableWidth > 0 else { return monthMarkers }

        var filtered: [MonthMarker] = []
        var lastAcceptedMaxX: CGFloat = -.infinity
        let horizontalInset: CGFloat = 4
        let minimumGap: CGFloat = 8

        for marker in monthMarkers {
            let labelWidth = monthLabelWidth(for: marker.label)
            let columnCenterX = (CGFloat(marker.columnIndex) * columnStride) + (cellSize / 2)
            let preferredOriginX = columnCenterX - (labelWidth / 2)
            let adjustedOriginX = min(
                max(horizontalInset, preferredOriginX),
                max(horizontalInset, availableWidth - labelWidth - horizontalInset)
            )

            if adjustedOriginX <= lastAcceptedMaxX + minimumGap {
                continue
            }

            filtered.append(
                MonthMarker(
                    id: marker.id,
                    columnIndex: marker.columnIndex,
                    label: marker.label,
                    xOffset: adjustedOriginX
                )
            )
            lastAcceptedMaxX = adjustedOriginX + labelWidth
        }

        return filtered
    }

    private func monthLabelWidth(for label: String) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 10, weight: .medium)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        return ceil((label as NSString).size(withAttributes: attributes).width)
    }

    private func heatmapMetrics(for availableWidth: CGFloat) -> (cellSize: CGFloat, spacing: CGFloat, columnStride: CGFloat) {
        guard availableWidth.isFinite, availableWidth > 0 else {
            return (cellSize: 8, spacing: 3, columnStride: 11)
        }

        let totalColumns = max(weekColumns.count, 1)
        let spacing: CGFloat = availableWidth > 360 ? 4 : 3
        let totalSpacing = spacing * CGFloat(max(totalColumns - 1, 0))
        let usableWidth = max(0, availableWidth - totalSpacing)
        let rawCellSize = floor(usableWidth / CGFloat(totalColumns))
        let cellSize = min(12, max(8, rawCellSize))
        return (cellSize: cellSize, spacing: spacing, columnStride: cellSize + spacing)
    }

    private func color(for count: Int) -> Color {
        guard count > 0 else {
            return SystemTheme.backgroundSecondary
        }

        let ratio = min(1, Double(count) / Double(maxDailyCompletions))
        switch ratio {
        case 0..<0.25:
            return SystemTheme.successGreen.opacity(0.25)
        case 0.25..<0.5:
            return SystemTheme.successGreen.opacity(0.45)
        case 0.5..<0.75:
            return SystemTheme.successGreen.opacity(0.7)
        default:
            return SystemTheme.successGreen
        }
    }

    private func legendColor(for level: Int) -> Color {
        switch level {
        case 0:
            return SystemTheme.backgroundSecondary
        case 1:
            return SystemTheme.successGreen.opacity(0.25)
        case 2:
            return SystemTheme.successGreen.opacity(0.45)
        case 3:
            return SystemTheme.successGreen.opacity(0.7)
        default:
            return SystemTheme.successGreen
        }
    }

    private func accessibilityLabel(for day: CompletionDay) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let formattedDate = formatter.string(from: day.date)
        let countText = day.count == 1 ? "1 quest completed" : "\(day.count) quests completed"
        return "\(formattedDate), \(countText)"
    }
}

// MARK: - Empty Quest State

struct EmptyQuestState: View {
    let onCreateTapped: () -> Void

    var body: some View {
        VStack(spacing: SystemSpacing.lg) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 64))
                .foregroundStyle(SystemTheme.textTertiary)

            Text("No Active Quests")
                .font(SystemTypography.titleSmall)
                .foregroundStyle(SystemTheme.textSecondary)

            Text("Create your first quest to begin tracking progress.")
                .font(SystemTypography.caption)
                .foregroundStyle(SystemTheme.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SystemSpacing.lg)

            Button(action: onCreateTapped) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Quest")
                }
                .font(SystemTypography.mono(14, weight: .semibold))
                .foregroundStyle(SystemTheme.primaryBlue)
                .padding()
                .background(SystemTheme.primaryBlue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: SystemRadius.medium))
            }
            .padding(.top, SystemSpacing.md)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Quest Row View

struct QuestRowView: View {
    let quest: DailyQuest
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var healthKitManager: HealthKitManager
    @ObservedObject var permissionManager: PermissionManager
    let liveProgressTick: Date
    let impactBossText: String?
    let impactRewardsText: String
    let impactStreakText: String
    let onComplete: () -> Void
    let onSubtaskComplete: (QuestSubtask) -> Void
    let onShowActions: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: onComplete) {
                    Image(systemName: quest.status == .completed ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 28))
                        .foregroundStyle(quest.status == .completed ? SystemTheme.successGreen : SystemTheme.textTertiary)
                }
                .disabled(quest.status == .completed)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(quest.title)
                            .font(SystemTypography.headline)
                            .foregroundStyle(quest.status == .completed ? SystemTheme.textTertiary : SystemTheme.textPrimary)
                            .strikethrough(quest.status == .completed)
                            .lineLimit(3)
                            .minimumScaleFactor(0.72)
                            .layoutPriority(1)

                        if quest.trackingType.isAutomatic {
                            Image(systemName: quest.trackingType.icon)
                                .font(.system(size: 12))
                                .foregroundStyle(SystemTheme.primaryBlue)
                        }
                    }

                    Text(quest.description)
                        .font(SystemTypography.caption)
                        .foregroundStyle(SystemTheme.textSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)

                    VStack(alignment: .leading, spacing: 2) {
                        if let impactBossText {
                            Text(impactBossText)
                                .font(SystemTypography.captionSmall)
                                .foregroundStyle(SystemTheme.warningOrange)
                                .lineLimit(1)
                                .minimumScaleFactor(0.65)
                        }
                        Text(impactRewardsText)
                            .font(SystemTypography.captionSmall)
                            .foregroundStyle(SystemTheme.primaryBlue)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                        Text(impactStreakText)
                            .font(SystemTypography.captionSmall)
                            .foregroundStyle(SystemTheme.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }

                    if quest.trackingType.isAutomatic && quest.status != .completed {
                        QuestTrackingDiagnosticsRow(
                            quest: quest,
                            locationManager: locationManager,
                            healthKitManager: healthKitManager,
                            permissionManager: permissionManager,
                            displayedProgress: displayedProgress
                        )
                    }

                    if quest.hasSubtasks {
                        QuestSubtaskListView(
                            quest: quest,
                            onSubtaskComplete: onSubtaskComplete
                        )
                        .padding(.top, 4)
                    }

                    HStack(spacing: 6) {
                        Text(quest.difficulty.rawValue)
                            .font(SystemTypography.mono(10, weight: .semibold))
                            .foregroundStyle(quest.difficulty.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(quest.difficulty.color.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        if quest.isOptional {
                            Text("Optional")
                                .font(SystemTypography.mono(10, weight: .semibold))
                                .foregroundStyle(SystemTheme.textSecondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(SystemTheme.backgroundSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }

                        ForEach(quest.targetStats.prefix(3), id: \.self) { stat in
                            QuestStatIconChip(stat: stat)
                        }

                        HStack(spacing: 2) {
                            Image(systemName: quest.resolvedFrequency.icon)
                                .font(.system(size: 9))
                            Text(quest.resolvedFrequency.rawValue)
                                .font(SystemTypography.mono(9, weight: .semibold))
                        }
                        .foregroundStyle(SystemTheme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)

                        Spacer()

                        QuestRewardSummaryView(
                            xpReward: quest.xpReward,
                            goldReward: quest.goldReward,
                            isOptional: quest.isOptional
                        )
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                }

                Button(action: onShowActions) {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(SystemTheme.textSecondary)
                        .padding(6)
                }
            }
            .padding()

            if quest.isMetricGoal {
                HStack {
                    Text("Progress")
                        .font(SystemTypography.captionSmall)
                        .foregroundStyle(SystemTheme.textTertiary)

                    Spacer()

                    Text(progressText)
                        .font(SystemTypography.mono(10, weight: .semibold))
                        .foregroundStyle(quest.status == .completed ? SystemTheme.successGreen : SystemTheme.primaryBlue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 6)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(SystemTheme.backgroundSecondary)

                        Capsule()
                            .fill(quest.status == .completed ? SystemTheme.successGreen : SystemTheme.primaryBlue)
                            .frame(width: max(0, geometry.size.width) * uiSafeUnitProgress(displayedProgress))
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .background(SystemTheme.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: SystemRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: SystemRadius.medium)
                .stroke(
                    quest.status == .completed ? SystemTheme.successGreen.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
    }

    private var displayedProgress: Double {
        if quest.trackingType == .location {
            _ = liveProgressTick
            return uiSafeUnitProgress(locationManager.liveLocationProgress(for: quest, now: liveProgressTick))
        }
        return uiSafeUnitProgress(quest.normalizedProgress)
    }

    private var displayedMetricValue: Double {
        if quest.status == .completed { return max(1, quest.targetValue) }
        return min(max(0, uiSafeUnitProgress(displayedProgress) * max(1, quest.targetValue)), max(1, quest.targetValue))
    }

    private var progressText: String {
        if quest.hasSubtasks {
            return "\(quest.completedSubtaskCount)/\(quest.subtasks.count) subtasks • \(Int(uiSafeUnitProgress(displayedProgress) * 100))%"
        }
        return "\(QuestProgressFormatter.metricDisplay(displayedMetricValue))/\(QuestProgressFormatter.metricDisplay(max(1, quest.targetValue))) \(quest.unit) • \(Int(uiSafeUnitProgress(displayedProgress) * 100))%"
    }
}

private struct NextUpSection: View {
    let quests: [DailyQuest]
    let bossImpactText: (DailyQuest) -> String?
    let rewardImpactText: (DailyQuest) -> String
    let streakImpactText: (DailyQuest) -> String
    @Binding var isCollapsed: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isCollapsed.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Text("Next Up")
                        .font(SystemTypography.mono(14, weight: .bold))
                        .foregroundStyle(SystemTheme.primaryBlue)

                    Spacer()

                    Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(SystemTheme.primaryBlue)
                        .padding(6)
                        .background(SystemTheme.backgroundTertiary)
                        .clipShape(Circle())
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !isCollapsed {
                VStack(spacing: 8) {
                    ForEach(Array(quests.enumerated()), id: \.element.id) { index, quest in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(SystemTypography.mono(11, weight: .bold))
                                .foregroundStyle(SystemTheme.backgroundPrimary)
                                .frame(width: 18, height: 18)
                                .background(SystemTheme.primaryBlue)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(quest.title)
                                    .font(SystemTypography.caption)
                                    .foregroundStyle(SystemTheme.textPrimary)
                                    .lineLimit(1)
                                if let bossLine = bossImpactText(quest) {
                                    Text(bossLine)
                                        .font(SystemTypography.captionSmall)
                                        .foregroundStyle(SystemTheme.warningOrange)
                                        .lineLimit(1)
                                }
                                Text(rewardImpactText(quest))
                                    .font(SystemTypography.captionSmall)
                                    .foregroundStyle(SystemTheme.primaryBlue)
                                    .lineLimit(1)
                                Text(streakImpactText(quest))
                                    .font(SystemTypography.captionSmall)
                                    .foregroundStyle(SystemTheme.textSecondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        if index < quests.count - 1 {
                            Divider().overlay(SystemTheme.borderSecondary)
                        }
                    }
                }
                .padding(10)
                .background(SystemTheme.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: SystemRadius.medium))
            }
        }
    }
}

private struct QuestStatIconChip: View {
    let stat: StatType

    var body: some View {
        Image(systemName: stat.icon)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(stat.color)
            .frame(width: 16, height: 16)
            .background(stat.color.opacity(0.14))
            .clipShape(Circle())
            .accessibilityLabel(Text(stat.fullName))
    }
}

private struct QuestSubtaskListView: View {
    let quest: DailyQuest
    let onSubtaskComplete: (QuestSubtask) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(quest.subtasks.enumerated()), id: \.element.id) { index, subtask in
                Button {
                    onSubtaskComplete(subtask)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(subtask.isCompleted ? SystemTheme.successGreen : SystemTheme.textTertiary)
                            .frame(width: 18)

                        Text(subtask.title)
                            .font(SystemTypography.captionSmall)
                            .foregroundStyle(subtask.isCompleted ? SystemTheme.textTertiary : SystemTheme.textPrimary)
                            .strikethrough(subtask.isCompleted)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(rewardText(for: index))
                            .font(SystemTypography.mono(9, weight: .semibold))
                            .foregroundStyle(SystemTheme.primaryBlue)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 8)
                    .background(SystemTheme.backgroundSecondary.opacity(subtask.isCompleted ? 0.35 : 0.65))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(subtask.isCompleted || quest.status == .completed)
            }
        }
    }

    private func rewardText(for index: Int) -> String {
        let xp = quest.subtaskXPReward(at: index)
        let gold = quest.subtaskGoldReward(at: index)
        if gold > 0 {
            return "+\(xp) XP +\(gold)g"
        }
        return "+\(xp) XP"
    }
}

private struct QuestTrackingDiagnosticsRow: View {
    let quest: DailyQuest
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var healthKitManager: HealthKitManager
    @ObservedObject var permissionManager: PermissionManager
    let displayedProgress: Double

    private var diagnostics: (icon: String, text: String, color: Color) {
        switch quest.trackingType {
        case .healthKit:
            guard permissionManager.healthKitEnabled else {
                return ("exclamationmark.triangle.fill", "Health access missing. Connect Vital Signs in Neural Links.", SystemTheme.warningOrange)
            }

            let current = Int(max(0, healthValueForQuest))
            let target = Int(max(1, quest.targetValue))
            let syncText = relativeTimestamp(healthKitManager.lastSyncDate)
            return (
                "heart.text.square.fill",
                "Detected \(current)/\(target) \(quest.unit) • Synced \(syncText)",
                SystemTheme.primaryBlue
            )

        case .location:
            let syncText = relativeTimestamp(locationManager.lastTrackingEventDate)
            let status = locationManager.questTrackingStatus(for: quest)
            switch status {
            case .permissionRequired:
                if displayedProgress > 0 || quest.status == .inProgress {
                    return (
                        "location.circle.fill",
                        "Foreground tracking active • Enable Always Location for background auto-complete.",
                        SystemTheme.textSecondary
                    )
                }
                return ("location.slash.fill", "Allow Always Location to keep auto-complete active in background.", SystemTheme.warningOrange)
            case .invalidAddress:
                return ("mappin.slash", "Address not validated. Edit and validate with Apple Maps.", SystemTheme.warningOrange)
            case .notMonitoring:
                return ("antenna.radiowaves.left.and.right.slash", "Geofence not active yet. Re-save quest to start tracking.", SystemTheme.textTertiary)
            case .monitoring(let place):
                return ("location.circle.fill", "Monitoring \(compactLocation(place)) • Synced \(syncText)", SystemTheme.primaryBlue)
            case .inRange(let minutes, let required):
                return ("timer.circle.fill", "In range \(minutes)/\(required) min • Synced \(syncText)", SystemTheme.successGreen)
            case .completed:
                return ("checkmark.seal.fill", "Location objective completed.", SystemTheme.successGreen)
            case .monitoringUnavailable:
                return ("exclamationmark.triangle.fill", "Geofencing unavailable on this device.", SystemTheme.criticalRed)
            }

        case .manual, .timer:
            return ("info.circle", "Manual tracking", SystemTheme.textSecondary)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 5) {
            Image(systemName: diagnostics.icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(diagnostics.color)
                .padding(.top, 1)

            Text(diagnostics.text)
                .font(SystemTypography.captionSmall)
                .foregroundStyle(diagnostics.color)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
    }

    private var healthValueForQuest: Double {
        guard let identifier = quest.healthKitIdentifier else { return quest.targetValue * displayedProgress }
        switch identifier {
        case "HKQuantityTypeIdentifierStepCount":
            return Double(healthKitManager.todaySteps)
        case "HKQuantityTypeIdentifierDistanceWalkingRunning":
            return healthKitManager.todayDistanceKM
        case "HKQuantityTypeIdentifierActiveEnergyBurned":
            return healthKitManager.todayActiveEnergy
        case "HKQuantityTypeIdentifierAppleExerciseTime":
            return Double(healthKitManager.todayWorkoutMinutes)
        case "HKWorkoutType":
            return Double(healthKitManager.todayWorkoutCount)
        case "HKCategoryTypeIdentifierAppleStandHour":
            return Double(healthKitManager.todayStandHours)
        case "HKCategoryTypeIdentifierSleepAnalysis":
            return healthKitManager.todaySleepHours
        case "HKQuantityTypeIdentifierDietaryWater":
            return healthKitManager.todayWaterGlasses
        case "HKCategoryTypeIdentifierMindfulSession":
            return Double(healthKitManager.todayMindfulMinutes)
        default:
            return quest.targetValue * displayedProgress
        }
    }

    private func relativeTimestamp(_ date: Date?) -> String {
        guard let date else { return "never" }
        return date.formatted(.relative(presentation: .named))
    }

    private func compactLocation(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 30 {
            return trimmed
        }
        return String(trimmed.prefix(29)) + "…"
    }
}

private struct QuestRewardSummaryView: View {
    let xpReward: Int
    let goldReward: Int
    var isOptional: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 3) {
                Image(systemName: "star.fill")
                    .font(.system(size: 9))
                Text("\(xpReward)")
                    .font(SystemTypography.mono(10, weight: .semibold))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .foregroundStyle(SystemTheme.primaryBlue)

            if !isOptional {
                HStack(spacing: 3) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 9))
                    Text("\(goldReward)")
                        .font(SystemTypography.mono(10, weight: .semibold))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .foregroundStyle(SystemTheme.goldColor)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.9)
    }
}

private struct QuestUndoBanner: View {
    let title: String
    let onUndo: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.uturn.backward.circle.fill")
                .foregroundStyle(SystemTheme.primaryBlue)

            Text("Completed \"\(title)\"")
                .font(SystemTypography.caption)
                .foregroundStyle(SystemTheme.textPrimary)
                .lineLimit(1)

            Spacer(minLength: 8)

            Button("Undo", action: onUndo)
                .font(SystemTypography.mono(12, weight: .bold))
                .foregroundStyle(SystemTheme.warningOrange)

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(SystemTheme.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(SystemTheme.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: SystemRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: SystemRadius.medium)
                .stroke(SystemTheme.borderSecondary, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 8, y: 3)
    }
}

// MARK: - Preview

#Preview {
    QuestsView()
        .environmentObject(GameEngine.shared)
}
