//
//  PlayerModels.swift
//  GAMELIFE
//
//  The System recognizes you as a Player.
//  These models define your existence within the System.
//

import Foundation
import SwiftUI

// MARK: - Core Stats (The Six Pillars)

/// The six fundamental attributes that define a Player's power
enum StatType: String, CaseIterable, Codable, Identifiable {
    case strength = "STR"      // Physical exercise
    case intelligence = "INT"  // Reading, studying, coding
    case agility = "AGI"       // Stretching, yoga, promptness
    case vitality = "VIT"      // Sleep, water, nutrition
    case willpower = "WIL"     // Resisting bad habits
    case spirit = "SPI"        // Meditation, mindfulness, gratitude

    var id: String { rawValue }

    var fullName: String {
        switch self {
        case .strength: return "Strength"
        case .intelligence: return "Intelligence"
        case .agility: return "Agility"
        case .vitality: return "Vitality"
        case .willpower: return "Willpower"
        case .spirit: return "Spirit"
        }
    }

    var description: String {
        switch self {
        case .strength: return "Physical power. Train your vessel."
        case .intelligence: return "Mental acuity. Sharpen your mind."
        case .agility: return "Swift action. Move with purpose."
        case .vitality: return "Life force. Maintain your foundation."
        case .willpower: return "Inner resolve. Resist the shadows."
        case .spirit: return "Soul strength. Find your center."
        }
    }

    var icon: String {
        switch self {
        case .strength: return "figure.strengthtraining.traditional"
        case .intelligence: return "brain.head.profile"
        case .agility: return "figure.run"
        case .vitality: return "heart.fill"
        case .willpower: return "shield.fill"
        case .spirit: return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .strength: return SystemTheme.statStrength
        case .intelligence: return SystemTheme.statIntelligence
        case .agility: return SystemTheme.statAgility
        case .vitality: return SystemTheme.statVitality
        case .willpower: return SystemTheme.statWillpower
        case .spirit: return SystemTheme.statSpirit
        }
    }
}

// MARK: - Stat Value

/// Represents a single stat with its current and maximum values
struct Stat: Codable, Identifiable {
    let id: UUID
    let type: StatType
    var baseValue: Int
    var bonusValue: Int
    var experience: Int

    var totalValue: Int {
        min(baseValue + bonusValue, 999) // Cap at 999 like Solo Leveling
    }

    var level: Int {
        // Every 100 XP in a stat = 1 stat point
        experience / 100
    }

    var progressToNextPoint: Double {
        Double(experience % 100) / 100.0
    }

    init(type: StatType, baseValue: Int = 0, bonusValue: Int = 0, experience: Int = 0) {
        self.id = UUID()
        self.type = type
        self.baseValue = baseValue
        self.bonusValue = bonusValue
        self.experience = experience
    }
}

// MARK: - Player Rank

/// Player ranks inspired by Solo Leveling's hunter ranking system
enum PlayerRank: String, Codable, CaseIterable {
    case e = "E"
    case d = "D"
    case c = "C"
    case b = "B"
    case a = "A"
    case s = "S"
    case ss = "SS"
    case sss = "SSS"
    case monarch = "MONARCH"

    var minLevel: Int {
        switch self {
        case .e: return 1
        case .d: return 10
        case .c: return 25
        case .b: return 50
        case .a: return 75
        case .s: return 100
        case .ss: return 150
        case .sss: return 200
        case .monarch: return 300
        }
    }

    var title: String {
        switch self {
        case .e: return "Awakened"
        case .d: return "Novice Hunter"
        case .c: return "Hunter"
        case .b: return "Elite Hunter"
        case .a: return "Veteran Hunter"
        case .s: return "National Level Hunter"
        case .ss: return "Transcendent"
        case .sss: return "Apex Predator"
        case .monarch: return "Shadow Monarch"
        }
    }

    var glowColor: Color {
        switch self {
        case .e: return .gray
        case .d: return .green
        case .c: return .blue
        case .b: return .purple
        case .a: return .orange
        case .s: return .red
        case .ss: return SystemTheme.primaryBlue
        case .sss: return SystemTheme.primaryPurple
        case .monarch: return .yellow
        }
    }

    static func rank(forLevel level: Int) -> PlayerRank {
        for rank in PlayerRank.allCases.reversed() {
            if level >= rank.minLevel {
                return rank
            }
        }
        return .e
    }
}

