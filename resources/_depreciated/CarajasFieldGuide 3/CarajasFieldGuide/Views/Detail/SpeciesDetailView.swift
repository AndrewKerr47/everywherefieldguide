import SwiftUI
import SafariServices

// ─────────────────────────────────────────────────────────────────────────────
// SpeciesDetailView.swift
// Carajás Field Guide
//
// The core species detail screen. Built exactly to the locked HTML/Tailwind
// reference in MasterDoc v0.3 Section 7.
//
// Screen anatomy (Section 6.2):
//   1. Fixed back button overlaid on hero
//   2. Full-bleed hero image — 353pt, hard cut, names overlaid on gradient
//   3. Quick facts — venom, size, habitat, IUCN (vertically stacked rows)
//   4. About section — description + venom closing sentence
//   5. Survey presence — tappable pills → SFSafariViewController
//   6. iNaturalist visibility — progress bar
//   7. Source footer
//
// Null handling: every section is conditionally rendered.
// If all fields in a section are nil, the section is not rendered at all.
// ─────────────────────────────────────────────────────────────────────────────

struct SpeciesDetailView: View {

    let species: Species
    let store: SpeciesStore

    @Environment(\.dismiss) private var dismiss
    @State private var safariURL: URL? = nil
    @State private var showSafari = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── 1. Hero image with names overlaid ─────────────────────
                    HeroImageView(
                        imageURL: species.inatImageURL,
                        commonName: species.displayName,
                        scientificName: species.scientificName
                    )

                    // ── Content canvas ────────────────────────────────────────
                    // HTML ref: px-6 pt-8 pb-32 max-w-2xl mx-auto
                    VStack(alignment: .leading, spacing: 0) {

                        // ── 2. Quick facts ────────────────────────────────────
                        if species.hasQuickFacts {
                            QuickFactsView(species: species)
                                .padding(.bottom, AppSpacing.sectionMargin)
                        }

                        // ── 3. About ──────────────────────────────────────────
                        if species.aboutText != nil || species.venomClosingSentence != nil {
                            AboutSectionView(species: species)
                                .padding(.bottom, AppSpacing.sectionMargin)
                        }

                        // ── 4. Survey presence ────────────────────────────────
                        if let surveys = species.surveyPresence, !surveys.isEmpty {
                            SurveyPresenceView(surveys: surveys) { url in
                                safariURL = url
                                showSafari = true
                            }
                            .padding(.bottom, AppSpacing.sectionMargin)
                        }

                        // ── 5. iNaturalist visibility ─────────────────────────
                        if species.inatObservations != nil {
                            iNatVisibilityView(
                                species: species,
                                store: store
                            )
                            .padding(.bottom, 48)
                        }

                        // ── 6. Source footer ──────────────────────────────────
                        if let source = species.sourceNotes {
                            SourceFooterView(text: source)
                        }

                        // Safe area clearance for nav bar
                        Spacer().frame(height: AppSpacing.contentBottomPadding)
                    }
                    .padding(.horizontal, AppSpacing.pagePadding)
                    .padding(.top, AppSpacing.contentTopPadding)
                }
            }
            .ignoresSafeArea(edges: .top)

            // ── Back button — overlaid on hero ────────────────────────────────
            // HTML ref: fixed top-0 left-0 px-6 py-4
            //   button: w-10 h-10 rounded-full bg-stone-50/20 backdrop-blur-md
            BackButtonView { dismiss() }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showSafari) {
            if let url = safariURL {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 1. Hero image
// ─────────────────────────────────────────────────────────────────────────────
// HTML ref:
//   <section class="w-full h-[353px] relative overflow-hidden bg-surface-dim">
//   <img class="w-full h-full object-cover" />
//   gradient: absolute inset-x-0 bottom-0 h-64 bg-gradient-to-t from-black/70
//   name block: absolute bottom-6 left-6 right-6
//     h1: font-headline font-medium text-[21px] text-surface-bright
//     p:  font-body italic text-[11px] text-primary-fixed-dim

struct HeroImageView: View {

    let imageURL: String?
    let commonName: String
    let scientificName: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {

            // ── Image ─────────────────────────────────────────────────────────
            Group {
                if let urlString = imageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure, .empty:
                            Color.surfaceDim
                        @unknown default:
                            Color.surfaceDim
                        }
                    }
                } else {
                    Color.surfaceDim
                }
            }
            .frame(width: UIScreen.main.bounds.width,
                   height: AppSpacing.heroHeight)
            .clipped()

            // ── Gradient overlay for name legibility ──────────────────────────
            // HTML ref: h-64 bg-gradient-to-t from-black/70 to-transparent
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.70), location: 0),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 220)

            // ── Name block ────────────────────────────────────────────────────
            // HTML ref: absolute bottom-6 left-6 right-6
            VStack(alignment: .leading, spacing: 2) {
                Text(commonName)
                    .font(.heroCommonName)
                    .foregroundColor(.surfaceBright)
                    .lineLimit(2)

                Text(scientificName)
                    .font(.heroScientificName)
                    .italic()
                    .foregroundColor(.primaryFixedDim)
            }
            .padding(.horizontal, AppSpacing.pagePadding)
            .padding(.bottom, 24) // bottom-6 = 24pt
        }
        .frame(height: AppSpacing.heroHeight)
        .clipped()
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Back button
// ─────────────────────────────────────────────────────────────────────────────
// HTML ref:
//   header fixed top-0 px-6 py-4
//   button: w-10 h-10 rounded-full bg-stone-50/20 backdrop-blur-md text-stone-50

