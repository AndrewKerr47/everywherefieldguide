import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// CarajasFieldGuideApp.swift
// Carajás Field Guide
//
// App entry point. Sets ContentView as root and applies global appearance.
// ─────────────────────────────────────────────────────────────────────────────

@main
struct CarajasFieldGuideApp: App {

    init() {
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Force light mode — app is designed for light theme only (Section 6.1)
                .preferredColorScheme(.light)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Global UIKit appearance overrides
    // ─────────────────────────────────────────────────────────────────────────
    private func configureAppearance() {
        // Remove default UINavigationBar background so hero image can bleed
        // under the navigation area — we use a custom back button overlaid on hero
        let transparentAppearance = UINavigationBarAppearance()
        transparentAppearance.configureWithTransparentBackground()
        transparentAppearance.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance    = transparentAppearance
        UINavigationBar.appearance().scrollEdgeAppearance  = transparentAppearance
        UINavigationBar.appearance().compactAppearance     = transparentAppearance
        UINavigationBar.appearance().tintColor             = .white

        // Tab bar: hide default UITabBar — we use a custom bottom nav overlay
        UITabBar.appearance().isHidden = true
    }
}
