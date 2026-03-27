import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// CarajasFieldGuideApp.swift
// Carajás Field Guide
//
// App flow:
//   1. System splash screen — dark green bg + Mantella logo (configured in Info.plist)
//   2. LandingView — full-screen photo, 2 seconds, fade to list
//   3. ContentView (HomeView → species list)
// ─────────────────────────────────────────────────────────────────────────────

@main
struct CarajasFieldGuideApp: App {

    init() {
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            LandingView()
                .preferredColorScheme(.light)
        }
    }

    private func configureAppearance() {
        // Transparent navigation bar so hero image bleeds under it
        let transparent = UINavigationBarAppearance()
        transparent.configureWithTransparentBackground()
        transparent.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance   = transparent
        UINavigationBar.appearance().scrollEdgeAppearance = transparent
        UINavigationBar.appearance().compactAppearance    = transparent
        UINavigationBar.appearance().tintColor            = .white

        // Hide default UITabBar — we use custom bottom nav overlay
        UITabBar.appearance().isHidden = true
    }
}
