import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// CarajasFieldGuideApp.swift
// Carajás Field Guide
//
// App entry point. Routes to DownloadView on first launch (images not yet
// cached) or directly to LandingView on all subsequent launches.
//
// Sprint 4: injects a SwiftUI Locale environment value derived from
// selectedLanguage so that String Catalog lookups respect the in-app
// language picker immediately, without an app restart.
// ─────────────────────────────────────────────────────────────────────────────

@main
struct CarajasFieldGuideApp: App {

    @State private var showDownload: Bool =
        !UserDefaults.standard.bool(forKey: UserDefaultsKeys.imagesDownloaded)

    @AppStorage("selectedLanguage") private var selectedLanguage: String =
        LandingView.defaultLanguage

    private let seenStore = SeenSpeciesStore.shared

    init() {
        configureAppearance()
    }

    // ── Resolved locale ───────────────────────────────────────────────────────
    private var appLocale: Locale {
        let locale = Locale(identifier: selectedLanguage)
        LocaleManager.shared.current = locale   // keeps model-layer lookups in sync
        return locale
    }

    var body: some Scene {
        WindowGroup {
            if showDownload {
                DownloadView {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        showDownload = false
                    }
                }
                .environment(seenStore)
                .environment(\.locale, appLocale)
            } else {
                LandingView()
                    .environment(seenStore)
                    .environment(\.locale, appLocale)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Appearance
// ─────────────────────────────────────────────────────────────────────────────

private func configureAppearance() {
    let navAppearance = UINavigationBarAppearance()
    navAppearance.configureWithTransparentBackground()
    UINavigationBar.appearance().standardAppearance   = navAppearance
    UINavigationBar.appearance().scrollEdgeAppearance = navAppearance

    UITabBar.appearance().isHidden = true
}
