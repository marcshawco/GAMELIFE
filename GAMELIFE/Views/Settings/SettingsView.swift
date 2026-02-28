//
//  SettingsView.swift
//  GAMELIFE
//
//  [SYSTEM]: Configuration interface accessed.
//  Customize your System experience.
//

import SwiftUI
import Combine
import UIKit

// MARK: - Settings View

/// Settings page accessed via gear icon on Status tab
struct SettingsView: View {

    // MARK: - Properties

    @EnvironmentObject var gameEngine: GameEngine
    @AppStorage("defaultTab") private var defaultTab: Int = 0
    @AppStorage("useSystemAppearance") private var useSystemAppearance = true
    @AppStorage("preferDarkMode") private var preferDarkMode = true
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @AppStorage("questCompletionNotificationMode") private var questCompletionNotificationMode = NotificationManager.QuestCompletionNotificationMode.immediate.rawValue
    @AppStorage("deathMechanicEnabled") private var deathMechanicEnabled = true
    @StateObject private var appIconManager = AppIconManager.shared
    @State private var showResetConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var showDeathMechanicInfo = false

    // MARK: - Body

    var body: some View {
        List {
            // Player Section
            Section {
                NavigationLink {
                    PlayerProfileView()
                } label: {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(gameEngine.player.rank.glowColor.opacity(0.2))
                                .frame(width: 44, height: 44)

                            Text(gameEngine.player.rank.rawValue)
                                .font(SystemTypography.mono(14, weight: .bold))
                                .foregroundStyle(gameEngine.player.rank.glowColor)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(gameEngine.player.name)
                                .font(SystemTypography.headline)
                                .foregroundStyle(SystemTheme.textPrimary)

                            Text("Lv. \(gameEngine.player.level) \(gameEngine.player.title)")
                                .font(SystemTypography.caption)
                                .foregroundStyle(SystemTheme.textSecondary)
                        }

                        Spacer()
                    }
                }
            } header: {
                Text("Hunter Profile")
            }

            // Preferences Section
            Section {
                Picker("Default Tab", selection: $defaultTab) {
                    Text("Status").tag(0)
                    Text("Quests").tag(1)
                    Text("Training").tag(2)
                    Text("Bosses").tag(3)
                    Text("Shop").tag(4)
                }

                Toggle("Use System Appearance", isOn: $useSystemAppearance)

                if !useSystemAppearance {
                    Toggle("Dark Mode", isOn: $preferDarkMode)
                }

                Toggle("Haptic Feedback", isOn: $hapticEnabled)
                    .onChange(of: hapticEnabled) { _, isEnabled in
                        if isEnabled {
                            HapticManager.shared.selection()
                        }
                    }

                Picker("Quest Completion Alerts", selection: $questCompletionNotificationMode) {
                    ForEach(NotificationManager.QuestCompletionNotificationMode.allCases) { mode in
                        Text(mode.displayName).tag(mode.rawValue)
                    }
                }
                .onChange(of: questCompletionNotificationMode) { _, rawValue in
                    let mode = NotificationManager.QuestCompletionNotificationMode(rawValue: rawValue) ?? .immediate
                    NotificationManager.shared.questCompletionNotificationMode = mode
                }

                NavigationLink {
                    AppIconPickerView()
                } label: {
                    HStack {
                        Label("App Icon", systemImage: "app.badge")
                            .foregroundStyle(SystemTheme.textPrimary)
                        Spacer()
                        Text(appIconManager.currentOption.displayName)
                            .foregroundStyle(SystemTheme.textSecondary)
                    }
                }

                HStack(spacing: 8) {
                    Toggle("Death Mechanic Penalties", isOn: $deathMechanicEnabled)

                    Button {
                        showDeathMechanicInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(SystemTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Death mechanic info")
                }
            } header: {
                Text("Preferences")
            } footer: {
                Text("Set your default tab, appearance, app icon, alerts, and death penalties in one place. Turning off death penalties does not stop HP loss.")
            }

            // Neural Links Section
            Section {
                NavigationLink {
                    PermissionManagerView()
                } label: {
                    HStack {
                        Label("Neural Links", systemImage: "brain.head.profile")
                            .foregroundStyle(SystemTheme.textPrimary)

                        Spacer()

                        // Connection status indicator
                        ConnectionStatusBadge()
                    }
                }
            } header: {
                Text("Data Connections")
            } footer: {
                Text("Connect PRAXIS to health and location data")
            }

            // Statistics Section
            Section {
                StatRow(label: "Quests Completed", value: "\(gameEngine.player.completedQuestCount)")
                StatRow(label: "Bosses Defeated", value: "\(gameEngine.player.defeatedBossCount)")
                StatRow(label: "Training Sessions", value: "\(gameEngine.player.dungeonsClearedCount)")
                StatRow(label: "Current Streak", value: "\(gameEngine.player.currentStreak) days")
                StatRow(label: "Longest Streak", value: "\(gameEngine.player.longestStreak) days")
                StatRow(label: "Total XP Earned", value: "\(gameEngine.player.totalXP)")
                StatRow(label: "Achievements", value: "\(gameEngine.player.unlockedAchievements.count)")
            } header: {
                Text("Statistics")
            }

            // Danger Zone Section
            Section {
                Button {
                    showResetConfirmation = true
                } label: {
                    Label("Reset Quest Progress", systemImage: "arrow.counterclockwise")
                        .foregroundStyle(SystemTheme.warningOrange)
                }

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete All Data", systemImage: "trash.fill")
                }
            } header: {
                Text("Danger Zone")
            } footer: {
                Text("These actions cannot be undone")
            }

            // About Section
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(SystemTheme.textSecondary)
                }

