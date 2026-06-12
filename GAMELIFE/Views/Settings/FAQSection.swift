import SwiftUI

// MARK: - FAQ

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

enum FAQCatalog {

    static let items: [FAQItem] = [
        FAQItem(
            question: "What is PRAXIS?",
            answer: "PRAXIS turns your real life into an RPG. You create daily quests for habits you want to build, earn XP and gold for completing them, level up your hunter, and grow six stats — Strength, Intelligence, Agility, Vitality, Willpower, and Spirit."
        ),
        FAQItem(
            question: "How do XP, levels, and ranks work?",
            answer: "Every completed quest awards XP based on its difficulty. XP raises your level, and your level determines your hunter rank. An active streak multiplies the XP and gold you earn."
        ),
        FAQItem(
            question: "How do streaks work?",
            answer: "Complete all of your daily quests to extend your streak by one day. Longer streaks increase the XP and gold multiplier on every reward. A Streak Shield, when charged, protects your streak from one missed day."
        ),
        FAQItem(
            question: "What happens if I miss my daily quests?",
            answer: "Missed quests drain your HP. If HP reaches zero, you are defeated and death penalties apply: your stats and progress take a hit scaled to your rank. Higher ranks risk more."
        ),
        FAQItem(
            question: "What does the Death Mechanic Penalties toggle do?",
            answer: "Turning it off stops stat and progress penalties when your HP is depleted — but missed quests still cost HP. With penalties off, your HP simply restores after depletion instead of triggering a defeat."
        ),
        FAQItem(
            question: "How do the six stats increase?",
            answer: "Each quest targets a stat. Physical exercise builds Strength, studying builds Intelligence, stretching and promptness build Agility, sleep and nutrition build Vitality, resisting bad habits builds Willpower, and meditation builds Spirit. Completing quests raises the matching stat."
        ),
        FAQItem(
            question: "What is the Training tab?",
            answer: "Training is a focus timer for deep work. Pick a 15, 30, 45, or 60 minute session and stay focused until it ends. Completed sessions count toward your Training Sessions total and earn rewards."
        ),
        FAQItem(
            question: "What is the Shop?",
            answer: "The Shop is where you spend the gold you earn. You define your own real-life rewards — like a movie night or a treat — set a gold price, and buy them when you can afford it."
        ),
        FAQItem(
            question: "What are Neural Links?",
            answer: "Neural Links connect PRAXIS to your health and location data. With them enabled, quests like steps, workouts, or arriving at the gym can track progress automatically instead of being checked off by hand."
        ),
        FAQItem(
            question: "Does my progress sync between devices?",
            answer: "Yes. PRAXIS saves a snapshot of your game state to your private iCloud. Sign in with the same Apple ID and enable iCloud on each device to keep progress in sync."
        ),
        FAQItem(
            question: "What does Reset All do?",
            answer: "It wipes your hunter back to Level 1 — quests, bosses, XP, gold, HP, streaks, and achievements are all cleared. Your settings are kept. This cannot be undone."
        )
    ]
}

/// Collapsible FAQ for the Settings "About" section.
/// The whole section collapses, and each question expands individually.
struct FAQSection: View {

    @State private var isExpanded = false
    @State private var expandedItemID: UUID?

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(FAQCatalog.items) { item in
                FAQRow(
                    item: item,
                    isExpanded: expandedItemID == item.id,
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expandedItemID = expandedItemID == item.id ? nil : item.id
                        }
                    }
                )
            }
        } label: {
            Label("FAQ", systemImage: "questionmark.circle")
                .foregroundStyle(SystemTheme.textPrimary)
        }
        .tint(SystemTheme.textSecondary)
    }
}

private struct FAQRow: View {
    let item: FAQItem
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: onTap) {
                HStack(alignment: .top, spacing: 8) {
                    Text(item.question)
                        .font(SystemTypography.caption)
                        .foregroundStyle(SystemTheme.textPrimary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(SystemTheme.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(item.answer)
                    .font(SystemTypography.captionSmall)
                    .foregroundStyle(SystemTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 2)
    }
}
