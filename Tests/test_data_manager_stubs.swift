import Foundation

// Minimal supporting types needed to compile DataManagers.swift in the
// standalone regression test binary without pulling in the full app graph.

enum AppLanguage: String {
    case system
}

enum RewardCategory: String, Codable {
    case treat
    case entertainment
    case time
    case item
    case experience
}

struct MarketplaceReward: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let cost: Int
    let category: RewardCategory
    let icon: String
    let isCustom: Bool
    let healthRestore: Int?
    let streakShieldCharges: Int?
}

struct TrackedLocation: Codable, Identifiable {
    let id: UUID
    let name: String
    let type: LocationType
    let latitude: Double
    let longitude: Double
    let radius: Double
    let minimumVisitMinutes: Int
    let statContribution: StatType
    let xpReward: Int
    let questID: UUID?

    enum LocationType: String, Codable {
        case gym
        case library
        case office
        case park
        case custom
    }
}
