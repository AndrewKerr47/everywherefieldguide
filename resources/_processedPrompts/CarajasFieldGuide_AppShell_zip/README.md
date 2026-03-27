# Carajás Field Guide — Prompt 01 Output

## Project scaffold — SwiftUI iPhone app

MasterDoc v0.3 · Prompt 01 · Project Setup & App Shell

---

## Folder structure

```
CarajasFieldGuide/
├── CarajasFieldGuideApp.swift     App entry point, global UIKit appearance
├── ContentView.swift              Root TabView — 3 tabs (Home active, Guides + Explore disabled)
├── AppColors.swift                All design token colours (Section 6.1)
├── AppFonts.swift                 Manrope + Inter font extensions
├── AppTheme.swift                 Spacing constants, radius values, shared ViewModifiers
├── Info.plist                     Font registration, ATS config, orientation lock
│
├── Models/                        ← Prompt 02: Species, Survey, VenomStatus, IUCNStatus
├── ViewModels/                    ← Prompt 02+: SpeciesStore, SearchViewModel
├── Resources/
│   └── Fonts/                     ← ADD FONT FILES HERE (see below)
│       ├── Manrope-Medium.ttf
│       ├── Manrope-Bold.ttf
│       ├── Manrope-ExtraBold.ttf
│       ├── Inter-Regular.ttf
│       ├── Inter-Medium.ttf
│       └── Inter-SemiBold.ttf
│
└── Views/
    ├── List/
    │   └── HomeView.swift          NavigationStack root + placeholder
    ├── Detail/                     ← Prompt 04: SpeciesDetailView and components
    └── About/                      ← Prompt 08: AboutView
```

---

## Required setup steps in Xcode

### 1. Create the Xcode project

- Product Name: `CarajasFieldGuide`
- Team: your development team
- Organization Identifier: your reverse domain
- Interface: SwiftUI
- Language: Swift
- Minimum deployment: iOS 17.0

### 2. Add source files

Copy all `.swift` files and `Info.plist` into the Xcode project, maintaining the folder structure above. Ensure each file has Target Membership checked for `CarajasFieldGuide`.

### 3. Download and add fonts

**Manrope** — https://fonts.google.com/specimen/Manrope
Download and add to `Resources/Fonts/`:
- `Manrope-Medium.ttf`
- `Manrope-Bold.ttf`
- `Manrope-ExtraBold.ttf`

**Inter** — https://fonts.google.com/specimen/Inter
Download and add to `Resources/Fonts/`:
- `Inter-Regular.ttf`
- `Inter-Medium.ttf`
- `Inter-SemiBold.ttf`

For each font file:
- Drag into Xcode project under `Resources/Fonts/`
- In the file inspector: check ✓ Target Membership → CarajasFieldGuide
- In `Info.plist`, confirm each filename is listed under `UIAppFonts` (already done)

### 4. Verify font registration

Run the app and add this temporary debug snippet to `CarajasFieldGuideApp.init()`:

```swift
for family in UIFont.familyNames.sorted() {
    print("Family: \(family)")
    for name in UIFont.fontNames(forFamilyName: family) {
        print("  Font: \(name)")
    }
}
```

You should see `Manrope` and `Inter` families with the registered weights.

### 5. Accent colour

In `Assets.xcassets`, set the `AccentColor` to `#23422a` (appPrimary) for the launch screen background.

---

## Design tokens loaded

All colour tokens from Section 6.1 are available as `Color` extensions:

| Token | Usage |
|---|---|
| `.appBackground` | `#faf9f6` — all screen backgrounds |
| `.appPrimary` | `#23422a` — active nav, headings |
| `.appSecondary` | `#406840` — iNat bar fill |
| `.onSurface` | `#1a1c1a` — primary text |
| `.onSurfaceVariant` | `#424842` — body / fact values |
| `.outline` | `#727971` — section labels |
| `.outlineVariant` | `#c2c8bf` — dividers, bar track |
| `.appError` | `#ba1a1a` — dangerous venom |
| `.errorContainer` | `#ffdad6` — venom row bg tint |
| `.secondaryContainer` | `#beecb9` — survey pill bg |
| `.onSecondaryContainer` | `#446c44` — survey pill text |
| `.primaryFixedDim` | `#abd0af` — sci name on hero |
| `.venomDangerous` | `#ba1a1a` — red skull |
| `.venomMild` | `#C07820` — orange skull |
| `.venomLowRisk` | `#4A8A30` — green skull |
| `.iucnAmber` | `#C07820` — VU/EN |
| `.iucnRed` | `#ba1a1a` — CR/EW/EX |

---

## Navigation architecture

```
ContentView (custom TabView overlay)
├── Tab: Home     [ACTIVE]  → HomeView → NavigationStack
│                                └── SpeciesListView (Prompt 03)
│                                    └── SpeciesDetailView (Prompt 04)
├── Tab: Guides   [DISABLED, opacity 0.4]  Future: multi-taxon guidebook list
└── Tab: Explore  [DISABLED, opacity 0.4]  Future: multi-region selector
```

---

## Next prompt

Issue **Prompt 02 — Species Data Model & JSON Loading** to build:
- `Species.swift`
- `Survey.swift`
- `VenomStatus.swift` enum
- `IUCNStatus.swift` enum
- `SpeciesStore.swift`
- `species.json` sample dataset
