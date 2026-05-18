//
//  QuestFormSheet.swift
//  GAMELIFE
//
//  Quest creation and editing.
//

import SwiftUI
import CoreLocation
import MapKit
import Combine

// MARK: - Quest Form Mode

enum QuestFormMode: Identifiable {
    case add
    case edit(DailyQuest)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let quest): return quest.id.uuidString
        }
    }

    var isEditing: Bool {
        if case .edit = self { return true }
        return false
    }

    var existingQuest: DailyQuest? {
        if case .edit(let quest) = self { return quest }
        return nil
    }
}

// MARK: - Quest Form Sheet

struct QuestFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var gameEngine: GameEngine

    let mode: QuestFormMode

    // Core form state
    @State private var title = ""
    @State private var description = ""
    @State private var difficulty: QuestDifficulty = .easy
    @State private var selectedStats: Set<StatType> = []
    @State private var trackingType: QuestTrackingType = .manual
    @State private var frequency: QuestFrequency = .daily
    @State private var targetValue: Double = 1
    @State private var unit = "times"

    // Tracking-specific state
    @State private var healthKitType: HealthKitQuestType = .steps
    @State private var showHealthTypePicker = false
    @State private var locationAddress = ""
    @State private var locationCoordinate: LocationCoordinate?
    @State private var locationRadiusMeters: Double = 804.67
    @State private var isValidatingAddress = false
    @State private var locationValidationMessage: String?
    @State private var locationValidationIsError = false
    @StateObject private var addressAutocomplete = AddressAutocompleteProvider()

    // Boss linking
    @State private var selectedBossID: UUID?
    @State private var showCreateBossSheet = false

    // Reminders
    @State private var reminderEnabled = false
    @State private var reminderTime = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var isOptionalQuest = false

    // UI state
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var activeWheelInput: QuestWheelInput?
    @State private var showValidationFeedback = false

    private var linkableBosses: [BossFight] {
        gameEngine.activeBossFights.sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    private var selectedBoss: BossFight? {
        guard let selectedBossID else { return nil }
        return gameEngine.activeBossFights.first(where: { $0.id == selectedBossID })
    }

    private var estimatedBossDamage: Int {
        let baseDamage = GameFormulas.bossDamage(taskDifficulty: difficulty, playerLevel: gameEngine.player.level)
        return max(1, Int(Double(baseDamage) * 0.8))
    }

    private var estimatedBossDamagePercentage: Int {
        guard let selectedBoss, selectedBoss.maxHP > 0 else { return 0 }
        let ratio = (Double(estimatedBossDamage) / Double(selectedBoss.maxHP)) * 100
        return Int(max(0, min(100, ratio.rounded())))
    }

    private var isValid: Bool {
        let hasLocationAddress = trackingType != .location || !locationAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasValidatedLocation = trackingType != .location || locationCoordinate != nil
        return hasTitle && hasStats && hasLocationAddress && hasValidatedLocation
    }

    private var hasTitle: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasStats: Bool {
        !selectedStats.isEmpty
    }

    private var hasLocationAddress: Bool {
        trackingType != .location || !locationAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasValidatedLocation: Bool {
        trackingType != .location || locationCoordinate != nil
    }

    private var validationSummaryText: String {
        if isValid {
            return mode.isEditing ? "Ready to save this quest." : "Ready to create this quest."
        }

        var missing: [String] = []
        if !hasTitle { missing.append("name") }
        if !hasStats { missing.append("stat") }
        if trackingType == .location {
            if !hasLocationAddress {
                missing.append("address")
            } else if !hasValidatedLocation {
                missing.append("validated address")
            }
        }

        return "Required before \(mode.isEditing ? "saving" : "creating"): \(missing.joined(separator: ", "))."
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    questReadinessCard
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 6, trailing: 16))

                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Quest Title", text: $title)
                            .onChange(of: title) { _, _ in
                                if isValid {
                                    showValidationFeedback = false
                                }
                            }

                        if showValidationFeedback && !hasTitle {
                            Label("Give this quest a name so it can be created.", systemImage: "exclamationmark.triangle.fill")
                                .font(SystemTypography.captionSmall)
                                .foregroundStyle(SystemTheme.warningOrange)
                        }
                    }

                    TextField("Description (optional)", text: $description)
                } header: {
                    Text("Quest Details")
                }

                Section {
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(QuestDifficulty.allCases, id: \.self) { diff in
                            Label(diff.rawValue, systemImage: diff.icon)
                                .foregroundStyle(diff.color)
                                .tag(diff)
                        }
                    }
                    .pickerStyle(.menu)

                    VStack(spacing: 10) {
                        HStack {
                            let previewXP = GameFormulas.questXP(difficulty: difficulty)
                            let previewGold = isOptionalQuest ? 0 : GameFormulas.questGold(difficulty: difficulty)

                            Text("Rewards")
                                .font(SystemTypography.body)
                                .foregroundStyle(SystemTheme.textPrimary)
                            Spacer()
                            Label("+\(previewXP)", systemImage: "star.fill")
                                .font(SystemTypography.mono(16, weight: .semibold))
                                .foregroundStyle(SystemTheme.primaryBlue)
                            if previewGold > 0 {
                                Label("+\(previewGold)", systemImage: "dollarsign.circle.fill")
                                    .font(SystemTypography.mono(16, weight: .semibold))
                                    .foregroundStyle(SystemTheme.goldColor)
                            } else {
                                Text("XP only")
                                    .font(SystemTypography.caption)
                                    .foregroundStyle(SystemTheme.textTertiary)
                            }
                        }

                        Divider()
                    }

                    Toggle("Optional Quest (XP only)", isOn: $isOptionalQuest)
                } header: {
                    Text("Difficulty")
                } footer: {
                    Text("Optional quests never deal missed-quest HP damage. Completing them awards XP and stats, but no Gold.")
                }

                Section {
                    ForEach(StatType.allCases) { stat in
                        let isSelected = selectedStats.contains(stat)
                        Button {
                            toggleStat(stat)
                        } label: {
                            HStack {
                                Image(systemName: stat.icon)
                                    .foregroundStyle(stat.color)
                                    .frame(width: 24)
                                Text(stat.fullName)
                                    .foregroundStyle(SystemTheme.textPrimary)
                                Text(stat.rawValue)
                                    .font(SystemTypography.mono(12, weight: .semibold))
                                    .foregroundStyle(stat.color)
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(SystemTheme.primaryBlue)
                                }
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        isSelected
                                        ? stat.color.opacity(0.16)
                                        : SystemTheme.backgroundSecondary.opacity(0.45)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        isSelected
                                        ? stat.color.opacity(0.95)
                                        : SystemTheme.borderSecondary.opacity(0.45),
                                        lineWidth: isSelected ? 1.6 : 1
                                    )
                            )
                            .shadow(
                                color: isSelected ? stat.color.opacity(0.28) : .clear,
                                radius: isSelected ? 8 : 0,
                                x: 0,
                                y: 0
                            )
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                    }
                } header: {
                    HStack(spacing: 6) {
                        Text("Target Stats (Select 1-3)")
                        if showValidationFeedback && !hasStats {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(SystemTheme.warningOrange)
                        }
                    }
                } footer: {
                    if showValidationFeedback && !hasStats {
                        Text("Select at least one stat. This tells PRAXIS where to award XP when the quest is completed.")
                            .foregroundStyle(SystemTheme.warningOrange)
                    } else {
                        Text("Selected stats receive XP when this quest is completed.")
                    }
                }

                Section {
                    Picker("Tracking Method", selection: $trackingType) {
                        ForEach(QuestTrackingType.betaSelectableTypes, id: \.self) { type in
                            Text(trackingLabel(for: type)).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    trackingConfigurationSection
                } header: {
                    Text("Tracking")
                } footer: {
                    trackingFooter
                }

                Section {
                    if linkableBosses.isEmpty {
                        Text("No active bosses yet.")
                            .foregroundStyle(SystemTheme.textTertiary)

                        Button {
                            showCreateBossSheet = true
                        } label: {
                            Label("Create Boss", systemImage: "plus.circle.fill")
                                .foregroundStyle(SystemTheme.primaryBlue)
                        }
                    } else {
                        Picker("Linked Boss", selection: $selectedBossID) {
                            Text("None").tag(UUID?.none)
                            ForEach(linkableBosses) { boss in
                                Text(boss.title).tag(Optional(boss.id))
                            }
                        }
                        // navigationLink keeps the Form's scroll position
                        // stable instead of letting iOS' contextual menu
                        // popup yank the scroll up to anchor on the row.
                        .pickerStyle(.navigationLink)
                    }
                } header: {
                    Text("Boss Link")
                } footer: {
                    if let selectedBoss {
                        Text("Estimated impact: \(estimatedBossDamage) HP (~\(estimatedBossDamagePercentage)% of \(selectedBoss.title)'s max HP) each completion.")
                    } else {
                        Text("Completing this quest will damage the linked boss.")
                    }
                }

                Section {
                    Picker("Repeat", selection: $frequency) {
                        ForEach(QuestFrequency.allCases) { option in
                            Label(option.rawValue, systemImage: option.icon)
                                .tag(option)
                        }
                    }
                    .pickerStyle(.menu)

                    Toggle("Enable Reminder", isOn: $reminderEnabled)

                    if reminderEnabled {
                        DatePicker(
                            "Reminder Time",
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                    }
                } header: {
                    Text("Schedule")
                } footer: {
                    Text("Set how often the quest resets and optionally schedule a reminder.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(
                ZStack {
                    GW.bg
                    GWAurora()
                }
                .ignoresSafeArea()
            )
            .navigationTitle(mode.isEditing ? "Edit Quest" : "Create Quest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GW.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(GW.mute)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(mode.isEditing ? "Save" : "Create") {
                        Task { await saveQuest() }
                    }
                    .fontWeight(isValid ? .semibold : .regular)
                    .foregroundStyle(GW.cyan)
                    .disabled(isSaving)
                }
            }
            
            .sheet(isPresented: $showCreateBossSheet) {
                BossFormSheet()
            }
            .alert(mode.isEditing ? "Unable to Save Quest" : "Unable to Create Quest", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
            .sheet(item: $activeWheelInput) { input in
                BottomWheelValuePickerSheet(
                    title: input.title,
                    subtitle: input.subtitle,
                    accentColor: SystemTheme.primaryBlue,
                    options: wheelOptions(for: input),
                    selection: wheelBinding(for: input),
                    confirmTitle: "Apply"
                )
            }
            .sheet(isPresented: $showHealthTypePicker) {
                BottomHealthTypePickerSheet(
                    selection: $healthKitType,
                    accentColor: SystemTheme.primaryBlue
                )
            }
            .keyboardDismissToolbar()
            .onAppear(perform: loadExistingQuest)
            .onChange(of: trackingType) { _, newType in
                if newType == .location && targetValue < 5 {
                    targetValue = 45
                }
                if newType != .location {
                    locationValidationMessage = nil
                    locationValidationIsError = false
                    addressAutocomplete.clear()
                }
            }
            .onChange(of: locationRadiusMeters) { _, newValue in
                guard let existing = locationCoordinate else { return }
                locationCoordinate = LocationCoordinate(
                    latitude: existing.latitude,
                    longitude: existing.longitude,
                    radius: newValue,
                    locationName: existing.locationName
                )
            }
            .onChange(of: locationAddress) { _, _ in
                guard trackingType == .location else { return }
                locationCoordinate = nil
                locationValidationMessage = nil
                locationValidationIsError = false
                addressAutocomplete.updateQuery(locationAddress)
            }
        }
    }

    private var questReadinessCard: some View {
        let accentColor = isValid
            ? SystemTheme.successGreen
            : (showValidationFeedback ? SystemTheme.warningOrange : SystemTheme.primaryBlue)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.16))
                        .frame(width: 38, height: 38)
                    Image(systemName: isValid ? "checkmark.seal.fill" : "checklist")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(isValid ? "Quest ready" : "Quest requirements")
                        .font(SystemTypography.titleSmall)
                        .foregroundStyle(SystemTheme.textPrimary)
                    Text(validationSummaryText)
                        .font(SystemTypography.caption)
                        .foregroundStyle(showValidationFeedback && !isValid ? SystemTheme.warningOrange : SystemTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            VStack(spacing: 8) {
                requirementRow(
                    title: "Name",
                    detail: hasTitle ? title.trimmingCharacters(in: .whitespacesAndNewlines) : "Enter a quest title",
                    isComplete: hasTitle,
                    showWarning: showValidationFeedback
                )

                requirementRow(
                    title: "Stat",
                    detail: hasStats ? "\(selectedStats.count) selected" : "Choose at least one target stat",
                    isComplete: hasStats,
                    showWarning: showValidationFeedback
                )

                if trackingType == .location {
                    requirementRow(
                        title: "Address",
                        detail: hasLocationAddress ? "Address entered" : "Enter a location address",
                        isComplete: hasLocationAddress,
                        showWarning: showValidationFeedback
                    )

                    requirementRow(
                        title: "Validation",
                        detail: hasValidatedLocation ? "Apple Maps validated" : "Validate address before creating",
                        isComplete: hasValidatedLocation,
                        showWarning: showValidationFeedback
                    )
                }
            }

            if showValidationFeedback && !isValid {
                Text("Tip: the Create button will explain what is missing, but the quest can only be created after every required item above is checked.")
                    .font(SystemTypography.captionSmall)
                    .foregroundStyle(SystemTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(SystemTheme.backgroundSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(accentColor.opacity(showValidationFeedback || isValid ? 0.9 : 0.35), lineWidth: showValidationFeedback || isValid ? 1.5 : 1)
        )
        .shadow(
            color: accentColor.opacity(showValidationFeedback || isValid ? 0.18 : 0.08),
            radius: showValidationFeedback || isValid ? 12 : 6,
            x: 0,
            y: 4
        )
        .animation(.easeInOut(duration: SystemTheme.animationFast), value: isValid)
        .animation(.easeInOut(duration: SystemTheme.animationFast), value: showValidationFeedback)
    }

    private func requirementRow(title: String, detail: String, isComplete: Bool, showWarning: Bool) -> some View {
        let color = isComplete ? SystemTheme.successGreen : (showWarning ? SystemTheme.warningOrange : SystemTheme.textTertiary)

        return HStack(spacing: 10) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SystemTypography.mono(12, weight: .bold))
                    .foregroundStyle(SystemTheme.textPrimary)
                Text(detail)
                    .font(SystemTypography.captionSmall)
                    .foregroundStyle(color)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(color.opacity(isComplete || showWarning ? 0.1 : 0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var trackingConfigurationSection: some View {
        switch trackingType {
        case .manual:
            VStack(alignment: .leading, spacing: 8) {
                Text("Target Value")
                    .font(SystemTypography.caption)
                    .foregroundStyle(SystemTheme.textSecondary)

                HStack {
                    Button {
                        HapticManager.shared.selection()
                        activeWheelInput = .manualTarget
                    } label: {
                        wheelInputPill(label: "Count", value: "\(Int(targetValue))")
                    }
                    .buttonStyle(.plain)

                    TextField("Unit", text: $unit)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }
            }

        case .healthKit:
            HStack {
                Text("Health Data Type")
                    .foregroundStyle(SystemTheme.textSecondary)
                Spacer()
                Button {
                    HapticManager.shared.selection()
                    showHealthTypePicker = true
                } label: {
                    wheelInputPill(label: "Metric", value: healthKitType.displayName)
                }
                .buttonStyle(.plain)
            }

            HStack {
                Image(systemName: healthKitType.icon)
                    .foregroundStyle(SystemTheme.primaryBlue)
                    .frame(width: 22)
                Text("Source: Apple Health")
                    .font(SystemTypography.captionSmall)
                    .foregroundStyle(SystemTheme.textTertiary)
                Spacer()
            }

            HStack {
                Text("Target")
                    .foregroundStyle(SystemTheme.textSecondary)
                Spacer()
                Button {
                    HapticManager.shared.selection()
                    activeWheelInput = .healthTarget
                } label: {
                    wheelInputPill(label: healthKitType.unit, value: formattedTargetValue)
                }
                .buttonStyle(.plain)
                Text(healthKitType.unit)
                    .foregroundStyle(SystemTheme.textSecondary)
            }

        case .location:
            VStack(alignment: .leading, spacing: 4) {
                Text("Address")
                    .font(SystemTypography.caption)
                    .foregroundStyle(SystemTheme.textSecondary)

                TextField(
                    "e.g. 1 Infinite Loop, Cupertino",
                    text: $locationAddress,
                    axis: .vertical
                )
                .lineLimit(2...3)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
            }

            if addressAutocomplete.isSearching {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(SystemTheme.primaryBlue)
                    Text("Searching Apple Maps…")
                        .font(SystemTypography.captionSmall)
                        .foregroundStyle(SystemTheme.textSecondary)
                }
            }

            if !addressAutocomplete.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(addressAutocomplete.suggestions) { suggestion in
                        Button {
                            Task { await selectAddressSuggestion(suggestion) }
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(suggestion.primaryText)
                                    .font(SystemTypography.bodySmall)
                                    .foregroundStyle(SystemTheme.textPrimary)
                                if let secondary = suggestion.secondaryText, !secondary.isEmpty {
                                    Text(secondary)
                                        .font(SystemTypography.captionSmall)
                                        .foregroundStyle(SystemTheme.textTertiary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                        }
                        if suggestion.id != addressAutocomplete.suggestions.last?.id {
                            Divider()
                                .overlay(SystemTheme.borderPrimary)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .background(SystemTheme.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: SystemRadius.small))
            }

            Button {
                Task { await validateLocationAddress() }
            } label: {
                HStack {
                    if isValidatingAddress {
                        ProgressView()
                            .tint(SystemTheme.primaryBlue)
                    } else {
                        Image(systemName: "map.fill")
                            .foregroundStyle(SystemTheme.primaryBlue)
                    }
                    Text(isValidatingAddress ? "Validating with Apple Maps..." : "Validate Address (Apple Maps)")
                        .foregroundStyle(SystemTheme.textPrimary)
                    Spacer()
                }
            }
            .disabled(isValidatingAddress || locationAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            HStack {
                Text("Minimum stay")
                    .foregroundStyle(SystemTheme.textSecondary)
                Spacer()
                Button {
                    HapticManager.shared.selection()
                    activeWheelInput = .locationDuration
                } label: {
                    wheelInputPill(label: "Stay", value: "\(Int(targetValue)) min")
                }
                .buttonStyle(.plain)
            }

            HStack {
                Text("Tracking radius")
                    .foregroundStyle(SystemTheme.textSecondary)
                Spacer()
                Button {
                    HapticManager.shared.selection()
                    activeWheelInput = .locationRadius
                } label: {
                    wheelInputPill(label: "Radius", value: radiusLabel)
                }
                .buttonStyle(.plain)
            }

            if let locationCoordinate {
                let previewPoint = QuestLocationPreviewPoint(
                    coordinate: CLLocationCoordinate2D(latitude: locationCoordinate.latitude, longitude: locationCoordinate.longitude),
                    title: locationCoordinate.locationName
                )
                let previewRegion = MKCoordinateRegion(
                    center: previewPoint.coordinate,
                    latitudinalMeters: max(400, locationRadiusMeters * 2.5),
                    longitudinalMeters: max(400, locationRadiusMeters * 2.5)
                )

                Map(initialPosition: .region(previewRegion)) {
                    Annotation("Target", coordinate: previewPoint.coordinate) {
                        VStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(SystemTheme.primaryBlue)
                            Text("Target")
                                .font(SystemTypography.captionSmall)
                                .foregroundStyle(SystemTheme.textSecondary)
                        }
                    }
                }
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: SystemRadius.small))
                .overlay(
                    RoundedRectangle(cornerRadius: SystemRadius.small)
                        .stroke(SystemTheme.borderSecondary, lineWidth: 1)
                )

                Button {
                    openValidatedLocationInMaps(locationCoordinate)
                } label: {
                    Label("Open in Maps", systemImage: "map")
                        .font(SystemTypography.caption)
                }
            }

            HStack(alignment: .top) {
                Image(systemName: "location.circle.fill")
                    .foregroundStyle(SystemTheme.statAgility)
                Text("Quest auto-completes after you stay within \(radiusLabel) for the minimum time.")
                    .font(SystemTypography.captionSmall)
                    .foregroundStyle(SystemTheme.textSecondary)
            }

            if let locationCoordinate {
                Text("Saved: \(locationCoordinate.locationName)")
                    .font(SystemTypography.captionSmall)
                    .foregroundStyle(SystemTheme.successGreen)

                Text("Tracking armed after save. The app confirms live status on the quest card.")
                    .font(SystemTypography.captionSmall)
                    .foregroundStyle(SystemTheme.textSecondary)
            }

            if let locationValidationMessage {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: locationValidationIsError ? "xmark.octagon.fill" : "checkmark.seal.fill")
                        .foregroundStyle(locationValidationIsError ? SystemTheme.criticalRed : SystemTheme.successGreen)
                    Text(locationValidationMessage)
                        .font(SystemTypography.captionSmall)
                        .foregroundStyle(locationValidationIsError ? SystemTheme.criticalRed : SystemTheme.successGreen)
                }
            }

        case .timer:
            EmptyView()
        }
    }

    @ViewBuilder
    private var trackingFooter: some View {
        switch trackingType {
        case .manual:
            Text("You manually mark this quest complete.")
        case .healthKit:
            if healthKitType == .workoutCount {
                Text("Auto-completes when Apple Health records workouts from Fitness/Activity, Apple Watch, or synced apps like Strava/Peloton.")
            } else {
                Text("Progress auto-tracked with Apple Health (including data synced from Fitness, Strava, Peloton, and more).")
            }
        case .location:
            Text("Validate with Apple Maps first. Quest auto-completes after staying within the configured radius (\(radiusLabel)) for the configured duration.")
        case .timer:
            EmptyView()
        }
    }

    private func toggleStat(_ stat: StatType) {
        if selectedStats.contains(stat) {
            selectedStats.remove(stat)
        } else if selectedStats.count < 3 {
            selectedStats.insert(stat)
        }

        if isValid {
            showValidationFeedback = false
        }
    }

    private func loadExistingQuest() {
        guard let quest = mode.existingQuest else { return }

        title = quest.title
        description = quest.description
        difficulty = quest.difficulty
        selectedStats = Set(quest.targetStats)
        trackingType = quest.trackingType
        frequency = quest.resolvedFrequency
        targetValue = quest.targetValue
        unit = quest.unit
        reminderEnabled = quest.reminderEnabled
        reminderTime = quest.reminderTime ?? reminderTime
        isOptionalQuest = quest.isOptional
        locationAddress = quest.locationAddress ?? ""
        locationCoordinate = quest.locationCoordinate
            ?? QuestDataManager.shared.cachedValidatedLocation(forQuestID: quest.id)
            ?? QuestDataManager.shared.cachedValidatedLocation(for: locationAddress)
        locationRadiusMeters = locationCoordinate?.radius ?? 804.67
        if let savedCoordinate = quest.locationCoordinate {
            locationValidationMessage = "Address validated: \(savedCoordinate.locationName)"
            locationValidationIsError = false
        } else if let restoredCoordinate = locationCoordinate {
            locationValidationMessage = "Using saved validated address: \(restoredCoordinate.locationName)"
            locationValidationIsError = false
        }

        if quest.trackingType == .location, quest.unit == "visits", quest.targetValue <= 1 {
            targetValue = 45
        }

        if let explicitBossID = quest.linkedBossID {
            selectedBossID = explicitBossID
        } else {
            selectedBossID = gameEngine.activeBossFights.first(where: { $0.linkedQuestIDs.contains(quest.id) })?.id
        }

        if let hkIdentifier = quest.healthKitIdentifier {
            healthKitType = HealthKitQuestType.allCases.first { $0.identifier == hkIdentifier } ?? .steps
        }
    }

    private func saveQuest() async {
        guard isValid else {
            presentValidationFeedback()
            return
        }
        isSaving = true
        defer { isSaving = false }

        let existingQuest = mode.existingQuest
        let questID = existingQuest?.id ?? UUID()
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = locationAddress.trimmingCharacters(in: .whitespacesAndNewlines)

        let resolvedCoordinate: LocationCoordinate?
        if trackingType == .location {
            if trimmedAddress.isEmpty {
                errorMessage = "Please enter an address for location tracking."
                return
            }

            let baseCoordinate: LocationCoordinate?
            if existingQuest?.locationAddress == trimmedAddress, let existingCoordinate = existingQuest?.locationCoordinate {
                baseCoordinate = existingCoordinate
            } else if let validatedCoordinate = locationCoordinate {
                baseCoordinate = validatedCoordinate
            } else if let cachedCoordinate = QuestDataManager.shared.cachedValidatedLocation(for: trimmedAddress) {
                baseCoordinate = cachedCoordinate
            } else if let resolved = await resolveAddressWithAppleMaps(trimmedAddress) {
                baseCoordinate = resolved
            } else {
                errorMessage = "Could not validate that address with Apple Maps. Try a fuller street + city + state address."
                return
            }

            guard let baseCoordinate else {
                errorMessage = "Could not resolve that address."
                return
            }

            resolvedCoordinate = LocationCoordinate(
                latitude: baseCoordinate.latitude,
                longitude: baseCoordinate.longitude,
                radius: locationRadiusMeters,
                locationName: baseCoordinate.locationName
            )
            if let resolvedCoordinate {
                QuestDataManager.shared.cacheValidatedLocation(
                    resolvedCoordinate,
                    forQuestID: existingQuest?.id ?? questID,
                    address: trimmedAddress
                )
            }
        } else {
            resolvedCoordinate = nil
        }

        let now = Date()
        let resolvedTrackingType = trackingType
        let previousFrequency = existingQuest?.resolvedFrequency
        let expiresAt: Date
        if let existingQuest, previousFrequency == frequency {
            expiresAt = existingQuest.expiresAt
        } else {
            expiresAt = frequency.nextResetDate(from: now)
        }

        let newQuest = DailyQuest(
            id: questID,
            title: trimmedTitle,
            description: trimmedDescription.isEmpty ? defaultDescription(for: resolvedTrackingType, address: trimmedAddress) : trimmedDescription,
            difficulty: difficulty,
            status: existingQuest?.status ?? .available,
            targetStats: Array(selectedStats),
            frequency: frequency,
            isOptional: isOptionalQuest,
            trackingType: resolvedTrackingType,
            currentProgress: existingQuest?.currentProgress ?? 0,
            targetValue: max(1, targetValue),
            unit: effectiveUnit,
            createdAt: existingQuest?.createdAt ?? now,
            expiresAt: expiresAt,
            healthKitIdentifier: resolvedTrackingType == .healthKit ? healthKitType.identifier : nil,
            locationCoordinate: resolvedCoordinate,
            locationAddress: resolvedTrackingType == .location ? trimmedAddress : nil,
            linkedBossID: selectedBossID,
            reminderEnabled: reminderEnabled,
            reminderTime: reminderEnabled ? reminderTime : nil
        )

        gameEngine.saveQuest(newQuest, replacing: existingQuest?.id)
        dismiss()
    }

    private func presentValidationFeedback() {
        showValidationFeedback = true
        HapticManager.shared.warning()
        errorMessage = validationSummaryText
    }

    private func validateLocationAddress() async {
        let trimmed = locationAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            locationCoordinate = nil
            locationValidationMessage = "Enter an address before validating."
            locationValidationIsError = true
            return
        }

        isValidatingAddress = true
        defer { isValidatingAddress = false }

        if let resolved = await resolveAddressWithAppleMaps(trimmed) {
            locationCoordinate = LocationCoordinate(
                latitude: resolved.latitude,
                longitude: resolved.longitude,
                radius: locationRadiusMeters,
                locationName: resolved.locationName
            )
            // Lock text to a canonical address string so repeated edits/reopens
            // do not jitter between equivalent Apple Maps labels.
            locationAddress = resolved.locationName
            locationValidationMessage = "Validated: \(resolved.locationName)"
            locationValidationIsError = false
            addressAutocomplete.clear()
            if let coordinate = locationCoordinate {
                QuestDataManager.shared.cacheValidatedLocation(
                    coordinate,
                    forQuestID: mode.existingQuest?.id,
                    address: resolved.locationName
                )
            }
        } else {
            locationCoordinate = nil
            locationValidationMessage = "Address not found. Try a complete address (street, city, state)."
            locationValidationIsError = true
        }
    }

    private func selectAddressSuggestion(_ suggestion: AddressSuggestion) async {
        locationAddress = suggestion.fullText
        await validateLocationAddress()
    }

    private func resolveAddressWithAppleMaps(_ address: String) async -> LocationCoordinate? {
        if let mapResult = await searchAddressWithMapKit(address) {
            return mapResult
        }
        // Fallback to geocoder for compatibility on sparse map results.
        return await geocodeAddress(address)
    }

    private func searchAddressWithMapKit(_ address: String) async -> LocationCoordinate? {
        await withCheckedContinuation { continuation in
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = address
            request.resultTypes = .address

            let search = MKLocalSearch(request: request)
            search.start { response, _ in
                guard let item = response?.mapItems.first else {
                    continuation.resume(returning: nil)
                    return
                }

                let coordinate = item.placemark.coordinate
                guard CLLocationCoordinate2DIsValid(coordinate) else {
                    continuation.resume(returning: nil)
                    return
                }

                let stableCoordinate = stabilizedCoordinate(coordinate)
                let resolvedName = normalizedAddressName(from: item.placemark, fallback: address)

                continuation.resume(returning: LocationCoordinate(
                    latitude: stableCoordinate.latitude,
                    longitude: stableCoordinate.longitude,
                    radius: 804.67, // ~0.5 miles
                    locationName: resolvedName
                ))
            }
        }
    }

    private func geocodeAddress(_ address: String) async -> LocationCoordinate? {
        await withCheckedContinuation { continuation in
            CLGeocoder().geocodeAddressString(address) { placemarks, _ in
                guard let placemark = placemarks?.first,
                      let coordinate = placemark.location?.coordinate else {
                    continuation.resume(returning: nil)
                    return
                }

                let stableCoordinate = stabilizedCoordinate(coordinate)
                let resolvedName = normalizedAddressName(from: placemark, fallback: address)

                continuation.resume(returning: LocationCoordinate(
                    latitude: stableCoordinate.latitude,
                    longitude: stableCoordinate.longitude,
                    radius: 804.67, // ~0.5 miles
                    locationName: resolvedName.isEmpty ? address : resolvedName
                ))
            }
        }
    }

    private func defaultDescription(for trackingType: QuestTrackingType, address: String) -> String {
        switch trackingType {
        case .manual: return "Complete this task to grow stronger."
        case .healthKit: return "Tracked via Apple Health."
        case .location:
            let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
            let minimumMinutes = Int(max(5, targetValue))
            return trimmedAddress.isEmpty
                ? "Stay near this location for \(minimumMinutes) minutes to complete."
                : "Auto-completes when you stay near \(trimmedAddress) for \(minimumMinutes) minutes."
        case .timer: return "Complete a focused session."
        }
    }

    private var effectiveUnit: String {
        switch trackingType {
        case .healthKit:
            return healthKitType.unit
        case .location:
            return "minutes"
        default:
            return unit
        }
    }

    private func trackingLabel(for type: QuestTrackingType) -> String {
        switch type {
        case .manual: return "Manual"
        case .healthKit: return "Health"
        case .location: return "Location"
        case .timer: return "Timer"
        }
    }

    private var radiusLabel: String {
        let miles = locationRadiusMeters / 1609.34
        return String(format: "%.2f mi (%.0f m)", miles, locationRadiusMeters)
    }

    private var formattedTargetValue: String {
        if targetValue.rounded() == targetValue {
            return "\(Int(targetValue))"
        }
        return String(format: "%.1f", targetValue)
    }

    private func wheelOptions(for input: QuestWheelInput) -> [WheelValueOption] {
        switch input {
        case .manualTarget:
            return Array(1...100).map { WheelValueOption(value: Double($0), label: "\($0)") }
        case .healthTarget:
            return healthTargetOptions
        case .locationDuration:
            return Array(stride(from: 5, through: 240, by: 5)).map { WheelValueOption(value: Double($0), label: "\($0) min") }
        case .locationRadius:
            return Array(stride(from: 100, through: 1600, by: 50)).map { value in
                let miles = Double(value) / 1609.34
                return WheelValueOption(value: Double(value), label: String(format: "%.2f mi • %dm", miles, value))
            }
        }
    }

    private var healthTargetOptions: [WheelValueOption] {
        switch healthKitType {
        case .steps:
            return Array(stride(from: 1000, through: 30000, by: 500)).map { WheelValueOption(value: Double($0), label: "\($0)") }
        case .distance, .sleep:
            return Array(stride(from: 1, through: 20, by: 1)).map { WheelValueOption(value: Double($0), label: "\($0)") }
        case .activeEnergy:
            return Array(stride(from: 50, through: 2000, by: 50)).map { WheelValueOption(value: Double($0), label: "\($0)") }
        case .exerciseMinutes, .mindfulness:
            return Array(stride(from: 5, through: 240, by: 5)).map { WheelValueOption(value: Double($0), label: "\($0)") }
        case .workoutCount:
            return Array(1...14).map { WheelValueOption(value: Double($0), label: "\($0)") }
        case .standHours:
            return Array(1...24).map { WheelValueOption(value: Double($0), label: "\($0)") }
        case .water:
            return Array(stride(from: 1, through: 20, by: 1)).map { WheelValueOption(value: Double($0), label: "\($0)") }
        }
    }

    private func wheelBinding(for input: QuestWheelInput) -> Binding<Double> {
        switch input {
        case .manualTarget, .healthTarget, .locationDuration:
            return $targetValue
        case .locationRadius:
            return $locationRadiusMeters
        }
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
                .foregroundStyle(SystemTheme.primaryBlue)
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

    private func openValidatedLocationInMaps(_ coordinate: LocationCoordinate) {
        let placemark = MKPlacemark(
            coordinate: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
        )
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = coordinate.locationName
        mapItem.openInMaps()
    }

    private func stabilizedCoordinate(_ coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: roundedCoordinate(coordinate.latitude),
            longitude: roundedCoordinate(coordinate.longitude)
        )
    }

    private func roundedCoordinate(_ value: Double, decimals: Int = 5) -> Double {
        let scale = pow(10.0, Double(decimals))
        return (value * scale).rounded() / scale
    }

    private func normalizedAddressName(from placemark: CLPlacemark, fallback: String) -> String {
        let line1 = [placemark.subThoroughfare, placemark.thoroughfare]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let line2 = [placemark.locality, placemark.administrativeArea, placemark.postalCode]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        let full = [line1, line2]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        if !full.isEmpty {
            return full
        }

        if let title = placemark.name?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
            return title
        }

        return fallback
    }
}