                if let aboutURL = URL(string: "https://gamelife.app") {
                    Link(destination: aboutURL) {
                        Label("About PRAXIS", systemImage: "info.circle")
                    }
                }

                if let privacyURL = URL(string: "https://gamelife.app/privacy") {
                    Link(destination: privacyURL) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                }
            } header: {
                Text("About")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Reset Quest Progress?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                resetDailyQuests()
            }
        } message: {
            Text("This will reset progress on your current quests for the active cycle.")
        }
        .alert("Delete All Data?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Everything", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("This will permanently delete your player profile, all quests, bosses, and progress. This action cannot be undone.")
        }
        .alert("Death Mechanic Penalties", isPresented: $showDeathMechanicInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(
                """
                When HP reaches 0:
                • If enabled: rank may drop by 1 tier, stats are reduced based on your current rank, 20% Gold is lost, HP resets to full, and a death summary appears.
                • If disabled: HP still drops to 0 from missed required quests, but no rank/stat/gold penalties are applied; HP resets to full.
                """
            )
        }
    }

    // MARK: - Actions

    private func resetDailyQuests() {
        gameEngine.resetQuestProgressManually()

        SystemMessageHelper.showInfo("Quests Reset", "Quest progress has been reset for the current cycle.")
    }

    private func deleteAllData() {
        // Clear persisted app domain and reset in-memory state.
        SettingsManager.shared.resetAllSettings()

        gameEngine.startFreshProfile(named: "Hunter")

        MarketplaceManager.shared.resetForFreshStart()
        NotificationManager.shared.clearAllQuestReminders()
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")

        SystemMessageHelper.show(SystemMessage(
            type: .critical,
            title: "Data Deleted",
            message: "All data has been erased and reset."
        ))
    }
}

// MARK: - Connection Status Badge

struct ConnectionStatusBadge: View {
    @StateObject private var permissionManager = PermissionManager.shared

    private var connectedCount: Int {
        var count = 0
        if permissionManager.healthKitEnabled { count += 1 }
        if AppFeatureFlags.screenTimeEnabled && permissionManager.screenTimeEnabled { count += 1 }
        if permissionManager.locationEnabled { count += 1 }
        if permissionManager.notificationsEnabled { count += 1 }
        return count
    }

    private var totalCount: Int {
        NeuralLinkType.betaAvailableCases.count
    }

