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
    @AppStorage("preferredLanguageCode") private var preferredLanguageCode = AppLanguage.system.rawValue
    @AppStorage("useSystemAppearance") private var useSystemAppearance = true
    @AppStorage("preferDarkMode") private var preferDarkMode = true
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @AppStorage("useCustomAppFont") private var useCustomAppFont = false
    @AppStorage("showQuestCompletionGrid") private var showQuestCompletionGrid = true
    @AppStorage("showQuestNextUpSection") private var showQuestNextUpSection = true
    @AppStorage("questCompletionNotificationMode") private var questCompletionNotificationMode = NotificationManager.QuestCompletionNotificationMode.immediate.rawValue
    @AppStorage("deathMechanicEnabled") private var deathMechanicEnabled = true
    @StateObject private var appIconManager = AppIconManager.shared
    @State private var showResetConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var showDeathMechanicInfo = false

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Derived

    /// 3-state appearance binding (System · Light · Dark) wired to the
    /// existing `useSystemAppearance` + `preferDarkMode` AppStorage so
    /// nothing else in the app needs to change to honor it.
    private var appearanceBinding: Binding<AppearancePreference> {
        Binding(
            get: {
                if useSystemAppearance { return .system }
                return preferDarkMode ? .dark : .light
            },
            set: { new in
                switch new {
                case .system:
                    useSystemAppearance = true
                case .light:
                    useSystemAppearance = false
                    preferDarkMode = false
                case .dark:
                    useSystemAppearance = false
                    preferDarkMode = true
                }
            }
        )
    }

    /// "<MARKETING> (<BUILD>)" pulled live from the Info.plist so the
    /// Settings row always reflects the latest pbxproj bump.
    private var appVersionDisplay: String {
        let info = Bundle.main.infoDictionary
        let marketing = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return marketing == build ? marketing : "\(marketing) (\(build))"
    }

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
            .listRowBackground(glassRowBackground)

            Section {
                Picker("App Language", selection: $preferredLanguageCode) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language.rawValue)
                    }
                }
            } header: {
                Text("Language")
            } footer: {
                Text("Change the app language without leaving PRAXIS. Widgets and notifications follow this setting where supported.")
            }
            .listRowBackground(glassRowBackground)

            Section {
                Picker("Open App To", selection: $defaultTab) {
                    ForEach(GameTab.allCases, id: \.rawValue) { tab in
                        Text(tab.localizedTitle).tag(tab.rawValue)
                    }
                }
            } header: {
                Text("Launch")
            } footer: {
                Text("Choose which tab PRAXIS opens to when you launch the app.")
            }
            .listRowBackground(glassRowBackground)

            // Preferences Section
            Section {
                Picker("Appearance", selection: appearanceBinding) {
                    Text("System").tag(AppearancePreference.system)
                    Text("Light").tag(AppearancePreference.light)
                    Text("Dark").tag(AppearancePreference.dark)
                }
                .pickerStyle(.menu)

                Toggle("Haptic Feedback", isOn: $hapticEnabled)
                    .onChange(of: hapticEnabled) { _, isEnabled in
                        if isEnabled {
                            HapticManager.shared.selection()
                        }
                    }

                Toggle("PRAXIS FONT", isOn: $useCustomAppFont)

                Toggle("Show Quest Completion Grid", isOn: $showQuestCompletionGrid)

                Toggle("Show Next Up Section", isOn: $showQuestNextUpSection)

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
                Text("Set your appearance, app icon, quests layout, alerts, font style, and death penalties in one place. Haptic Feedback is the master switch for taps, picker ticks, confirmations, and combat/training feedback. Turning off death penalties does not stop HP loss.")
            }
            .listRowBackground(glassRowBackground)

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
            .listRowBackground(glassRowBackground)

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
            .listRowBackground(glassRowBackground)

            // Danger Zone Section
            Section {
                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    Label("Reset All", systemImage: "arrow.counterclockwise")
                }
            } header: {
                Text("Danger Zone")
            } footer: {
                Text("Wipes your hunter back to Lv. 1 — clears quests, bosses, XP, gold, HP, streak, achievements, and onboarding. Settings stay. This cannot be undone.")
            }
            .listRowBackground(glassRowBackground)

            // About Section
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersionDisplay)
                        .foregroundStyle(SystemTheme.textSecondary)
                }

                if let aboutURL = URL(string: "https://gamelife.app") {
                    Link(destination: aboutURL) {
                        Label("About PRAXIS", systemImage: "info.circle")
                    }
                }

                if let privacyURL = URL(string: "https://shawhause.com/praxis-privacy.html") {
                    Link(destination: privacyURL) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                }
            } header: {
                Text("About")
            }
            .listRowBackground(glassRowBackground)
        }
        .scrollContentBackground(.hidden)
        .background(
            ZStack {
                GW.bg
                GWAurora()
            }
            .ignoresSafeArea()
        )
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GW.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        
        .accentColor(GW.cyan)
        .alert("Reset everything?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                resetAll()
            }
        } message: {
            Text("Wipes your hunter back to Lv. 1 — clears quests, bosses, XP, gold, HP, streak, achievements, and onboarding. Settings stay. This cannot be undone.")
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
        .onAppear {
            AnalyticsManager.shared.trackScreenView("settings")
        }
        .onChange(of: defaultTab) { _, _ in
            AnalyticsManager.shared.trackFeature("settings_changed_default_tab")
        }
        .onChange(of: preferredLanguageCode) { _, newValue in
            SettingsManager.shared.preferredLanguageCode = newValue
            AnalyticsManager.shared.trackFeature("settings_changed_language_\(newValue)")
        }
        .onChange(of: useSystemAppearance) { _, isEnabled in
            AnalyticsManager.shared.trackFeature(isEnabled ? "settings_enabled_system_appearance" : "settings_disabled_system_appearance")
        }
        .onChange(of: preferDarkMode) { _, isEnabled in
            AnalyticsManager.shared.trackFeature(isEnabled ? "settings_enabled_dark_mode" : "settings_enabled_light_mode")
        }
        .onChange(of: hapticEnabled) { _, isEnabled in
            AnalyticsManager.shared.trackFeature(isEnabled ? "settings_enabled_haptics" : "settings_disabled_haptics")
        }
        .onChange(of: deathMechanicEnabled) { _, isEnabled in
            AnalyticsManager.shared.trackFeature(isEnabled ? "settings_enabled_death_penalties" : "settings_disabled_death_penalties")
        }
    }

    // MARK: - Actions

    /// Wipe the hunter back to a fresh profile while keeping user settings.
    /// This is the "Reset All" Danger Zone action — destroys all game state
    /// (player progression, quests, bosses, achievements, onboarding) but
    /// preserves Appearance / Language / Haptic / PRAXIS Font etc.
    private func resetAll() {
        gameEngine.startFreshProfile(named: "Hunter")
        MarketplaceManager.shared.resetForFreshStart()
        NotificationManager.shared.clearAllQuestReminders()
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        AnalyticsManager.shared.trackFeature("settings_reset_all")

        SystemMessageHelper.show(SystemMessage(
            type: .critical,
            title: "Reset Complete",
            message: "Hunter wiped to Lv. 1. Settings preserved."
        ))
    }

    /// Glass-tinted row background applied to each Section so the Form
    /// reads as floating frosted cards over the Glasswork aurora.
    private var glassRowBackground: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay(
                LinearGradient(
                    colors: [Color.white.opacity(colorScheme == .dark ? 0.06 : 0.025),
                             Color.white.opacity(colorScheme == .dark ? 0.02 : 0.01)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
    }

    private func deleteAllData() {
        // Clear persisted app domain and reset in-memory state.
        SettingsManager.shared.resetAllSettings()

        gameEngine.startFreshProfile(named: "Hunter")

        MarketplaceManager.shared.resetForFreshStart()
        NotificationManager.shared.clearAllQuestReminders()
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        AnalyticsManager.shared.trackFeature("settings_deleted_all_data")

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

// MARK: - Appearance preference

enum AppearancePreference: String, Hashable {
    case system, light, dark
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

@MainActor
final class AppIconManager: ObservableObject {
    static let shared = AppIconManager()
    private static let storedOptionKey = "selectedAppIconOption"

    @Published private(set) var currentOption: AppIconOption = .signal
    @Published private(set) var isSupported: Bool = UIApplication.shared.supportsAlternateIcons
    @Published private(set) var hasLegacyIconOverride = false
    @Published private(set) var hasPendingIconChange = false
    @Published private(set) var pendingIconDisplayName: String?
    private var pendingOption: AppIconOption?
    private var pendingRequestID = UUID()
    private var cancellables = Set<AnyCancellable>()
    private var storedOption: AppIconOption? {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: Self.storedOptionKey) else {
                return nil
            }
            return AppIconOption(rawValue: rawValue)
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue.rawValue, forKey: Self.storedOptionKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.storedOptionKey)
            }
        }
    }

    private init() {
        normalizeLegacyIconIfNeeded()
        refreshCurrentIcon()
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.refreshCurrentIcon()
            }
            .store(in: &cancellables)
    }

    func refreshCurrentIcon() {
        isSupported = UIApplication.shared.supportsAlternateIcons
        guard isSupported else {
            currentOption = .signal
            hasLegacyIconOverride = false
            hasPendingIconChange = false
            pendingIconDisplayName = nil
            pendingOption = nil
            storedOption = nil
            return
        }

        let resolvedState = resolvedSystemState()

        if hasPendingIconChange, let pendingOption {
            if resolvedState.currentOption == pendingOption {
                applyResolvedSystemState(resolvedState)
                clearPendingIconChange()
            } else {
                currentOption = pendingOption
                hasLegacyIconOverride = resolvedState.hasLegacyIconOverride
            }
            return
        }

        applyResolvedSystemState(resolvedState)
    }

    func setIcon(_ option: AppIconOption) {
        isSupported = UIApplication.shared.supportsAlternateIcons
        guard isSupported else {
            SystemMessageHelper.showWarning("Alternate app icons are not supported on this device.")
            return
        }

        let targetIconName = option.iconName
        let resolvedState = resolvedSystemState()
        guard hasPendingIconChange || resolvedState.currentOption != option else {
            applyResolvedSystemState(resolvedState)
            return
        }
        guard pendingOption != option else { return }

        let requestID = UUID()
        pendingRequestID = requestID
        pendingOption = option
        currentOption = option
        hasPendingIconChange = true
        pendingIconDisplayName = option.displayName

        performIconChange(
            requestID: requestID,
            targetIconName: targetIconName
        )
    }

    /// Reset the alternate icon to the bundle default if it currently
    /// points at a name that has been removed from the catalog (legacy
    /// Phoenix variants, or the redundant pre-rename "AppIconPrism").
    /// Silent — no toast — so users don't see warnings when iOS recovers.
    private func normalizeLegacyIconIfNeeded() {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        guard let currentName = UIApplication.shared.alternateIconName else { return }
        let resolvedState = AppIconStateResolver.resolve(
            currentIconName: currentName,
            storedOption: storedOption
        )
        guard resolvedState.shouldNormalizeIconName else { return }

        storedOption = .signal
        UIApplication.shared.setAlternateIconName(nil) { [weak self] _ in
            DispatchQueue.main.async {
                self?.refreshCurrentIcon()
            }
        }
    }

    private func performIconChange(
        requestID: UUID,
        targetIconName: String?
    ) {
        guard requestID == pendingRequestID else { return }

        UIApplication.shared.setAlternateIconName(targetIconName) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self?.finishIconChange(
                    requestID: requestID,
                    targetIconName: targetIconName
                )
            }
        }
    }

    private func finishIconChange(
        requestID: UUID,
        targetIconName: String?
    ) {
        guard requestID == pendingRequestID else { return }

        let resolvedState = resolvedSystemState()
        if UIApplication.shared.alternateIconName == targetIconName {
            applyResolvedSystemState(resolvedState)
            clearPendingIconChange()
            return
        }

        applyResolvedSystemState(resolvedState)
        clearPendingIconChange()
        SystemMessageHelper.showWarning("App icon could not be changed. Please try again.")
    }

    private func resolvedSystemState() -> AppIconResolvedState {
        AppIconStateResolver.resolve(
            currentIconName: UIApplication.shared.alternateIconName,
            storedOption: storedOption
        )
    }

    private func applyResolvedSystemState(_ state: AppIconResolvedState) {
        currentOption = state.currentOption
        storedOption = state.storedOption
        hasLegacyIconOverride = state.hasLegacyIconOverride
    }

    private func clearPendingIconChange() {
        hasPendingIconChange = false
        pendingIconDisplayName = nil
        pendingOption = nil
    }

}

struct AppIconPickerView: View {
    @ObservedObject private var appIconManager = AppIconManager.shared

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
        .background(
            ZStack {
                GW.bg
                GWAurora()
            }
            .ignoresSafeArea()
        )
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
        .scrollContentBackground(.hidden)
        .background(
            ZStack {
                GW.bg
                GWAurora()
            }
            .ignoresSafeArea()
        )
        .navigationTitle("Hunter Profile")
        .toolbarBackground(GW.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
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
                .foregroundStyle(GW.cyan)
            }
        }
        .keyboardDismissToolbar()
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