private enum QuestWheelInput: String, Identifiable {
    case manualTarget
    case healthTarget
    case locationDuration
    case locationRadius

    var id: String { rawValue }

    var title: String {
        switch self {
        case .manualTarget: return "Quest Target"
        case .healthTarget: return "Health Target"
        case .locationDuration: return "Minimum Stay"
        case .locationRadius: return "Tracking Radius"
        }
    }

    var subtitle: String {
        switch self {
        case .manualTarget: return "Choose how many actions define success for this quest."
        case .healthTarget: return "Set the amount needed for this auto-tracked target."
        case .locationDuration: return "Set how long the user must stay at the location."
        case .locationRadius: return "Choose how tight the location tracking zone should be."
        }
    }
}

private struct QuestLocationPreviewPoint: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
}

private struct AddressSuggestion: Identifiable, Equatable {
    let id: String
    let primaryText: String
    let secondaryText: String?

    var fullText: String {
        let secondary = secondaryText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if secondary.isEmpty {
            return primaryText
        }
        return "\(primaryText), \(secondary)"
    }
}

private struct BottomHealthTypePickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selection: HealthKitQuestType
    let accentColor: Color

    @State private var draftSelection: HealthKitQuestType = .steps

    var body: some View {
        ZStack {
            SystemTheme.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 22)
                    .padding(.top, 12)
                    .padding(.bottom, 10)

                pickerBar
            }
            .padding(.bottom, 8)
        }
        .presentationDetents([.fraction(0.5)])
        .presentationDragIndicator(.visible)
        .onAppear {
            draftSelection = selection
        }
        .onChange(of: draftSelection) { _, _ in
            HapticManager.shared.selection()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Health Parameter")
                .font(SystemTypography.titleSmall)
                .foregroundStyle(SystemTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .allowsTightening(true)

            Rectangle()
                .fill(accentColor)
                .frame(width: 42, height: 4)
                .clipShape(Capsule())

            Text("Choose which Apple Health metric completes this quest.")
                .font(SystemTypography.caption)
                .foregroundStyle(SystemTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
                .allowsTightening(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var pickerBar: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(SystemTheme.textTertiary.opacity(0.45))
                .frame(width: 54, height: 5)
                .padding(.top, 2)
                .padding(.bottom, 12)

            HStack {
                Button {
                    HapticManager.shared.selection()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(accentColor)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                Text("Apply")
                    .font(SystemTypography.body)
                    .foregroundStyle(SystemTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .allowsTightening(true)

                Spacer()

                Button {
                    selection = draftSelection
                    HapticManager.shared.success()
                    dismiss()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(accentColor)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 6)

            Picker("Health Parameter", selection: $draftSelection) {
                ForEach(HealthKitQuestType.allCases, id: \.self) { type in
                    Text(type.displayName)
                        .tag(type)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 196)
            .clipped()
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(SystemTheme.backgroundElevated)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

@MainActor
private final class AddressAutocompleteProvider: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published private(set) var suggestions: [AddressSuggestion] = []
    @Published private(set) var isSearching = false

    private let completer = MKLocalSearchCompleter()
    private var lastQuery = ""

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    func updateQuery(_ rawQuery: String) {
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query != lastQuery else { return }
        lastQuery = query

        if query.count < 3 {
            clear()
            return
        }

        isSearching = true
        completer.queryFragment = query
    }

    func clear() {
        isSearching = false
        suggestions = []
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        isSearching = false
        suggestions = completer.results.prefix(5).map { result in
            let title = result.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let subtitle = result.subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
            return AddressSuggestion(
                id: "\(title)|\(subtitle)",
                primaryText: title.isEmpty ? "Unknown place" : title,
                secondaryText: subtitle.isEmpty ? nil : subtitle
            )
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        isSearching = false
        suggestions = []
        #if DEBUG
        print("[SYSTEM] Apple Maps autocomplete failed: \(error.localizedDescription)")
        #endif
    }
}

// MARK: - HealthKit Quest Types

enum HealthKitQuestType: String, CaseIterable {
    case steps = "steps"
    case distance = "distance"
    case activeEnergy = "activeEnergy"
    case exerciseMinutes = "exerciseMinutes"
    case workoutCount = "workoutCount"
    case standHours = "standHours"
    case sleep = "sleep"
    case water = "water"
    case mindfulness = "mindfulness"

    var displayName: String {
        switch self {
        case .steps: return "Steps"
        case .distance: return "Distance Walked"
        case .activeEnergy: return "Active Calories"
        case .exerciseMinutes: return "Exercise Minutes"
        case .workoutCount: return "Workouts (Activity/Fitness)"
        case .standHours: return "Stand Hours"
        case .sleep: return "Sleep"
        case .water: return "Water Intake"
        case .mindfulness: return "Mindful Minutes"
        }
    }

    var icon: String {
        switch self {
        case .steps: return "figure.walk"
        case .distance: return "figure.walk.motion"
        case .activeEnergy: return "flame.fill"
        case .exerciseMinutes: return "timer"
        case .workoutCount: return "figure.run"
        case .standHours: return "figure.stand"
        case .sleep: return "bed.double.fill"
        case .water: return "drop.fill"
        case .mindfulness: return "brain.head.profile"
        }
    }

    var unit: String {
        switch self {
        case .steps: return "steps"
        case .distance: return "km"
        case .activeEnergy: return "kcal"
        case .exerciseMinutes: return "minutes"
        case .workoutCount: return "workouts"
        case .standHours: return "hours"
        case .sleep: return "hours"
        case .water: return "glasses"
        case .mindfulness: return "minutes"
        }
    }

    var identifier: String {
        switch self {
        case .steps: return "HKQuantityTypeIdentifierStepCount"
        case .distance: return "HKQuantityTypeIdentifierDistanceWalkingRunning"
        case .activeEnergy: return "HKQuantityTypeIdentifierActiveEnergyBurned"
        case .exerciseMinutes: return "HKQuantityTypeIdentifierAppleExerciseTime"
        case .workoutCount: return "HKWorkoutType"
        case .standHours: return "HKCategoryTypeIdentifierAppleStandHour"
        case .sleep: return "HKCategoryTypeIdentifierSleepAnalysis"
        case .water: return "HKQuantityTypeIdentifierDietaryWater"
        case .mindfulness: return "HKCategoryTypeIdentifierMindfulSession"
        }
    }
}

#Preview {
    QuestFormSheet(mode: .add)
        .environmentObject(GameEngine.shared)
}
