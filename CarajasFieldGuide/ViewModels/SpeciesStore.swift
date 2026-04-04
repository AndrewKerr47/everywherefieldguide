import SwiftUI
import Observation

// ─────────────────────────────────────────────────────────────────────────────
// SpeciesStore.swift
// Carajás Field Guide
//
// Loads species.json from the app bundle and merges a language-specific
// translation patch file (e.g. translations.pt-BR.json) when the active
// locale is not English.
//
// Translation patch files contain only translatable fields keyed by
// scientific name:
//   { "Bothrops atrox": { "description": "...", "venom_type": "...",
//                          "habitat": ["..."] } }
//
// species.json is always the single source of truth for all other fields.
// ─────────────────────────────────────────────────────────────────────────────

@Observable
final class SpeciesStore {

    // ── Published state ───────────────────────────────────────────────────────

    private(set) var species: [Species] = []
    private(set) var isLoading: Bool = false
    private(set) var loadError: String? = nil

    // ── Derived ───────────────────────────────────────────────────────────────

    var maxObservations: Int {
        species.compactMap(\.inatObservations).max() ?? 1
    }

    var speciesCount: Int { species.count }

    // ── Load ──────────────────────────────────────────────────────────────────

    /// Loads species.json and applies the appropriate translation patch.
    /// Safe to call multiple times — reloads if already loaded so that
    /// language switches take effect immediately.
    func load() {
        isLoading = true
        loadError = nil

        do {
            var loaded = try Self.loadFromBundle()

            // Apply translation patch if a non-English locale is active
            let languageCode = LocaleManager.shared.current.identifier
            if languageCode != "en", languageCode != "en-GB" {
                if let patch = try? Self.loadTranslations(for: languageCode) {
                    loaded = Self.applyPatch(patch, to: loaded)
                }
            }

            self.species = loaded
        } catch {
            self.loadError = error.localizedDescription
            print("SpeciesStore: failed to load species.json — \(error)")
        }

        isLoading = false
    }

    // ── Bundle loading ────────────────────────────────────────────────────────

    private static func loadFromBundle() throws -> [Species] {
        guard let url = Bundle.main.url(forResource: "species", withExtension: "json") else {
            throw SpeciesStoreError.fileNotFound
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([Species].self, from: data)
    }

    // ── Translation loading ───────────────────────────────────────────────────

    /// Loads a translation patch file for the given locale identifier.
    /// Returns nil silently if no patch file exists for that locale —
    /// the app simply stays in English for untranslated locales.
    private static func loadTranslations(for locale: String) throws -> SpeciesTranslationPatch? {
        guard let url = Bundle.main.url(
            forResource: "translations.\(locale)",
            withExtension: "json"
        ) else {
            return nil  // No patch for this locale — fall back to English
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(SpeciesTranslationPatch.self, from: data)
    }

    // ── Patch application ─────────────────────────────────────────────────────

    /// Merges translation fields onto matching species objects.
    /// Only fields present in the patch are overwritten —
    /// all other fields retain their original values from species.json.
    private static func applyPatch(
        _ patch: SpeciesTranslationPatch,
        to species: [Species]
    ) -> [Species] {
        species.map { sp in
            guard let translation = patch.translations[sp.scientificName] else {
                return sp  // No translation for this species — keep English
            }
            return sp.applying(translation)
        }
    }

    // ── Observation count helper ──────────────────────────────────────────────

    func observationProgress(for species: Species) -> Double {
        guard let count = species.inatObservations, maxObservations > 0 else { return 0 }
        return Double(count) / Double(maxObservations)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Translation patch model
// ─────────────────────────────────────────────────────────────────────────────

/// Top-level wrapper decoded from translations.{locale}.json.
/// The JSON is a flat dictionary: { "Scientific Name": { fields... } }
struct SpeciesTranslationPatch: Decodable {

    let translations: [String: SpeciesTranslation]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        translations = try container.decode([String: SpeciesTranslation].self)
    }
}

/// The translatable fields for a single species.
/// All fields are optional — only present fields are patched.
struct SpeciesTranslation: Decodable {
    let description: String?
    let venomType: String?
    let habitat: [String]?

    enum CodingKeys: String, CodingKey {
        case description
        case venomType = "venom_type"
        case habitat
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Errors
// ─────────────────────────────────────────────────────────────────────────────

enum SpeciesStoreError: LocalizedError {
    case fileNotFound

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "species.json not found in app bundle. Add the file to the Xcode project with Target Membership checked."
        }
    }
}
