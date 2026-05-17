//
//  MainTabView.swift
//  GAMELIFE
//
//  [SYSTEM]: Navigation matrix initialized.
//  Your journey through the realms begins here.
//

import SwiftUI

// MARK: - Main Tab View

/// The root navigation structure - 5 distinct tabs for the Hunter's journey
struct MainTabView: View {

    // MARK: - Properties

    @EnvironmentObject var gameEngine: GameEngine
    @EnvironmentObject var deepLinkManager: DeepLinkManager
    @AppStorage("defaultTab") private var defaultTab: Int = 0
    @State private var selectedTab: Int

    // MARK: - System Message State

    @State private var currentSystemMessage: SystemMessage?

    // MARK: - Initialization

    init() {
        let savedDefault = SettingsManager.shared.defaultTab
        let normalizedDefault = GameTab(rawValue: savedDefault)?.rawValue ?? GameTab.status.rawValue
        _selectedTab = State(initialValue: normalizedDefault)
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                // Tab 0: Status (Player Profile & Stats) — Glasswork direction
                GlassworkStatusView()
                    .tabItem {
                        Label(LocalizedStringKey("Status"), systemImage: "person.fill")
                    }
                    .tag(0)

                // Tab 1: Quests (Daily/Micro Tasks) — Glasswork direction
                GlassworkQuestsView()
                    .tabItem {
                        Label(LocalizedStringKey("Quests"), systemImage: "list.bullet.rectangle")
                    }
                    .tag(1)

                // Tab 2: Training (Focus Timer - formerly Dungeon) — Glasswork direction
                GlassworkTrainingView()
                    .tabItem {
                        Label(LocalizedStringKey("Training"), systemImage: "timer")
                    }
                    .tag(2)

                // Tab 3: Bosses (Projects & Long-term Goals) — Glasswork direction
                GlassworkBossesView()
                    .tabItem {
                        Label(LocalizedStringKey("Bosses"), systemImage: "bolt.shield.fill")
                    }
                    .tag(3)

                // Tab 4: Shop (Rewards Marketplace) — Glasswork direction
                GlassworkShopView()
                    .tabItem {
                        Label(LocalizedStringKey("Shop"), systemImage: "bag.fill")
                    }
                    .tag(4)
            }
            .tint(GW.cyan)

            // System Message Banner Overlay
            if let message = currentSystemMessage {
                SystemMessageBanner(message: message) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        currentSystemMessage = nil
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showSystemMessage)) { notification in
            if let message = notification.object as? SystemMessage {
                withAnimation(.easeOut(duration: 0.22)) {
                    currentSystemMessage = message
                }
            }
        }
        .onAppear {
            AnalyticsManager.shared.trackScreenView(GameTab(rawValue: selectedTab)?.title ?? "unknown_tab")
            AnalyticsManager.shared.trackFeature("tab_selected_\(GameTab(rawValue: selectedTab)?.title ?? "unknown")")
        }
        .onChange(of: defaultTab) { _, newValue in
            selectedTab = newValue
        }
        .onChange(of: selectedTab) { _, newValue in
            HapticManager.shared.selection()
            let tabName = GameTab(rawValue: newValue)?.title ?? "unknown"
            AnalyticsManager.shared.trackScreenView(tabName)
            AnalyticsManager.shared.trackFeature("tab_selected_\(tabName)")
        }
        .onChange(of: deepLinkManager.pendingLink) { _, link in
            guard let link else { return }
            selectedTab = link.route.tabIndex
        }
        .sheet(item: $gameEngine.deathPenaltySummary) { summary in
            DeathPenaltySummaryView(summary: summary)
        }
        .fullScreenCover(isPresented: $gameEngine.showLevelUpAlert) {
            if let data = gameEngine.lastLevelUpData {
                GlassworkLevelUpView(data: data) {
                    gameEngine.showLevelUpAlert = false
                }
                .presentationBackground(.clear)
            }
        }
    }
}

// MARK: - Tab Enum

/// The five pillars of the Hunter's interface
enum GameTab: Int, CaseIterable {
    case status = 0
    case quests = 1
    case training = 2
    case bosses = 3
    case shop = 4

    var title: String {
        switch self {
        case .status: return "Status"
        case .quests: return "Quests"
        case .training: return "Training"
        case .bosses: return "Bosses"
        case .shop: return "Shop"
        }
    }

