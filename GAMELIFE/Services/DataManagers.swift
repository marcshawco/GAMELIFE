//
//  DataManagers.swift
//  GAMELIFE
//
//  [SYSTEM]: Data persistence modules initialized.
//  Your progress is being recorded.
//

import Foundation

// MARK: - Player Data Manager

/// Manages player data persistence
class PlayerDataManager {

    static let shared = PlayerDataManager()

    private let playerKey = "gamelife_player"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var cachedPlayer: Player?
    private var cachedPlayerData: Data?

    private init() {}

    // MARK: - Player Persistence

    /// Save player to UserDefaults
    func savePlayer(_ player: Player) {
        do {
            let data = try encoder.encode(player)
            if data == cachedPlayerData {
                cachedPlayer = player
                return
            }
            UserDefaults.standard.set(data, forKey: playerKey)
            cachedPlayer = player
            cachedPlayerData = data
        } catch {
            print("[SYSTEM] Failed to save player: \(error)")
        }
    }

    /// Load player from UserDefaults
    func loadPlayer() -> Player? {
        if let cachedPlayer {
            return cachedPlayer
        }

        guard let data = UserDefaults.standard.data(forKey: playerKey) else {
            return nil
        }

        do {
            let player = try decoder.decode(Player.self, from: data)
            cachedPlayer = player
            cachedPlayerData = data
            return player
        } catch {
            print("[SYSTEM] Failed to load player: \(error)")
            return nil
        }
    }

    /// Delete player data
    func deletePlayer() {
        UserDefaults.standard.removeObject(forKey: playerKey)
        cachedPlayer = nil
        cachedPlayerData = nil
    }

    /// Check if player exists
    var playerExists: Bool {
        UserDefaults.standard.data(forKey: playerKey) != nil
    }

    /// Export player data as JSON string
    func exportPlayerData() -> String? {
        guard let player = loadPlayer() else { return nil }

        do {
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(player)
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }

    /// Import player data from JSON string
    func importPlayerData(_ jsonString: String) -> Bool {
        guard let data = jsonString.data(using: .utf8) else { return false }

        do {
            let player = try decoder.decode(Player.self, from: data)
            savePlayer(player)
            return true
        } catch {
            print("[SYSTEM] Failed to import player: \(error)")
            return false
        }
    }
}

// MARK: - Quest Data Manager

/// Manages quest data persistence
class QuestDataManager {

    static let shared = QuestDataManager()

    private let dailyQuestsKey = "gamelife_daily_quests"
    private let bossFightsKey = "gamelife_boss_fights"
    private let completedQuestsKey = "gamelife_completed_quests"
    private let questHistoryKey = "gamelife_quest_history"
    private let validatedLocationCacheKey = "gamelife_validated_location_cache"

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var cachedDailyQuests: [DailyQuest]?
    private var cachedDailyQuestsData: Data?
    private var cachedBossFights: [BossFight]?
    private var cachedBossFightsData: Data?
    private var cachedQuestHistory: [QuestHistoryRecord]?
    private var cachedQuestHistoryData: Data?
    private var cachedValidatedLocationCache: ValidatedLocationCache?
    private var cachedValidatedLocationCacheData: Data?

    private init() {}

    private struct ValidatedLocationCache: Codable {
        var byQuestID: [String: LocationCoordinate] = [:]
        var byAddress: [String: LocationCoordinate] = [:]
    }

    // MARK: - Daily Quests

    /// Save daily quests
    func saveDailyQuests(_ quests: [DailyQuest]) {
        do {
            let data = try encoder.encode(quests)
            if data != cachedDailyQuestsData {
                UserDefaults.standard.set(data, forKey: dailyQuestsKey)
                cachedDailyQuestsData = data
            }
            cachedDailyQuests = quests
            persistValidatedLocationCache(from: quests)
        } catch {
            print("[SYSTEM] Failed to save daily quests: \(error)")
        }
    }