struct BackButtonView: View {

    let action: () -> Void

    var body: some View {
        VStack {
            HStack {
                Button(action: action) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 40, height: 40)
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, AppSpacing.pagePadding)
            .padding(.top, 4) // just inside the dynamic island safe area
            Spacer()
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 2. Quick facts
// ─────────────────────────────────────────────────────────────────────────────
// HTML ref: space-y-4 mb-10
// Each row: flex justify-between py-1 px-3 rounded-sm

struct QuickFactsView: View {

    let species: Species

    var body: some View {
        VStack(spacing: AppSpacing.factRowGap) {

            // ── Venom ─────────────────────────────────────────────────────────
            // HTML ref: bg-error-container/10, skull icon FILL=1, text-error
            if let venom = species.venomStatus {
                FactRowView(
                    background: venom.rowBackground
                ) {
                    HStack(spacing: 12) {
                        Image("icon_skull")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .foregroundColor(venom.color)
                        Text("Venom status")
                            .font(.factLabel)
                            .textCase(.uppercase)
                            .tracking(1.0)
                            .foregroundColor(.onSurface)
                        Spacer()
                        Text(venom.label)
                            .font(.venomValue)
                            .foregroundColor(venom.color)
                    }
                }
            }

            // ── Size ──────────────────────────────────────────────────────────
            // HTML ref: bg-surface-container-low, straighten icon
            if let size = species.sizeDisplay {
                FactRowView(background: .clear) {
                    HStack(spacing: 12) {
                        Image("icon_ruler")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .foregroundColor(.appPrimary)
                        Text("Size")
                            .font(.factLabel)
                            .textCase(.uppercase)
                            .tracking(1.0)
                            .foregroundColor(.onSurface)
                        Spacer()
                        Text(size)
                            .font(.factValue)
                            .foregroundColor(.onSurfaceVariant)
                    }
                }
            }

            // ── Habitat ───────────────────────────────────────────────────────
            // HTML ref: no background, terrain icon
            if let habitat = species.habitatDisplay {
                FactRowView(background: .clear) {
                    HStack(spacing: 12) {
                        Image("icon_habitat")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .foregroundColor(.appPrimary)
                        Text("Habitat")
                            .font(.factLabel)
                            .textCase(.uppercase)
                            .tracking(1.0)
                            .foregroundColor(.onSurface)
                        Spacer()
                        Text(habitat)
                            .font(.factValue)
                            .foregroundColor(.onSurfaceVariant)
                    }
                }
            }

            // ── IUCN ──────────────────────────────────────────────────────────
            // HTML ref: bg-surface-container-low/50
            //   (LC) font-headline font-bold text-[12px] text-primary
            if let iucn = species.iucnStatus {
                FactRowView(background: .clear) {
                    HStack(spacing: 12) {
                        Image("icon_IUCN")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .foregroundColor(iucn.color)
                        Text("IUCN Status")
                            .font(.factLabel)
                            .textCase(.uppercase)
                            .tracking(1.0)
                            .foregroundColor(.onSurface)
                        Spacer()
                        Text(iucn.label)
                            .font(.factValue)
                            .foregroundColor(.onSurfaceVariant)
                    }
                }
            }
        }
    }
}

// ── Fact row container ────────────────────────────────────────────────────────
// HTML ref: flex justify-between py-1 px-3 rounded-sm {bg}

struct FactRowView<Content: View>: View {

    let background: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(.vertical, 4)   // py-1
            .padding(.horizontal, 12) // px-3
            .background(background)
            .cornerRadius(AppRadius.small) // rounded-sm = 2pt
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 3. About section
// ─────────────────────────────────────────────────────────────────────────────
// HTML ref:
//   <article class="mb-10">
//   <p class="font-body text-[12px] leading-[1.65] text-on-surface-variant">
//   <p class="font-body text-[12px] font-medium">Hemotoxic venom.</p>

struct AboutSectionView: View {

    let species: Species

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let description = species.aboutText {
                Text(description)
                    .font(.bodyText)
                    .foregroundColor(.onSurfaceVariant)
                    .lineSpacing(4) // approximates leading-[1.65]
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let closing = species.venomClosingSentence {
                Text(closing)
                    .font(.bodyMedium)
                    .foregroundColor(.onSurfaceVariant)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 4. Survey presence
// ─────────────────────────────────────────────────────────────────────────────
// HTML ref:
//   <h3 class="font-label text-[9px] uppercase tracking-widest text-outline mb-4">
//   <a class="px-3 py-1 rounded-full bg-secondary-container
//             text-on-secondary-container font-label text-[9px] font-semibold
//             hover:opacity-80">

struct SurveyPresenceView: View {

    let surveys: [Survey]
    let onTap: (URL) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.labelMargin) {

            Text("Survey Presence")
                .sectionLabelStyle()

            SurveyPillsFlow(surveys: surveys, onTap: onTap)
        }
    }
}

struct SurveyPillView: View {

    let survey: Survey
    let onTap: (URL) -> Void

    var body: some View {
        Button {
            if let url = survey.resolvedURL {
                onTap(url)
            }
        } label: {
            HStack(spacing: 4) {
                Text(survey.name)
                    .font(.surveyPill)
                    .textCase(.none)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 8, weight: .semibold))
            }
            // HTML ref: px-3 py-1 rounded-full bg-secondary-container text-on-secondary-container
            .padding(.vertical, 4)   // py-1
            .padding(.horizontal, 12) // px-3
            .background(Color.secondaryContainer)
            .foregroundColor(.onSecondaryContainer)
            .cornerRadius(AppRadius.pill) // rounded-full
        }
        .buttonStyle(.plain)
        .opacity(survey.resolvedURL == nil ? 0.5 : 1.0)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 5. iNaturalist visibility
// ─────────────────────────────────────────────────────────────────────────────
// HTML ref:
//   flex justify-between items-end mb-2
//   <h3 font-label 9px uppercase tracking-widest text-outline>
//   <span font-body 11px font-semibold text-primary> N observations
//   progress bar: w-full h-[3px] bg-outline-variant/20, fill bg-secondary

struct iNatVisibilityView: View {

    let species: Species
    let store: SpeciesStore

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.labelMargin) {

            // Label + count
            HStack(alignment: .lastTextBaseline) {
                Text("iNaturalist Visibility")
                    .sectionLabelStyle()
                Spacer()
                if let count = species.inatObservations {
                    Text("\(count.formatted()) observations")
                        .font(.inatCount)
                        .foregroundColor(.appPrimary)
                }
            }

            // Progress bar
            // HTML ref: w-full h-[3px] bg-outline-variant/20 rounded-full overflow-hidden
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.outlineVariant.opacity(0.20))
                        .frame(height: 3)

                    // Fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.appSecondary)
                        .frame(
                            width: geo.size.width * store.observationProgress(for: species),
                            height: 3
                        )
                }
            }
            .frame(height: 3)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 6. Source footer
// ─────────────────────────────────────────────────────────────────────────────
// HTML ref:
//   <footer class="pt-6 border-t border-outline-variant/15">
//   <p class="font-body text-[10px] text-outline leading-relaxed">

struct SourceFooterView: View {

    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hairline divider
            // HTML ref: border-t border-outline-variant/15
            Rectangle()
                .fill(Color.outlineVariant.opacity(0.15))
                .frame(height: 0.5)
                .padding(.bottom, 24) // pt-6

            Text(text)
                .font(.sourceFooter)
                .foregroundColor(.outline)
                .lineSpacing(3) // leading-relaxed
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Flow layout for survey pills
// ─────────────────────────────────────────────────────────────────────────────
// Reliable wrapping layout using iOS 16+ Layout protocol.
// Wraps pill views to multiple rows as needed.

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Flow layout for survey pills
// ─────────────────────────────────────────────────────────────────────────────
// Uses a ViewThatFits-safe approach: renders pills in a simple wrapping
// VStack of HStacks. Heights are explicit so ScrollView renders correctly.

struct SurveyPillsFlow: View {

    let surveys: [Survey]
    let onTap: (URL) -> Void

    var body: some View {
        // Simple approach: one HStack per row, calculated from estimated widths.
        // This is scroll-view safe because all frames are explicit — no GeometryReader.
        let rows = buildRows(surveys: surveys, availableWidth: UIScreen.main.bounds.width - 48)

        VStack(alignment: .leading, spacing: 8) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 8) {
                    ForEach(rows[rowIndex]) { survey in
                        SurveyPillView(survey: survey, onTap: onTap)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func buildRows(surveys: [Survey], availableWidth: CGFloat) -> [[Survey]] {
        var rows: [[Survey]] = [[]]
        var currentRowWidth: CGFloat = 0
        let spacing: CGFloat = 8

        for survey in surveys {
            // Estimate pill width: ~7pt per character + 40pt padding + arrow icon
            let pillWidth = CGFloat(survey.name.count) * 7.5 + 48
            if currentRowWidth + pillWidth + spacing > availableWidth,
               !rows[rows.count - 1].isEmpty {
                rows.append([])
                currentRowWidth = 0
            }
            rows[rows.count - 1].append(survey)
            currentRowWidth += pillWidth + spacing
        }
        return rows
    }
}

// Keep WrappingHStack stub so no other references break
struct WrappingHStack<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content
    var body: some View { content() }
}

extension View {
    @ViewBuilder
    func _flowLayout(hSpacing: CGFloat, vSpacing: CGFloat) -> some View { self }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Safari view wrapper
// ─────────────────────────────────────────────────────────────────────────────

struct SafariView: UIViewControllerRepresentable {

    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
