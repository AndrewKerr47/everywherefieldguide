import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// AppTheme.swift
// Carajás Field Guide
//
// Spacing constants, border radii, and shared ViewModifiers.
// All values derived from the locked HTML/Tailwind reference (Section 7).
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Spacing & sizing constants
// ─────────────────────────────────────────────────────────────────────────────

enum AppSpacing {
    /// px-6 in Tailwind = 24pt horizontal page margin
    static let pagePadding: CGFloat     = 24
    /// pt-8 = 32pt top padding on content canvas
    static let contentTopPadding: CGFloat = 32
    /// pb-32 = 128pt bottom padding (clears fixed nav bar)
    static let contentBottomPadding: CGFloat = 128
    /// gap-2 = 8pt gap between survey pills
    static let pillGap: CGFloat         = 8
    /// space-y-4 = 16pt between fact rows
    static let factRowGap: CGFloat      = 16
    /// mb-10 = 40pt section bottom margin
    static let sectionMargin: CGFloat   = 40
    /// mb-4 = 16pt label bottom margin
    static let labelMargin: CGFloat     = 16
    /// Hero image height
    static let heroHeight: CGFloat      = 353
    /// List thumbnail size
    static let thumbnailSize: CGFloat   = 44
    /// Thumbnail corner radius (rounded-lg = 0.25rem ≈ 4pt)
    static let thumbnailRadius: CGFloat = 8
}

enum AppRadius {
    /// DEFAULT = 0.125rem ≈ 2pt — used on fact rows (rounded-sm)
    static let small: CGFloat  = 2
    /// lg = 0.25rem ≈ 4pt
    static let medium: CGFloat = 4
    /// xl = 0.5rem ≈ 8pt
    static let large: CGFloat  = 8
    /// full = 0.75rem ≈ 12pt — survey pills (rounded-full)
    static let pill: CGFloat   = 12
    /// Back button circle
    static let circle: CGFloat = 20
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Section label modifier
// ─────────────────────────────────────────────────────────────────────────────

/// Reusable section label style.
/// HTML ref: font-label text-[9px] uppercase tracking-widest text-outline
struct SectionLabelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.sectionLabel)
            .textCase(.uppercase)
            .tracking(1.0)
            .foregroundColor(.outline)
    }
}

extension View {
    func sectionLabelStyle() -> some View {
        modifier(SectionLabelStyle())
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Fact row modifier
// ─────────────────────────────────────────────────────────────────────────────

/// Applies the standard fact row container style.
/// HTML ref: flex justify-between py-1 px-3 rounded-sm {optional bg}
struct FactRowStyle: ViewModifier {
    var background: Color

    func body(content: Content) -> some View {
        content
            .padding(.vertical, 4)   // py-1
            .padding(.horizontal, 12) // px-3
            .background(background)
            .cornerRadius(AppRadius.small)
    }
}

extension View {
    func factRowStyle(background: Color = .clear) -> some View {
        modifier(FactRowStyle(background: background))
    }
}
