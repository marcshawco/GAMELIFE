//
//  GlassworkMockData.swift
//  GAMELIFE
//
//  Hardcoded player / stats / quests / bosses / activity that match the
//  design package exactly (Arjun Mehta, Lv 47, Rank B). Gallery mock only —
//  not wired to GameEngine.
//

import SwiftUI

struct GWPlayer {
    let name: String
    let handle: String
    let rank: String
    let level: Int
    let xpCurrent: Int
    let xpNeeded: Int
    let gold: Int
    let hp: Int
    let hpMax: Int
    let streak: Int
    let questsDoneToday: Int
    let questsTodayTotal: Int
}

let GW_PLAYER = GWPlayer(
    name: "ARJUN MEHTA",
    handle: "@arjun",
    rank: "B",
    level: 47,
    xpCurrent: 2840,
    xpNeeded: 4500,
    gold: 12480,
    hp: 78,
    hpMax: 100,
    streak: 23,
    questsDoneToday: 4,
    questsTodayTotal: 7
)

struct GWStat: Identifiable {
    let id = UUID()
    let key: String
    let name: String
    let value: Int
    let max: Int
    let hue: Double
    let tint: Color
}

let GW_STATS: [GWStat] = [
    GWStat(key: "STR", name: "Strength",     value: 124, max: 200, hue:   8, tint: GW.col("EF4444")),
    GWStat(key: "INT", name: "Intelligence", value: 188, max: 200, hue: 200, tint: GW.col("38BDF8")),
    GWStat(key: "AGI", name: "Agility",      value:  96, max: 200, hue: 152, tint: GW.col("10B981")),
    GWStat(key: "VIT", name: "Vitality",     value: 142, max: 200, hue:  24, tint: GW.col("FB923C")),
    GWStat(key: "WIL", name: "Willpower",    value: 165, max: 200, hue: 280, tint: GW.col("A855F7")),
    GWStat(key: "SPI", name: "Spirit",       value: 110, max: 200, hue:  46, tint: GW.col("EAB308")),
]

enum GWQuestStatus { case done, active, queued }

struct GWQuest: Identifiable {
    let id: String
    let title: String
    let sub: String
    let xp: Int
    let gold: Int
    let stat: String
    let progress: Double
    let status: GWQuestStatus
}

let GW_QUESTS: [GWQuest] = [
    GWQuest(id: "q1", title: "Run 5 kilometres",    sub: "Health — auto-tracked", xp: 220, gold: 60, stat: "STR", progress: 1.0,  status: .done),
    GWQuest(id: "q2", title: "Read 30 pages",       sub: "Daily • Manual",        xp: 180, gold: 40, stat: "INT", progress: 0.6,  status: .active),
    GWQuest(id: "q3", title: "Meditate 15 minutes", sub: "Daily • Timer",         xp: 140, gold: 30, stat: "SPI", progress: 0.0,  status: .queued),
    GWQuest(id: "q4", title: "Hydrate — 2 L water", sub: "Health",                xp:  80, gold: 20, stat: "VIT", progress: 0.75, status: .active),
    GWQuest(id: "q5", title: "Ship one PR review",  sub: "Weekly • Manual",       xp: 300, gold: 90, stat: "INT", progress: 0.33, status: .active),
    GWQuest(id: "q6", title: "Bed by 23:30",        sub: "Daily • Health",        xp: 160, gold: 40, stat: "VIT", progress: 0.0,  status: .queued),
]

struct GWBoss: Identifiable {
    let id = UUID()
    let name: String
    let sub: String
    let hp: Double
    let hue: Double
}

let GW_BOSSES: [GWBoss] = [
    GWBoss(name: "COLUMN OF DEBT", sub: "Savings → $20k",         hp: 0.62, hue:  14),
    GWBoss(name: "THE LATE WOLF",  sub: "Sleep before 23:30 × 30", hp: 0.41, hue: 264),
    GWBoss(name: "IRONWORK",       sub: "Workouts × 60",          hp: 0.78, hue: 200),
]