    /// Load daily quests
    func loadDailyQuests() -> [DailyQuest]? {
        if let cachedDailyQuests {
            return cachedDailyQuests
        }

        guard let data = UserDefaults.standard.data(forKey: dailyQuestsKey) else {
            return nil
        }

        do {
            var quests = try decoder.decode([DailyQuest].self, from: data)
            let repairedCount = restoreValidatedLocationsIfNeeded(in: &quests)
            if repairedCount > 0 {
                do {
                    let repairedData = try encoder.encode(quests)
                    if repairedData != cachedDailyQuestsData {
                        UserDefaults.standard.set(repairedData, forKey: dailyQuestsKey)
                    }
                    cachedDailyQuestsData = repairedData
                } catch {
                    print("[SYSTEM] Failed to persist repaired location quests: \(error)")
                }
                print("[SYSTEM] Restored \(repairedCount) validated location quest(s) from cache")
            } else {
                cachedDailyQuestsData = data
            }
            cachedDailyQuests = quests
            return quests
        } catch {
            print("[SYSTEM] Failed to load daily quests: \(error)")
            return nil
        }
    }

    func cachedValidatedLocation(for address: String) -> LocationCoordinate? {
        let normalized = normalizeAddress(address)
        guard !normalized.isEmpty else { return nil }
        return loadValidatedLocationCache().byAddress[normalized]
    }

    func cachedValidatedLocation(forQuestID questID: UUID) -> LocationCoordinate? {
        loadValidatedLocationCache().byQuestID[questID.uuidString]
    }

    func cacheValidatedLocation(_ coordinate: LocationCoordinate, forQuestID questID: UUID?, address: String?) {
        var cache = loadValidatedLocationCache()
        if let questID {
            cache.byQuestID[questID.uuidString] = coordinate
        }
        if let address {
            let normalized = normalizeAddress(address)
            if !normalized.isEmpty {
                cache.byAddress[normalized] = coordinate
            }
        }
        saveValidatedLocationCache(cache)
    }

    /// Reset daily quests (called at midnight)
    func resetDailyQuests() -> [DailyQuest] {
        let emptyQuests: [DailyQuest] = []
        saveDailyQuests(emptyQuests)
        return emptyQuests
    }

    // MARK: - Boss Fights

    /// Save boss fights
    func saveBossFights(_ bossFights: [BossFight]) {
        do {
            let data = try encoder.encode(bossFights)
            if data == cachedBossFightsData {
                cachedBossFights = bossFights
                return
            }
            UserDefaults.standard.set(data, forKey: bossFightsKey)
            cachedBossFights = bossFights
            cachedBossFightsData = data
        } catch {
            print("[SYSTEM] Failed to save boss fights: \(error)")
        }
    }

    private func persistValidatedLocationCache(from quests: [DailyQuest]) {
        var cache = loadValidatedLocationCache()

        for quest in quests where quest.trackingType == .location {
            guard let coordinate = quest.locationCoordinate else { continue }

            cache.byQuestID[quest.id.uuidString] = coordinate

            if let address = quest.locationAddress {
                let normalized = normalizeAddress(address)
                if !normalized.isEmpty {
                    cache.byAddress[normalized] = coordinate
                }
            }

            let canonicalName = normalizeAddress(coordinate.locationName)
            if !canonicalName.isEmpty {
                cache.byAddress[canonicalName] = coordinate
            }
        }

        saveValidatedLocationCache(cache)
    }

    private func restoreValidatedLocationsIfNeeded(in quests: inout [DailyQuest]) -> Int {
        let cache = loadValidatedLocationCache()
        var restoredCount = 0

        for index in quests.indices where quests[index].trackingType == .location && quests[index].locationCoordinate == nil {
            let questIDKey = quests[index].id.uuidString
            if let byID = cache.byQuestID[questIDKey] {
                quests[index].locationCoordinate = byID
                restoredCount += 1
                continue
            }

            guard let address = quests[index].locationAddress else { continue }
            let normalized = normalizeAddress(address)
            guard !normalized.isEmpty else { continue }
            if let byAddress = cache.byAddress[normalized] {
                quests[index].locationCoordinate = byAddress
                restoredCount += 1
            }
        }

        return restoredCount
    }

    private func loadValidatedLocationCache() -> ValidatedLocationCache {
        if let cachedValidatedLocationCache {
            return cachedValidatedLocationCache
        }

        guard let data = UserDefaults.standard.data(forKey: validatedLocationCacheKey) else {
            return ValidatedLocationCache()
        }
        do {
            let cache = try decoder.decode(ValidatedLocationCache.self, from: data)
            cachedValidatedLocationCache = cache
            cachedValidatedLocationCacheData = data
            return cache
        } catch {
            return ValidatedLocationCache()
        }
    }