    var icon: String {
        switch self {
        case .status: return "person.fill"
        case .quests: return "list.bullet.rectangle"
        case .training: return "timer"
        case .bosses: return "bolt.shield.fill"
        case .shop: return "bag.fill"
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let showSystemMessage = Notification.Name("showSystemMessage")
}

struct DeathPenaltySummaryView: View {
    let summary: DeathPenaltySummary
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GW.bg.ignoresSafeArea()
                Canvas { ctx, size in
                    let w = size.width, h = size.height
                    func ellipse(_ c: CGPoint, _ rx: CGFloat, _ ry: CGFloat, _ color: Color) {
                        let rect = CGRect(x: c.x - rx, y: c.y - ry, width: rx * 2, height: ry * 2)
                        let g = Gradient(colors: [color, color.opacity(0)])
                        ctx.fill(Path(ellipseIn: rect),
                                 with: .radialGradient(g, center: c,
                                                       startRadius: 0,
                                                       endRadius: max(rx, ry)))
                    }
                    ellipse(CGPoint(x: w * 0.5, y: h * 0.0), w * 0.9, h * 0.5, GW.danger.opacity(0.35))
                    ellipse(CGPoint(x: w * 0.5, y: h * 1.0), w * 0.7, h * 0.5, GW.danger.opacity(0.15))
                }
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("[ SYSTEM · DEFEAT ]")
                            .font(GW.mono(10, weight: .medium))
                            .tracking(3)
                            .foregroundStyle(GW.danger)
                        Text("You were defeated.")
                            .font(GW.display(28, weight: .bold))
                            .tracking(-0.5)
                            .foregroundStyle(GW.ink)
                        Text("You missed \(summary.missedQuestCount) required quest\(summary.missedQuestCount == 1 ? "" : "s"). Health was restored, and penalties were applied.")
                            .font(GW.sans(13))
                            .foregroundStyle(GW.mute)
                            .lineSpacing(3)

                        GWCard(paddingX: 14, paddingY: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("RANK")
                                    .font(GW.mono(9, weight: .medium))
                                    .tracking(2)
                                    .foregroundStyle(GW.mute)
                                Text(summary.wasDemoted ? "\(summary.previousRank.rawValue) → \(summary.newRank.rawValue)" : "\(summary.previousRank.rawValue) · NO DEMOTION")
                                    .font(GW.display(18, weight: .bold))
                                    .foregroundStyle(summary.wasDemoted ? GW.amber : GW.ink)
                            }
                        }

                        GWCard(paddingX: 14, paddingY: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("CURRENCY")
                                    .font(GW.mono(9, weight: .medium))
                                    .tracking(2)
                                    .foregroundStyle(GW.mute)
                                HStack(alignment: .firstTextBaseline) {
                                    Text("−\(summary.goldLost.formatted()) g")
                                        .font(GW.display(20, weight: .bold))
                                        .foregroundStyle(GW.danger)
                                    Spacer()
                                    Text("\(summary.goldRemaining.formatted()) remaining")
                                        .font(GW.mono(10))
                                        .foregroundStyle(GW.mute)
                                }
                            }
                        }

                        GWCard(paddingX: 14, paddingY: 12) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("STAT LOSS")
                                        .font(GW.mono(9, weight: .medium))
                                        .tracking(2)
                                        .foregroundStyle(GW.mute)
                                    Spacer()
                                    Text("−\(summary.statLossPercent)%")
                                        .font(GW.mono(9, weight: .bold))
                                        .tracking(2)
                                        .foregroundStyle(GW.danger)
                                }
                                ForEach(summary.statLosses) { loss in
                                    HStack {
                                        Text(loss.stat.rawValue)
                                            .font(GW.mono(11, weight: .bold))
                                            .tracking(1.2)
                                            .foregroundStyle(loss.stat.color)
                                        Text(loss.stat.rawValue == "STR" ? "Strength"
                                             : loss.stat.rawValue == "INT" ? "Intelligence"
                                             : loss.stat.rawValue == "AGI" ? "Agility"
                                             : loss.stat.rawValue == "VIT" ? "Vitality"
                                             : loss.stat.rawValue == "WIL" ? "Willpower"
                                             : loss.stat.rawValue == "SPI" ? "Spirit"
                                             : "")
                                            .font(GW.sans(12))
                                            .foregroundStyle(GW.inkSoft)
                                        Spacer()
                                        Text("−\(loss.lost)")
                                            .font(GW.mono(12, weight: .bold))
                                            .foregroundStyle(GW.danger)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Continue") { dismiss() }
                        .font(GW.sans(14, weight: .semibold))
                        .foregroundStyle(GW.cyan)
                }
            }
            .toolbarBackground(GW.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle("Death Report")
            .navigationBarTitleDisplayMode(.inline)
        }
        .foregroundStyle(GW.ink)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .environmentObject(GameEngine.shared)
}
