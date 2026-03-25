//
//  BossesView.swift
//  GAMELIFE
//
//  [SYSTEM]: Boss encounter zone accessed.
//  Defeat the monsters blocking your path, Hunter.
//

import SwiftUI

private func uiSafeUnitProgress(_ value: Double) -> Double {
    guard value.isFinite else { return 0 }
    return min(1, max(0, value))
}

// MARK: - Bosses View

/// Tab 4: Projects & Long-term Goals displayed as Boss Fights
struct BossesView: View {

    // MARK: - Properties

    @EnvironmentObject var gameEngine: GameEngine
    @EnvironmentObject var deepLinkManager: DeepLinkManager
    @State private var showCreateBoss = false
    @State private var highlightedBossID: UUID?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                SystemTheme.backgroundPrimary
                    .ignoresSafeArea()

                if gameEngine.activeBossFights.isEmpty {
                    EmptyBossState(onCreateTapped: { showCreateBoss = true })
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: SystemSpacing.md) {
                                ForEach(gameEngine.activeBossFights) { boss in
                                    BossCardView(
                                        boss: boss,
                                        autoExpand: highlightedBossID == boss.id,
                                        onDealDamage: { task in
                                            dealDamage(boss: boss, task: task)
                                        },
                                        onUpdateDynamicValue: { value in
                                            updateDynamicBoss(boss: boss, currentValue: value)
                                        }
                                    )
                                    .id(boss.id)
                                    .overlay {
                                        if highlightedBossID == boss.id {
                                            RoundedRectangle(cornerRadius: SystemRadius.medium)
                                                .stroke(SystemTheme.primaryBlue, lineWidth: 2)
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                        .onChange(of: deepLinkManager.pendingLink) { _, link in
                            guard let link else { return }
                            guard case let .bosses(bossID) = link.route else { return }
                            guard let bossID else { return }

                            highlightedBossID = bossID
                            withAnimation(.easeInOut(duration: 0.25)) {
                                proxy.scrollTo(bossID, anchor: .top)
                            }

                            Task {
                                try? await Task.sleep(nanoseconds: 3_000_000_000)
                                await MainActor.run {
                                    if highlightedBossID == bossID {
                                        highlightedBossID = nil
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Bosses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateBoss = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(SystemTheme.primaryBlue)
                    }
                }
            }
            .toolbarBackground(SystemTheme.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .keyboardDismissToolbar()
            .sheet(isPresented: $showCreateBoss) {
                BossFormSheet()
            }
        }
    }

    // MARK: - Actions

    private func dealDamage(boss: BossFight, task: MicroTask) {
        _ = gameEngine.completeMicroTask(bossId: boss.id, taskId: task.id)
    }

    private func updateDynamicBoss(boss: BossFight, currentValue: Double) {
        gameEngine.updateDynamicBossCurrentValue(bossId: boss.id, currentValue: currentValue)
    }
}

// MARK: - Empty Boss State

struct EmptyBossState: View {
    let onCreateTapped: () -> Void

    var body: some View {
        VStack(spacing: SystemSpacing.lg) {
            Image(systemName: "bolt.shield")
                .font(.system(size: 64))
                .foregroundStyle(SystemTheme.textTertiary)

            Text("No Active Boss Fights")
                .font(SystemTypography.titleSmall)
                .foregroundStyle(SystemTheme.textSecondary)

            Text("\"Slay the monsters blocking your path\"")
                .font(SystemTypography.caption)
                .foregroundStyle(SystemTheme.textTertiary)
                .italic()

            Button(action: onCreateTapped) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Boss")
                }
                .font(SystemTypography.mono(14, weight: .semibold))
                .foregroundStyle(SystemTheme.primaryBlue)
                .padding()
                .background(SystemTheme.primaryBlue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: SystemRadius.medium))
            }
            .padding(.top, SystemSpacing.md)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Boss Card View

struct BossCardView: View {
    @EnvironmentObject var gameEngine: GameEngine
    let boss: BossFight
    let autoExpand: Bool
    let onDealDamage: (MicroTask) -> Void
    let onUpdateDynamicValue: (Double) -> Void

    @State private var isExpanded = false
    @State private var dynamicCurrentInput = ""

    private var linkedQuestTitles: [String] {
        boss.linkedQuestIDs.compactMap { questID in
            gameEngine.dailyQuests.first(where: { $0.id == questID })?.title
        }
    }

    var body: some View {
        VStack(spacing: SystemSpacing.md) {
            // Boss header with HP bar
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(boss.title)
                            .font(SystemTypography.headline)
                            .foregroundStyle(SystemTheme.textPrimary)

                        Text(boss.description)
                            .font(SystemTypography.caption)
                            .foregroundStyle(SystemTheme.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    // Expand/collapse
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundStyle(SystemTheme.textSecondary)
                            .padding(8)
                    }
                }

                // HP Bar
                VStack(spacing: 4) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(SystemTheme.backgroundSecondary)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(SystemTheme.hpGradient)
                                .frame(width: max(0, geometry.size.width) * uiSafeUnitProgress(boss.hpPercentage))
                        }
                    }
                    .frame(height: 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(SystemTheme.criticalRed.opacity(0.5), lineWidth: 1)
                    )

                    HStack {
                        Text("HP: \(boss.remainingHP) / \(boss.maxHP)")
                            .font(SystemTypography.mono(12, weight: .semibold))
                            .foregroundStyle(SystemTheme.criticalRed)

                        Spacer()

                        Text("\(Int(uiSafeUnitProgress(boss.damageDealtPercentage) * 100))% defeated")
                            .font(SystemTypography.captionSmall)
                            .foregroundStyle(SystemTheme.textTertiary)
                    }
                }
            }

            // Micro-tasks (expanded)
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    if let dynamicGoal = boss.dynamicGoal {
                        dynamicGoalSection(dynamicGoal)
                    }

                    Text("Micro-Tasks (Deal Damage)")
                        .font(SystemTypography.caption)
                        .foregroundStyle(SystemTheme.textSecondary)

                    ForEach(boss.microTasks) { task in
                        MicroTaskRow(task: task) {
                            onDealDamage(task)
                        }
                    }

                    if !linkedQuestTitles.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Linked Current Quests")
                                .font(SystemTypography.caption)
                                .foregroundStyle(SystemTheme.primaryBlue)

                            ForEach(linkedQuestTitles, id: \.self) { questTitle in
                                HStack(spacing: 8) {
                                    Image(systemName: "link")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(SystemTheme.primaryBlue)

                                    Text(questTitle)
                                        .font(SystemTypography.captionSmall)
                                        .foregroundStyle(SystemTheme.textSecondary)
                                }
                            }
                        }
                        .padding(10)
                        .background(SystemTheme.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: SystemRadius.small))
                    }

                    // Rewards preview
                    HStack {
                        Text("Defeat Rewards:")
                            .font(SystemTypography.captionSmall)
                            .foregroundStyle(SystemTheme.textTertiary)

                        Spacer()

                        HStack(spacing: SystemSpacing.sm) {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                Text("\(boss.xpReward)")
                                    .font(SystemTypography.mono(11, weight: .semibold))
                            }
                            .foregroundStyle(SystemTheme.primaryBlue)

                            HStack(spacing: 2) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 10))
                                Text("\(boss.goldReward)")
                                    .font(SystemTypography.mono(11, weight: .semibold))
                            }
                            .foregroundStyle(SystemTheme.goldColor)
                        }
                    }
                    .padding(.top, SystemSpacing.xs)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(SystemTheme.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: SystemRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: SystemRadius.medium)
                .stroke(SystemTheme.criticalRed.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            if let dynamicGoal = boss.dynamicGoal {
                dynamicCurrentInput = String(format: dynamicGoal.type == .savings ? "%.0f" : "%.1f", dynamicGoal.currentValue)
            }
        }
        .onChange(of: autoExpand) { _, shouldExpand in
            guard shouldExpand else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded = true
            }
        }
    }

    @ViewBuilder
    private func dynamicGoalSection(_ goal: DynamicBossGoal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Dynamic Goal", systemImage: goal.type.icon)
                    .font(SystemTypography.caption)
                    .foregroundStyle(SystemTheme.primaryBlue)
                Spacer()
                Text(goal.type.rawValue)
                    .font(SystemTypography.mono(11, weight: .semibold))
                    .foregroundStyle(SystemTheme.textSecondary)
            }

            HStack {
                Text("Start: \(formattedGoalValue(goal.startValue, unit: goal.unitLabel))")
                    .font(SystemTypography.captionSmall)
                    .foregroundStyle(SystemTheme.textTertiary)
                Spacer()
                Text("Current: \(formattedGoalValue(goal.currentValue, unit: goal.unitLabel))")
                    .font(SystemTypography.captionSmall)
                    .foregroundStyle(SystemTheme.textSecondary)
                Spacer()
                Text("Target: \(formattedGoalValue(goal.targetValue, unit: goal.unitLabel))")
                    .font(SystemTypography.captionSmall)
                    .foregroundStyle(SystemTheme.successGreen)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(SystemTheme.backgroundSecondary)
                    Capsule()
                        .fill(SystemTheme.primaryBlue)
                        .frame(width: max(0, geo.size.width) * uiSafeUnitProgress(goal.normalizedProgress))
                }
            }
            .frame(height: 5)

            Text("Progress: \(Int(uiSafeUnitProgress(goal.normalizedProgress) * 100))% • Remaining \(formattedGoalValue(goal.remainingAmount, unit: goal.unitLabel))")
                .font(SystemTypography.captionSmall)
                .foregroundStyle(SystemTheme.textSecondary)

            if goal.type == .savings {
                HStack(spacing: 8) {
                    TextField("Current savings", text: $dynamicCurrentInput)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)

                    Button("Update") {
                        if let value = Double(dynamicCurrentInput.replacingOccurrences(of: ",", with: "")) {
                            onUpdateDynamicValue(value)
                        }
                    }
                    .font(SystemTypography.mono(12, weight: .semibold))
                    .foregroundStyle(SystemTheme.primaryBlue)
                    .disabled(Double(dynamicCurrentInput.replacingOccurrences(of: ",", with: "")) == nil)
                }
            } else {
                Text(dynamicSourceText(for: goal.type))
                    .font(SystemTypography.captionSmall)
                    .foregroundStyle(SystemTheme.textTertiary)
            }
        }
        .padding(10)
        .background(SystemTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: SystemRadius.small))
    }

    private func dynamicSourceText(for type: DynamicBossGoalType) -> String {
        switch type {
        case .weight, .bodyFat, .stepCount, .sleepConsistency, .hydration, .mindfulness, .distance, .workoutConsistency:
            return "Auto-syncing from Apple Health."
        case .screenTimeDiscipline:
            return "Auto-syncing from Screen Time usage."
        case .savings:
            return "Update manually with your current saved amount."
        }
    }

    private func formattedGoalValue(_ value: Double, unit: String) -> String {
        if unit == "$" {
            return String(format: "$%.0f", value)
        }
        if value.rounded() == value {
            return "\(Int(value))\(unit)"
        }
        return String(format: "%.1f%@", value, unit)
    }
}

