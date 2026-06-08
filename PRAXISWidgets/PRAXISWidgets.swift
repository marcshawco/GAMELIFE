//
//  PRAXISWidgets.swift
//  PRAXISWidgets
//

import SwiftUI
import WidgetKit
import AppIntents

private enum WidgetTheme {
    static let backgroundPrimary = Color(red: 10 / 255, green: 10 / 255, blue: 15 / 255)
    static let backgroundSecondary = Color(red: 18 / 255, green: 18 / 255, blue: 26 / 255)
    static let backgroundTertiary = Color(red: 26 / 255, green: 26 / 255, blue: 46 / 255)
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 160 / 255, green: 160 / 255, blue: 176 / 255)
    static let textTertiary = Color(red: 112 / 255, green: 112 / 255, blue: 132 / 255)
    static let primaryBlue = Color(red: 76 / 255, green: 201 / 255, blue: 240 / 255)
    static let primaryPurple = Color(red: 123 / 255, green: 44 / 255, blue: 191 / 255)
    static let accentCyan = Color(red: 0 / 255, green: 245 / 255, blue: 212 / 255)
    static let warningOrange = Color(red: 255 / 255, green: 107 / 255, blue: 53 / 255)
    static let criticalRed = Color(red: 239 / 255, green: 35 / 255, blue: 60 / 255)
    static let successGreen = Color(red: 6 / 255, green: 214 / 255, blue: 160 / 255)
    static let gold = Color(red: 255 / 255, green: 215 / 255, blue: 0 / 255)

    static let xpGradient = LinearGradient(
        colors: [primaryBlue, accentCyan],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let hpGradient = LinearGradient(
        colors: [criticalRed, warningOrange],
        startPoint: .leading,
        endPoint: .trailing
    )

    static func cardBackground(accent: Color = primaryBlue) -> some View {
        ZStack {
            LinearGradient(
                colors: [backgroundSecondary, backgroundPrimary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            LinearGradient(
                colors: [accent.opacity(0.28), primaryPurple.opacity(0.16), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private enum WidgetLanguageSupport {
    static let appGroupID = "group.com.gamelife.shared"
    static let preferredLanguageFileName = "preferredLanguageCode.txt"

    static var locale: Locale {
        Locale(identifier: resolvedLanguageCode)
    }

    private static var resolvedLanguageCode: String {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return Locale.autoupdatingCurrent.language.languageCode?.identifier ?? "en"
        }

        let preferenceURL = containerURL.appendingPathComponent(preferredLanguageFileName)
        let code = (try? String(contentsOf: preferenceURL, encoding: .utf8))?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !code.isEmpty, code != "system" else {
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
                        .foregroundStyle(WidgetTheme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Label("\(entry.payload.streak)", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(WidgetTheme.warningOrange)
                    Label("\(entry.payload.gold)", systemImage: "dollarsign.circle.fill")
                        .font(.caption)
                        .foregroundStyle(WidgetTheme.gold)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                metricRow(title: "HP", value: "\(entry.payload.currentHP)/\(entry.payload.maxHP)")
                ProgressView(value: Double(entry.payload.currentHP), total: Double(max(1, entry.payload.maxHP)))
                    .tint(WidgetTheme.criticalRed)
            }

            VStack(alignment: .leading, spacing: 4) {
                metricRow(title: "XP", value: "\(Int((entry.payload.xpProgress * 100).rounded()))%")
                ProgressView(value: entry.payload.xpProgress)
                    .tint(WidgetTheme.primaryBlue)
            }

            Spacer(minLength: 0)

            Text("\(entry.payload.completedToday)/\(entry.payload.totalToday) quests complete")
                .font(.caption2)
                .foregroundStyle(WidgetTheme.textSecondary)
        }
        .foregroundStyle(WidgetTheme.textPrimary)
        .containerBackground(for: .widget) {
            WidgetTheme.cardBackground(accent: WidgetTheme.primaryBlue)
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
                .foregroundStyle(WidgetTheme.textSecondary)
        }
        .foregroundStyle(WidgetTheme.textPrimary)
    }

    private func metricRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption2)
                .foregroundStyle(WidgetTheme.textSecondary)
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
                        .foregroundStyle(WidgetTheme.textSecondary)
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
                                .foregroundStyle(WidgetTheme.accentCyan)
                                .background(WidgetTheme.accentCyan.opacity(0.14))
                                .clipShape(Capsule())
                        }
                    }
                    Text(quest.subtitle)
                        .font(.caption2)
                        .foregroundStyle(WidgetTheme.textSecondary)
                        .lineLimit(1)
                    ProgressView(value: quest.progressValue)
                        .tint(quest.isOptional ? WidgetTheme.successGreen : WidgetTheme.primaryBlue)
                    HStack {
                        Text(quest.progressText)
                        Spacer()
                        Text(relativeExpiry(for: quest.expiresAt))
                    }
                    .font(.caption2)
                    .foregroundStyle(WidgetTheme.textSecondary)
                }
            }

            if displayedQuests.isEmpty {
                Spacer()
                Text("All clear. No unfinished quests right now.")
                    .font(.caption)
                    .foregroundStyle(WidgetTheme.textSecondary)
            }
        }
        .foregroundStyle(WidgetTheme.textPrimary)
        .containerBackground(for: .widget) {
            WidgetTheme.cardBackground(accent: WidgetTheme.accentCyan)
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
                    .foregroundStyle(WidgetTheme.textSecondary)
                    .lineLimit(1)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(WidgetTheme.backgroundTertiary)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(WidgetTheme.hpGradient)
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
                            .foregroundStyle(WidgetTheme.textSecondary)
                        Text(quest.title)
                            .font(.caption.bold())
                            .lineLimit(1)
                        Text(quest.subtitle)
                            .font(.caption2)
                            .foregroundStyle(WidgetTheme.textSecondary)
                            .lineLimit(1)
                    }
                }
            } else {
                Spacer()
                Text("Create a boss to track long-term progress here.")
                    .font(.caption)
                    .foregroundStyle(WidgetTheme.textSecondary)
            }
        }
        .foregroundStyle(WidgetTheme.textPrimary)
        .containerBackground(for: .widget) {
            WidgetTheme.cardBackground(accent: WidgetTheme.criticalRed)
        }
        .environment(\.locale, WidgetLanguageSupport.locale)
        .widgetURL(bossURL)
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(WidgetTheme.textSecondary)
            Text(value)
                .font(.caption.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(WidgetTheme.backgroundTertiary.opacity(0.72))
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