    var body: some View {
        Text("\(connectedCount)/\(totalCount)")
            .font(SystemTypography.mono(12, weight: .semibold))
            .foregroundStyle(connectedCount == totalCount ? SystemTheme.successGreen : SystemTheme.textTertiary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                (connectedCount == totalCount ? SystemTheme.successGreen : SystemTheme.textTertiary).opacity(0.1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .onAppear {
                Task {
                    await permissionManager.checkAllPermissions()
                }
            }
    }
}

// MARK: - Stat Row

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(SystemTheme.textSecondary)
            Spacer()
            Text(value)
                .font(SystemTypography.mono(14, weight: .semibold))
                .foregroundStyle(SystemTheme.textPrimary)
        }
    }
}

// MARK: - App Icon Support

enum AppIconOption: String, CaseIterable, Identifiable {
    case systemDefault
    case phoenixDark
    case phoenixIvory
    case phoenixWhite

    var id: String { rawValue }

    var iconName: String? {
        switch self {
        case .systemDefault: return nil
        case .phoenixDark: return "AppIconPhoenixDarkV2"
        case .phoenixIvory: return "AppIconPhoenixIvoryV2"
        case .phoenixWhite: return "AppIconPhoenixWhiteV2"
        }
    }

    var displayName: String {
        switch self {
        case .systemDefault: return "Default (Black)"
        case .phoenixDark: return "Phoenix (Navy)"
        case .phoenixIvory: return "Phoenix (Ivory)"
        case .phoenixWhite: return "Phoenix (White)"
        }
    }

    var previewAssetName: String {
        switch self {
        case .systemDefault: return "AppIconPreviewDefault"
        case .phoenixDark: return "AppIconPreviewDark"
        case .phoenixIvory: return "AppIconPreviewIvory"
        case .phoenixWhite: return "AppIconPreviewWhite"
        }
    }

    init?(iconName: String?) {
        switch iconName {
        case nil: self = .systemDefault
        case "AppIconPhoenixDark", "AppIconPhoenixDarkV2": self = .phoenixDark
        case "AppIconPhoenixIvory", "AppIconPhoenixIvoryV2": self = .phoenixIvory
        case "AppIconPhoenixWhite", "AppIconPhoenixWhiteV2": self = .phoenixWhite
        default: return nil
        }
    }
}

@MainActor
final class AppIconManager: ObservableObject {
    static let shared = AppIconManager()

    @Published private(set) var currentOption: AppIconOption = .systemDefault
    @Published private(set) var isSupported: Bool = UIApplication.shared.supportsAlternateIcons
    @Published private(set) var hasLegacyIconOverride = false
    @Published private(set) var hasPendingIconChange = false
    @Published private(set) var pendingIconDisplayName: String?
    private let requestedIconKey = "requestedIconName"
    private var cancellables = Set<AnyCancellable>()

