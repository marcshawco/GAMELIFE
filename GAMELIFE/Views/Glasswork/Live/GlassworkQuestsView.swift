//
//  GlassworkQuestsView.swift
//  GAMELIFE
//
//  Live Glasswork Quests tab — wired to GameEngine. Mirrors the Praxis Demo
//  prototype: header + day progress + filter chips + tappable quest cards
//  with checkbox completion → triggers the Quest Cleared modal with the
//  real reward payload. FAB opens the existing QuestFormSheet for create.
//

import SwiftUI

struct GlassworkQuestsView: View {
    @EnvironmentObject var gameEngine: GameEngine
    @State private var showAddSheet = false
    @State private var showQuickAddSheet = false
    @State private var clearedPayload: ClearedQuestPayload?
    @State private var expandedSubtaskQuestIDs: Set<UUID> = []

    struct ClearedQuestPayload: Identifiable {
        let id = UUID()
        let title: String
        let primaryStat: String
        let xpAwarded: Int
        let goldAwarded: Int
        let statGains: [(StatType, Int)]
    }

    var body: some View {
        let quests = gameEngine.dailyQuests
        let doneCount = quests.filter { $0.status == .completed }.count
        let totalCount = quests.count
        let dayPct = totalCount == 0 ? 0 : Double(doneCount) / Double(totalCount)

        ZStack(alignment: .bottom) {
            ZStack {
                GW.bg.ignoresSafeArea()
                GWAurora().ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        header(doneCount: doneCount, totalCount: totalCount)
                        dayProgressCard(pct: dayPct)
                        filterStrip
                        questList(quests: quests)
                        Color.clear.frame(height: 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 130)
                }
            }

            HStack(spacing: 12) {
                Spacer()
                Button { showQuickAddSheet = true } label: {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(GW.bg)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(GW.cyan))
                        .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                        .shadow(color: GW.cyan.opacity(0.32), radius: 12, x: 0, y: 7)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add quick quest")

                Button { showAddSheet = true } label: {
                    Text("+")
                        .font(GW.display(28, weight: .regular))
                        .foregroundStyle(GW.bg)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(GW.grad))
                        .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .shadow(color: GW.pink.opacity(0.4), radius: 14, x: 0, y: 8)
                }
                .buttonStyle(.plain)
            }
            .padding(.trailing, 18)
            .padding(.bottom, 16)
        }
        .foregroundStyle(GW.ink)
        
        .sheet(isPresented: $showAddSheet) {
            QuestFormSheet(mode: .add)
        }
        .sheet(isPresented: $showQuickAddSheet) {
            QuickQuestSheet()
        }
        .fullScreenCover(item: $clearedPayload) { payload in
            GlassworkQuestClearedModal(
                questTitle: payload.title,
                primaryStat: payload.primaryStat,
                xpAwarded: payload.xpAwarded,
                goldAwarded: payload.goldAwarded,
                statGains: payload.statGains,
                onClose: { clearedPayload = nil }
            )
            .presentationBackground(.clear)
        }
    }

    // MARK: - Header

    private func header(doneCount: Int, totalCount: Int) -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text("QUEST LOG")
                    .font(GW.mono(10, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(GW.mute)
                Text("Today")
                    .font(GW.display(26, weight: .semibold))
                    .tracking(-0.5)
                    .foregroundStyle(GW.ink)
            }
            Spacer()
            GWPill(text: totalCount == 0 ? "NO QUESTS" : "\(doneCount)/\(totalCount) CLEARED",
                   color: GW.cyan,
                   bg: GW.cyan.opacity(0.07),
                   border: GW.cyan.opacity(0.33))
        }
    }

    private func dayProgressCard(pct: Double) -> some View {
        GWCard(paddingX: 14, paddingY: 12) {
            VStack(spacing: 8) {
                HStack {
                    Text("DAY PROGRESS")
                        .font(GW.mono(10))
                        .tracking(1)
                        .foregroundStyle(GW.mute)
                    Spacer()
                    Text("\(Int(pct * 100))%")
                        .font(GW.mono(10))
                        .tracking(1)
                        .foregroundStyle(GW.mute)
                }
                GWBar(pct: pct, height: 6)
            }
        }
    }

    private var filterStrip: some View {
        HStack(spacing: 6) {
            ForEach(Array(["ALL", "DAILY", "WEEKLY", "BOSS"].enumerated()),
                    id: \.element) { i, t in
                GWFilterChip(label: t, active: i == 0)
            }
            Spacer()
        }
    }

    // MARK: - Quest list

    @ViewBuilder
    private func questList(quests: [DailyQuest]) -> some View {
        if quests.isEmpty {
            GWCard(paddingX: 14, paddingY: 18) {
                VStack(spacing: 6) {
                    Text("No quests yet")
                        .font(GW.sans(14, weight: .semibold))
                        .foregroundStyle(GW.ink)
                    Text("Tap the + button to summon your first one.")
                        .font(GW.sans(12))
                        .foregroundStyle(GW.mute)
                }
                .frame(maxWidth: .infinity)
            }
        } else {
            ForEach(quests, id: \.id) { q in
                questCard(q)
            }
        }
    }

    private func questCard(_ q: DailyQuest) -> some View {
        let done = q.status == .completed
        let progress = q.normalizedProgress
        let active = !done && progress > 0
        let primaryStat = q.targetStats.first?.rawValue ?? "—"

        return GWCard(paddingX: 14, paddingY: 12) {
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    completionBadge(done: done, active: active, progress: progress)
                        .onTapGesture { tapComplete(q) }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(q.title)
                            .font(GW.sans(13, weight: .medium))
                            .foregroundStyle(done ? GW.mute : GW.ink)
                            .strikethrough(done)
                        Text(q.description.uppercased())
                            .font(GW.mono(9))
                            .tracking(0.5)
                            .foregroundStyle(GW.mute)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 6)
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("+\(q.xpReward)")
                            .font(GW.mono(10))
                            .foregroundStyle(GW.cyan)
                        Text("+\(q.goldReward)g")
                            .font(GW.mono(9))
                            .foregroundStyle(GW.amber)
                    }
                }
                if active {
                    GWBar(pct: progress, height: 3, glow: false)
                }
                HStack(spacing: 8) {
                    Text("\(primaryStat) primary")
                        .font(GW.mono(8))
                        .tracking(1)
                        .foregroundStyle(GW.mute)

                    Spacer()

                    if q.hasSubtasks {
                        subtaskDropDownButton(for: q)
                    }
                }

                if q.hasSubtasks && expandedSubtaskQuestIDs.contains(q.id) {
                    subtaskDropDownList(for: q)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .opacity(done ? 0.55 : 1)
    }

    private func subtaskDropDownButton(for quest: DailyQuest) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                if expandedSubtaskQuestIDs.contains(quest.id) {
                    expandedSubtaskQuestIDs.remove(quest.id)
                } else {
                    expandedSubtaskQuestIDs.insert(quest.id)
                }
            }
            HapticManager.shared.selection()
        } label: {
            HStack(spacing: 5) {
                Text("\(quest.completedSubtaskCount)/\(quest.subtasks.count) STEPS")
                    .font(GW.mono(8, weight: .medium))
                    .tracking(1)
                Image(systemName: expandedSubtaskQuestIDs.contains(quest.id) ? "chevron.up" : "chevron.down")
                    .font(.system(size: 8, weight: .bold))
            }
            .foregroundStyle(GW.cyan)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Capsule().fill(GW.cyan.opacity(0.07)))
            .overlay(Capsule().stroke(GW.cyan.opacity(0.26), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Toggle subtasks")
    }

    private func subtaskDropDownList(for quest: DailyQuest) -> some View {
        VStack(spacing: 6) {
            ForEach(Array(quest.subtasks.enumerated()), id: \.element.id) { index, subtask in
                Button {
                    tapSubtask(subtask, in: quest)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(subtask.isCompleted ? GW.cyan : GW.mute)
                            .frame(width: 16)

                        Text(subtask.title.uppercased())
                            .font(GW.mono(8))
                            .tracking(0.7)
                            .foregroundStyle(subtask.isCompleted ? GW.mute : GW.ink)
                            .strikethrough(subtask.isCompleted)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(subtaskRewardText(for: quest, index: index))
                            .font(GW.mono(8))
                            .foregroundStyle(GW.cyan)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 7)
                    .padding(.horizontal, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(subtask.isCompleted ? 0.035 : 0.055))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(subtask.isCompleted || quest.status == .completed)
            }
        }
        .padding(.top, 2)
    }

    private func subtaskRewardText(for quest: DailyQuest, index: Int) -> String {
        let xp = quest.subtaskXPReward(at: index)
        let gold = quest.subtaskGoldReward(at: index)
        if gold > 0 {
            return "+\(xp) +\(gold)g"
        }
        return "+\(xp)"
    }

    private func completionBadge(done: Bool, active: Bool, progress: Double) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(done ? AnyShapeStyle(GW.grad)
                      : active ? AnyShapeStyle(GW.cyan.opacity(0.08))
                      : AnyShapeStyle(Color.clear))
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(done ? GW.cyan
                        : active ? GW.cyan.opacity(0.53)
                        : Color.white.opacity(0.18),
                        lineWidth: 1.5)
            if done {
                Text("✓").font(GW.mono(10, weight: .bold)).foregroundStyle(GW.bg)
            } else if active {
                Text("\(Int(progress * 100))")
                    .font(GW.mono(10, weight: .bold))
                    .foregroundStyle(GW.cyan)
            } else {
                Text("◇").font(GW.mono(10, weight: .bold)).foregroundStyle(GW.cyan)
            }
        }
        .frame(width: 28, height: 28)
        .contentShape(Rectangle())
    }

    // MARK: - Actions

    private func tapComplete(_ q: DailyQuest) {
        guard q.status != .completed else { return }
        let result = gameEngine.completeQuest(q)
        guard result.success else { return }

        HapticManager.shared.success()
        clearedPayload = ClearedQuestPayload(
            title: q.title,
            primaryStat: q.targetStats.first?.rawValue ?? "—",
            xpAwarded: result.xpAwarded,
            goldAwarded: result.goldAwarded,
            statGains: result.statGains
        )
    }

    private func tapSubtask(_ subtask: QuestSubtask, in quest: DailyQuest) {
        guard !subtask.isCompleted, quest.status != .completed else { return }
        let result = gameEngine.completeQuestSubtask(questID: quest.id, subtaskID: subtask.id)
        guard result.success else { return }

        HapticManager.shared.success()
        clearedPayload = ClearedQuestPayload(
            title: result.isQuestComplete ? quest.title : subtask.title,
            primaryStat: quest.targetStats.first?.rawValue ?? "—",
            xpAwarded: result.xpAwarded,
            goldAwarded: result.goldAwarded,
            statGains: result.statGains
        )
    }
}