// MARK: - Micro Task Row

struct MicroTaskRow: View {
    let task: MicroTask
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onComplete) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isCompleted ? SystemTheme.successGreen : SystemTheme.textTertiary)
            }
            .disabled(task.isCompleted)

            Text(task.title)
                .font(SystemTypography.bodySmall)
                .foregroundStyle(task.isCompleted ? SystemTheme.textTertiary : SystemTheme.textPrimary)
                .strikethrough(task.isCompleted)

            Spacer()

            Text("-\(task.estimatedDamage) HP")
                .font(SystemTypography.mono(12, weight: .semibold))
                .foregroundStyle(SystemTheme.criticalRed)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(SystemTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: SystemRadius.small))
    }
}

// MARK: - Boss Form Sheet

struct BossFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var gameEngine: GameEngine

    @State private var name = ""
    @State private var description = ""
    @State private var maxHP = 1000
    @State private var difficulty: QuestDifficulty = .hard
    @State private var hasDeadline = false
    @State private var deadline = Date().addingTimeInterval(86400 * 7) // 1 week default
    @State private var useDynamicGoal = false
    @State private var dynamicGoalType: DynamicBossGoalType = .weight
    @State private var dynamicStartValue: Double = 180
    @State private var dynamicTargetValue: Double = 170
    @State private var dynamicCurrentValue: Double = 180
    @State private var dynamicCadence: GoalCadence = .weekly
    @State private var dynamicCadenceTarget: Double = 1
    @State private var autoGenerateGoalQuest = true
    @State private var activeWheelInput: BossWheelInput?

    // Micro-tasks
    @State private var microTasks: [String] = [""]
    @State private var linkedQuestIDs: Set<UUID> = []

    var isValid: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        if useDynamicGoal {
            return abs(dynamicTargetValue - dynamicStartValue) > 0.0001 && dynamicCadenceTarget > 0
        }
        return true
    }

    private var linkableQuests: [DailyQuest] {
        gameEngine.dailyQuests
            .filter { $0.status != .completed }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    private var selectableDynamicGoalTypes: [DynamicBossGoalType] {
        DynamicBossGoalType.betaSelectableTypes
    }

    private var draftDynamicGoal: DynamicBossGoal? {
        guard useDynamicGoal else { return nil }
        return DynamicBossGoal(
            type: dynamicGoalType,
            startValue: dynamicStartValue,
            targetValue: dynamicTargetValue,
            currentValue: dynamicCurrentValue,
            cadence: dynamicCadence,
            perCadenceTarget: dynamicCadenceTarget,
            generatedQuestID: nil,
            lastUpdatedAt: Date()
        )
    }

    private var resolvedBossHP: Int {
        guard let draftDynamicGoal else { return maxHP }
        return gameEngine.scaledDynamicBossMaxHP(
            for: draftDynamicGoal,
            difficulty: difficulty,
            playerLevel: gameEngine.player.level
        )
    }

    private var dynamicBossScalingPreview: GameEngine.DynamicBossScaling? {
        guard let draftDynamicGoal else { return nil }
        return gameEngine.dynamicBossScaling(
            for: draftDynamicGoal,
            difficulty: difficulty,
            playerLevel: gameEngine.player.level
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                // Boss Details
                Section {
                    TextField("Boss Name", text: $name)
                        .font(SystemTypography.body)

                    TextField("Description (Project goal)", text: $description)
                        .font(SystemTypography.body)
                } header: {
                    Text("Boss Details")
                }

                Section {
                    Toggle("Use Dynamic Goal Boss", isOn: $useDynamicGoal)

                    if useDynamicGoal {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Goal Type")
                                .font(SystemTypography.mono(11, weight: .bold))
                                .foregroundStyle(SystemTheme.primaryBlue)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(selectableDynamicGoalTypes) { type in
                                    Button {
                                        HapticManager.shared.selection()
                                        dynamicGoalType = type
                                    } label: {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack(spacing: 8) {
                                                Image(systemName: type.icon)
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundStyle(dynamicGoalType == type ? SystemTheme.backgroundPrimary : SystemTheme.primaryBlue)
                                                    .frame(width: 24, height: 24)
                                                    .background(
                                                        Circle()
                                                            .fill(dynamicGoalType == type ? SystemTheme.primaryBlue : SystemTheme.primaryBlue.opacity(0.15))
                                                    )

                                                Spacer(minLength: 0)

                                                if dynamicGoalType == type {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.system(size: 15, weight: .bold))
                                                        .foregroundStyle(SystemTheme.primaryBlue)
                                                }
                                            }

                                            Text(type.displayName)
                                                .font(SystemTypography.mono(12, weight: .bold))
                                                .foregroundStyle(SystemTheme.textPrimary)
                                                .multilineTextAlignment(.leading)

                                            Text(type.shortDescription)
                                                .font(SystemTypography.captionSmall)
                                                .foregroundStyle(SystemTheme.textSecondary)
                                                .multilineTextAlignment(.leading)
                                                .lineLimit(3)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
                                        .padding(12)
                                        .background(dynamicGoalType == type ? SystemTheme.primaryBlue.opacity(0.12) : SystemTheme.backgroundSecondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(dynamicGoalType == type ? SystemTheme.primaryBlue : SystemTheme.borderSecondary, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        HStack {
                            Text("Starting Value")
                            Spacer()
                            Button {
                                HapticManager.shared.selection()
                                activeWheelInput = .dynamicStart
                            } label: {
                                wheelInputPill(label: "Start", value: formattedValue(dynamicStartValue))
                            }
                            .buttonStyle(.plain)
                            Text(dynamicGoalType.unitLabel)
                                .foregroundStyle(SystemTheme.textSecondary)
                        }

                        HStack {
                            Text("Current Value")
                            Spacer()
                            Button {
                                HapticManager.shared.selection()
                                activeWheelInput = .dynamicCurrent
                            } label: {
                                wheelInputPill(label: "Current", value: formattedValue(dynamicCurrentValue))
                            }
                            .buttonStyle(.plain)
                            Text(dynamicGoalType.unitLabel)
                                .foregroundStyle(SystemTheme.textSecondary)
                        }

                        HStack {
                            Text("Target Value")
                            Spacer()
                            Button {
                                HapticManager.shared.selection()
                                activeWheelInput = .dynamicTarget
                            } label: {
                                wheelInputPill(label: "Target", value: formattedValue(dynamicTargetValue))
                            }
                            .buttonStyle(.plain)
                            Text(dynamicGoalType.unitLabel)
                                .foregroundStyle(SystemTheme.textSecondary)
                        }

                        Picker("Cadence", selection: $dynamicCadence) {
                            ForEach(GoalCadence.allCases) { cadence in
                                Label(cadence.rawValue, systemImage: cadence.icon)
                                    .tag(cadence)
                            }
                        }

                        HStack {
                            Text("Per-\(dynamicCadence.rawValue) Target")
                            Spacer()
                            Button {
                                HapticManager.shared.selection()
                                activeWheelInput = .cadenceTarget
                            } label: {
                                wheelInputPill(label: "Cadence", value: formattedValue(dynamicCadenceTarget))
                            }
                            .buttonStyle(.plain)
                            Text(dynamicGoalType.unitLabel)
                                .foregroundStyle(SystemTheme.textSecondary)
                        }

                        Toggle("Auto-generate linked quest", isOn: $autoGenerateGoalQuest)

                        Text(dynamicGoalExplanation)
                            .font(SystemTypography.captionSmall)
                            .foregroundStyle(SystemTheme.textSecondary)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Useful Scenarios")
                                .font(SystemTypography.mono(11, weight: .bold))
                                .foregroundStyle(SystemTheme.primaryBlue)

                            ForEach(dynamicGoalScenarios, id: \.self) { scenario in
                                Text("• \(scenario)")
                                    .font(SystemTypography.captionSmall)
                                    .foregroundStyle(SystemTheme.textTertiary)
                            }
                        }
                    }
                } header: {
                    Text("Dynamic Goal Engine")
                } footer: {
                    Text("Dynamic bosses lose or regain HP based on your real metric progress. Weight/body fat sync from Apple Health. Savings updates from your entered amount.")
                }

                // Combat Stats
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(useDynamicGoal ? "Auto-Scaled HP: \(resolvedBossHP)" : "Total HP: \(maxHP)")
                            .font(SystemTypography.mono(14, weight: .semibold))

                        if useDynamicGoal {
                            if let scaling = dynamicBossScalingPreview {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("\(scaling.requiredQuestCount) \(dynamicCadence.rawValue.lowercased()) quests at ~\(scaling.linkedQuestDamage) damage each")
                                        .font(SystemTypography.captionSmall)
                                        .foregroundStyle(SystemTheme.textSecondary)

                                    Text("HP is derived from total goal distance, so the boss matches the full journey instead of a fixed slider.")
                                        .font(SystemTypography.captionSmall)
                                        .foregroundStyle(SystemTheme.textTertiary)
                                }
                            }
                        } else {
                            Button {
                                HapticManager.shared.selection()
                                activeWheelInput = .maxHP
                            } label: {
                                wheelInputPill(label: "Boss HP", value: "\(maxHP)")
                            }
                            .buttonStyle(.plain)

                            Text("Higher HP = more micro-tasks needed to defeat")
                                .font(SystemTypography.captionSmall)
                                .foregroundStyle(SystemTheme.textTertiary)
                        }
                    }

                    Picker("Difficulty", selection: $difficulty) {
                        ForEach([QuestDifficulty.normal, .hard, .extreme, .legendary], id: \.self) { diff in
                            Text(diff.rawValue).tag(diff)
                        }
                    }
                } header: {
                    Text("Combat Stats")
                }

                // Deadline
                Section {
                    Toggle("Has Deadline", isOn: $hasDeadline)

                    if hasDeadline {
                        DatePicker(
                            "Deadline",
                            selection: $deadline,
                            in: Date()...,
                            displayedComponents: .date
                        )
                    }
                } header: {
                    Text("Deadline (Optional)")
                }

                // Initial Micro-tasks
                Section {
                    ForEach(microTasks.indices, id: \.self) { index in
                        HStack {
                            TextField("Micro-task \(index + 1)", text: $microTasks[index])
                                .font(SystemTypography.body)

                            if microTasks.count > 1 {
                                Button {
                                    microTasks.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(SystemTheme.criticalRed)
                                }
                            }
                        }
                    }

                    Button {
                        microTasks.append("")
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Micro-task")
                        }
                        .foregroundStyle(SystemTheme.primaryBlue)
                    }
                } header: {
                    Text("Initial Attacks (Micro-tasks)")
                } footer: {
                    Text("Break down your project into small actionable tasks")
                }

                Section {
                    if linkableQuests.isEmpty {
                        Text("No active daily quests available to link.")
                            .font(SystemTypography.caption)
                            .foregroundStyle(SystemTheme.textTertiary)
                    } else {
                        ForEach(linkableQuests) { quest in
                            Button {
                                if linkedQuestIDs.contains(quest.id) {
                                    linkedQuestIDs.remove(quest.id)
                                } else {
                                    linkedQuestIDs.insert(quest.id)
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(quest.title)
                                            .font(SystemTypography.bodySmall)
                                            .foregroundStyle(SystemTheme.textPrimary)

                                        Text(quest.trackingType.isAutomatic ? "Auto-tracked" : "Manual")
                                            .font(SystemTypography.captionSmall)
                                            .foregroundStyle(SystemTheme.textTertiary)
                                    }

                                    Spacer()

                                    Image(systemName: linkedQuestIDs.contains(quest.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(linkedQuestIDs.contains(quest.id) ? SystemTheme.primaryBlue : SystemTheme.textTertiary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Linked Current Quests")
                } footer: {
                    Text("Completing linked quests deals direct damage to this boss. Dynamic bosses also auto-scale linked quest targets to match remaining goal progress.")
                }

                // Rewards Preview
                Section {
                    HStack {
                        Text("XP Reward:")
                            .foregroundStyle(SystemTheme.textSecondary)
                        Spacer()
                        Text("+\(GameFormulas.questXP(difficulty: difficulty) * 10)")
                            .font(SystemTypography.mono(14, weight: .bold))
                            .foregroundStyle(SystemTheme.primaryBlue)
                    }

                    HStack {
                        Text("Gold Reward:")
                            .foregroundStyle(SystemTheme.textSecondary)
                        Spacer()
                        Text("+\(GameFormulas.questGold(difficulty: difficulty) * 10)")
                            .font(SystemTypography.mono(14, weight: .bold))
                            .foregroundStyle(SystemTheme.goldColor)
                    }
                } header: {
                    Text("Defeat Rewards")
                }
            }
            .navigationTitle("Create Boss")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createBoss() }
                        .disabled(!isValid)
                }
            }
            .sheet(item: $activeWheelInput) { input in
                BottomWheelValuePickerSheet(
                    title: input.title,
                    subtitle: input.subtitle,
                    accentColor: SystemTheme.criticalRed,
                    options: wheelOptions(for: input),
                    selection: wheelBinding(for: input),
                    confirmTitle: "Apply"
                )
            }
            .keyboardDismissToolbar()
            .onChange(of: dynamicGoalType) { _, newType in
                switch newType {
                case .weight:
                    dynamicStartValue = 180
                    dynamicCurrentValue = 180
                    dynamicTargetValue = 170
                    dynamicCadence = .weekly
                    dynamicCadenceTarget = 1
                case .bodyFat:
                    dynamicStartValue = 28
                    dynamicCurrentValue = 28
                    dynamicTargetValue = 20
                    dynamicCadence = .weekly
                    dynamicCadenceTarget = 0.5
                case .savings:
                    dynamicStartValue = 0
                    dynamicCurrentValue = 0
                    dynamicTargetValue = 5000
                    dynamicCadence = .weekly
                    dynamicCadenceTarget = 250
                case .stepCount:
                    dynamicStartValue = 0
                    dynamicCurrentValue = 0
                    dynamicTargetValue = 10000
                    dynamicCadence = .daily
                    dynamicCadenceTarget = 2000
                case .sleepConsistency:
                    dynamicStartValue = 5
                    dynamicCurrentValue = 5
                    dynamicTargetValue = 8
                    dynamicCadence = .daily
                    dynamicCadenceTarget = 0.5
                case .hydration:
                    dynamicStartValue = 2
                    dynamicCurrentValue = 2
                    dynamicTargetValue = 8
                    dynamicCadence = .daily
                    dynamicCadenceTarget = 1
                case .mindfulness:
                    dynamicStartValue = 0
                    dynamicCurrentValue = 0
                    dynamicTargetValue = 20
                    dynamicCadence = .daily
                    dynamicCadenceTarget = 5
                case .distance:
                    dynamicStartValue = 0
                    dynamicCurrentValue = 0
                    dynamicTargetValue = 30
                    dynamicCadence = .weekly
                    dynamicCadenceTarget = 5
                case .workoutConsistency:
                    dynamicStartValue = 0
                    dynamicCurrentValue = 0
                    dynamicTargetValue = 4
                    dynamicCadence = .weekly
                    dynamicCadenceTarget = 4
                case .screenTimeDiscipline:
                    dynamicStartValue = 180
                    dynamicCurrentValue = 180
                    dynamicTargetValue = 60
                    dynamicCadence = .daily
                    dynamicCadenceTarget = 60
                }
            }
        }
    }

    private var dynamicGoalExplanation: String {
        switch dynamicGoalType {
        case .weight:
            return "Example: start 180lb, goal 160lb, target 1lb per week. The boss auto-scales to 20 weekly quests worth of HP."
        case .bodyFat:
            return "Example: start 30%, goal 20%, target 1% per week. HP scales to 10 weeks of progress and tracks the real trend from Health."
        case .savings:
            return "Example: start $0, goal $5000, target $250 per week. HP scales to 20 weekly deposits and updates as savings change."
        case .stepCount:
            return "Example: build from 0 to 10,000 daily steps at a 2,000-step pace. HP scales to the full movement climb."
        case .sleepConsistency:
            return "Example: move from 5 to 8 hours nightly at 0.5 hours per cadence. HP reflects the full recovery journey."
        case .hydration:
            return "Example: move from 2 to 8 glasses daily at 1 glass per cadence. HP scales to the full hydration gap."
        case .mindfulness:
            return "Example: move from 0 to 20 mindful minutes daily at 5 minutes per cadence. HP tracks the whole calm-building block."
        case .distance:
            return "Example: build from 0 to 30km weekly at 5km per cadence. HP scales to the full endurance milestone."
        case .workoutConsistency:
            return "Example: start 0, goal 12 workouts, target 4 per week. HP scales to 3 weeks of workout quests."
        case .screenTimeDiscipline:
            return "Example: baseline 180 min social media, target 60 min, target 10 min per day. HP scales to 12 daily quests."
        }
    }

    private var dynamicGoalScenarios: [String] {
        switch dynamicGoalType {
        case .weight:
            return [
                "A cut for a trip, photo shoot, or summer block.",
                "A lean bulk capped at a target bodyweight.",
                "Post-holiday weight recovery with weekly checkpoints."
            ]
        case .bodyFat:
            return [
                "Dropping from one body-fat range into another over a season.",
                "Recomp prep where trend changes matter more than scale weight.",
                "A coaching-style cut with weekly composition targets."
            ]
        case .savings:
            return [
                "Building an emergency fund over several months.",
                "Saving for a console, trip, car down payment, or tuition.",
                "Aggressively paying down a budget target one deposit at a time."
            ]
        case .stepCount:
            return [
                "Building a walking habit after long desk-heavy days.",
                "Increasing daily movement before a trip or event.",
                "Recovering a consistent cardio baseline without intense training."
            ]
        case .sleepConsistency:
            return [
                "Repairing a chaotic sleep schedule before a hard season.",
                "A recovery block where sleep is the real performance lever.",
                "Stabilizing bedtime and total hours during stressful weeks."
            ]
        case .hydration:
            return [
                "Fixing low daily water intake during training or summer heat.",
                "Using hydration to support energy, cravings, and recovery.",
                "Creating a simple daily win that compounds into better habits."
            ]
        case .mindfulness:
            return [
                "A meditation streak during anxious or overloaded weeks.",
                "Daily breathing resets before deep work or sleep.",
                "Building calm recovery time into a demanding season."
            ]
        case .distance:
            return [
                "Training for a walk, hike, 5K, or endurance milestone.",
                "Progressively increasing weekly movement volume.",
                "A rehab-friendly distance build with clear checkpoints."
            ]
        case .workoutConsistency:
            return [
                "Twelve workouts over three weeks before an event.",
                "Rebuilding gym consistency after a long break.",
                "Locking in a run, lift, or class streak each week."
            ]
        case .screenTimeDiscipline:
            return [
                "Reducing social scroll before bed.",
                "Cutting reels or TikTok time during work weeks.",
                "A focused exam or launch sprint with lower daily usage caps."
            ]
        }
    }

    private func createBoss() {
        let dynamicGoal = draftDynamicGoal

        let resolvedTargetStats = dynamicGoal?.type.defaultStatTargets ?? [.intelligence, .willpower]

        // Create the boss
        let boss = gameEngine.createBossFight(
            title: name,
            description: description,
            difficulty: difficulty,
            targetStats: resolvedTargetStats,
            maxHP: maxHP,
            linkedQuestIDs: Array(linkedQuestIDs),
            dynamicGoal: dynamicGoal,
            autoGenerateGoalQuest: useDynamicGoal && autoGenerateGoalQuest,
            deadline: hasDeadline ? deadline : nil
        )

        // Add micro-tasks
        for taskTitle in microTasks where !taskTitle.trimmingCharacters(in: .whitespaces).isEmpty {
            gameEngine.addMicroTask(to: boss.id, title: taskTitle, difficulty: .normal)
        }

        dismiss()
    }

    private func wheelOptions(for input: BossWheelInput) -> [WheelValueOption] {
        switch input {
        case .maxHP:
            return Array(stride(from: 100, through: 10000, by: 100)).map { WheelValueOption(value: Double($0), label: "\($0) HP") }
        case .dynamicStart, .dynamicCurrent, .dynamicTarget:
            return dynamicValueOptions(for: dynamicGoalType)
        case .cadenceTarget:
            return cadenceTargetOptions(for: dynamicGoalType)
        }
    }

    private func wheelBinding(for input: BossWheelInput) -> Binding<Double> {
        switch input {
        case .maxHP:
            return Binding(
                get: { Double(maxHP) },
                set: { maxHP = Int($0.rounded()) }
            )
        case .dynamicStart:
            return $dynamicStartValue
        case .dynamicCurrent:
            return $dynamicCurrentValue
        case .dynamicTarget:
            return $dynamicTargetValue
        case .cadenceTarget:
            return $dynamicCadenceTarget
        }
    }

    private func dynamicValueOptions(for type: DynamicBossGoalType) -> [WheelValueOption] {
        switch type {
        case .savings:
            return Array(stride(from: 0, through: 20000, by: 50)).map { WheelValueOption(value: Double($0), label: "$\($0)") }
        case .weight:
            return Array(stride(from: 80, through: 400, by: 1)).map { WheelValueOption(value: Double($0), label: "\($0) lb") }
        case .bodyFat:
            return Array(stride(from: 5, through: 60, by: 1)).map { WheelValueOption(value: Double($0), label: "\($0)%") }
        case .stepCount:
            return Array(stride(from: 0, through: 50000, by: 500)).map { WheelValueOption(value: Double($0), label: "\($0) steps") }
        case .sleepConsistency:
            return Array(stride(from: 0, through: 14, by: 0.5)).map { WheelValueOption(value: $0, label: formattedDecimalLabel($0, suffix: " hr")) }
        case .hydration:
            return Array(stride(from: 0, through: 24, by: 0.5)).map { WheelValueOption(value: $0, label: formattedDecimalLabel($0, suffix: " glasses")) }
        case .mindfulness:
            return Array(stride(from: 0, through: 120, by: 5)).map { WheelValueOption(value: Double($0), label: "\($0) min") }
        case .distance:
            return Array(stride(from: 0, through: 100, by: 0.5)).map { WheelValueOption(value: $0, label: formattedDecimalLabel($0, suffix: " km")) }
        case .workoutConsistency:
            return Array(0...14).map { WheelValueOption(value: Double($0), label: "\($0) workouts") }
        case .screenTimeDiscipline:
            return Array(stride(from: 0, through: 360, by: 5)).map { WheelValueOption(value: Double($0), label: "\($0) min") }
        }
    }

    private func cadenceTargetOptions(for type: DynamicBossGoalType) -> [WheelValueOption] {
        switch type {
        case .savings:
            return Array(stride(from: 25, through: 5000, by: 25)).map { WheelValueOption(value: Double($0), label: "$\($0)") }
        case .weight, .bodyFat:
            return Array(stride(from: 1, through: 40, by: 1)).map { WheelValueOption(value: Double($0), label: "\($0) \(type.unitLabel)") }
        case .stepCount:
            return Array(stride(from: 500, through: 25000, by: 500)).map { WheelValueOption(value: Double($0), label: "\($0) steps") }
        case .sleepConsistency:
            return Array(stride(from: 0.5, through: 4, by: 0.5)).map { WheelValueOption(value: $0, label: formattedDecimalLabel($0, suffix: " hr")) }
        case .hydration:
            return Array(stride(from: 0.5, through: 8, by: 0.5)).map { WheelValueOption(value: $0, label: formattedDecimalLabel($0, suffix: " glasses")) }
        case .mindfulness:
            return Array(stride(from: 5, through: 60, by: 5)).map { WheelValueOption(value: Double($0), label: "\($0) min") }
        case .distance:
            return Array(stride(from: 0.5, through: 20, by: 0.5)).map { WheelValueOption(value: $0, label: formattedDecimalLabel($0, suffix: " km")) }
        case .workoutConsistency:
            return Array(1...14).map { WheelValueOption(value: Double($0), label: "\($0) workouts") }
        case .screenTimeDiscipline:
            return Array(stride(from: 5, through: 360, by: 5)).map { WheelValueOption(value: Double($0), label: "\($0) min") }
        }
    }

    private func formattedValue(_ value: Double) -> String {
        if dynamicGoalType == .savings {
            return String(format: "$%.0f", value)
        }
        if value.rounded() == value {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }

    private func formattedDecimalLabel(_ value: Double, suffix: String) -> String {
        if value.rounded() == value {
            return "\(Int(value))\(suffix)"
        }
        return String(format: "%.1f%@", value, suffix)
    }

    @ViewBuilder
    private func wheelInputPill(label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Text(label.uppercased())
                .font(SystemTypography.mono(10, weight: .bold))
                .foregroundStyle(SystemTheme.textTertiary)
            Text(value)
                .font(SystemTypography.mono(14, weight: .bold))
                .foregroundStyle(SystemTheme.textPrimary)
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(SystemTheme.criticalRed)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(SystemTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(SystemTheme.borderSecondary, lineWidth: 1)
        )
    }
}

private enum BossWheelInput: String, Identifiable {
    case maxHP
    case dynamicStart
    case dynamicCurrent
    case dynamicTarget
    case cadenceTarget

    var id: String { rawValue }

    var title: String {
        switch self {
        case .maxHP: return "Boss Hit Points"
        case .dynamicStart: return "Starting Value"
        case .dynamicCurrent: return "Current Value"
        case .dynamicTarget: return "Target Value"
        case .cadenceTarget: return "Cadence Target"
        }
    }

    var subtitle: String {
        switch self {
        case .maxHP: return "Set the overall durability of this boss."
        case .dynamicStart: return "Choose the metric value where the boss begins."
        case .dynamicCurrent: return "Set the latest real-world metric value."
        case .dynamicTarget: return "Choose the value that defeats the boss."
        case .cadenceTarget: return "Set how much progress is expected each cadence."
        }
    }
}

// MARK: - Preview

#Preview {
    BossesView()
        .environmentObject(GameEngine.shared)
}