    private init() {
        normalizeLegacyIconIfNeeded()
        refreshCurrentIcon()
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.reconcileRequestedIconIfNeeded()
            }
            .store(in: &cancellables)
    }

    func refreshCurrentIcon() {
        isSupported = UIApplication.shared.supportsAlternateIcons
        guard isSupported else {
            currentOption = .systemDefault
            hasLegacyIconOverride = false
            return
        }
        let currentName = UIApplication.shared.alternateIconName
        currentOption = AppIconOption(iconName: currentName) ?? .systemDefault
        hasLegacyIconOverride = (currentName != nil && AppIconOption(iconName: currentName) == nil)
        reconcilePendingState(currentName: currentName)
    }

    func setIcon(_ option: AppIconOption) {
        guard isSupported else {
            SystemMessageHelper.showWarning("Alternate app icons are not supported on this device.")
            return
        }
        normalizeLegacyIconIfNeeded()

        let targetIconName = option.iconName
        let currentIconName = UIApplication.shared.alternateIconName
        guard currentIconName != targetIconName else { return }
        UserDefaults.standard.set(targetIconName, forKey: requestedIconKey)
        hasPendingIconChange = true
        pendingIconDisplayName = option.displayName

        let applyRequestedIcon: () -> Void = { [weak self] in
            UIApplication.shared.setAlternateIconName(targetIconName) { error in
                if let error {
                    SystemMessageHelper.showWarning("Could not change app icon: \(error.localizedDescription)")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self?.refreshCurrentIcon()
                    self?.reconcileRequestedIconIfNeeded()
                }
            }
        }

        // iOS can occasionally ignore direct alternate->alternate changes.
        // Force a reset to primary first, then apply the requested icon.
        if currentIconName != nil, targetIconName != nil {
            UIApplication.shared.setAlternateIconName(nil) { [weak self] resetError in
                if let resetError {
                    SystemMessageHelper.showWarning("Could not reset icon state: \(resetError.localizedDescription)")
                    DispatchQueue.main.async {
                        self?.refreshCurrentIcon()
                    }
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    applyRequestedIcon()
                }
            }
            return
        }

        applyRequestedIcon()
    }

    private func normalizeLegacyIconIfNeeded() {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        guard let currentName = UIApplication.shared.alternateIconName else { return }
        guard AppIconOption(iconName: currentName) == nil else { return }

        UIApplication.shared.setAlternateIconName(nil) { [weak self] error in
            if let error {
                SystemMessageHelper.showWarning("Legacy icon reset failed: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                self?.refreshCurrentIcon()
            }
        }
    }

    private func reconcilePendingState(currentName: String?) {
        guard let requestedName = UserDefaults.standard.object(forKey: requestedIconKey) as? String? else {
            hasPendingIconChange = false
            pendingIconDisplayName = nil
            return
        }

        if currentName == requestedName {
            UserDefaults.standard.removeObject(forKey: requestedIconKey)
            hasPendingIconChange = false
            pendingIconDisplayName = nil
        } else {
            hasPendingIconChange = true
            pendingIconDisplayName = AppIconOption(iconName: requestedName)?.displayName
        }
    }

    private func reconcileRequestedIconIfNeeded() {
        guard isSupported else { return }
        let currentName = UIApplication.shared.alternateIconName
        guard let requestedName = UserDefaults.standard.object(forKey: requestedIconKey) as? String? else {
            hasPendingIconChange = false
            pendingIconDisplayName = nil
            return
        }

        if currentName == requestedName {
            UserDefaults.standard.removeObject(forKey: requestedIconKey)
            hasPendingIconChange = false
            pendingIconDisplayName = nil
            return
        }

        UIApplication.shared.setAlternateIconName(requestedName) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self?.refreshCurrentIcon()
            }
        }
    }
}

