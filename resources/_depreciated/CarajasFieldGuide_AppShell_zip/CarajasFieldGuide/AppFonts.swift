import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// AppFonts.swift
// Carajás Field Guide
//
// Manrope (headline) and Inter (body/label) font system.
// Sourced from MasterDoc v0.3 Section 6.1 and the locked HTML reference.
//
// SETUP REQUIRED:
// 1. Download font files and add to Xcode project under Resources/Fonts/
// 2. Register all font files in Info.plist under "Fonts provided by application"
//
// Manrope files required:
//   Manrope-Medium.ttf     (weight 500)
//   Manrope-Bold.ttf       (weight 700)
//   Manrope-ExtraBold.ttf  (weight 800)
//
// Inter files required:
//   Inter-Regular.ttf      (weight 400)
//   Inter-Medium.ttf       (weight 500)
//   Inter-SemiBold.ttf     (weight 600)
//
// Font download: https://fonts.google.com/specimen/Manrope
//                https://fonts.google.com/specimen/Inter
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Font name constants
// ─────────────────────────────────────────────────────────────────────────────

enum AppFontName {
    // Manrope — used for species common name in hero and list screen title
    static let manropeMedium    = "Manrope-Medium"
    static let manropeBold      = "Manrope-Bold"
    static let manropeExtraBold = "Manrope-ExtraBold"

    // Inter — used for all body text, labels, values, section headers
    static let interRegular     = "Inter-Regular"
    static let interMedium      = "Inter-Medium"
    static let interSemiBold    = "Inter-SemiBold"
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Font extensions
// ─────────────────────────────────────────────────────────────────────────────

extension Font {

    // ── Headline (Manrope) ────────────────────────────────────────────────────

    /// Common name overlaid on hero image. Manrope Medium 21px.
    /// HTML ref: font-headline font-medium text-[21px]
    static var heroCommonName: Font {
        .custom(AppFontName.manropeMedium, size: 21)
    }

    /// List screen title (e.g. "Carajás snakes"). Manrope Medium 18px.
    static var listTitle: Font {
        .custom(AppFontName.manropeMedium, size: 18)
    }

    /// IUCN badge text "(LC)". Manrope Bold 12px.
    /// HTML ref: font-headline font-bold text-[12px]
    static var iucnBadge: Font {
        .custom(AppFontName.manropeBold, size: 12)
    }

    // ── Body (Inter) ──────────────────────────────────────────────────────────

    /// Scientific name overlaid on hero. Inter Regular italic 11px.
    /// HTML ref: font-body italic text-[11px]
    static var heroScientificName: Font {
        .custom(AppFontName.interRegular, size: 11)
    }

    /// Fact row value (size, habitat, IUCN full name). Inter Regular 12px.
    /// HTML ref: font-body text-[12px]
    static var factValue: Font {
        .custom(AppFontName.interRegular, size: 12)
    }

    /// Venom status value. Inter SemiBold 12px.
    /// HTML ref: font-body text-[12px] font-semibold
    static var venomValue: Font {
        .custom(AppFontName.interSemiBold, size: 12)
    }

    /// About/description paragraph. Inter Regular 12px, line height 1.65.
    /// HTML ref: font-body text-[12px] leading-[1.65]
    static var bodyText: Font {
        .custom(AppFontName.interRegular, size: 12)
    }

    /// Venom type closing sentence. Inter Medium 12px.
    /// HTML ref: font-body text-[12px] font-medium
    static var bodyMedium: Font {
        .custom(AppFontName.interMedium, size: 12)
    }

    /// iNat observation count. Inter SemiBold 11px.
    /// HTML ref: font-body text-[11px] font-semibold
    static var inatCount: Font {
        .custom(AppFontName.interSemiBold, size: 11)
    }

    /// Source footer text. Inter Regular 10px.
    /// HTML ref: font-body text-[10px]
    static var sourceFooter: Font {
        .custom(AppFontName.interRegular, size: 10)
    }

    // ── Label (Inter uppercase) ───────────────────────────────────────────────

    /// Section header labels (SURVEY PRESENCE, iNATURALIST VISIBILITY etc).
    /// Inter Regular 9px — use with .textCase(.uppercase) and tracking 0.07em.
    /// HTML ref: font-label text-[9px] uppercase tracking-widest
    static var sectionLabel: Font {
        .custom(AppFontName.interRegular, size: 9)
    }

    /// Fact row left label (VENOM STATUS, SIZE, HABITAT, IUCN STATUS).
    /// Inter Regular 9px uppercase.
    /// HTML ref: font-label text-[9px] uppercase tracking-widest
    static var factLabel: Font {
        .custom(AppFontName.interRegular, size: 9)
    }

    /// Survey pill text. Inter SemiBold 9px.
    /// HTML ref: font-label text-[9px] font-semibold
    static var surveyPill: Font {
        .custom(AppFontName.interSemiBold, size: 9)
    }

    /// Nav tab label. Inter Regular 9px uppercase.
    static var navLabel: Font {
        .custom(AppFontName.interRegular, size: 9)
    }

    /// List row species name. Inter Medium 13px.
    static var listSpeciesName: Font {
        .custom(AppFontName.interMedium, size: 13)
    }

    /// List row scientific name. Inter Regular 10px italic.
    static var listScientificName: Font {
        .custom(AppFontName.interRegular, size: 10)
    }

    /// List subtitle (species count). Inter Regular 10px.
    static var listSubtitle: Font {
        .custom(AppFontName.interRegular, size: 10)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Letter spacing helper
// ─────────────────────────────────────────────────────────────────────────────

extension View {
    /// Applies tracking equivalent to Tailwind's tracking-widest (~0.1em at 9px = ~1pt).
    func labelTracking() -> some View {
        self.tracking(1.0)
    }
}
