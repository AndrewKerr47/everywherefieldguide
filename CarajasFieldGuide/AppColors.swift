import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// AppColors.swift
// Carajás Field Guide
//
// All colour tokens sourced from MasterDoc v0.3 Section 6.1.
// These map directly from the locked HTML/Tailwind reference (Section 7).
// Do NOT hardcode hex values anywhere else in the app — always use these tokens.
// ─────────────────────────────────────────────────────────────────────────────

extension Color {

    // ── Surfaces ──────────────────────────────────────────────────────────────
    /// #faf9f6 — warm off-white. App background throughout.
    static let appBackground         = Color(hex: "faf9f6")

    /// #f4f3f1 — surface-container-low. Size fact row background.
    static let surfaceContainerLow   = Color(hex: "f4f3f1")

    /// #dbdad7 — surface-dim. Hero placeholder, thumbnail placeholder.
    static let surfaceDim            = Color(hex: "dbdad7")

    /// #faf9f6 — surface-bright. Common name text overlaid on hero gradient.
    static let surfaceBright         = Color(hex: "faf9f6")

    // ── Primary greens ────────────────────────────────────────────────────────
    /// #23422a — deep forest green. Headings, icons, active nav tab.
    static let appPrimary            = Color(hex: "23422a")

    /// #406840 — mid green. iNat progress bar fill, active states.
    static let appSecondary          = Color(hex: "406840")

    /// #3a5a40 — primary-container. Deeper green for containers.
    static let primaryContainer      = Color(hex: "3a5a40")

    // ── Text ──────────────────────────────────────────────────────────────────
    /// #1a1c1a — near-black. Primary body text, on-surface.
    static let onSurface             = Color(hex: "1a1c1a")

    /// #424842 — muted body text. Fact values, about paragraph, on-surface-variant.
    static let onSurfaceVariant      = Color(hex: "424842")

    /// #727971 — section labels, source footer. outline.
    static let outline               = Color(hex: "727971")

    /// #c2c8bf — dividers, iNat bar track. outline-variant.
    static let outlineVariant        = Color(hex: "c2c8bf")

    // ── Hero name overlay ─────────────────────────────────────────────────────
    /// #abd0af — scientific name text overlaid on hero. primary-fixed-dim.
    static let primaryFixedDim       = Color(hex: "abd0af")

    /// #c7ecca — primary-fixed. Selection highlight.
    static let primaryFixed          = Color(hex: "c7ecca")

    // ── Venom / Error ─────────────────────────────────────────────────────────
    /// #ba1a1a — dangerous venom text and skull icon. error.
    static let appError              = Color(hex: "ba1a1a")

    /// #ffdad6 — venom row background tint. error-container.
    static let errorContainer        = Color(hex: "ffdad6")

    // ── Survey pills ──────────────────────────────────────────────────────────
    /// #beecb9 — survey pill background. secondary-container.
    static let secondaryContainer    = Color(hex: "beecb9")

    /// #446c44 — survey pill text. on-secondary-container.
    static let onSecondaryContainer  = Color(hex: "446c44")

    // ── Venom status colours (four-state system, Section 6.2) ─────────────────
    /// Red skull — dangerously venomous. Human fatalities recorded.
    static let venomDangerous        = Color(hex: "ba1a1a")

    /// Orange skull — mildly venomous. Side effects, no deaths.
    static let venomMild             = Color(hex: "C07820")

    /// Green skull — venomous, low risk. Minimal human effect.
    static let venomLowRisk          = Color(hex: "4A8A30")

    /// Green smiley — non-venomous.
    static let venomNone             = Color(hex: "406840")

    // ── IUCN colour groups (Section 6.2) ──────────────────────────────────────
    /// LC / NT — green
    static let iucnGreen             = Color(hex: "23422a")

    /// VU / EN — amber
    static let iucnAmber             = Color(hex: "C07820")

    /// CR / EW / EX — red
    static let iucnRed               = Color(hex: "ba1a1a")

    // ── Navigation ────────────────────────────────────────────────────────────
    /// Active nav tab colour — emerald-900 equivalent.
    static let navActive             = Color(hex: "23422a")

    /// Inactive / disabled nav tab — stone-300 equivalent.
    static let navInactive           = Color(hex: "b0afa8")

    // ── Bottom nav bar ────────────────────────────────────────────────────────
    /// Nav bar background — stone-50/70 equivalent (use with .ultraThinMaterial overlay).
    static let navBarBackground      = Color(hex: "faf9f6").opacity(0.7)
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Hex initialiser
// ─────────────────────────────────────────────────────────────────────────────

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255,
                            (int >> 8) * 17,
                            (int >> 4 & 0xF) * 17,
                            (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255,
                            int >> 16,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24,
                            int >> 16 & 0xFF,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:     Double(r) / 255,
            green:   Double(g) / 255,
            blue:    Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