struct AppIconPickerView: View {
    @StateObject private var appIconManager = AppIconManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(AppIconOption.allCases) { option in
                    let isSelected = appIconManager.currentOption == option

                    Button {
                        appIconManager.setIcon(option)
                    } label: {
                        HStack(spacing: 14) {
                            Image(option.previewAssetName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 54, height: 54)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(SystemTheme.textTertiary.opacity(0.25), lineWidth: 1)
                                )

                            Text(option.displayName)
                                .font(SystemTypography.body)
                                .foregroundStyle(SystemTheme.textPrimary)

                            Spacer(minLength: 0)

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(SystemTheme.primaryBlue)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(SystemTheme.backgroundTertiary)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(
                                    isSelected
                                        ? SystemTheme.primaryBlue.opacity(0.5)
                                        : SystemTheme.textTertiary.opacity(0.15),
                                    lineWidth: isSelected ? 1.5 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .disabled(!appIconManager.isSupported)
                }

                Text(
                    appIconManager.isSupported
                        ? "Changes apply immediately on your home screen."
                        : "Alternate app icons are not supported on this device."
                )
                .font(SystemTypography.caption)
                .foregroundStyle(SystemTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)

                if appIconManager.hasPendingIconChange {
                    Text("Pending icon sync: \(appIconManager.pendingIconDisplayName ?? "Selected icon"). iOS may apply this after returning to the home screen.")
                        .font(SystemTypography.captionSmall)
                        .foregroundStyle(SystemTheme.warningOrange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(SystemTheme.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            appIconManager.refreshCurrentIcon()
        }
    }
}

// MARK: - Player Profile View

struct PlayerProfileView: View {
    @EnvironmentObject var gameEngine: GameEngine
    @State private var editedName: String = ""
    @State private var editedTitle: String = ""
    @State private var isEditing = false

    var body: some View {
        List {
            Section {
                if isEditing {
                    TextField("Hunter Name", text: $editedName)
                        .font(SystemTypography.body)
                } else {
                    HStack {
                        Text("Name")
                            .foregroundStyle(SystemTheme.textSecondary)
                        Spacer()
                        Text(gameEngine.player.name)
                            .font(SystemTypography.headline)
                    }
                }

                HStack {
                    Text("Rank")
                        .foregroundStyle(SystemTheme.textSecondary)
                    Spacer()
                    Text(gameEngine.player.rank.rawValue)
                        .font(SystemTypography.mono(14, weight: .bold))
                        .foregroundStyle(gameEngine.player.rank.glowColor)
                }

                if isEditing {
                    Picker("Title", selection: $editedTitle) {
                        ForEach(gameEngine.player.unlockedTitles, id: \.self) { title in
                            Text(title).tag(title)
                        }
                    }
                } else {
                    HStack {
                        Text("Title")
                            .foregroundStyle(SystemTheme.textSecondary)
                        Spacer()
                        Text(gameEngine.player.title)
                    }
                }

                HStack {
                    Text("Level")
                        .foregroundStyle(SystemTheme.textSecondary)
                    Spacer()
                    Text("\(gameEngine.player.level)")
                        .font(SystemTypography.mono(14, weight: .bold))
                        .foregroundStyle(SystemTheme.primaryBlue)
                }

                HStack {
                    Text("Power Level")
                        .foregroundStyle(SystemTheme.textSecondary)
                    Spacer()
                    Text("\(gameEngine.player.powerLevel)")
                        .font(SystemTypography.mono(14, weight: .bold))
                }
            } header: {
                Text("Profile")
            }

            Section {
                HStack {
                    Text("Total XP")
                        .foregroundStyle(SystemTheme.textSecondary)
                    Spacer()
                    Text("\(gameEngine.player.totalXP)")
                        .font(SystemTypography.mono(14, weight: .semibold))
                        .foregroundStyle(SystemTheme.primaryBlue)
                }

                HStack {
                    Text("Gold")
                        .foregroundStyle(SystemTheme.textSecondary)
                    Spacer()
                    Text("\(gameEngine.player.gold)")
                        .font(SystemTypography.mono(14, weight: .semibold))
                        .foregroundStyle(SystemTheme.goldColor)
                }

                HStack {
                    Text("Shadow Soldiers")
                        .foregroundStyle(SystemTheme.textSecondary)
                    Spacer()
                    Text("\(gameEngine.player.shadowSoldiers.count)")
                        .font(SystemTypography.mono(14, weight: .semibold))
                }

                HStack {
                    Text("Member Since")
                        .foregroundStyle(SystemTheme.textSecondary)
                    Spacer()
                    Text(gameEngine.player.createdAt, style: .date)
                        .font(SystemTypography.caption)
                }
            } header: {
                Text("Progress")
            }

            if !gameEngine.player.unlockedTitles.isEmpty {
                Section {
                    ForEach(gameEngine.player.unlockedTitles, id: \.self) { title in
                        HStack {
                            Image(systemName: "text.badge.star")
                                .foregroundStyle(SystemTheme.goldColor)
                            Text(title)
                            Spacer()
                            if title == gameEngine.player.title {
                                Text("Active")
                                    .font(SystemTypography.captionSmall)
                                    .foregroundStyle(SystemTheme.successGreen)
                            }
                        }
                    }
                } header: {
                    Text("Unlocked Titles")
                }
            }
        }
        .navigationTitle("Hunter Profile")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveProfile()
                    } else {
                        editedName = gameEngine.player.name
                        editedTitle = gameEngine.player.title
                    }
                    isEditing.toggle()
                }
            }
        }
    }

    private func saveProfile() {
        gameEngine.player.name = editedName.trimmingCharacters(in: .whitespaces)
        gameEngine.player.title = editedTitle
        gameEngine.save()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(GameEngine.shared)
}
