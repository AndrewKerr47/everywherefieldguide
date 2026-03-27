import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// CarajasFieldGuideApp.swift
// Carajás Field Guide
//
// App entry point. Routes to DownloadView on first launch (images not yet
// cached) or directly to LandingView on all subsequent launches.
// ─────────────────────────────────────────────────────────────────────────────

@main
struct CarajasFieldGuideApp: App {

    @State private var showDownload: Bool =
        !UserDefaults.standard.bool(forKey: UserDefaultsKeys.imagesDownloaded)

    init() {
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            if showDownload {
                DownloadView {
                    // Transition to main app once download completes
                    withAnimation(.easeInOut(duration: 0.6)) {
                        showDownload = false
                    }
                }
            } else {
                LandingView()
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Appearance
// ─────────────────────────────────────────────────────────────────────────────

private func configureAppearance() {
    // Transparent navigation bar — content scrolls behind it
    let navAppearance = UINavigationBarAppearance()
    navAppearance.configureWithTransparentBackground()
    UINavigationBar.appearance().standardAppearance  = navAppearance
    UINavigationBar.appearance().scrollEdgeAppearance = navAppearance

    // Tab bar hidden globally — custom BottomNavBar overlay used instead
    UITabBar.appearance().isHidden = true
}
