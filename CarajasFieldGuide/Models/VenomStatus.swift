import SwiftUI

enum VenomStatus: String, Codable, CaseIterable {
    case dangerous   = "dangerous"
    case mild        = "mild"
    case lowRisk     = "low_risk"
    case nonVenomous = "non_venomous"

    var label: String {
        switch self {
        case .dangerous:   return LocaleManager.shared.localizedString("venom.dangerous",   defaultValue: "Dangerously venomous")
        case .mild:        return LocaleManager.shared.localizedString("venom.mild",         defaultValue: "Mildly venomous")
        case .lowRisk:     return LocaleManager.shared.localizedString("venom.low_risk",     defaultValue: "Venomous, low risk")
        case .nonVenomous: return LocaleManager.shared.localizedString("venom.non_venomous", defaultValue: "Non-venomous")
        }
    }

    var color: Color {
        switch self {
        case .dangerous:   return .venomDangerous
        case .mild:        return .venomMild
        case .lowRisk:     return .venomLowRisk
        case .nonVenomous: return .venomNone
        }
    }

    var rowBackground: Color {
        switch self {
        case .dangerous:   return Color(hex: "FBCDCD")
        case .mild:        return Color(hex: "C07820").opacity(0.06)
        case .lowRisk:     return Color(hex: "DFF1E2")
        case .nonVenomous: return Color(hex: "DFF1E2")
        }
    }

    var iconName: String {
        switch self {
        case .dangerous:   return "skull.fill"
        case .mild:        return "skull.fill"
        case .lowRisk:     return "skull.fill"
        case .nonVenomous: return "face.smiling"
        }
    }
}