    private func saveValidatedLocationCache(_ cache: ValidatedLocationCache) {
        do {
            let data = try encoder.encode(cache)
            if data == cachedValidatedLocationCacheData {
                cachedValidatedLocationCache = cache
                return
            }
            UserDefaults.standard.set(data, forKey: validatedLocationCacheKey)
            cachedValidatedLocationCache = cache
            cachedValidatedLocationCacheData = data
        } catch {
            print("[SYSTEM] Failed to save validated location cache: \(error)")
        }
    }

    private func normalizeAddress(_ raw: String) -> String {
        raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Load boss fights
    func loadBossFights() -> [BossFight]? {
        if let cachedBossFights {
            return cachedBossFights
        }

        guard let data = UserDefaults.standard.data(forKey: bossFightsKey) else {
            return nil
        }

        do {
            let bossFights = try decoder.decode([BossFight].self, from: data)
            cachedBossFights = bossFights
            cachedBossFightsData = data
            return bossFights
        } catch {
            print("[SYSTEM] Failed to load boss fights: \(error)")
            return nil
        }
    }

    // MARK: - Quest History

    /// Record a completed quest in history
    func recordCompletedQuest(_ quest: any QuestProtocol, xpAwarded: Int, goldAwarded: Int) {
        var history = loadQuestHistory()

        let record = QuestHistoryRecord(
            questId: quest.id,
            questTitle: quest.title,
            questType: quest.questType,
            difficulty: quest.difficulty,
            completedAt: Date(),
            xpAwarded: xpAwarded,
            goldAwarded: goldAwarded
        )

        history.append(record)

        // Keep only last 1000 records
        if history.count > 1000 {
            history = Array(history.suffix(1000))
        }

        saveQuestHistory(history)
    }

    /// Save quest history
    private func saveQuestHistory(_ history: [QuestHistoryRecord]) {
        do {
            let data = try encoder.encode(history)
            if data == cachedQuestHistoryData {
                cachedQuestHistory = history
                return
            }
            UserDefaults.standard.set(data, forKey: questHistoryKey)
            cachedQuestHistory = history
            cachedQuestHistoryData = data
        } catch {
            print("[SYSTEM] Failed to save quest history: \(error)")
        }
    }

    /// Load quest history
    func loadQuestHistory() -> [QuestHistoryRecord] {
        if let cachedQuestHistory {
            return cachedQuestHistory
        }

        guard let data = UserDefaults.standard.data(forKey: questHistoryKey) else {
            return []
        }

        do {
            let history = try decoder.decode([QuestHistoryRecord].self, from: data)
            cachedQuestHistory = history
            cachedQuestHistoryData = data
            return history
        } catch {
            print("[SYSTEM] Failed to load quest history: \(error)")
            return []
        }
    }

    /// Replace quest history with imported/synced records.
    func overwriteQuestHistory(_ history: [QuestHistoryRecord]) {
        saveQuestHistory(history)
    }

    /// Get statistics from quest history
    func getQuestStatistics() -> QuestStatistics {
        let history = loadQuestHistory()
        let now = Date()
        let calendar = Calendar.current

        // Today's stats
        let todayStart = calendar.startOfDay(for: now)
        let todayQuests = history.filter { $0.completedAt >= todayStart }

        // This week's stats
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? todayStart
        let weekQuests = history.filter { $0.completedAt >= weekStart }

        // This month's stats
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? todayStart
        let monthQuests = history.filter { $0.completedAt >= monthStart }

        return QuestStatistics(
            totalCompleted: history.count,
            todayCompleted: todayQuests.count,
            weekCompleted: weekQuests.count,
            monthCompleted: monthQuests.count,
            totalXPEarned: history.reduce(0) { $0 + $1.xpAwarded },
            totalGoldEarned: history.reduce(0) { $0 + $1.goldAwarded },
            dailyQuestsCompleted: history.filter { $0.questType == .daily }.count,
            bossesDefeated: history.filter { $0.questType == .boss }.count,
            dungeonsCleared: history.filter { $0.questType == .dungeon }.count
        )
    }
}

// MARK: - Quest History Record

struct QuestHistoryRecord: Codable {
    let questId: UUID
    let questTitle: String
    let questType: QuestType
    let difficulty: QuestDifficulty
    let completedAt: Date
    let xpAwarded: Int
    let goldAwarded: Int
}

// MARK: - Quest Statistics

struct QuestStatistics {
    let totalCompleted: Int
    let todayCompleted: Int
    let weekCompleted: Int
    let monthCompleted: Int
    let totalXPEarned: Int
    let totalGoldEarned: Int
    let dailyQuestsCompleted: Int
    let bossesDefeated: Int
    let dungeonsCleared: Int
}

// MARK: - Activity Log Data Manager

/// Persists recent activity entries for the Status screen.
class ActivityLogDataManager {

