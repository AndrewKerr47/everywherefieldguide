import Foundation

// ─────────────────────────────────────────────────────────────────────────────
// Survey.swift
// Carajás Field Guide
//
// Represents a single survey in which a species was recorded.
// Each survey renders as a tappable pill that opens the survey URL
// via SFSafariViewController.
//
// Defined in MasterDoc v0.3 Section 8.2.
// HTML ref: <a class="px-3 py-1 rounded-full bg-secondary-container ...">
// ─────────────────────────────────────────────────────────────────────────────

struct Survey: Codable, Identifiable, Hashable {

    /// Unique identifier — used as the pill display label (e.g. "RS-2024-01")
    let id: String

    /// Full human-readable name shown on the pill button
    let name: String

    /// URL string for the survey document — opened via SFSafariViewController
    let url: String

    /// Resolved URL for use with SwiftUI Link / SFSafariViewController
    var resolvedURL: URL? {
        URL(string: url)
    }

    // ── Coding keys ───────────────────────────────────────────────────────────
    enum CodingKeys: String, CodingKey {
        case id, name, url
    }
}
