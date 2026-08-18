//
//  PlayerTitleSystem.swift
//  GAMELIFE
//
//  Playstyle "class" titles derived from the player's dominant attribute(s)
//  and level. Complements the level-based `PlayerRank` — the rank shows how
//  far you've climbed, the class title shows *how* you've been climbing.
//

import Foundation

enum PlayerClassTitle {

    /// Player level → mastery tier (0 = novice, 1 = adept, 2 = master).
    static func tier(forLevel level: Int) -> Int {
        switch level {
        case ..<10: return 0
        case 10..<40: return 1
        default: return 2
        }
    }

    /// Resolve the class title from the current stat spread and level.
    /// - A clear single specialty → a tiered single-stat title.
    /// - Two comparably-strong stats (once past novice) → a hybrid title.
    private struct RankedStat {
        let type: StatType
        let value: Int
        let xp: Int
    }

    static func resolve(stats: [StatType: Stat], level: Int) -> String {
        // Rank stats by strength (totalValue, tie-broken by raw experience).
        var ranked: [RankedStat] = []
        for type in StatType.allCases {
            let stat = stats[type]
            ranked.append(RankedStat(type: type, value: stat?.totalValue ?? 0, xp: stat?.experience ?? 0))
        }
        ranked.sort { lhs, rhs in
            if lhs.value != rhs.value { return lhs.value > rhs.value }
            return lhs.xp > rhs.xp
        }

        let t = tier(forLevel: level)

        guard let top = ranked.first, top.value > 0 else {
            return "Wanderer" // brand-new hunter, no stats trained yet
        }

        let second: RankedStat? = ranked.count > 1 ? ranked[1] : nil
        let third: RankedStat? = ranked.count > 2 ? ranked[2] : nil

        // Balanced build: the top three stats are tied, so there's no real
        // specialization to name — call them a generalist.
        if let second, let third,
           top.value == second.value, second.value == third.value {
            let balanced = ["Wanderer", "Generalist", "Paragon"]
            return balanced[min(max(t, 0), balanced.count - 1)]
        }

        // Hybrid title: a genuine secondary specialty (≥60% of the top stat)
        // that only emerges once the hunter is past the novice tier.
        if let second, second.value > 0, t >= 1,
           Double(second.value) >= Double(top.value) * 0.6 {
            let combo = comboTitle(top.type, second.type)
            return t >= 2 ? "Grand \(combo)" : combo
        }

        return singleTitle(top.type, tier: t)
    }

    private static func singleTitle(_ stat: StatType, tier: Int) -> String {
        let ladders: [StatType: [String]] = [
            .strength:     ["Brawler", "Warrior", "Warlord"],
            .intelligence: ["Apprentice", "Scholar", "Grand Wizard"],
            .agility:      ["Scout", "Ranger", "Shadowblade"],
            .vitality:     ["Survivor", "Ironhide", "Juggernaut"],
            .willpower:    ["Disciple", "Ascetic", "Unbroken"],
            .spirit:       ["Seeker", "Mystic", "Oracle"]
        ]
        let ladder = ladders[stat] ?? ["Adventurer", "Hero", "Legend"]
        return ladder[min(max(tier, 0), ladder.count - 1)]
    }

    private static func comboTitle(_ a: StatType, _ b: StatType) -> String {
        let combos: [Set<StatType>: String] = [
            [.strength, .intelligence]: "Battlemage",
            [.strength, .agility]:      "Duelist",
            [.strength, .vitality]:     "Berserker",
            [.strength, .willpower]:    "Gladiator",
            [.strength, .spirit]:       "War Monk",
            [.intelligence, .agility]:  "Arcane Trickster",
            [.intelligence, .vitality]: "Alchemist",
            [.intelligence, .willpower]:"Strategist",
            [.intelligence, .spirit]:   "Archmage",
            [.agility, .vitality]:      "Pathfinder",
            [.agility, .willpower]:     "Assassin",
            [.agility, .spirit]:        "Windwalker",
            [.vitality, .willpower]:    "Sentinel",
            [.vitality, .spirit]:       "Lifebinder",
            [.willpower, .spirit]:      "Zealot"
        ]
        return combos[Set([a, b])] ?? "Vanguard"
    }
}

extension Player {
    /// Playstyle "class" title derived from the player's dominant attribute(s)
    /// and level. Complements the level-based `rank`.
    var classTitle: String {
        PlayerClassTitle.resolve(stats: stats, level: level)
    }
}
