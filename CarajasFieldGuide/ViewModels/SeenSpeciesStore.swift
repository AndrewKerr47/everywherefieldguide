import Foundation
import Observation

// ─────────────────────────────────────────────────────────────────────────────
// SeenSpeciesStore.swift
// Carajás Field Guide
//
// Manages the set of species the user has marked as seen.
// Persisted to UserDefaults as a comma-separated string of scientific names.
// Scientific name is used as the stable unique key (matches Species.id).
//
// Usage:
//   @Environment(SeenSpeciesStore.self) private var seenStore
//   seenStore.toggle("Bothrops atrox")
//   seenStore.isSeen("Bothrops atrox") → Bool
// ─────────────────────────────────────────────────────────────────────────────

@Observable
final class SeenSpeciesStore {

    // ── Singleton ─────────────────────────────────────────────────────────────

    static let shared = SeenSpeciesStore()

    // ── Storage ───────────────────────────────────────────────────────────────

    private let key = "seenSpecies"

    private(set) var seenNames: Set<String> {
        didSet { persist() }
    }

    // ── Init ──────────────────────────────────────────────────────────────────

    init() {
        let saved = UserDefaults.standard.string(forKey: "seenSpecies") ?? ""
        seenNames = saved.isEmpty
            ? []
            : Set(saved.components(separatedBy: "||"))
    }

    // ── Public API ────────────────────────────────────────────────────────────

    func isSeen(_ scientificName: String) -> Bool {
        seenNames.contains(scientificName)
    }

    func toggle(_ scientificName: String) {
        if seenNames.contains(scientificName) {
            seenNames.remove(scientificName)
        } else {
            seenNames.insert(scientificName)
        }
    }

    var count: Int { seenNames.count }

    // ── Persistence ───────────────────────────────────────────────────────────

    private func persist() {
        UserDefaults.standard.set(
            seenNames.joined(separator: "||"),
            forKey: key
        )
    }
}
