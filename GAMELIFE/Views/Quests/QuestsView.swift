//
//  QuestsView.swift
//  GAMELIFE
//
//  [SYSTEM]: Quest log accessed.
//  Complete your missions to grow stronger, Hunter.
//

import SwiftUI
import Combine

// MARK: - Quests View

/// Tab 2: Daily Quests with CRUD operations
struct QuestsView: View {

    // MARK: - Properties

    @EnvironmentObject var gameEngine: GameEngine
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
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
                    ScrollView {
                        LazyVStack(spacing: SystemSpacing.sm) {
                            QuestSummaryHeader(quests: gameEngine.dailyQuests)
                                .padding(.horizontal)
                                .padding(.top, SystemSpacing.sm)

                            if !nextUpQuests.isEmpty {
                                NextUpSection(
                                    quests: nextUpQuests,
                                    bossImpactText: bossImpactText(for:),
                                    rewardImpactText: rewardImpactText(for:),
                                    streakImpactText: streakImpactText(for:)
                                )
                                .padding(.horizontal)
                            }

                            ForEach(sortedQuests) { quest in
                                QuestRowView(
                                    quest: quest,
                                    locationManager: locationManager,
                                    healthKitManager: healthKitManager,
                                    screenTimeManager: screenTimeManager,
                                    permissionManager: permissionManager,
                                    liveProgressTick: liveProgressTick,
                                    impactBossText: bossImpactText(for: quest),
                                    impactRewardsText: rewardImpactText(for: quest),
                                    impactStreakText: streakImpactText(for: quest),
                                    onComplete: { completeQuest(quest) },
                                    onShowActions: { questActionTarget = quest }
                                )
                                .padding(.horizontal)
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

        if result.success {
            SystemMessageHelper.showQuestComplete(
                title: result.isCritical ? "Critical Success!" : "Quest Complete",
                xp: result.xpAwarded,
                gold: result.goldAwarded
            )

            if gameEngine.canUndoLatestQuestCompletion {
                undoBannerTitle = gameEngine.lastUndoQuestTitle ?? quest.title
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
        QuestManager.shared.checkExtensionCompletions()

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

// MARK: - Quest Summary Header

struct QuestSummaryHeader: View {
    let quests: [DailyQuest]

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

    var body: some View {
        VStack(spacing: SystemSpacing.sm) {
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
                        .trim(from: 0, to: completionPercentage)
                        .stroke(SystemTheme.primaryBlue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(completionPercentage * 100))%")
                        .font(SystemTypography.mono(12, weight: .bold))
                        .foregroundStyle(SystemTheme.primaryBlue)
                }
                .frame(width: 50, height: 50)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(SystemTheme.backgroundSecondary)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(SystemTheme.xpGradient)
                        .frame(width: geometry.size.width * completionPercentage)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(SystemTheme.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: SystemRadius.medium))
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
    @ObservedObject var screenTimeManager: ScreenTimeManager
    @ObservedObject var permissionManager: PermissionManager
    let liveProgressTick: Date
    let impactBossText: String?
    let impactRewardsText: String
    let impactStreakText: String
    let onComplete: () -> Void
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

                        if quest.trackingType.isAutomatic {
                            Image(systemName: quest.trackingType.icon)
                                .font(.system(size: 12))
                                .foregroundStyle(SystemTheme.primaryBlue)
                        }
                    }

                    Text(quest.description)
                        .font(SystemTypography.caption)
                        .foregroundStyle(SystemTheme.textSecondary)
                        .lineLimit(1)

                    VStack(alignment: .leading, spacing: 2) {
                        if let impactBossText {
                            Text(impactBossText)
                                .font(SystemTypography.captionSmall)
                                .foregroundStyle(SystemTheme.warningOrange)
                                .lineLimit(1)
                        }
                        Text(impactRewardsText)
                            .font(SystemTypography.captionSmall)
                            .foregroundStyle(SystemTheme.primaryBlue)
                            .lineLimit(1)
                        Text(impactStreakText)
                            .font(SystemTypography.captionSmall)
                            .foregroundStyle(SystemTheme.textSecondary)
                            .lineLimit(1)
                    }

                    if quest.trackingType.isAutomatic && quest.status != .completed {
                        QuestTrackingDiagnosticsRow(
                            quest: quest,
                            locationManager: locationManager,
                            healthKitManager: healthKitManager,
                            screenTimeManager: screenTimeManager,
                            permissionManager: permissionManager,
                            displayedProgress: displayedProgress
                        )
                    }

                    HStack(spacing: 8) {
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
                                .font(.system(size: 10))
                            Text(quest.resolvedFrequency.rawValue)
                                .font(SystemTypography.mono(10, weight: .semibold))
                        }
                        .foregroundStyle(SystemTheme.textSecondary)

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

                    Text("\(QuestProgressFormatter.metricDisplay(displayedMetricValue))/\(QuestProgressFormatter.metricDisplay(max(1, quest.targetValue))) \(quest.unit) • \(Int(displayedProgress * 100))%")
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
                            .frame(width: geometry.size.width * displayedProgress)
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
            return locationManager.liveLocationProgress(for: quest, now: liveProgressTick)
        }
        return quest.normalizedProgress
    }

    private var displayedMetricValue: Double {
        if quest.status == .completed { return max(1, quest.targetValue) }
        return min(max(0, displayedProgress * max(1, quest.targetValue)), max(1, quest.targetValue))
    }
}

private struct NextUpSection: View {
    let quests: [DailyQuest]
    let bossImpactText: (DailyQuest) -> String?
    let rewardImpactText: (DailyQuest) -> String
    let streakImpactText: (DailyQuest) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Next Up")
                .font(SystemTypography.mono(14, weight: .bold))
                .foregroundStyle(SystemTheme.primaryBlue)

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

private struct QuestTrackingDiagnosticsRow: View {
    let quest: DailyQuest
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var healthKitManager: HealthKitManager
    @ObservedObject var screenTimeManager: ScreenTimeManager
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

        case .screenTime:
            guard AppFeatureFlags.screenTimeEnabled else {
                return ("pause.circle.fill", "Usage tracking is temporarily disabled for this beta.", SystemTheme.textTertiary)
            }
            guard permissionManager.screenTimeEnabled else {
                return ("exclamationmark.triangle.fill", "Screen Time access missing. Connect Mind Activity in Neural Links.", SystemTheme.warningOrange)
            }
            guard screenTimeManager.isMonitorExtensionInstalled else {
                return (
                    "app.badge.checkmark",
                    "Screen Time monitor extension is not bundled in this build. Quest usage cannot auto-update yet.",
                    SystemTheme.warningOrange
                )
            }

            let progressPct = Int(displayedProgress * 100)
            let syncText = relativeTimestamp(screenTimeManager.lastSyncDate)
            let selectionMissing = quest.screenTimeSelectionData == nil && (quest.screenTimeCategory?.isEmpty ?? true)
            if selectionMissing {
                return ("apps.iphone.badge.plus", "No apps/categories linked yet. Edit quest to select tracking targets.", SystemTheme.warningOrange)
            }
            return (
                "apps.iphone",
                "Auto-tracking active • \(progressPct)% complete • Synced \(syncText)",
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
                    .font(.system(size: 10))
                Text("\(xpReward)")
                    .font(SystemTypography.mono(11, weight: .semibold))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .foregroundStyle(SystemTheme.primaryBlue)

            if !isOptional {
                HStack(spacing: 3) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 10))
                    Text("\(goldReward)")
                        .font(SystemTypography.mono(11, weight: .semibold))
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
