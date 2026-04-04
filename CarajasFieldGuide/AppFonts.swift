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
        .custom(AppFontName.manropeMedium, size: 28)
    }

    /// List screen title (e.g. "Carajás snakes"). Manrope Medium 36px.
    static var listTitle: Font {
        .custom(AppFontName.manropeMedium, size: 36)
    }

    /// IUCN badge text "(LC)". Manrope Bold 14px.
    static var iucnBadge: Font {
        .custom(AppFontName.manropeBold, size: 14)
    }

    // ── Body (Inter) ──────────────────────────────────────────────────────────

    /// Scientific name overlaid on hero. Inter Regular italic 14px.
    static var heroScientificName: Font {
        .custom(AppFontName.interRegular, size: 14)
    }

    /// Fact row value (size, habitat, IUCN full name). Inter Regular 14px.
    static var factValue: Font {
        .custom(AppFontName.interRegular, size: 14)
    }

    /// Venom status value. Inter SemiBold 14px.
    static var venomValue: Font {
        .custom(AppFontName.interSemiBold, size: 14)
    }

    /// About/description paragraph. Inter Regular 16px.
    static var bodyText: Font {
        .custom(AppFontName.interRegular, size: 16)
    }

    /// Venom type closing sentence. Inter Medium 16px.
    static var bodyMedium: Font {
        .custom(AppFontName.interMedium, size: 16)
    }

    /// iNat observation count. Inter SemiBold 14px.
    static var inatCount: Font {
        .custom(AppFontName.interSemiBold, size: 14)
    }

    /// Source footer text. Inter Regular 12px.
    static var sourceFooter: Font {
        .custom(AppFontName.interRegular, size: 12)
    }

    // ── Label (Inter uppercase) ───────────────────────────────────────────────

    /// Section header labels. Inter Regular 14px uppercase.
    static var sectionLabel: Font {
        .custom(AppFontName.interRegular, size: 14)
    }

    /// Fact row left label. Inter Regular 14px uppercase.
    static var factLabel: Font {
        .custom(AppFontName.interRegular, size: 14)
    }

    /// Survey pill text. Inter SemiBold 14px.
    static var surveyPill: Font {
        .custom(AppFontName.interSemiBold, size: 14)
    }

    /// Nav tab label. Inter Regular 9px uppercase.
    static var navLabel: Font {
        .custom(AppFontName.interRegular, size: 9)
    }

    /// List row species name. Inter Medium 16px.
    static var listSpeciesName: Font {
        .custom(AppFontName.interMedium, size: 16)
    }

    /// List row scientific name. Inter Regular 12px italic.
    static var listScientificName: Font {
        .custom(AppFontName.interRegular, size: 12)
    }

    /// List subtitle (species count). Inter Regular 12px.
    static var listSubtitle: Font {
        .custom(AppFontName.interRegular, size: 12)
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
