import Foundation

// ─────────────────────────────────────────────────────────────────────────────
// LocaleManager.swift
// Carajás Field Guide
//
// Provides the active in-app locale to code that runs outside the SwiftUI
// view tree (e.g. VenomStatus.label, IUCNStatus.label).
//
// CarajasFieldGuideApp writes to `current` whenever selectedLanguage changes.
// Models read from `current` via String(localized:locale:).
// ─────────────────────────────────────────────────────────────────────────────

final class LocaleManager {

    static let shared = LocaleManager()
    private init() {
        let saved = UserDefaults.standard.string(forKey: "selectedLanguage")
            ?? LandingView.defaultLanguage
        current = Locale(identifier: saved)
    }

    var current: Locale
}