    static let shared = ActivityLogDataManager()

    private let activityLogKey = "gamelife_recent_activity"
    private let minimumRetentionWindow: TimeInterval = 24 * 60 * 60
    private let maxRetainedEntries = 250
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var cachedEntries: [ActivityLogEntry]?
    private var cachedEntriesData: Data?

    private init() {}

    func loadActivityLog() -> [ActivityLogEntry] {
        if let cachedEntries {
            return trimmedEntriesPreservingRetentionWindow(cachedEntries)
        }

        guard let data = UserDefaults.standard.data(forKey: activityLogKey) else {
            return []
        }

        do {
            let entries = try decoder.decode([ActivityLogEntry].self, from: data)
            let trimmedEntries = trimmedEntriesPreservingRetentionWindow(entries)

            if trimmedEntries.count != entries.count {
                saveActivityLog(trimmedEntries)
            }

            cachedEntries = trimmedEntries
            cachedEntriesData = data
            return trimmedEntries
        } catch {
            print("[SYSTEM] Failed to load recent activity: \(error)")
            return []
        }
    }

    func saveActivityLog(_ entries: [ActivityLogEntry]) {
        do {
            let trimmedEntries = trimmedEntriesPreservingRetentionWindow(entries)
            let data = try encoder.encode(trimmedEntries)
            if data == cachedEntriesData {
                cachedEntries = trimmedEntries
                return
            }
            UserDefaults.standard.set(data, forKey: activityLogKey)
            cachedEntries = trimmedEntries
            cachedEntriesData = data
        } catch {
            print("[SYSTEM] Failed to save recent activity: \(error)")
        }
    }

    func appendActivity(_ entry: ActivityLogEntry) {
        var entries = cachedEntries ?? loadActivityLog()
        entries.insert(entry, at: 0)
        saveActivityLog(entries)
    }

    private func trimmedEntriesPreservingRetentionWindow(_ entries: [ActivityLogEntry], now: Date = Date()) -> [ActivityLogEntry] {
        let sortedEntries = entries.sorted { $0.timestamp > $1.timestamp }
        let retentionCutoff = now.addingTimeInterval(-minimumRetentionWindow)

        let guaranteedEntries = sortedEntries.filter { $0.timestamp >= retentionCutoff }
        let olderEntries = sortedEntries.filter { $0.timestamp < retentionCutoff }

        if guaranteedEntries.count >= maxRetainedEntries {
            return guaranteedEntries
        }

        let remainingCapacity = max(0, maxRetainedEntries - guaranteedEntries.count)
        return guaranteedEntries + olderEntries.prefix(remainingCapacity)
    }
}

// MARK: - Runtime Cache Manager

/// Centralized local-first cache layer used to keep derived/UI data snappy
/// between app launches and during heavy refresh cycles.
final class RuntimeCacheManager {

    static let shared = RuntimeCacheManager()

    private enum Keys {
        static let questOrdering = "praxis_cache_quest_ordering"
        static let healthDailySnapshot = "praxis_cache_health_daily_snapshot"
        static let locationRuntimeSnapshot = "praxis_cache_location_runtime_snapshot"
        static let achievementProgressSnapshot = "praxis_cache_achievement_progress"
        static let marketplaceCatalogSnapshot = "praxis_cache_marketplace_catalog"
        static let statusUISnapshot = "praxis_cache_status_ui_snapshot"
    }

    struct QuestOrderingSnapshot: Codable {
        let digest: Int
        let orderedQuestIDs: [UUID]
        let nextUpQuestIDs: [UUID]
        let savedAt: Date
    }

    struct HealthDailySnapshot: Codable {
        let dayKey: String
        let steps: Int
        let sleepHours: Double
        let activeEnergy: Double
        let workoutMinutes: Int
        let workoutCount: Int
        let standHours: Int
        let mindfulMinutes: Int
        let distanceKM: Double
        let waterGlasses: Double
        let bodyWeightLB: Double
        let bodyFatPercent: Double
        let lastSyncDate: Date?
        let lastDetectedEvent: String
    }