// MARK: - Player Model

/// The Player - You. Your digital avatar within the System.
@Observable
class Player: Codable {
    var id: UUID
    var name: String
    var title: String
    var originStory: String
    var createdAt: Date

    // Core Progression
    var level: Int
    var currentXP: Int
    var totalXP: Int
    var gold: Int

    // Stats
    var stats: [StatType: Stat]

    // Streak Tracking
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDate: Date?
    var streakShieldCharges: Int

    // Achievements & Collections
    var unlockedAchievements: [UnlockedAchievement]
    var unlockedTitles: [String]
    var shadowSoldiers: [ShadowSoldier]
    var completedQuestCount: Int
    var defeatedBossCount: Int
    var dungeonsClearedCount: Int

    // Health (loss-aversion loop)
    var maxHP: Int
    var currentHP: Int

    // Penalty System
    var penaltyCount: Int
    var inPenaltyZone: Bool

    // Computed Properties
    var rank: PlayerRank {
        PlayerRank.rank(forLevel: level)
    }

    var xpRequiredForNextLevel: Int {
        GameFormulas.xpRequired(forLevel: level + 1)
    }

    var xpProgress: Double {
        let currentLevelXP = level > 1 ? GameFormulas.xpRequired(forLevel: level) : 0
        let nextLevelXP = GameFormulas.xpRequired(forLevel: level + 1)
        let xpInCurrentLevel = max(0, currentXP - currentLevelXP)
        let xpNeeded = max(1, nextLevelXP - currentLevelXP)
        return min(1.0, max(0.0, Double(xpInCurrentLevel) / Double(xpNeeded)))
    }

    var statArray: [Stat] {
        StatType.allCases.compactMap { stats[$0] }
    }

    var totalStatPoints: Int {
        stats.values.reduce(0) { $0 + $1.totalValue }
    }

    var powerLevel: Int {
        // Power Level = (Total Stats * Level) / 10
        (totalStatPoints * level) / 10
    }

    var hpProgress: Double {
        guard maxHP > 0 else { return 0 }
        return min(1.0, max(0.0, Double(currentHP) / Double(maxHP)))
    }

