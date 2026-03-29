import SwiftUI
import SafariServices

// ─────────────────────────────────────────────────────────────────────────────
// SpeciesDetailView.swift
// Carajás Field Guide
// ─────────────────────────────────────────────────────────────────────────────

struct SpeciesDetailView: View {

    let species: Species
    let store: SpeciesStore

    @Environment(\.dismiss) private var dismiss
    @Environment(SeenSpeciesStore.self) private var seenStore
    @State private var safariURL: URL? = nil
    @State private var showSafari = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── 1. Hero image with names overlaid ─────────────────────
                    HeroImageView(
                        scientificName: species.scientificName,
                        imageURL: species.inatImageURL,
                        commonName: species.displayName,
                        portugueseName: species.localName,
                        isSeen: seenStore.isSeen(species.scientificName),
                        onToggleSeen: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                seenStore.toggle(species.scientificName)
                            }
                        }
                    )

                    // ── Content canvas ────────────────────────────────────────
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

                        // ── 6. Image credit ───────────────────────────────────
                        if let creditLine = species.creditLine, !creditLine.isEmpty {
                            ImageCreditView(
                                creditLine: creditLine,
                                observerURL: species.observerURL,
                                licenceLabel: species.licenceLabel,
                                licenceURL: species.licenceURL,
                                sourceURL: species.sourceURL
                            ) { url in
                                safariURL = url
                                showSafari = true
                            }
                            .padding(.bottom, AppSpacing.sectionMargin)
                        }

                        // ── 7. Source footer ──────────────────────────────────
                        if let source = species.sourceNotes {
                            SourceFooterView(text: source)
                        }

                        Spacer().frame(height: AppSpacing.contentBottomPadding)
                    }
                    .padding(.horizontal, AppSpacing.pagePadding)
                    .padding(.top, AppSpacing.contentTopPadding)
                }
            }
            .ignoresSafeArea(edges: .top)

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

struct HeroImageView: View {

    let scientificName: String
    let imageURL: String?
    let commonName: String
    let portugueseName: String?
    let isSeen: Bool
    let onToggleSeen: () -> Void

    @AppStorage("showPortugueseNames") private var showPortugueseNames = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {

            // ── Image ─────────────────────────────────────────────────────────
            CachedSpeciesImage(
                scientificName: scientificName,
                remoteURL: imageURL,
                contentMode: .fill
            )
            .frame(width: UIScreen.main.bounds.width,
                   height: AppSpacing.heroHeight)
            .clipped()

            // ── Gradient overlay ──────────────────────────────────────────────
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.70), location: 0),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 220)

            // ── Name block + seen toggle ──────────────────────────────────────
            HStack(alignment: .bottom, spacing: 12) {

                VStack(alignment: .leading, spacing: 2) {
                    Text(commonName)
                        .font(.heroCommonName)
                        .foregroundColor(.surfaceBright)
                        .lineLimit(2)

                    if showPortugueseNames, let ptName = portugueseName {
                        Text(ptName)
                            .font(.heroScientificName)
                            .foregroundColor(.appSecondary)
                            .lineLimit(1)
                    }

                    Text(scientificName)
                        .font(.heroScientificName)
                        .italic()
                        .foregroundColor(.primaryFixedDim)
                }

                Spacer()

                // ── Seen toggle ───────────────────────────────────────────────
                Button(action: onToggleSeen) {
                    SeenToggleIcon(isSeen: isSeen)
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.2), value: isSeen)
            }
            .padding(.horizontal, AppSpacing.pagePadding)
            .padding(.bottom, 24)
        }
        .frame(height: AppSpacing.heroHeight)
        .clipped()
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Back button
// ─────────────────────────────────────────────────────────────────────────────

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
            .padding(.top, 4)
            Spacer()
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 2. Quick facts
// ─────────────────────────────────────────────────────────────────────────────

struct QuickFactsView: View {

    let species: Species

    var body: some View {
        VStack(spacing: AppSpacing.factRowGap) {

            // ── Venom ─────────────────────────────────────────────────────────
            if let venom = species.venomStatus {
                FactRowView(background: venom.rowBackground) {
                    HStack(spacing: 12) {
                        Group {
                            if venom == .nonVenomous {
                                Image("icon_smile")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                            } else {
                                Image("icon_skull")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                            }
                        }
                        .frame(width: 28, height: 28)
                        .foregroundColor(venom.color)

                        Text("Venom")
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

struct FactRowView<Content: View>: View {

    let background: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(.vertical, 4)
            .padding(.horizontal, 12)
            .background(background)
            .cornerRadius(AppRadius.small)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 3. About section
// ─────────────────────────────────────────────────────────────────────────────

struct AboutSectionView: View {

    let species: Species

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let description = species.aboutText {
                Text(description)
                    .font(.bodyText)
                    .foregroundColor(.onSurfaceVariant)
                    .lineSpacing(4)
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
            .padding(.vertical, 4)
            .padding(.horizontal, 12)
            .background(Color.secondaryContainer)
            .foregroundColor(.onSecondaryContainer)
            .cornerRadius(AppRadius.pill)
        }
        .buttonStyle(.plain)
        .opacity(survey.resolvedURL == nil ? 0.5 : 1.0)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 5. iNaturalist visibility
// ─────────────────────────────────────────────────────────────────────────────

struct iNatVisibilityView: View {

    let species: Species
    let store: SpeciesStore

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.labelMargin) {

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

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.outlineVariant.opacity(0.20))
                        .frame(height: 3)
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
// MARK: - 6. Image credit
// ─────────────────────────────────────────────────────────────────────────────

struct ImageCreditView: View {

    let creditLine: String
    let observerURL: String?
    let licenceLabel: String?
    let licenceURL: String?
    let sourceURL: String?
    let onTap: (URL) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            Text("Image credit")
                .sectionLabelStyle()

            HStack(alignment: .top, spacing: 0) {
                // Credit text — tappable if observer URL exists
                if let urlString = observerURL, let url = URL(string: urlString) {
                    Button {
                        onTap(url)
                    } label: {
                        Text(creditLine)
                            .font(.sourceFooter)
                            .foregroundColor(.outline)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(creditLine)
                        .font(.sourceFooter)
                        .foregroundColor(.outline)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                // Licence badge — tappable if licence URL exists
                if let lbl = licenceLabel, !lbl.isEmpty {
                    let badge = licenceBadge(lbl)
                    if let urlString = licenceURL, let url = URL(string: urlString) {
                        Button {
                            onTap(url)
                        } label: {
                            badge
                        }
                        .buttonStyle(.plain)
                    } else {
                        badge
                    }
                }
            }
        }
    }

    // Small pill showing the licence code
    private func licenceBadge(_ label: String) -> some View {
        Text(label)
            .font(.custom("Inter_18pt-Regular", size: 9))
            .foregroundColor(.onSecondaryContainer)
            .kerning(0.5)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.secondaryContainer)
            .clipShape(Capsule())
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 7. Source footer
// ─────────────────────────────────────────────────────────────────────────────

struct SourceFooterView: View {

    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Color.outlineVariant.opacity(0.15))
                .frame(height: 0.5)
                .padding(.bottom, 24)
            Text(text)
                .font(.sourceFooter)
                .foregroundColor(.outline)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Flow layout for survey pills
// ─────────────────────────────────────────────────────────────────────────────

struct SurveyPillsFlow: View {

    let surveys: [Survey]
    let onTap: (URL) -> Void

    var body: some View {
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
