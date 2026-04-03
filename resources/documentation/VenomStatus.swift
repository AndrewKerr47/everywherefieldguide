import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// VenomStatus.swift
// Carajás Field Guide
//
// Four-state venom classification system.
// Defined in MasterDoc v0.3 Section 6.2 and Section 8.3.
//
// Colour system:
//   dangerous   → red skull    #ba1a1a  human fatalities recorded
//   mild        → orange skull #C07820  side effects, no deaths
//   lowRisk     → green skull  #4A8A30  venom present, minimal human effect
//   nonVenomous → green smiley #406840  no venom
// ─────────────────────────────────────────────────────────────────────────────

enum VenomStatus: String, Codable, CaseIterable {
    case dangerous   = "dangerous"
    case mild        = "mild"
    case lowRisk     = "low_risk"
    case nonVenomous = "non_venomous"

    // ── Display label ─────────────────────────────────────────────────────────
    var label: String {
        let locale = LocaleManager.shared.current
        switch self {
        case .dangerous:   return String(localized: "venom.dangerous",   locale: locale)
        case .mild:        return String(localized: "venom.mild",         locale: locale)
        case .lowRisk:     return String(localized: "venom.low_risk",     locale: locale)
        case .nonVenomous: return String(localized: "venom.non_venomous", locale: locale)
        }
    }

    // ── Icon colour ───────────────────────────────────────────────────────────
    var color: Color {
        switch self {
        case .dangerous:   return .venomDangerous  // #ba1a1a
        case .mild:        return .venomMild        // #C07820
        case .lowRisk:     return .venomLowRisk     // #4A8A30
        case .nonVenomous: return .venomNone        // #406840
        }
    }

    // ── Row background tint ───────────────────────────────────────────────────
    var rowBackground: Color {
        switch self {
        case .dangerous:   return Color(hex: "FBCDCD")
        case .mild:        return Color(hex: "C07820").opacity(0.06)
        case .lowRisk:     return Color(hex: "DFF1E2")
        case .nonVenomous: return Color(hex: "DFF1E2")
        }
    }

    // ── SF Symbol icon name ───────────────────────────────────────────────────
    var iconName: String {
        switch self {
        case .dangerous:   return "skull.fill"
        case .mild:        return "skull.fill"
        case .lowRisk:     return "skull.fill"
        case .nonVenomous: return "face.smiling"
        }
    }
}
