//
//  GAMELIFEApp.swift
//  GAMELIFE
//
//  [SYSTEM]: Application core initialized.
//  Welcome to the Game of Life.
//
//  Created by Marcus Shaw II on 2/5/26.
//

import SwiftUI

@main
struct GAMELIFEApp: App {

    // MARK: - State Objects

    @StateObject private var gameEngine = GameEngine.shared
    @StateObject private var deepLinkManager = DeepLinkManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("useSystemAppearance") private var useSystemAppearance = true
    @AppStorage("preferDarkMode") private var preferDarkMode = true
    @AppStorage("useCustomAppFont") private var useCustomAppFont = false

    // MARK: - Environment

    init() {
        // [SYSTEM]: Configure app defaults
        SettingsManager.shared.setDefaults()
        _ = CloudKitSyncManager.shared
        AnalyticsManager.shared.trackAppLaunch()

        // [SYSTEM]: Configure appearance
        configureAppearance()
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            RootView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .environmentObject(gameEngine)
                .environmentObject(deepLinkManager)
                .preferredColorScheme(resolvedColorScheme)
                .id(useCustomAppFont)
                .onOpenURL { url in
                    deepLinkManager.handle(url)
                }
                .onAppear {
                    configureAppearance()
                }
                .onChange(of: useCustomAppFont) { _, _ in
                    configureAppearance()
                }
            // [SYSTEM]: NO permission bombing - permissions are requested
            // via "Neural Link" setup quests in onboarding or settings
        }
    }

    private var resolvedColorScheme: ColorScheme? {
        guard !useSystemAppearance else { return nil }
        return preferDarkMode ? .dark : .light
    }

    // MARK: - Configuration

    private func configureAppearance() {
        // Configure navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(SystemTheme.backgroundPrimary)
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(SystemTheme.textPrimary),
            .font: SystemTypography.uiFont(17, weight: .bold, design: .monospaced)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(SystemTheme.primaryBlue),
            .font: SystemTypography.uiFont(34, weight: .bold, design: .monospaced)
        ]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance

        // Configure tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(SystemTheme.backgroundSecondary)

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
}

// MARK: - Root View

/// The root view that handles onboarding vs main app flow
struct RootView: View {
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject var gameEngine: GameEngine

    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if !hasCompletedOnboarding {
                FirstLaunchSetupView {
                    hasCompletedOnboarding = true
                }
                    .transition(.opacity)
            } else {
                MainTabView()
                    .environmentObject(gameEngine)
                    .transition(.opacity)
            }
        }
        .onAppear {
            AnalyticsManager.shared.trackScreenView("splash")
            // Show splash for 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
        .onChange(of: showSplash) { _, isShowingSplash in
            guard !isShowingSplash else { return }
            AnalyticsManager.shared.trackScreenView(hasCompletedOnboarding ? "main_tabs" : "onboarding")
        }
    }
}

// MARK: - Splash View

/// The initial splash screen with system initialization effect
struct SplashView: View {
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var glowIntensity: Double = 0

    var body: some View {
        ZStack {
            SystemTheme.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Logo/Icon
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(SystemTheme.primaryBlue.opacity(glowIntensity * 0.3), lineWidth: 4)
                        .frame(width: 120, height: 120)

                    // Inner ring
                    Circle()
                        .stroke(SystemTheme.primaryBlue, lineWidth: 2)
                        .frame(width: 100, height: 100)

                    // System icon
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(SystemTheme.primaryBlue)
                        .glow(color: SystemTheme.primaryBlue, radius: 15 * glowIntensity)
                }

                if showTitle {
                    Text("PRAXIS")
                        .font(SystemTypography.titleLarge)
                        .foregroundStyle(SystemTheme.primaryBlue)
                        .glow(color: SystemTheme.primaryBlue, radius: 10)
                }

                if showSubtitle {
                    Text("[SYSTEM INITIALIZING...]")
                        .font(SystemTypography.systemMessage)
                        .foregroundStyle(SystemTheme.textSecondary)
                }
            }
        }
        .onAppear {
            // Animate in sequence
            withAnimation(.easeOut(duration: 0.5)) {
                glowIntensity = 1.0
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showTitle = true
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                showSubtitle = true
            }

            // Pulsing glow
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(1.0)) {
                glowIntensity = 0.5
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RootView(hasCompletedOnboarding: .constant(true))
        .environmentObject(GameEngine.shared)
}
