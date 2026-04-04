import SwiftUI

enum IUCNStatus: String, Codable, CaseIterable {
    case lc = "LC"
    case nt = "NT"
    case vu = "VU"
    case en = "EN"
    case cr = "CR"
    case ew = "EW"
    case ex = "EX"

    var code: String { rawValue }
    var badgeText: String { "(\(rawValue))" }

    var label: String {
        switch self {
        case .lc: return LocaleManager.shared.localizedString("iucn.lc", defaultValue: "Least Concern")
        case .nt: return LocaleManager.shared.localizedString("iucn.nt", defaultValue: "Near Threatened")
        case .vu: return LocaleManager.shared.localizedString("iucn.vu", defaultValue: "Vulnerable")
        case .en: return LocaleManager.shared.localizedString("iucn.en", defaultValue: "Endangered")
        case .cr: return LocaleManager.shared.localizedString("iucn.cr", defaultValue: "Critically Endangered")
        case .ew: return LocaleManager.shared.localizedString("iucn.ew", defaultValue: "Extinct in the Wild")
        case .ex: return LocaleManager.shared.localizedString("iucn.ex", defaultValue: "Extinct")
        }
    }

    enum ColorGroup { case green, amber, red }

    var colorGroup: ColorGroup {
        switch self {
        case .lc, .nt:      return .green
        case .vu, .en:      return .amber
        case .cr, .ew, .ex: return .red
        }
    }

    var color: Color {
        switch colorGroup {
        case .green: return .iucnGreen
        case .amber: return .iucnAmber
        case .red:   return .iucnRed
        }
    }

    var rowBackground: Color {
        Color.surfaceContainerLow.opacity(0.50)
    }
}
