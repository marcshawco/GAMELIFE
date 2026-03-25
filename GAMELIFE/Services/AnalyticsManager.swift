//
//  AnalyticsManager.swift
//  GAMELIFE
//
//  [SYSTEM]: Analytics layer initialized.
//  Feature usage is now being observed locally.
//

import Foundation
import Combine

// MARK: - Analytics Models

struct AnalyticsCounter: Codable {
    var count: Int
    var lastTriggeredAt: Date
}

struct AnalyticsSnapshot: Codable {
    var firstTrackedAt: Date
    var lastTrackedAt: Date
    var appLaunchCount: Int
    var featureEvents: [String: AnalyticsCounter]
    var screenViews: [String: AnalyticsCounter]

    static func empty(now: Date = Date()) -> AnalyticsSnapshot {
        AnalyticsSnapshot(
            firstTrackedAt: now,
            lastTrackedAt: now,
            appLaunchCount: 0,
            featureEvents: [:],
            screenViews: [:]
        )
    }
}

struct AnalyticsSummaryItem: Identifiable {
    let name: String
    let count: Int
    let lastTriggeredAt: Date

    var id: String { name }
}

// MARK: - Analytics Manager

@MainActor
final class AnalyticsManager: ObservableObject {

    static let shared = AnalyticsManager()

    @Published private(set) var snapshot: AnalyticsSnapshot

    private let storageKey = "gamelife_analytics_snapshot"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let stored = try? decoder.decode(AnalyticsSnapshot.self, from: data) {
            snapshot = stored
        } else {
            snapshot = .empty()
            persist()
        }
    }

    var totalTrackedEvents: Int {
        snapshot.appLaunchCount
        + snapshot.featureEvents.values.reduce(0) { $0 + $1.count }
        + snapshot.screenViews.values.reduce(0) { $0 + $1.count }
    }

    var topFeatureEvents: [AnalyticsSummaryItem] {
        sortedItems(from: snapshot.featureEvents)
    }

    var topScreenViews: [AnalyticsSummaryItem] {
        sortedItems(from: snapshot.screenViews)
    }

    func trackAppLaunch() {
        let now = Date()
        snapshot.appLaunchCount += 1
        snapshot.lastTrackedAt = now
        persist()
    }

    func trackScreenView(_ name: String) {
        increment(\.screenViews, key: normalizedKey(name))
    }

    func trackFeature(_ name: String) {
        increment(\.featureEvents, key: normalizedKey(name))
    }

    func exportJSON() -> String? {
        do {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(snapshot)
            return String(data: data, encoding: .utf8)
        } catch {
            print("[SYSTEM] Failed to export analytics: \(error)")
            return nil
        }
    }

    func reset() {
        snapshot = .empty()
        persist()
    }

    private func increment(
        _ keyPath: WritableKeyPath<AnalyticsSnapshot, [String: AnalyticsCounter]>,
        key: String
    ) {
        let now = Date()
        if snapshot.appLaunchCount == 0
            && snapshot.featureEvents.isEmpty
            && snapshot.screenViews.isEmpty {
            snapshot.firstTrackedAt = now
        }

        var bucket = snapshot[keyPath: keyPath][key] ?? AnalyticsCounter(count: 0, lastTriggeredAt: now)
        bucket.count += 1
        bucket.lastTriggeredAt = now
        snapshot[keyPath: keyPath][key] = bucket
        snapshot.lastTrackedAt = now
        persist()
    }

    private func normalizedKey(_ raw: String) -> String {
        raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
    }

    private func sortedItems(from values: [String: AnalyticsCounter]) -> [AnalyticsSummaryItem] {
        values
            .map { key, value in
                AnalyticsSummaryItem(name: key, count: value.count, lastTriggeredAt: value.lastTriggeredAt)
            }
            .sorted {
                if $0.count == $1.count {
                    return $0.lastTriggeredAt > $1.lastTriggeredAt
                }
                return $0.count > $1.count
            }
    }

    private func persist() {
        do {
            let data = try encoder.encode(snapshot)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("[SYSTEM] Failed to persist analytics: \(error)")
        }
    }
}
