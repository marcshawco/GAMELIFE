//
//  WidgetSnapshotModels.swift
//  PRAXISWidgets
//

import Foundation

struct WidgetQuestSummaryItem: Codable, Identifiable {
    let id: UUID
    let title: String
    let subtitle: String
    let progressText: String
    let progressValue: Double
    let isOptional: Bool
    let trackingType: String
    let expiresAt: Date
}

struct WidgetBossSummary: Codable, Identifiable {
    let id: UUID
    let title: String
    let subtitle: String
    let progressValue: Double
    let remainingHP: Int
    let maxHP: Int
}

struct WidgetSnapshotPayload: Codable {
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

    static var placeholder: WidgetSnapshotPayload {
        WidgetSnapshotPayload(
            generatedAt: Date(),
            playerName: "Hunter",
            playerTitle: "Awakened",
            rank: "E",
            level: 12,
            xpProgress: 0.64,
            currentHP: 82,
            maxHP: 100,
            gold: 145,
            streak: 6,
            completedToday: 3,
            totalToday: 5,
            remainingRequired: 1,
            remainingOptional: 1,
            nextUp: [
                WidgetQuestSummaryItem(
                    id: UUID(),
                    title: "Morning Walk",
                    subtitle: "+25 XP | +10 Gold",
                    progressText: "3/5 km",
                    progressValue: 0.6,
                    isOptional: false,
                    trackingType: "healthKit",
                    expiresAt: Date().addingTimeInterval(4 * 3600)
                ),
                WidgetQuestSummaryItem(
                    id: UUID(),
                    title: "Inbox Zero Sprint",
                    subtitle: "Hits Inbox Hydra for 180 HP",
                    progressText: "0/1 times",
                    progressValue: 0,
                    isOptional: false,
                    trackingType: "manual",
                    expiresAt: Date().addingTimeInterval(9 * 3600)
                ),
                WidgetQuestSummaryItem(
                    id: UUID(),
                    title: "Stretch Break",
                    subtitle: "Optional | +12 XP",
                    progressText: "5/10 min",
                    progressValue: 0.5,
                    isOptional: true,
                    trackingType: "manual",
                    expiresAt: Date().addingTimeInterval(2 * 3600)
                )
            ],
            bosses: [
                WidgetBossSummary(
                    id: UUID(),
                    title: "Inbox Hydra",
                    subtitle: "Deadline Mar 30",
                    progressValue: 0.72,
                    remainingHP: 2800,
                    maxHP: 10000
                ),
                WidgetBossSummary(
                    id: UUID(),
                    title: "Debt Warden",
                    subtitle: "41% defeated",
                    progressValue: 0.41,
                    remainingHP: 5900,
                    maxHP: 10000
                )
            ],
            primaryBoss: WidgetBossSummary(
                id: UUID(),
                title: "Inbox Hydra",
                subtitle: "Deadline Mar 30",
                progressValue: 0.72,
                remainingHP: 2800,
                maxHP: 10000
            )
        )
    }
}

enum WidgetSnapshotLoader {
    static let appGroupID = "group.com.gamelife.shared"
    static let payloadFileName = "widgetSnapshotPayload.json"

    static func load() -> WidgetSnapshotPayload {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID),
              let data = try? Data(contentsOf: containerURL.appendingPathComponent(payloadFileName)),
              let payload = try? JSONDecoder().decode(WidgetSnapshotPayload.self, from: data) else {
            return .placeholder
        }
        return payload
    }
}