private struct QuickQuestSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var gameEngine: GameEngine

    @State private var title = ""
    @State private var reminderEnabled = false
    @State private var reminderTime = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var makeTinySteps = false
    @State private var showValidation = false
    @FocusState private var titleFocused: Bool

    private let templates = [
        "5 min clean",
        "Drink water",
        "Take meds",
        "Reply to one message",
        "Walk outside",
        "Start homework"
    ]

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedTitle.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GW.bg.ignoresSafeArea()
                GWAurora().ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        header
                        titleCard
                        templateCard
                        optionsCard
                        saveButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, 28)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .foregroundStyle(GW.ink)
            .navigationTitle("Quick Quest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(GW.mute)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                titleFocused = true
            }
        }
        .accentColor(GW.cyan)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("[ QUICK CAPTURE ]")
                .font(GW.mono(10, weight: .medium))
                .tracking(2.4)
                .foregroundStyle(GW.cyan)
            Text("Add it before it slips.")
                .font(GW.display(24, weight: .semibold))
                .foregroundStyle(GW.ink)
            Text("PRAXIS fills in the game details. You can edit them later.")
                .font(GW.sans(12))
                .foregroundStyle(GW.mute)
                .lineSpacing(2)
        }
    }

    private var titleCard: some View {
        GWCard(paddingX: 14, paddingY: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("QUEST NAME")
                    .font(GW.mono(9, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(GW.mute)
                TextField("What needs doing?", text: $title)
                    .font(GW.sans(16, weight: .medium))
                    .foregroundStyle(GW.ink)
                    .textFieldStyle(.plain)
                    .submitLabel(.done)
                    .focused($titleFocused)
                    .onSubmit { saveQuickQuest() }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(GW.cyan.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(GW.cyan.opacity(0.22), lineWidth: 1)
                            )
                    )

                if showValidation && !canSave {
                    Label("Name the quest first.", systemImage: "exclamationmark.triangle.fill")
                        .font(GW.sans(12, weight: .medium))
                        .foregroundStyle(GW.amber)
                }
            }
        }
    }

    private var templateCard: some View {
        GWCard(paddingX: 14, paddingY: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text("TAP A STARTER")
                    .font(GW.mono(9, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(GW.mute)

                QuickQuestChipsRow {
                    ForEach(templates, id: \.self) { template in
                        Button {
                            title = template
                            showValidation = false
                            HapticManager.shared.selection()
                        } label: {
                            Text(template.uppercased())
                                .font(GW.mono(9, weight: .medium))
                                .tracking(1)
                                .foregroundStyle(title == template ? GW.bg : GW.cyan)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule()
                                        .fill(title == template ? GW.cyan : GW.cyan.opacity(0.07))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(GW.cyan.opacity(0.32), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var optionsCard: some View {
        GWCard(paddingX: 14, paddingY: 12) {
            VStack(spacing: 12) {
                Toggle(isOn: $makeTinySteps) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Make it tiny")
                            .font(GW.sans(13, weight: .semibold))
                            .foregroundStyle(GW.ink)
                        Text("Adds 3 quick steps with partial rewards.")
                            .font(GW.sans(11))
                            .foregroundStyle(GW.mute)
                    }
                }
                .tint(GW.cyan)

                Divider().overlay(GW.hairline)

                Toggle(isOn: $reminderEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reminder")
                            .font(GW.sans(13, weight: .semibold))
                            .foregroundStyle(GW.ink)
                        Text("Optional daily nudge for this quest.")
                            .font(GW.sans(11))
                            .foregroundStyle(GW.mute)
                    }
                }
                .tint(GW.cyan)

                if reminderEnabled {
                    DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .font(GW.sans(13))
                        .foregroundStyle(GW.ink)
                        .datePickerStyle(.compact)
                }
            }
        }
    }

    private var saveButton: some View {
        GWButton(label: "ADD QUEST", variant: .primary) {
            saveQuickQuest()
        }
        .disabled(!canSave)
        .opacity(canSave ? 1 : 0.55)
        .padding(.top, 2)
    }

    private func saveQuickQuest() {
        guard canSave else {
            showValidation = true
            HapticManager.shared.warning()
            return
        }

        let now = Date()
        let subtasks = makeTinySteps ? defaultTinySteps(for: trimmedTitle) : []
        let quest = DailyQuest(
            title: trimmedTitle,
            description: "Quick quest",
            difficulty: .easy,
            status: .available,
            targetStats: [.willpower],
            frequency: .daily,
            isOptional: false,
            trackingType: .manual,
            currentProgress: 0,
            targetValue: 1,
            unit: "times",
            createdAt: now,
            expiresAt: QuestFrequency.daily.nextResetDate(from: now),
            reminderEnabled: reminderEnabled,
            reminderTime: reminderEnabled ? reminderTime : nil,
            subtasks: subtasks
        )

        gameEngine.saveQuest(quest)
        HapticManager.shared.success()
        SystemMessageHelper.showInfo("Quest Added", "\"\(trimmedTitle)\" is ready.")
        dismiss()
    }

    private func defaultTinySteps(for questTitle: String) -> [QuestSubtask] {
        [
            QuestSubtask(title: "Start \(questTitle)"),
            QuestSubtask(title: "Do the next tiny piece"),
            QuestSubtask(title: "Finish or park it cleanly")
        ]
    }
}

private struct QuickQuestChipsRow<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                content
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ],
                alignment: .leading,
                spacing: 8
            ) {
                content
            }
        }
    }
}
