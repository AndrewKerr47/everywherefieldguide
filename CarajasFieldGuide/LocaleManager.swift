import Foundation

// ─────────────────────────────────────────────────────────────────────────────
// LocaleManager.swift
// Carajás Field Guide
// ─────────────────────────────────────────────────────────────────────────────

final class LocaleManager {

    static let shared = LocaleManager()

    private init() {
        let saved = UserDefaults.standard.string(forKey: "selectedLanguage")
            ?? LandingView.defaultLanguage
        current = Locale(identifier: saved)
    }

    var current: Locale

    // ── Localised string lookup ───────────────────────────────────────────────

    /// Looks up a localised string from the correct .lproj bundle for the
    /// current locale. Falls back to English, then to defaultValue.
    func localizedString(_ key: String, defaultValue: String) -> String {
        let languageCode = current.identifier
        let candidates = [languageCode, String(languageCode.prefix(2)), "en"]

        for lang in candidates {
            if let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                let result = bundle.localizedString(forKey: key, value: nil, table: nil)
                if result != key { return result }
            }
        }
        return defaultValue
    }
}