    init(name: String = "Hunter", originStory: String = "") {
        self.id = UUID()
        self.name = name
        self.title = "Awakened"
        self.originStory = originStory
        self.createdAt = Date()

        self.level = 1
        self.currentXP = 0
        self.totalXP = 0
        self.gold = 0

        // Initialize all stats at base value 0 for clean progression from zero.
        var initialStats: [StatType: Stat] = [:]
        for type in StatType.allCases {
            initialStats[type] = Stat(type: type, baseValue: 0)
        }
        self.stats = initialStats

        self.currentStreak = 0
        self.longestStreak = 0
        self.lastActiveDate = nil
        self.streakShieldCharges = 0

        self.unlockedTitles = ["Awakened"]
        self.unlockedAchievements = []
        self.shadowSoldiers = []
        self.completedQuestCount = 0
        self.defeatedBossCount = 0
        self.dungeonsClearedCount = 0

        self.maxHP = 100
        self.currentHP = 100

        self.penaltyCount = 0
        self.inPenaltyZone = false
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, name, title, originStory, createdAt
        case level, currentXP, totalXP, gold
        case stats
        case currentStreak, longestStreak, lastActiveDate
        case streakShieldCharges
        case unlockedAchievements, unlockedTitles, shadowSoldiers
        case completedQuestCount, defeatedBossCount, dungeonsClearedCount
        case maxHP, currentHP
        case penaltyCount, inPenaltyZone
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        title = try container.decode(String.self, forKey: .title)
        originStory = try container.decode(String.self, forKey: .originStory)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        level = try container.decode(Int.self, forKey: .level)
        currentXP = try container.decode(Int.self, forKey: .currentXP)
        totalXP = try container.decode(Int.self, forKey: .totalXP)
        gold = try container.decode(Int.self, forKey: .gold)
        stats = try container.decode([StatType: Stat].self, forKey: .stats)
        currentStreak = try container.decode(Int.self, forKey: .currentStreak)
        longestStreak = try container.decode(Int.self, forKey: .longestStreak)
        lastActiveDate = try container.decodeIfPresent(Date.self, forKey: .lastActiveDate)
        streakShieldCharges = max(0, try container.decodeIfPresent(Int.self, forKey: .streakShieldCharges) ?? 0)
        unlockedAchievements = try container.decodeIfPresent([UnlockedAchievement].self, forKey: .unlockedAchievements) ?? []
        unlockedTitles = try container.decode([String].self, forKey: .unlockedTitles)
        shadowSoldiers = try container.decode([ShadowSoldier].self, forKey: .shadowSoldiers)
        completedQuestCount = try container.decode(Int.self, forKey: .completedQuestCount)
        defeatedBossCount = try container.decode(Int.self, forKey: .defeatedBossCount)
        dungeonsClearedCount = try container.decode(Int.self, forKey: .dungeonsClearedCount)
        let decodedMaxHP = max(1, try container.decodeIfPresent(Int.self, forKey: .maxHP) ?? 100)
        let decodedCurrentHP = try container.decodeIfPresent(Int.self, forKey: .currentHP) ?? decodedMaxHP
        maxHP = decodedMaxHP
        currentHP = min(decodedMaxHP, max(0, decodedCurrentHP))
        penaltyCount = try container.decode(Int.self, forKey: .penaltyCount)
        inPenaltyZone = try container.decode(Bool.self, forKey: .inPenaltyZone)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(title, forKey: .title)
        try container.encode(originStory, forKey: .originStory)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(level, forKey: .level)
        try container.encode(currentXP, forKey: .currentXP)
        try container.encode(totalXP, forKey: .totalXP)
        try container.encode(gold, forKey: .gold)
        try container.encode(stats, forKey: .stats)
        try container.encode(currentStreak, forKey: .currentStreak)
        try container.encode(longestStreak, forKey: .longestStreak)
        try container.encode(lastActiveDate, forKey: .lastActiveDate)
        try container.encode(streakShieldCharges, forKey: .streakShieldCharges)
        try container.encode(unlockedAchievements, forKey: .unlockedAchievements)
        try container.encode(unlockedTitles, forKey: .unlockedTitles)
        try container.encode(shadowSoldiers, forKey: .shadowSoldiers)
        try container.encode(completedQuestCount, forKey: .completedQuestCount)
        try container.encode(defeatedBossCount, forKey: .defeatedBossCount)
        try container.encode(dungeonsClearedCount, forKey: .dungeonsClearedCount)
        try container.encode(maxHP, forKey: .maxHP)
        try container.encode(currentHP, forKey: .currentHP)
        try container.encode(penaltyCount, forKey: .penaltyCount)
        try container.encode(inPenaltyZone, forKey: .inPenaltyZone)
    }
}

// MARK: - Achievement System

enum AchievementRarity: String, Codable, CaseIterable {
    case common
    case rare
    case epic
    case legendary

    var displayName: String {
        switch self {
        case .common: return "Common"
        case .rare: return "Rare"
        case .epic: return "Epic"
        case .legendary: return "Legendary"
        }
    }

    var color: Color {
        switch self {
        case .common: return Color(hex: "B08D57")
        case .rare: return Color(hex: "C0C0C0")
        case .epic: return SystemTheme.goldColor
        case .legendary: return Color(hex: "E5E4E2")
        }
    }
}

enum AchievementCategory: String, Codable, CaseIterable, Identifiable {
    case grind
    case arena
    case scholar
    case vault

    var id: String { rawValue }

    var title: String {
        switch self {
        case .grind: return "The Grind"
        case .arena: return "The Arena"
        case .scholar: return "The Scholar"
        case .vault: return "The Vault"
        }
    }
}

struct AchievementReward {
    let xp: Int
    let gold: Int
    let title: String?
}

struct AchievementDefinition: Identifiable {
    let id: String
    let title: String
    let description: String
    let requirementText: String
    let category: AchievementCategory
    let rarity: AchievementRarity
    let icon: String
    let targetValue: Int
    let reward: AchievementReward
}

struct UnlockedAchievement: Codable, Identifiable {
    let id: String
    let unlockedAt: Date
}

struct AchievementProgress {
    let current: Int
    let target: Int

    var fraction: Double {
        guard target > 0 else { return 0 }
        return min(1, max(0, Double(current) / Double(target)))
    }
}

