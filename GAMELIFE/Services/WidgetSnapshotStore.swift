//
//  WidgetSnapshotStore.swift
//  GAMELIFE
//
//  [SYSTEM]: Widget snapshot bridge online.
//  Shared glanceable state is ready for extensions.
//

import Foundation
import WidgetKit

struct WidgetQuestSummaryItem: Codable, Identifiable, Equatable {
    let id: UUID
    let title: String
    let subtitle: String
    let progressText: String
    let progressValue: Double
    let isOptional: Bool
    let trackingType: String
    let expiresAt: Date
}

struct WidgetBossSummary: Codable, Identifiable, Equatable {
    let id: UUID
    let title: String
    let subtitle: String
    let progressValue: Double
    let remainingHP: Int
    let maxHP: Int
}

struct WidgetSnapshotPayload: Codable, Equatable {
    let generatedAt: Date
    let playerName: String
    let playerTitle: String
    let rank: String
    let level: Int
    let xpProgress: Double
    let currentHP: Int
    let maxHP: Int
    let gold: Int
    let streak: Int
    let completedToday: Int
    let totalToday: Int
    let remainingRequired: Int
    let remainingOptional: Int
    let nextUp: [WidgetQuestSummaryItem]
    let bosses: [WidgetBossSummary]
    let primaryBoss: WidgetBossSummary?
}

@MainActor
final class WidgetSnapshotStore {

    static let shared = WidgetSnapshotStore()