    struct LocationRuntimeSnapshot: Codable {
        let regionEntryTimes: [String: Date]
        let lastTrackingEventDate: Date?
        let lastTrackingEventMessage: String
    }

    struct AchievementProgressSnapshot: Codable {
        let values: [String: Int]
        let savedAt: Date
    }

    struct MarketplaceCatalogSnapshot: Codable {
        let rewards: [MarketplaceReward]
        let savedAt: Date
    }

    struct StatusUISnapshot: Codable {
        let playerLevel: Int
        let currentXP: Int
        let maxXP: Int
        let rank: String
        let hp: Int
        let maxHP: Int
        let gold: Int
        let streak: Int
        let stats: [Stat]
        let recentActivity: [ActivityLogEntry]
        let savedAt: Date
    }

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var cachedDataByKey: [String: Data] = [:]

    private init() {}

    func saveQuestOrdering(_ snapshot: QuestOrderingSnapshot) {
        save(snapshot, forKey: Keys.questOrdering)
    }

    func loadQuestOrdering() -> QuestOrderingSnapshot? {
        load(QuestOrderingSnapshot.self, forKey: Keys.questOrdering)
    }

    func saveHealthDailySnapshot(_ snapshot: HealthDailySnapshot) {
        save(snapshot, forKey: Keys.healthDailySnapshot)
    }

    func loadHealthDailySnapshot() -> HealthDailySnapshot? {
        load(HealthDailySnapshot.self, forKey: Keys.healthDailySnapshot)
    }

    func saveLocationRuntimeSnapshot(_ snapshot: LocationRuntimeSnapshot) {
        save(snapshot, forKey: Keys.locationRuntimeSnapshot)
    }

    func loadLocationRuntimeSnapshot() -> LocationRuntimeSnapshot? {
        load(LocationRuntimeSnapshot.self, forKey: Keys.locationRuntimeSnapshot)
    }

    func saveAchievementProgressSnapshot(_ snapshot: AchievementProgressSnapshot) {
        save(snapshot, forKey: Keys.achievementProgressSnapshot)
    }

    func loadAchievementProgressSnapshot() -> AchievementProgressSnapshot? {
        load(AchievementProgressSnapshot.self, forKey: Keys.achievementProgressSnapshot)
    }

    func saveMarketplaceCatalogSnapshot(_ snapshot: MarketplaceCatalogSnapshot) {
        save(snapshot, forKey: Keys.marketplaceCatalogSnapshot)
    }

    func loadMarketplaceCatalogSnapshot(maxAge: TimeInterval = 86_400) -> MarketplaceCatalogSnapshot? {
        guard let snapshot = load(MarketplaceCatalogSnapshot.self, forKey: Keys.marketplaceCatalogSnapshot) else {
            return nil
        }
        guard Date().timeIntervalSince(snapshot.savedAt) <= maxAge else { return nil }
        return snapshot
    }

    func saveStatusUISnapshot(_ snapshot: StatusUISnapshot) {
        save(snapshot, forKey: Keys.statusUISnapshot)
    }

    func loadStatusUISnapshot(maxAge: TimeInterval = 900) -> StatusUISnapshot? {
        guard let snapshot = load(StatusUISnapshot.self, forKey: Keys.statusUISnapshot) else {
            return nil
        }
        guard Date().timeIntervalSince(snapshot.savedAt) <= maxAge else { return nil }
        return snapshot
    }

    private func save<T: Codable>(_ value: T, forKey key: String) {
        do {
            let data = try encoder.encode(value)
            if cachedDataByKey[key] == data {
                return
            }
            UserDefaults.standard.set(data, forKey: key)
            cachedDataByKey[key] = data
        } catch {
            print("[SYSTEM] Failed to cache \(key): \(error)")
        }
    }

    private func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        cachedDataByKey[key] = data
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            return nil
        }
    }
}

// MARK: - Settings Manager

/// Manages app settings
class SettingsManager {

    static let shared = SettingsManager()

    private init() {}

