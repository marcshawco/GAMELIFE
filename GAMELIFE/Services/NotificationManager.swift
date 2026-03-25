//
//  NotificationManager.swift
//  GAMELIFE
//
//  [SYSTEM]: Communication relay initialized.
//  You will be notified of all system events.
//

import Foundation
import UserNotifications
import SwiftUI
import Combine

// MARK: - Notification Manager

/// Handles all push notifications and alerts
@MainActor
class NotificationManager: NSObject, ObservableObject {

    static let shared = NotificationManager()

    // MARK: - Published Properties

    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []
    @Published var lastQuestCompletionNotificationDate: Date?
    @Published var queuedQuestCompletionDigestCount: Int = 0

    // MARK: - Constants

    private let notificationCategories = [
        "QUEST_COMPLETE",
        "LEVEL_UP",
        "PENALTY",
        "PENALTY_ZONE",
        "DUNGEON",
        "DAILY_REMINDER",
        "STREAK",
        "BOSS_DEFEATED",
        "LOCATION"
    ]
    private let digestNotificationIdentifier = "quest_completion_digest"
    private let digestQueueStoreKey = "questCompletionDigestQueue"
    private let digestWindowStartedAtStoreKey = "questCompletionDigestWindowStartedAt"
    private let questCompletionModeStoreKey = "questCompletionNotificationMode"
    private let questReminderCategoryIdentifier = "QUEST_REMINDER"
    private let completeQuestActionIdentifier = "COMPLETE_QUEST"
    private let engagementHistoryStoreKey = "engagementOpenHistory"
    private let lastEngagementOpenAtStoreKey = "lastEngagementOpenAt"
    private let engagementReminderIdentifier = "smart_engagement_reminder"
    private let inactivityShutdownIdentifier = "smart_engagement_shutdown"
    private let dailyReminderEnabledStoreKey = "dailyReminderEnabled"
    private let dailyReminderHourStoreKey = "dailyReminderHour"
    private let engagementHistoryLookbackDays = 28
    private let inactivityShutdownDays = 7
    private let reminderPlanDebounceInterval: TimeInterval = 0.35
    private var lastReminderPlanSignature: String?
    private var reminderPlanRefreshWorkItem: DispatchWorkItem?