enum AchievementCatalog {
    static let all: [AchievementDefinition] = [
        AchievementDefinition(
            id: "grind_streak_3",
            title: "Momentum Initiated",
            description: "Start the consistency engine.",
            requirementText: "Reach a 3-day streak.",
            category: .grind,
            rarity: .common,
            icon: "flame.fill",
            targetValue: 3,
            reward: AchievementReward(xp: 20, gold: 5, title: nil)
        ),
        AchievementDefinition(
            id: "grind_streak_14",
            title: "The Unbroken",
            description: "Two weeks without breaking stride.",
            requirementText: "Reach a 14-day streak.",
            category: .grind,
            rarity: .rare,
            icon: "flame.circle.fill",
            targetValue: 14,
            reward: AchievementReward(xp: 120, gold: 25, title: "The Unbroken")
        ),
        AchievementDefinition(
            id: "grind_streak_30",
            title: "Discipline Engine",
            description: "One full month of execution.",
            requirementText: "Reach a 30-day streak.",
            category: .grind,
            rarity: .epic,
            icon: "calendar.badge.checkmark",
            targetValue: 30,
            reward: AchievementReward(xp: 250, gold: 60, title: nil)
        ),
        AchievementDefinition(
            id: "arena_first_boss",
            title: "First Blood",
            description: "Your first boss has fallen.",
            requirementText: "Defeat 1 boss.",
            category: .arena,
            rarity: .common,
            icon: "bolt.shield.fill",
            targetValue: 1,
            reward: AchievementReward(xp: 60, gold: 15, title: nil)
        ),
        AchievementDefinition(
            id: "arena_boss_10",
            title: "Giant Slayer",
            description: "Battle-tested against major goals.",
            requirementText: "Defeat 10 bosses.",
            category: .arena,
            rarity: .epic,
            icon: "crown.fill",
            targetValue: 10,
            reward: AchievementReward(xp: 300, gold: 80, title: "Giant Slayer")
        ),
        AchievementDefinition(
            id: "scholar_training_5",
            title: "Focus Cadet",
            description: "You entered deep work mode repeatedly.",
            requirementText: "Complete 5 training sessions.",
            category: .scholar,
            rarity: .common,
            icon: "timer",
            targetValue: 5,
            reward: AchievementReward(xp: 70, gold: 15, title: nil)
        ),
        AchievementDefinition(
            id: "scholar_training_25",
            title: "Deep Work Adept",
            description: "Sustained concentration forged.",
            requirementText: "Complete 25 training sessions.",
            category: .scholar,
            rarity: .rare,
            icon: "brain.head.profile",
            targetValue: 25,
            reward: AchievementReward(xp: 180, gold: 40, title: nil)
        ),
        AchievementDefinition(
            id: "vault_purchase_1",
            title: "First Loot",
            description: "You converted effort into reward.",
            requirementText: "Purchase 1 shop reward.",
            category: .vault,
            rarity: .common,
            icon: "cart.fill.badge.plus",
            targetValue: 1,
            reward: AchievementReward(xp: 40, gold: 0, title: nil)
        ),
        AchievementDefinition(
            id: "vault_purchase_10",
            title: "Quartermaster",
            description: "You consistently reinvest your grind.",
            requirementText: "Purchase 10 shop rewards.",
            category: .vault,
            rarity: .rare,
            icon: "shippingbox.fill",
            targetValue: 10,
            reward: AchievementReward(xp: 120, gold: 30, title: nil)
        ),
        AchievementDefinition(
            id: "vault_spend_1000",
            title: "Golden Circuit",
            description: "Serious economy throughput.",
            requirementText: "Spend 1000 Gold in the shop.",
            category: .vault,
            rarity: .epic,
            icon: "banknote.fill",
            targetValue: 1000,
            reward: AchievementReward(xp: 220, gold: 50, title: nil)
        ),
        AchievementDefinition(
            id: "quests_complete_25",
            title: "Questline Initiated",
            description: "First major milestone reached.",
            requirementText: "Complete 25 quests.",
            category: .grind,
            rarity: .common,
            icon: "checkmark.circle.fill",
            targetValue: 25,
            reward: AchievementReward(xp: 80, gold: 20, title: nil)
        ),
        AchievementDefinition(
            id: "quests_complete_100",
            title: "System Veteran",
            description: "Relentless completion pressure applied.",
            requirementText: "Complete 100 quests.",
            category: .grind,
            rarity: .legendary,
            icon: "medal.fill",
            targetValue: 100,
            reward: AchievementReward(xp: 500, gold: 120, title: "System Veteran")
        ),
        AchievementDefinition(
            id: "legend_max_stat_100",
            title: "Apex Build",
            description: "A stat crossed elite threshold.",
            requirementText: "Reach 100 in any one stat.",
            category: .arena,
            rarity: .legendary,
            icon: "hexagon.fill",
            targetValue: 100,
            reward: AchievementReward(xp: 600, gold: 150, title: "Apex Hunter")
        )
    ]

