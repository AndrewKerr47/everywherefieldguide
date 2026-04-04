import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// CarajasFieldGuideApp.swift
// Carajás Field Guide
// ─────────────────────────────────────────────────────────────────────────────

@main
struct CarajasFieldGuideApp: App {

    @State private var showDownload: Bool =
        !UserDefaults.standard.bool(forKey: UserDefaultsKeys.imagesDownloaded)

    @AppStorage("selectedLanguage") private var selectedLanguage: String =
        LandingView.defaultLanguage

    @State private var speciesStore = SpeciesStore()
    private let seenStore = SeenSpeciesStore.shared

    init() {
        configureAppearance()
        let saved = UserDefaults.standard.string(forKey: "selectedLanguage")
            ?? LandingView.defaultLanguage
        LocaleManager.shared.current = Locale(identifier: saved)
    }

    private var appLocale: Locale {
        let locale = Locale(identifier: selectedLanguage)
        LocaleManager.shared.current = locale
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
                    .environment(speciesStore)
                    .task { speciesStore.load() }
            }
        }
        .onChange(of: selectedLanguage) { _, newLanguage in
            LocaleManager.shared.current = Locale(identifier: newLanguage)
            speciesStore.load()
        }
    }
}

private func configureAppearance() {
    let navAppearance = UINavigationBarAppearance()
    navAppearance.configureWithTransparentBackground()
    UINavigationBar.appearance().standardAppearance   = navAppearance
    UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    UITabBar.appearance().isHidden = true
}