    enum QuestCompletionNotificationMode: String, CaseIterable, Identifiable {
        case immediate
        case digest

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .immediate: return "Immediate"
            case .digest: return "Digest (1 min)"
            }
        }
    }

    private struct QueuedQuestCompletion: Codable {
        let title: String
        let xp: Int
        let gold: Int
        let timestamp: Date
    }

    private struct EngagementOpenRecord: Codable {
        let openedAt: Date
    }

    var questCompletionNotificationMode: QuestCompletionNotificationMode {
        get {
            guard let raw = UserDefaults.standard.string(forKey: questCompletionModeStoreKey),
                  let mode = QuestCompletionNotificationMode(rawValue: raw) else {
                return .immediate
            }
            return mode
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: questCompletionModeStoreKey)
            if newValue == .immediate {
                clearQuestDigestQueue()
            }
        }
    }

    // MARK: - Initialization

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
        setupNotificationCategories()
        updateQueuedDigestCount()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    // MARK: - Authorization

    /// Request notification authorization
    func requestAuthorization() async throws {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge, .criticalAlert]

        let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)

        await MainActor.run {
            self.isAuthorized = granted
            if granted {
                self.refreshPersonalizedReminderPlan()
            }
        }
    }

    /// Check current authorization status
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    /// Set up notification categories with actions
    private func setupNotificationCategories() {
        // Quest complete actions
        let completeQuestAction = UNNotificationAction(
            identifier: completeQuestActionIdentifier,
            title: "Complete Quest",
            options: []
        )

        let questCategory = UNNotificationCategory(
            identifier: "QUEST_COMPLETE",
            actions: [],
            intentIdentifiers: []
        )

        let questReminderCategory = UNNotificationCategory(
            identifier: questReminderCategoryIdentifier,
            actions: [completeQuestAction],
            intentIdentifiers: []
        )

        // Penalty actions
        let completePenaltyAction = UNNotificationAction(
            identifier: "COMPLETE_PENALTY",
            title: "Complete Now",
            options: .foreground
        )

        let penaltyCategory = UNNotificationCategory(
            identifier: "PENALTY",
            actions: [completePenaltyAction],
            intentIdentifiers: []
        )

        // Dungeon actions
        let startDungeonAction = UNNotificationAction(
            identifier: "START_DUNGEON",
            title: "Enter Dungeon",
            options: .foreground
        )

        let dungeonCategory = UNNotificationCategory(
            identifier: "DUNGEON",
            actions: [startDungeonAction],
            intentIdentifiers: []
        )

        // Register categories
        UNUserNotificationCenter.current().setNotificationCategories([
            questCategory,
            questReminderCategory,
            penaltyCategory,
            dungeonCategory
        ])
    }

    // MARK: - Quest Notifications

    /// Send quest completion notification
    func sendQuestCompleteNotification(title: String, body: String) {
        sendImmediateQuestCompleteNotification(title: title, body: body)
    }

    /// Send completion feedback either immediately or as a short digest, based on user preference.
    func sendQuestCompletionNotification(questTitle: String, xp: Int, gold: Int) {
        let messageBody = questCompletionBody(title: questTitle, xp: xp, gold: gold)

        switch questCompletionNotificationMode {
        case .immediate:
            sendImmediateQuestCompleteNotification(title: "Quest Complete", body: messageBody)
        case .digest:
            enqueueQuestCompletionDigest(questTitle: questTitle, xp: xp, gold: gold)
        }
    }

    private func sendImmediateQuestCompleteNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = "[SYSTEM] \(title)"
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "QUEST_COMPLETE"
        content.interruptionLevel = .active

        // Custom sound if available
        // content.sound = UNNotificationSound(named: UNNotificationSoundName("quest_complete.wav"))

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        lastQuestCompletionNotificationDate = Date()
        UNUserNotificationCenter.current().add(request)
    }

    private func enqueueQuestCompletionDigest(questTitle: String, xp: Int, gold: Int) {
        var queue = loadQuestDigestQueue()
        let now = Date()
        let currentWindowStart = UserDefaults.standard.object(forKey: digestWindowStartedAtStoreKey) as? Date
        if let currentWindowStart, now.timeIntervalSince(currentWindowStart) > 90 {
            queue = []
            UserDefaults.standard.set(now, forKey: digestWindowStartedAtStoreKey)
        } else if currentWindowStart == nil {
            UserDefaults.standard.set(now, forKey: digestWindowStartedAtStoreKey)
        }

        queue.append(
            QueuedQuestCompletion(
                title: questTitle,
                xp: xp,
                gold: gold,
                timestamp: now
            )
        )
        saveQuestDigestQueue(queue)

        let totalXP = queue.reduce(0) { $0 + $1.xp }
        let totalGold = queue.reduce(0) { $0 + $1.gold }

        let content = UNMutableNotificationContent()
        content.title = "[SYSTEM] Quest Digest"
        if queue.count == 1, let only = queue.first {
            content.body = questCompletionBody(title: only.title, xp: only.xp, gold: only.gold)
        } else {
            content.body = totalGold > 0
                ? "\(queue.count) quests completed • +\(totalXP) XP • +\(totalGold) Gold."
                : "\(queue.count) quests completed • +\(totalXP) XP (optional quests grant XP only)."
        }
        content.sound = .default
        content.categoryIdentifier = "QUEST_COMPLETE"
        content.interruptionLevel = .active

        // Re-schedule to keep aggregating within a short rolling window.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        let request = UNNotificationRequest(
            identifier: digestNotificationIdentifier,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [digestNotificationIdentifier])
        UNUserNotificationCenter.current().add(request)
        updateQueuedDigestCount()
    }

    private func loadQuestDigestQueue() -> [QueuedQuestCompletion] {
        guard let data = UserDefaults.standard.data(forKey: digestQueueStoreKey),
              let queue = try? JSONDecoder().decode([QueuedQuestCompletion].self, from: data) else {
            return []
        }
        return queue
    }

    private func saveQuestDigestQueue(_ queue: [QueuedQuestCompletion]) {
        if let data = try? JSONEncoder().encode(queue) {
            UserDefaults.standard.set(data, forKey: digestQueueStoreKey)
        }
        updateQueuedDigestCount()
    }

    private func clearQuestDigestQueue() {
        UserDefaults.standard.removeObject(forKey: digestQueueStoreKey)
        UserDefaults.standard.removeObject(forKey: digestWindowStartedAtStoreKey)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [digestNotificationIdentifier])
        updateQueuedDigestCount()
    }

    private func questCompletionBody(title: String, xp: Int, gold: Int) -> String {
        if gold > 0 {
            return "\(title) finished. +\(xp) XP, +\(gold) Gold."
        }
        return "\(title) finished. +\(xp) XP (optional quest: no gold)."
    }

    private func updateQueuedDigestCount() {
        queuedQuestCompletionDigestCount = loadQuestDigestQueue().count
    }

    /// Send daily quest reminder
    func scheduleDailyQuestReminder(at hour: Int, minute: Int) {
        UserDefaults.standard.set(hour, forKey: dailyReminderHourStoreKey)
        UserDefaults.standard.set(true, forKey: dailyReminderEnabledStoreKey)
        refreshPersonalizedReminderPlan()
    }

    /// Send evening reminder for incomplete quests
    func scheduleEveningReminder(incompleteCount: Int) {
        let content = UNMutableNotificationContent()
        content.title = "[SYSTEM] Quests Incomplete"
        content.body = "You have \(incompleteCount) quest\(incompleteCount == 1 ? "" : "s") remaining. Complete them to avoid penalties."
        content.sound = .default
        content.categoryIdentifier = "DAILY_REMINDER"

        // Schedule for 9 PM
        var dateComponents = DateComponents()
        dateComponents.hour = 21
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "evening_reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    /// Schedule or clear a quest-specific reminder.
    func scheduleQuestReminder(for quest: DailyQuest) {
        let identifier = "quest_reminder_\(quest.id.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])

        guard quest.reminderEnabled, let reminderTime = quest.reminderTime else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "[SYSTEM] Quest Reminder"
        content.body = "Time to complete: \(quest.title)"
        content.sound = .default
        content.categoryIdentifier = questReminderCategoryIdentifier
        content.userInfo = [
            "questID": quest.id.uuidString
        ]

        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        guard let hour = components.hour, let minute = components.minute else {
            return
        }

        var triggerComponents = DateComponents()
        triggerComponents.hour = hour
        triggerComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func removeQuestReminder(questID: UUID) {
        let identifier = "quest_reminder_\(questID.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func clearAllQuestReminders() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiers = requests
                .map(\.identifier)
                .filter { $0.hasPrefix("quest_reminder_") }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }

    // MARK: - Personalized Engagement Notifications

    @objc private func handleAppDidBecomeActive() {
        recordAppOpen()
        refreshPersonalizedReminderPlan()
    }

    func refreshPersonalizedReminderPlan() {
        reminderPlanRefreshWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.applyPersonalizedReminderPlanRefresh()
        }
        reminderPlanRefreshWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + reminderPlanDebounceInterval, execute: workItem)
    }

    private func applyPersonalizedReminderPlanRefresh() {
        guard isAuthorized, isDailyReminderEnabled else {
            lastReminderPlanSignature = nil
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: [engagementReminderIdentifier, inactivityShutdownIdentifier, "daily_quest_reminder"]
            )
            return
        }
        let nextReminderDate = nextPreferredEngagementDate(after: Date())
        let reminderProfile = personalizedReminderProfile()
        let shutdownBody = inactivityShutdownBody()
        let shutdownDate = inactivityShutdownTriggerDate()
        let signature = reminderPlanSignature(
            nextReminderDate: nextReminderDate,
            reminderProfile: reminderProfile,
            shutdownDate: shutdownDate,
            shutdownBody: shutdownBody
        )

        guard signature != lastReminderPlanSignature else { return }
        lastReminderPlanSignature = signature

        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [engagementReminderIdentifier, inactivityShutdownIdentifier, "daily_quest_reminder"]
        )

        scheduleNextEngagementReminder(at: nextReminderDate, profile: reminderProfile)
        scheduleInactivityShutdownNotification(triggerDate: shutdownDate, body: shutdownBody)
    }

    private var isDailyReminderEnabled: Bool {
        UserDefaults.standard.object(forKey: dailyReminderEnabledStoreKey) as? Bool ?? true
    }

    private var fallbackDailyReminderHour: Int {
        let hour = UserDefaults.standard.integer(forKey: dailyReminderHourStoreKey)
        return (0...23).contains(hour) ? hour : 8
    }

    private func recordAppOpen(at date: Date = Date()) {
        var history = loadEngagementHistory()
        if let last = history.last?.openedAt, date.timeIntervalSince(last) < 15 * 60 {
            UserDefaults.standard.set(date, forKey: lastEngagementOpenAtStoreKey)
            return
        }

        history.append(EngagementOpenRecord(openedAt: date))
        history = history.filter {
            guard let cutoff = Calendar.current.date(byAdding: .day, value: -engagementHistoryLookbackDays, to: date) else {
                return true
            }
            return $0.openedAt >= cutoff
        }

        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: engagementHistoryStoreKey)
        }
        UserDefaults.standard.set(date, forKey: lastEngagementOpenAtStoreKey)
    }

    private func loadEngagementHistory() -> [EngagementOpenRecord] {
        guard let data = UserDefaults.standard.data(forKey: engagementHistoryStoreKey),
              let history = try? JSONDecoder().decode([EngagementOpenRecord].self, from: data) else {
            return []
        }
        return history
    }

    private func scheduleNextEngagementReminder(at nextDate: Date, profile: (title: String, body: String)) {
        let content = personalizedEngagementContent(profile: profile)
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: engagementReminderIdentifier,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func nextPreferredEngagementDate(after now: Date) -> Date {
        let history = loadEngagementHistory()
        let calendar = Calendar.current
        let learnedMinutes = learnedReminderMinutes(from: history)

        if let learnedMinutes {
            let hour = learnedMinutes / 60
            let minute = learnedMinutes % 60

            var bestCandidate: Date?
            for offset in 0...2 {
                guard let day = calendar.date(byAdding: .day, value: offset, to: now) else { continue }
                var components = calendar.dateComponents([.year, .month, .day], from: day)
                components.hour = hour
                components.minute = minute
                guard let candidate = calendar.date(from: components), candidate > now.addingTimeInterval(45 * 60) else {
                    continue
                }
                bestCandidate = candidate
                break
            }

            if let bestCandidate {
                return bestCandidate
            }
        }

        var fallbackComponents = calendar.dateComponents([.year, .month, .day], from: now)
        fallbackComponents.hour = fallbackDailyReminderHour
        fallbackComponents.minute = 0
        let fallbackToday = calendar.date(from: fallbackComponents) ?? now.addingTimeInterval(3600)
        if fallbackToday > now.addingTimeInterval(45 * 60) {
            return fallbackToday
        }
        return calendar.date(byAdding: .day, value: 1, to: fallbackToday) ?? now.addingTimeInterval(24 * 3600)
    }

    private func learnedReminderMinutes(from history: [EngagementOpenRecord]) -> Int? {
        guard history.count >= 4 else { return nil }

        var buckets: [Int: Int] = [:]
        for record in history {
            let components = Calendar.current.dateComponents([.hour, .minute], from: record.openedAt)
            let hour = components.hour ?? 0
            let minute = components.minute ?? 0
            let bucket = hour * 2 + (minute >= 30 ? 1 : 0)
            buckets[bucket, default: 0] += 1
        }

        guard let best = buckets.max(by: { lhs, rhs in
            if lhs.value == rhs.value { return lhs.key > rhs.key }
            return lhs.value < rhs.value
        }), best.value >= 2 else {
            return nil
        }

        return best.key * 30
    }

    private func personalizedEngagementContent(profile: (title: String, body: String)) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = profile.title
        content.body = profile.body
        content.sound = .default
        content.categoryIdentifier = "DAILY_REMINDER"
        content.interruptionLevel = .active
        return content
    }

    private func personalizedReminderProfile() -> (title: String, body: String) {
        let engine = GameEngine.shared
        let player = engine.player
        let quests = engine.dailyQuests.filter { $0.status != .completed }
        let urgentQuest = mostUrgentQuest(from: quests, playerLevel: player.level, bosses: engine.activeBossFights)
        let activeBoss = currentBossTarget(from: engine.activeBossFights)

        if let urgentQuest, let activeBoss {
            return (
                title: "[SYSTEM] Return Window Detected",
                body: "\(urgentQuest.title) is your best next move. Push back against \(activeBoss.title) before it stalls your progress."
            )
        }

        if let urgentQuest {
            return (
                title: "[SYSTEM] Your Momentum Window Is Open",
                body: "\(urgentQuest.title) is still waiting. A short session now keeps your streak and XP pipeline alive."
            )
        }

        if let activeBoss {
            return (
                title: "[SYSTEM] Boss Pressure Rising",
                body: "\(activeBoss.title) is still standing. Log in and chip away before the system loses your rhythm."
            )
        }

        return (
            title: "[SYSTEM] Check-In Opportunity",
            body: "Your build is quiet right now. Log in, review your board, and set the next chain of progress in motion."
        )
    }

    private func scheduleInactivityShutdownNotification(triggerDate: Date?, body: String) {
        guard let triggerDate else { return }
        let content = UNMutableNotificationContent()
        content.title = "[SYSTEM] Transmission Ending"
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "DAILY_REMINDER"

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: inactivityShutdownIdentifier,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func inactivityShutdownTriggerDate() -> Date? {
        let referenceDate = (UserDefaults.standard.object(forKey: lastEngagementOpenAtStoreKey) as? Date) ?? Date()
        return Calendar.current.date(byAdding: .day, value: inactivityShutdownDays, to: referenceDate)
    }

    private func reminderPlanSignature(
        nextReminderDate: Date,
        reminderProfile: (title: String, body: String),
        shutdownDate: Date?,
        shutdownBody: String
    ) -> String {
        let nextReminderMinute = Int(nextReminderDate.timeIntervalSince1970 / 60)
        let shutdownMinute = shutdownDate.map { Int($0.timeIntervalSince1970 / 60) } ?? -1
        return [
            reminderProfile.title,
            reminderProfile.body,
            String(nextReminderMinute),
            shutdownBody,
            String(shutdownMinute),
            String(isAuthorized),
            String(isDailyReminderEnabled)
        ].joined(separator: "|")
    }

    private func inactivityShutdownBody() -> String {
        if let boss = currentBossTarget(from: GameEngine.shared.activeBossFights) {
            return "No activity detected for 7 days. PRAXIS is standing down for now. \(boss.title) remains undefeated."
        }
        return "No activity detected for 7 days. PRAXIS is standing down for now. Reopen the app whenever you're ready to resume the climb."
    }

    private func mostUrgentQuest(from quests: [DailyQuest], playerLevel: Int, bosses: [BossFight]) -> DailyQuest? {
        quests.max { lhs, rhs in
            questPriorityScore(lhs, playerLevel: playerLevel, bosses: bosses) < questPriorityScore(rhs, playerLevel: playerLevel, bosses: bosses)
        }
    }

    private func currentBossTarget(from bosses: [BossFight]) -> BossFight? {
        bosses
            .filter { !$0.isDefeated }
            .sorted { lhs, rhs in
                switch (lhs.deadline, rhs.deadline) {
                case let (left?, right?) where left != right:
                    return left < right
                case (nil, _?):
                    return false
                case (_?, nil):
                    return true
                default:
                    if lhs.hpPercentage == rhs.hpPercentage {
                        return lhs.title < rhs.title
                    }
                    return lhs.hpPercentage < rhs.hpPercentage
                }
            }
            .first
    }

    private func questPriorityScore(_ quest: DailyQuest, playerLevel: Int, bosses: [BossFight]) -> Double {
        let now = Date()
        let secondsLeft = max(60, quest.expiresAt.timeIntervalSince(now))
        let dueSoonScore = 250_000 / secondsLeft
        let rewardValue = Double(quest.xpReward) + Double(quest.isOptional ? 0 : quest.goldReward * 3)
        let streakRisk = (!quest.isOptional && quest.resolvedFrequency == .daily)
            ? (1.0 - quest.normalizedProgress) * 40.0
            : 0
        let bossImpact = Double(estimatedBossDamage(for: quest, playerLevel: playerLevel, bosses: bosses))
        return dueSoonScore + (rewardValue * 0.3) + streakRisk + (bossImpact * 1.6)
    }

    private func estimatedBossDamage(for quest: DailyQuest, playerLevel: Int, bosses: [BossFight]) -> Int {
        guard let linkedBossID = quest.linkedBossID,
              let boss = bosses.first(where: { $0.id == linkedBossID && !$0.isDefeated }) else {
            return 0
        }
        let baseDamage = GameFormulas.bossDamage(taskDifficulty: quest.difficulty, playerLevel: playerLevel)
        let estimated = max(1, Int(Double(baseDamage) * 0.8))
        return min(estimated, boss.currentHP)
    }

    // MARK: - Level Up Notifications

    /// Send level up notification
    func sendLevelUpNotification(level: Int, rank: PlayerRank) {
        let content = UNMutableNotificationContent()
        content.title = "⬆️ LEVEL UP!"
        content.body = "You have reached Level \(level). Rank: \(rank.title)"
        content.sound = .default
        content.categoryIdentifier = "LEVEL_UP"

        // Badge shows current level
        content.badge = NSNumber(value: level)

        let request = UNNotificationRequest(
            identifier: "level_up_\(level)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    /// Send rank up notification (special version)
    func sendRankUpNotification(newRank: PlayerRank) {
        let content = UNMutableNotificationContent()
        content.title = "🎖️ RANK UP!"
        content.body = "You have achieved the rank of \(newRank.title)!"
        content.sound = UNNotificationSound.defaultCritical
        content.categoryIdentifier = "LEVEL_UP"
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(
            identifier: "rank_up_\(newRank.rawValue)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Dungeon Notifications

    /// Schedule notification for dungeon completion
    func scheduleDungeonEndNotification(in minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "[SYSTEM] DUNGEON CLEARED!"
        content.body = "You have conquered the dungeon. Claim your rewards."
        content.sound = .default
        content.categoryIdentifier = "DUNGEON"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(minutes * 60),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "dungeon_complete",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    /// Send dungeon cleared celebration
    func sendDungeonClearedNotification(dungeonName: String, xp: Int) {
        let content = UNMutableNotificationContent()
        content.title = "🏰 DUNGEON CLEARED"
        content.body = "\(dungeonName) conquered! +\(xp) XP earned."
        content.sound = .default
        content.categoryIdentifier = "DUNGEON"

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    /// Cancel dungeon notification (if exited early)
    func cancelDungeonNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["dungeon_complete"]
        )
    }

    // MARK: - Boss Notifications

    /// Send boss defeated notification
    func sendBossDefeatedNotification(bossName: String) {
        let content = UNMutableNotificationContent()
        content.title = "💀 BOSS DEFEATED"
        content.body = "You have slain \(bossName)! Epic rewards await."
        content.sound = UNNotificationSound.defaultCritical
        content.categoryIdentifier = "BOSS_DEFEATED"
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(
            identifier: "boss_defeated_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    /// Send boss deadline warning
    func scheduleBossDeadlineWarning(bossName: String, deadline: Date) {
        // 24 hour warning
        let warningTime = deadline.addingTimeInterval(-86400)

        guard warningTime > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "⚠️ BOSS DEADLINE APPROACHING"
        content.body = "\(bossName) must be defeated within 24 hours!"
        content.sound = .default
        content.categoryIdentifier = "BOSS_DEFEATED"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: warningTime.timeIntervalSinceNow,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "boss_deadline_\(bossName)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Streak Notifications

    /// Send streak milestone notification
    func sendStreakMilestoneNotification(streak: Int) {
        let content = UNMutableNotificationContent()
        content.title = "🔥 STREAK MILESTONE"
        content.body = "\(streak) day streak! Your power grows with each passing day."
        content.sound = .default
        content.categoryIdentifier = "STREAK"

        let request = UNNotificationRequest(
            identifier: "streak_\(streak)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    /// Send streak at risk warning
    func scheduleStreakAtRiskNotification() {
        // Schedule for 10 PM if quests incomplete
        var dateComponents = DateComponents()
        dateComponents.hour = 22
        dateComponents.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "🔥 STREAK AT RISK"
        content.body = "Complete your daily quests before midnight to maintain your streak!"
        content.sound = UNNotificationSound.defaultCritical
        content.categoryIdentifier = "STREAK"
        content.interruptionLevel = .timeSensitive

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "streak_at_risk",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Location Notifications

    /// Send location arrival notification
    func sendLocationArrivalNotification(location: TrackedLocation) {
        let content = UNMutableNotificationContent()
        content.title = "[SYSTEM] LOCATION DETECTED"
        content.body = "You have arrived at \(location.name). Quest tracking active."
        content.sound = .default
        content.categoryIdentifier = "LOCATION"

        let request = UNNotificationRequest(
            identifier: "location_\(location.id.uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - System Notifications

    /// Send critical system alert
    func sendSystemAlert(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = "[CRITICAL] \(title)"
        content.body = message
        content.sound = UNNotificationSound.defaultCritical
        content.interruptionLevel = .critical

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Badge Management

    /// Update app badge with pending quests count
    func updateBadge(pendingQuests: Int) {
        UNUserNotificationCenter.current().setBadgeCount(pendingQuests)
    }

    /// Clear app badge
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }

    // MARK: - Notification Management

    /// Cancel all pending notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// Cancel specific notification
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )
    }

    /// Get all pending notifications
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        if notification.request.identifier == digestNotificationIdentifier {
            await MainActor.run {
                clearQuestDigestQueue()
                lastQuestCompletionNotificationDate = Date()
            }
        }
        // Suppress OS banner/list while app is foregrounded to avoid UI overlap.
        // In-app system messaging remains the primary foreground feedback channel.
        return []
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        if response.actionIdentifier == completeQuestActionIdentifier,
           let questIDString = response.notification.request.content.userInfo["questID"] as? String,
           let questID = UUID(uuidString: questIDString) {
            await MainActor.run {
                if let quest = GameEngine.shared.dailyQuests.first(where: { $0.id == questID }) {
                    _ = GameEngine.shared.completeQuest(quest)
                }
            }
        }
        if response.notification.request.identifier == digestNotificationIdentifier {
            await MainActor.run {
                clearQuestDigestQueue()
                lastQuestCompletionNotificationDate = Date()
            }
        }
    }
}

// MARK: - Notification Settings View

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared

    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled = true
    @AppStorage("dailyReminderHour") private var dailyReminderHour = 8
    @AppStorage("eveningReminderEnabled") private var eveningReminderEnabled = true
    @AppStorage("streakAlertsEnabled") private var streakAlertsEnabled = true

    var body: some View {
        ZStack {
            SystemTheme.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: SystemSpacing.lg) {
                    // Header
                    HStack {
                        Text("[NOTIFICATIONS]")
                            .font(SystemTypography.systemTitle)
                            .foregroundStyle(SystemTheme.primaryBlue)
                        Spacer()
                    }

                    // Authorization status
                    if !notificationManager.isAuthorized {
                        VStack(spacing: 12) {
                            Text("Notifications are disabled")
                                .font(SystemTypography.headline)
                                .foregroundStyle(SystemTheme.warningOrange)

                            Button("Enable Notifications") {
                                Task {
                                    try? await notificationManager.requestAuthorization()
                                }
                            }
                            .font(SystemTypography.mono(14, weight: .bold))
                            .foregroundStyle(SystemTheme.backgroundPrimary)
                            .padding()
                            .background(SystemTheme.primaryBlue)
                            .clipShape(Capsule())
                        }
                        .padding()
                        .systemCard()
                    }

                    // Daily Reminder
                    SettingsToggleRow(
                        title: "Daily Quest Reminder",
                        subtitle: "Remind me to complete daily quests",
                        isOn: $dailyReminderEnabled,
                        icon: "bell.fill",
                        color: SystemTheme.primaryBlue
                    )
                    .onChange(of: dailyReminderEnabled) { _, enabled in
                        UserDefaults.standard.set(enabled, forKey: "dailyReminderEnabled")
                        if enabled {
                            notificationManager.scheduleDailyQuestReminder(at: dailyReminderHour, minute: 0)
                        } else {
                            notificationManager.cancelNotification(identifier: "daily_quest_reminder")
                            notificationManager.refreshPersonalizedReminderPlan()
                        }
                    }

                    // Evening Reminder
                    SettingsToggleRow(
                        title: "Evening Reminder",
                        subtitle: "Warn me if quests are incomplete",
                        isOn: $eveningReminderEnabled,
                        icon: "moon.fill",
                        color: SystemTheme.primaryPurple
                    )

                    // Streak Alerts
                    SettingsToggleRow(
                        title: "Streak Alerts",
                        subtitle: "Alert me when my streak is at risk",
                        isOn: $streakAlertsEnabled,
                        icon: "flame.fill",
                        color: SystemTheme.warningOrange
                    )
                }
                .padding()
            }
        }
    }
}

// MARK: - Settings Toggle Row

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(SystemTypography.headline)
                    .foregroundStyle(SystemTheme.textPrimary)

                Text(subtitle)
                    .font(SystemTypography.caption)
                    .foregroundStyle(SystemTheme.textSecondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(color)
        }
        .padding()
        .systemCard()
    }
}