    static func definition(for id: String) -> AchievementDefinition? {
        all.first(where: { $0.id == id })
    }
}

// MARK: - Shadow Soldier (Collectibles)

/// Shadow Soldiers - Rare collectibles earned through exceptional performance
struct ShadowSoldier: Codable, Identifiable {
    let id: UUID
    let name: String
    let rank: SoldierRank
    let obtainedDate: Date
    let source: String

    enum SoldierRank: String, Codable {
        case normal = "Normal"
        case elite = "Elite"
        case knight = "Knight"
        case general = "General"
        case marshal = "Marshal"
    }

    var icon: String {
        switch rank {
        case .normal: return "person.fill"
        case .elite: return "person.fill.badge.plus"
        case .knight: return "shield.lefthalf.filled"
        case .general: return "star.fill"
        case .marshal: return "crown.fill"
        }
    }
}

// MARK: - Game Formulas

/// The mathematical foundation of the System
struct GameFormulas {

    /// XP required to reach a specific level
    /// Formula: XP = Level * 100 * 1.5^(Level/10)
    static func xpRequired(forLevel level: Int) -> Int {
        let base = Double(level) * 100.0
        let multiplier = pow(1.5, Double(level) / 10.0)
        return Int(base * multiplier)
    }

    /// XP awarded for completing a quest based on difficulty
    static func questXP(difficulty: QuestDifficulty, bonusMultiplier: Double = 1.0) -> Int {
        let baseXP: Int
        switch difficulty {
        case .trivial: baseXP = 5
        case .easy: baseXP = 15
        case .normal: baseXP = 30
        case .hard: baseXP = 60
        case .extreme: baseXP = 100
        case .legendary: baseXP = 200
        }
        return Int(Double(baseXP) * bonusMultiplier)
    }

    /// Gold awarded for completing a quest
    static func questGold(difficulty: QuestDifficulty) -> Int {
        switch difficulty {
        case .trivial: return 1
        case .easy: return 3
        case .normal: return 5
        case .hard: return 10
        case .extreme: return 20
        case .legendary: return 50
        }
    }

    /// Stat XP awarded based on quest type
    static func statXP(difficulty: QuestDifficulty) -> Int {
        switch difficulty {
        case .trivial: return 2
        case .easy: return 5
        case .normal: return 10
        case .hard: return 20
        case .extreme: return 35
        case .legendary: return 60
        }
    }

    /// Critical success chance (for loot boxes)
    static let criticalSuccessChance: Double = 0.10 // 10%

    /// Streak bonus multiplier
    static func streakMultiplier(streak: Int) -> Double {
        // +5% per day, capped at 100% bonus
        min(1.0 + (Double(streak) * 0.05), 2.0)
    }

    /// Boss damage calculation
    static func bossDamage(taskDifficulty: QuestDifficulty, playerLevel: Int) -> Int {
        let baseDamage = questXP(difficulty: taskDifficulty)
        let levelBonus = 1.0 + (Double(playerLevel) / 100.0)
        return Int(Double(baseDamage) * levelBonus)
    }

    /// Penalty damage to player stats
    static func penaltyDamage(missedQuests: Int) -> Int {
        // Each missed daily quest deals 5 "damage" to player's streak
        missedQuests * 5
    }
}

// MARK: - Quest Difficulty

enum QuestDifficulty: String, Codable, CaseIterable {
    case trivial = "Trivial"
    case easy = "Easy"
    case normal = "Normal"
    case hard = "Hard"
    case extreme = "Extreme"
    case legendary = "Legendary"

    var color: Color {
        switch self {
        case .trivial: return .gray
        case .easy: return .green
        case .normal: return .blue
        case .hard: return .purple
        case .extreme: return .orange
        case .legendary: return .yellow
        }
    }

    var icon: String {
        switch self {
        case .trivial: return "circle"
        case .easy: return "circle.fill"
        case .normal: return "diamond.fill"
        case .hard: return "star.fill"
        case .extreme: return "flame.fill"
        case .legendary: return "crown.fill"
        }
    }
}