    // MARK: - User Defaults Keys

    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let soundEnabled = "soundEnabled"
        static let hapticEnabled = "hapticEnabled"
        static let useCustomAppFont = "useCustomAppFont"
        static let showQuestCompletionGrid = "showQuestCompletionGrid"
        static let showQuestNextUpSection = "showQuestNextUpSection"
        static let dailyReminderTime = "dailyReminderTime"
        static let eveningReminderEnabled = "eveningReminderEnabled"
        static let streakAlertsEnabled = "streakAlertsEnabled"
        static let autoTrackHealthKit = "autoTrackHealthKit"
        static let autoTrackScreenTime = "autoTrackScreenTime"
        static let autoTrackLocation = "autoTrackLocation"
        static let deathMechanicEnabled = "deathMechanicEnabled"
    }

    // MARK: - Onboarding

    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }

    // MARK: - Sound & Haptics

    var soundEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.soundEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.soundEnabled) }
    }

    var hapticEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.hapticEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.hapticEnabled) }
    }

    var useCustomAppFont: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.useCustomAppFont) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.useCustomAppFont) }
    }

    var showQuestCompletionGrid: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.showQuestCompletionGrid) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.showQuestCompletionGrid) }
    }

    var showQuestNextUpSection: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.showQuestNextUpSection) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.showQuestNextUpSection) }
    }

    // MARK: - Notifications

    var dailyReminderTime: Date {
        get {
            UserDefaults.standard.object(forKey: Keys.dailyReminderTime) as? Date ?? defaultReminderTime
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.dailyReminderTime)
        }
    }

    var eveningReminderEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.eveningReminderEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.eveningReminderEnabled) }
    }

    var streakAlertsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.streakAlertsEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.streakAlertsEnabled) }
    }

    private var defaultReminderTime: Date {
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    // MARK: - Auto-Tracking

    var autoTrackHealthKit: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.autoTrackHealthKit) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.autoTrackHealthKit) }
    }

    var autoTrackScreenTime: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.autoTrackScreenTime) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.autoTrackScreenTime) }
    }

    var autoTrackLocation: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.autoTrackLocation) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.autoTrackLocation) }
    }

    var deathMechanicEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.deathMechanicEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.deathMechanicEnabled) }
    }

    // MARK: - Reset

    func resetAllSettings() {
        guard let domain = Bundle.main.bundleIdentifier else { return }
        UserDefaults.standard.removePersistentDomain(forName: domain)
    }

    func setDefaults() {
        let defaults: [String: Any] = [
            Keys.soundEnabled: true,
            Keys.hapticEnabled: true,
            Keys.useCustomAppFont: false,
            Keys.showQuestCompletionGrid: true,
            Keys.showQuestNextUpSection: true,
            Keys.eveningReminderEnabled: true,
            Keys.streakAlertsEnabled: true,
            Keys.autoTrackHealthKit: false,  // Disabled by default - requires Info.plist setup
            Keys.autoTrackScreenTime: false, // Disabled by default - requires entitlement
            Keys.autoTrackLocation: false,   // Disabled by default - requires Info.plist setup
            Keys.deathMechanicEnabled: true
        ]

        UserDefaults.standard.register(defaults: defaults)
    }
}

// MARK: - Location Data Manager

/// Manages saved locations for geofencing
class LocationDataManager {

    static let shared = LocationDataManager()

    private let locationsKey = "gamelife_tracked_locations"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var cachedLocations: [TrackedLocation]?
    private var cachedLocationsData: Data?

    private init() {}

    /// Save tracked locations
    func saveLocations(_ locations: [TrackedLocation]) {
        do {
            let data = try encoder.encode(locations)
            if data == cachedLocationsData {
                cachedLocations = locations
                return
            }
            UserDefaults.standard.set(data, forKey: locationsKey)
            cachedLocations = locations
            cachedLocationsData = data
        } catch {
            print("[SYSTEM] Failed to save locations: \(error)")
        }
    }

    /// Load tracked locations
    func loadLocations() -> [TrackedLocation] {
        if let cachedLocations {
            return cachedLocations
        }

        guard let data = UserDefaults.standard.data(forKey: locationsKey) else {
            return []
        }

        do {
            let locations = try decoder.decode([TrackedLocation].self, from: data)
            cachedLocations = locations
            cachedLocationsData = data
            return locations
        } catch {
            print("[SYSTEM] Failed to load locations: \(error)")
            return []
        }
    }

    /// Add a new location
    func addLocation(_ location: TrackedLocation) {
        var locations = loadLocations()
        locations.append(location)
        saveLocations(locations)
    }

    /// Remove a location
    func removeLocation(_ location: TrackedLocation) {
        var locations = loadLocations()
        locations.removeAll { $0.id == location.id }
        saveLocations(locations)
    }
}
