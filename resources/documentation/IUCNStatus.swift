import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// IUCNStatus.swift
// Carajás Field Guide
//
// Seven-state IUCN Red List classification.
// Defined in MasterDoc v0.3 Section 6.2 and Section 8.4.
//
// Colour groups:
//   LC / NT  → green  #23422a (appPrimary)
//   VU / EN  → amber  #C07820
//   CR/EW/EX → red    #ba1a1a (appError)
// ─────────────────────────────────────────────────────────────────────────────

enum IUCNStatus: String, Codable, CaseIterable {
    case lc = "LC"
    case nt = "NT"
    case vu = "VU"
    case en = "EN"
    case cr = "CR"
    case ew = "EW"
    case ex = "EX"

    // ── Badge text ────────────────────────────────────────────────────────────
    /// The acronym shown in the (XX) badge.
    var code: String { rawValue }

    /// Badge display with parentheses.
    var badgeText: String { "(\(rawValue))" }

    // ── Full category name ────────────────────────────────────────────────────
    /// Right-aligned value in the IUCN fact row.
    var label: String {
        let locale = LocaleManager.shared.current
        switch self {
        case .lc: return String(localized: "iucn.lc", locale: locale)
        case .nt: return String(localized: "iucn.nt", locale: locale)
        case .vu: return String(localized: "iucn.vu", locale: locale)
        case .en: return String(localized: "iucn.en", locale: locale)
        case .cr: return String(localized: "iucn.cr", locale: locale)
        case .ew: return String(localized: "iucn.ew", locale: locale)
        case .ex: return String(localized: "iucn.ex", locale: locale)
        }
    }

    // ── Colour group ──────────────────────────────────────────────────────────
    enum ColorGroup {
        case green, amber, red
    }

    var colorGroup: ColorGroup {
        switch self {
        case .lc, .nt:      return .green
        case .vu, .en:      return .amber
        case .cr, .ew, .ex: return .red
        }
    }

    // ── Resolved SwiftUI colour ───────────────────────────────────────────────
    var color: Color {
        switch colorGroup {
        case .green: return .iucnGreen  // #23422a
        case .amber: return .iucnAmber  // #C07820
        case .red:   return .iucnRed    // #ba1a1a
        }
    }

    // ── Row background ────────────────────────────────────────────────────────
    var rowBackground: Color {
        Color.surfaceContainerLow.opacity(0.50)
    }
}
