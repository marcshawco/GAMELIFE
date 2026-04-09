//
//  PRAXISWidgets.swift
//  PRAXISWidgets
//

import SwiftUI
import WidgetKit
import AppIntents

private enum WidgetLanguageSupport {
    static let appGroupID = "group.com.gamelife.shared"
    static let preferredLanguageKey = "preferredLanguageCode"

    static var locale: Locale {
        Locale(identifier: resolvedLanguageCode)
    }

    private static var resolvedLanguageCode: String {
        guard FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) != nil,
              let defaults = UserDefaults(suiteName: appGroupID),
              let code = defaults.string(forKey: preferredLanguageKey),
              code != "system" else {
            return Locale.autoupdatingCurrent.language.languageCode?.identifier ?? "en"
        }

        let normalized = code.split(whereSeparator: { $0 == "-" || $0 == "_" }).first.map(String.init) ?? code
        return normalized.isEmpty ? "en" : normalized
    }
}

struct PRAXISWidgetEntry: TimelineEntry {
    let date: Date
    let payload: WidgetSnapshotPayload
}

struct PRAXISBossWidgetEntry: TimelineEntry {
    let date: Date
    let payload: WidgetSnapshotPayload
    let selectedBoss: WidgetBossSummary?
}

struct PRAXISTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> PRAXISWidgetEntry {
        PRAXISWidgetEntry(date: Date(), payload: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (PRAXISWidgetEntry) -> Void) {
        completion(PRAXISWidgetEntry(date: Date(), payload: WidgetSnapshotLoader.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PRAXISWidgetEntry>) -> Void) {
        let entry = PRAXISWidgetEntry(date: Date(), payload: WidgetSnapshotLoader.load())
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct WidgetBossEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Boss")
    static var defaultQuery = WidgetBossEntityQuery()

    let id: String
    let title: String
    let subtitle: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: LocalizedStringResource(stringLiteral: title),
            subtitle: LocalizedStringResource(stringLiteral: subtitle)
        )
    }
}

struct WidgetBossEntityQuery: EntityQuery {
    func entities(for identifiers: [WidgetBossEntity.ID]) async throws -> [WidgetBossEntity] {
        let all = currentEntities()
        let requested = Set(identifiers)
        return all.filter { requested.contains($0.id) }
    }

    func suggestedEntities() async throws -> [WidgetBossEntity] {
        currentEntities()
    }

    private func currentEntities() -> [WidgetBossEntity] {
        WidgetSnapshotLoader.load().bosses.map { boss in
            WidgetBossEntity(
                id: boss.id.uuidString,
                title: boss.title,
                subtitle: boss.subtitle
            )
        }
    }
}

struct BossWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Boss Widget"
    static var description = IntentDescription("Choose which boss this widget should track.")

    @Parameter(title: "Boss")
    var boss: WidgetBossEntity?
}

struct PRAXISBossTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = PRAXISBossWidgetEntry
    typealias Intent = BossWidgetConfigurationIntent

    func placeholder(in context: Context) -> PRAXISBossWidgetEntry {
        let payload = WidgetSnapshotPayload.placeholder
        return PRAXISBossWidgetEntry(
            date: Date(),
            payload: payload,
            selectedBoss: payload.primaryBoss
        )
    }

    func snapshot(for configuration: BossWidgetConfigurationIntent, in context: Context) async -> PRAXISBossWidgetEntry {
        let payload = WidgetSnapshotLoader.load()
        return PRAXISBossWidgetEntry(
            date: Date(),
            payload: payload,
            selectedBoss: selectedBoss(from: payload, configuration: configuration)
        )
    }

    func timeline(for configuration: BossWidgetConfigurationIntent, in context: Context) async -> Timeline<PRAXISBossWidgetEntry> {
        let payload = WidgetSnapshotLoader.load()
        let entry = PRAXISBossWidgetEntry(
            date: Date(),
            payload: payload,
            selectedBoss: selectedBoss(from: payload, configuration: configuration)
        )
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }

    private func selectedBoss(from payload: WidgetSnapshotPayload, configuration: BossWidgetConfigurationIntent) -> WidgetBossSummary? {
        guard let selectedID = configuration.boss?.id else {
            return payload.primaryBoss
        }
        return payload.bosses.first(where: { $0.id.uuidString == selectedID }) ?? payload.primaryBoss
    }
}

struct StatusWidgetView: View {
    let entry: PRAXISWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular:
                accessoryBody
            default:
                defaultBody
            }
        }
        .environment(\.locale, WidgetLanguageSupport.locale)
        .widgetURL(URL(string: "praxis://status"))
    }

    private var defaultBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.payload.playerName)
                        .font(.headline)
                        .lineLimit(1)
                    Text("\(entry.payload.rank) Rank | Lv. \(entry.payload.level)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Label("\(entry.payload.streak)", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Label("\(entry.payload.gold)", systemImage: "dollarsign.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                metricRow(title: "HP", value: "\(entry.payload.currentHP)/\(entry.payload.maxHP)")
                ProgressView(value: Double(entry.payload.currentHP), total: Double(max(1, entry.payload.maxHP)))
                    .tint(.red)
            }

            VStack(alignment: .leading, spacing: 4) {
                metricRow(title: "XP", value: "\(Int((entry.payload.xpProgress * 100).rounded()))%")
                ProgressView(value: entry.payload.xpProgress)
                    .tint(.blue)
            }

            Spacer(minLength: 0)

            Text("\(entry.payload.completedToday)/\(entry.payload.totalToday) quests complete")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .containerBackground(for: .widget) {
            LinearGradient(colors: [Color(red: 0.06, green: 0.09, blue: 0.16), Color(red: 0.10, green: 0.14, blue: 0.22)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var accessoryBody: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(entry.payload.rank) Lv.\(entry.payload.level)")
                .font(.caption)
                .bold()
            Text("HP \(entry.payload.currentHP)/\(entry.payload.maxHP)")
                .font(.caption2)
            Text("\(entry.payload.completedToday)/\(entry.payload.totalToday) done")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func metricRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption2)
                .bold()
        }
    }
}

