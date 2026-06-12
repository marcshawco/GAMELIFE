import SwiftUI

// MARK: - Quest Completion Heatmap

/// GitHub-style contribution heatmap showing quests completed per day
/// over the last 12 months. Horizontally scrollable, anchored to today.
struct QuestHeatmapView: View {

    let history: [QuestHistoryRecord]
    let isCompact: Bool

    private static let weekCount = 53

    private struct DayCell {
        let date: Date
        let count: Int
    }

    private struct WeekColumn: Identifiable {
        let id: Int
        let days: [DayCell?] // always 7 slots; nil = outside range
        let monthLabel: String?
    }

    // MARK: Data

    private var dailyCounts: [Date: Int] {
        let calendar = Calendar.current
        var counts: [Date: Int] = [:]
        for record in history {
            let day = calendar.startOfDay(for: record.completedAt)
            counts[day, default: 0] += 1
        }
        return counts
    }

    private var weeks: [WeekColumn] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekdayOffset = (calendar.component(.weekday, from: today) - calendar.firstWeekday + 7) % 7

        guard let currentWeekStart = calendar.date(byAdding: .day, value: -weekdayOffset, to: today),
              let rangeStart = calendar.date(byAdding: .day, value: -7 * (Self.weekCount - 1), to: currentWeekStart) else {
            return []
        }

        let counts = dailyCounts
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"

        var columns: [WeekColumn] = []
        var lastLabeledMonth = -1

        for weekIndex in 0..<Self.weekCount {
            guard let weekStart = calendar.date(byAdding: .day, value: weekIndex * 7, to: rangeStart) else { continue }

            var days: [DayCell?] = []
            for dayIndex in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: dayIndex, to: weekStart),
                      date <= today else {
                    days.append(nil)
                    continue
                }
                days.append(DayCell(date: date, count: counts[date] ?? 0))
            }

            // Label a column when it contains the first week of a new month.
            var label: String? = nil
            let month = calendar.component(.month, from: weekStart)
            if month != lastLabeledMonth, calendar.component(.day, from: weekStart) <= 7 {
                label = monthFormatter.string(from: weekStart)
                lastLabeledMonth = month
            }

            columns.append(WeekColumn(id: weekIndex, days: days, monthLabel: label))
        }

        return columns
    }

    private var yearTotal: Int {
        let calendar = Calendar.current
        guard let cutoff = calendar.date(byAdding: .year, value: -1, to: Date()) else { return history.count }
        return history.filter { $0.completedAt >= cutoff }.count
    }

    // MARK: Appearance

    private var cellSize: CGFloat { isCompact ? 8 : 10 }
    private var cellSpacing: CGFloat { 2 }

    private func color(for count: Int) -> Color {
        switch count {
        case 0: return SystemTheme.backgroundSecondary
        case 1: return SystemTheme.accentCyan.opacity(0.25)
        case 2...3: return SystemTheme.accentCyan.opacity(0.45)
        case 4...6: return SystemTheme.accentCyan.opacity(0.7)
        default: return SystemTheme.accentCyan
        }
    }

    private var legendLevels: [Color] {
        [color(for: 0), color(for: 1), color(for: 2), color(for: 4), color(for: 7)]
    }

    // MARK: Body

    var body: some View {
        let columns = weeks

        VStack(alignment: .leading, spacing: isCompact ? 4 : 6) {
            Text("\(yearTotal) quests completed in the last year")
                .font(SystemTypography.mono(isCompact ? 10 : 11, weight: .semibold))
                .foregroundStyle(SystemTheme.textSecondary)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 3) {
                        // Month labels
                        HStack(alignment: .center, spacing: cellSpacing) {
                            ForEach(columns) { week in
                                Text(week.monthLabel ?? "")
                                    .font(SystemTypography.mono(8, weight: .medium))
                                    .foregroundStyle(SystemTheme.textTertiary)
                                    .fixedSize()
                                    .frame(width: cellSize, height: 10, alignment: .leading)
                            }
                        }

                        // Grid
                        HStack(alignment: .top, spacing: cellSpacing) {
                            ForEach(columns) { week in
                                VStack(spacing: cellSpacing) {
                                    ForEach(0..<7, id: \.self) { dayIndex in
                                        if let day = week.days[dayIndex] {
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(color(for: day.count))
                                                .frame(width: cellSize, height: cellSize)
                                        } else {
                                            Color.clear
                                                .frame(width: cellSize, height: cellSize)
                                        }
                                    }
                                }
                                .id(week.id)
                            }
                        }
                    }
                    .padding(.vertical, 1)
                }
                .onAppear {
                    proxy.scrollTo(Self.weekCount - 1, anchor: .trailing)
                }
            }

            // Legend
            HStack(spacing: 3) {
                Spacer()
                Text("Less")
                    .font(SystemTypography.mono(8, weight: .medium))
                    .foregroundStyle(SystemTheme.textTertiary)
                ForEach(Array(legendLevels.enumerated()), id: \.offset) { _, level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(level)
                        .frame(width: 8, height: 8)
                }
                Text("More")
                    .font(SystemTypography.mono(8, weight: .medium))
                    .foregroundStyle(SystemTheme.textTertiary)
            }
        }
    }
}