    private let appGroupID = "group.com.gamelife.shared"
    private let payloadFileName = "widgetSnapshotPayload.json"
    private let encoder = JSONEncoder()
    private lazy var sharedContainerURL: URL? = {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            print("[SYSTEM] App Group container unavailable for \(appGroupID). Widget snapshot publishing disabled.")
            return nil
        }
        return containerURL
    }()
    private var payloadURL: URL? {
        sharedContainerURL?.appendingPathComponent(payloadFileName)
    }

    private init() {}

    func publish(player: Player, dailyQuests: [DailyQuest], bossFights: [BossFight]) {
        guard let payloadURL else { return }

        let sortedQuests = dailyQuests.sorted { lhs, rhs in
            let left = questPriorityScore(lhs, bossFights: bossFights, playerLevel: player.level)
            let right = questPriorityScore(rhs, bossFights: bossFights, playerLevel: player.level)
            if left == right {
                return lhs.title < rhs.title
            }
            return left > right
        }

        let nextUp = sortedQuests
            .filter { $0.status != .completed }
            .prefix(3)
            .map { quest in
                WidgetQuestSummaryItem(
                    id: quest.id,
                    title: quest.title,
                    subtitle: questSubtitle(for: quest, bossFights: bossFights, playerLevel: player.level),
                    progressText: quest.displayProgress,
                    progressValue: quest.normalizedProgress,
                    isOptional: quest.isOptional,
                    trackingType: quest.trackingType.rawValue,
                    expiresAt: quest.expiresAt
                )
            }

        let sortedBosses = bossFights
            .filter { !$0.isDefeated }
            .sorted(by: bossSortComparator)
            .map { boss in
                WidgetBossSummary(
                    id: boss.id,
                    title: boss.title,
                    subtitle: bossSubtitle(for: boss),
                    progressValue: 1.0 - boss.hpPercentage,
                    remainingHP: boss.remainingHP,
                    maxHP: boss.maxHP
                )
            }
        let primaryBoss = sortedBosses.first

        let payload = WidgetSnapshotPayload(
            generatedAt: Date(),
            playerName: player.name,
            playerTitle: player.title,
            rank: player.rank.rawValue,
            level: player.level,
            xpProgress: min(1, max(0, player.xpProgress)),
            currentHP: player.currentHP,
            maxHP: player.maxHP,
            gold: player.gold,
            streak: player.currentStreak,
            completedToday: dailyQuests.filter { $0.status == .completed }.count,
            totalToday: dailyQuests.count,
            remainingRequired: dailyQuests.filter { !$0.isOptional && $0.status != .completed }.count,
            remainingOptional: dailyQuests.filter { $0.isOptional && $0.status != .completed }.count,
            nextUp: nextUp,
            bosses: sortedBosses,
            primaryBoss: primaryBoss
        )

        do {
            let data = try encoder.encode(payload)
            if let existingData = try? Data(contentsOf: payloadURL),
               let existingPayload = try? JSONDecoder().decode(WidgetSnapshotPayload.self, from: existingData),
               !payload.hasMeaningfulDifferences(from: existingPayload) {
                return
            }
            try data.write(to: payloadURL, options: .atomic)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("[SYSTEM] Failed to publish widget snapshot: \(error)")
        }
    }

    private func questPriorityScore(_ quest: DailyQuest, bossFights: [BossFight], playerLevel: Int) -> Double {
        guard quest.status != .completed else { return -10_000 }

        let now = Date()
        let secondsLeft = max(60, quest.expiresAt.timeIntervalSince(now))
        let dueSoonScore = 250_000 / secondsLeft
        let bossImpact = Double(estimatedBossDamage(for: quest, bossFights: bossFights, playerLevel: playerLevel))
        let streakRisk = (!quest.isOptional && quest.resolvedFrequency == .daily)
            ? (1.0 - quest.normalizedProgress) * 40.0
            : 0
        let rewardValue = Double(quest.xpReward) + Double(quest.isOptional ? 0 : quest.goldReward * 3)

        return dueSoonScore + (bossImpact * 1.6) + streakRisk + (rewardValue * 0.3)
    }

    private func estimatedBossDamage(for quest: DailyQuest, bossFights: [BossFight], playerLevel: Int) -> Int {
        guard let linkedBossID = quest.linkedBossID,
              let boss = bossFights.first(where: { $0.id == linkedBossID && !$0.isDefeated }) else {
            return 0
        }

        let baseDamage = GameFormulas.bossDamage(taskDifficulty: quest.difficulty, playerLevel: playerLevel)
        let estimated = max(1, Int(Double(baseDamage) * 0.8))
        return min(estimated, boss.currentHP)
    }

    private func questSubtitle(for quest: DailyQuest, bossFights: [BossFight], playerLevel: Int) -> String {
        if let linkedBossID = quest.linkedBossID,
           let boss = bossFights.first(where: { $0.id == linkedBossID && !$0.isDefeated }) {
            let damage = estimatedBossDamage(for: quest, bossFights: bossFights, playerLevel: playerLevel)
            return "Hits \(boss.title) for \(damage) HP"
        }

        if quest.isOptional {
            return "Optional | +\(quest.xpReward) XP"
        }

        return "+\(quest.xpReward) XP | +\(quest.goldReward) Gold"
    }

    private func bossSortComparator(_ lhs: BossFight, _ rhs: BossFight) -> Bool {
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

    private func bossSubtitle(for boss: BossFight) -> String {
        if let deadline = boss.deadline {
            return "Deadline \(deadline.formatted(date: .abbreviated, time: .omitted))"
        }
        return "\(Int((1.0 - boss.hpPercentage) * 100))% defeated"
    }
}

private extension WidgetSnapshotPayload {
    func hasMeaningfulDifferences(from other: WidgetSnapshotPayload) -> Bool {
        playerName != other.playerName ||
        playerTitle != other.playerTitle ||
        rank != other.rank ||
        level != other.level ||
        xpProgress != other.xpProgress ||
        currentHP != other.currentHP ||
        maxHP != other.maxHP ||
        gold != other.gold ||
        streak != other.streak ||
        completedToday != other.completedToday ||
        totalToday != other.totalToday ||
        remainingRequired != other.remainingRequired ||
        remainingOptional != other.remainingOptional ||
        nextUp != other.nextUp ||
        bosses != other.bosses ||
        primaryBoss != other.primaryBoss
    }
}