struct NextUpWidgetView: View {
    let entry: PRAXISWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next Up")
                        .font(.headline)
                    Text("\(entry.payload.remainingRequired) required left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(entry.payload.completedToday)/\(max(1, entry.payload.totalToday))")
                    .font(.title3.monospacedDigit().bold())
            }

            ForEach(displayedQuests) { quest in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(quest.title)
                            .font(.subheadline.bold())
                            .lineLimit(1)
                        if quest.isOptional {
                            Text("OPTIONAL")
                                .font(.caption2.bold())
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(.white.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    Text(quest.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    ProgressView(value: quest.progressValue)
                        .tint(quest.isOptional ? .mint : .blue)
                    HStack {
                        Text(quest.progressText)
                        Spacer()
                        Text(relativeExpiry(for: quest.expiresAt))
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }

            if displayedQuests.isEmpty {
                Spacer()
                Text("All clear. No unfinished quests right now.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(colors: [Color(red: 0.09, green: 0.08, blue: 0.05), Color(red: 0.16, green: 0.12, blue: 0.07)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        .environment(\.locale, WidgetLanguageSupport.locale)
        .widgetURL(nextUpURL)
    }

    private var displayedQuests: [WidgetQuestSummaryItem] {
        switch family {
        case .systemLarge:
            return Array(entry.payload.nextUp.prefix(3))
        default:
            return Array(entry.payload.nextUp.prefix(2))
        }
    }

    private func relativeExpiry(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Due \(formatter.localizedString(for: date, relativeTo: Date()))"
    }

    private var nextUpURL: URL? {
        if let quest = displayedQuests.first {
            return URL(string: "praxis://quests?questID=\(quest.id.uuidString)")
        }
        return URL(string: "praxis://quests")
    }
}

struct BossWidgetView: View {
    let entry: PRAXISBossWidgetEntry

    private var displayedBoss: WidgetBossSummary? {
        entry.selectedBoss ?? entry.payload.primaryBoss
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Boss Battle")
                        .font(.headline)
                    if let boss = displayedBoss {
                        Text(boss.title)
                            .font(.subheadline.bold())
                            .lineLimit(1)
                    } else {
                        Text("No active bosses")
                            .font(.subheadline.bold())
                    }
                }
                Spacer()
                if let boss = displayedBoss {
                    Text("\(Int(boss.progressValue * 100))%")
                        .font(.title3.monospacedDigit().bold())
                }
            }

            if let boss = displayedBoss {
                Text(boss.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white.opacity(0.12))
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(colors: [.pink, .red], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: max(14, geometry.size.width * boss.progressValue))
                    }
                }
                .frame(height: 14)

                HStack {
                    statPill(title: "HP Left", value: "\(boss.remainingHP)")
                    statPill(title: "Max HP", value: "\(boss.maxHP)")
                }

                if let quest = entry.payload.nextUp.first {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Best next move")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(quest.title)
                            .font(.caption.bold())
                            .lineLimit(1)
                        Text(quest.subtitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            } else {
                Spacer()
                Text("Create a boss to track long-term progress here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(colors: [Color(red: 0.16, green: 0.05, blue: 0.08), Color(red: 0.24, green: 0.08, blue: 0.10)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        .environment(\.locale, WidgetLanguageSupport.locale)
        .widgetURL(bossURL)
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var bossURL: URL? {
        guard let boss = displayedBoss else {
            return URL(string: "praxis://bosses")
        }
        return URL(string: "praxis://bosses?bossID=\(boss.id.uuidString)")
    }
}

struct PRAXISStatusWidget: Widget {
    let kind = "PRAXISStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PRAXISTimelineProvider()) { entry in
            StatusWidgetView(entry: entry)
        }
        .configurationDisplayName("Hunter Status")
        .description("See level, HP, streak, gold, and today’s completion status at a glance.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

struct PRAXISNextUpWidget: Widget {
    let kind = "PRAXISNextUpWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PRAXISTimelineProvider()) { entry in
            NextUpWidgetView(entry: entry)
        }
        .configurationDisplayName("Next Up")
        .description("Shows the most important quests to tackle next based on urgency, rewards, and boss impact.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct PRAXISBossWidget: Widget {
    let kind = "PRAXISBossWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: BossWidgetConfigurationIntent.self, provider: PRAXISBossTimelineProvider()) { entry in
            BossWidgetView(entry: entry)
        }
        .configurationDisplayName("Boss Progress")
        .description("Track a specific boss fight or let PRAXIS choose the most urgent one.")
        .supportedFamilies([.systemMedium])
    }
}

@main
struct PRAXISWidgetsBundle: WidgetBundle {
    var body: some Widget {
        PRAXISStatusWidget()
        PRAXISNextUpWidget()
        PRAXISBossWidget()
    }
}
