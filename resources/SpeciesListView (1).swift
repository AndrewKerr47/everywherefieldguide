import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// SpeciesListView.swift
// Carajás Field Guide
//
// Species list with full-bleed banner header, search, and collapsible
// survey filter panel.
//
// Filter UX:
//   - Filter icon sits on the right of the search bar
//   - Tapping it slides/fades a panel open below the search bar
//   - Panel shows filter options, each with an independent species count
//   - Active filters tint the filter icon to signal filters are applied
//   - Filters compose with text search
//
// Filter IDs:
//   "CN-1985"        → Cunha et al. 1985
//   "UFSC-2023"      → CNF Herpetofauna Survey 2015–2023
//   "inat"           → iNaturalist (sightings in Carajás bounding box)
//   "seen"           → Seen species
//   "needs_credit"   → Needs image credit (DEBUG only — hidden in release)
// ─────────────────────────────────────────────────────────────────────────────

struct SpeciesListView: View {

    let store: SpeciesStore

    @State private var searchText     = ""
    @State private var activeFilters: Set<String> = ["CN-1985", "UFSC-2023", "inat"]
    @AppStorage("showPortugueseNames") private var showPortugueseNames = false
    @Environment(SeenSpeciesStore.self) private var seenStore
    @State private var showFilters    = false

    // ── Filter definitions ────────────────────────────────────────────────────

    private var filterDefs: [(id: String, label: String)] {
        var defs: [(id: String, label: String)] = [
            ("CN-1985",   "Cunha et al. 1985"),
            ("UFSC-2023", "CNF Herpetofauna Survey 2015–2023"),
            ("inat",      "iNaturalist"),
            ("seen",      "Seen"),
        ]
        #if DEBUG
        defs.append(("needs_credit", "Needs credit ⚠️"))
        #endif
        return defs
    }

    // ── Species count per filter (independent) ────────────────────────────────

    func count(for filterID: String) -> Int {
        store.species.filter { species in
            if filterID == "inat" {
                return species.hasSightings
            } else if filterID == "seen" {
                return seenStore.isSeen(species.scientificName)
            } else if filterID == "needs_credit" {
                return species.imageStatus == "needs_outreach"
            } else {
                return species.surveyPresence?.contains { $0.id == filterID } ?? false
            }
        }.count
    }

    // ── Filtered species ──────────────────────────────────────────────────────

    var filteredSpecies: [Species] {
        var result = store.species

        let allFilterIDs = Set(filterDefs.map { $0.id })
        if !activeFilters.isEmpty && activeFilters != allFilterIDs {
            result = result.filter { species in
                activeFilters.contains { filterID in
                    if filterID == "inat" {
                        return species.hasSightings
                    } else if filterID == "seen" {
                        return seenStore.isSeen(species.scientificName)
                    } else if filterID == "needs_credit" {
                        return species.imageStatus == "needs_outreach"
                    } else {
                        return species.surveyPresence?.contains { $0.id == filterID } ?? false
                    }
                }
            }
        }

        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            result = result.filter {
                $0.scientificName.lowercased().contains(query) ||
                ($0.englishName?.lowercased().contains(query) ?? false) ||
                ($0.localName?.lowercased().contains(query) ?? false)
            }
        }

        return result
    }

    var isFiltered: Bool {
        let allFilterIDs = Set(filterDefs.map { $0.id })
        let filtersReduced = !activeFilters.isEmpty && activeFilters != allFilterIDs
        return filtersReduced || !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // ── Body ──────────────────────────────────────────────────────────────────

    var body: some View {
        ZStack(alignment: .top) {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {

                    // ── Banner ────────────────────────────────────────────────
                    BannerView(
                        totalCount: store.speciesCount,
                        filteredCount: filteredSpecies.count,
                        isFiltered: isFiltered,
                        searchText: $searchText,
                        hasActiveFilters: !activeFilters.isEmpty,
                        showFilters: $showFilters,
                        showPortugueseNames: $showPortugueseNames
                    )

                    // ── Collapsible filter panel ───────────────────────────────
                    if showFilters {
                        FilterPanelView(
                            filterDefs: filterDefs,
                            activeFilters: $activeFilters,
                            countForFilter: { count(for: $0) },
                            filteredCount: filteredSpecies.count
                        )
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal:   .move(edge: .top).combined(with: .opacity)
                            )
                        )
                        .background(Color.appBackground)
                    }

                    // ── Species rows ──────────────────────────────────────────
                    if filteredSpecies.isEmpty {
                        emptyState
                    } else {
                        ForEach(filteredSpecies) { species in
                            NavigationLink(
                                destination: SpeciesDetailView(
                                    species: species,
                                    store: store
                                )
                            ) {
                                SpeciesRowView(
                                    species: species,
                                    showPortugueseNames: showPortugueseNames,
                                    isSeen: seenStore.isSeen(species.scientificName)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer().frame(height: AppSpacing.contentBottomPadding)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
    }

    // ── Empty state ───────────────────────────────────────────────────────────

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28))
                .foregroundColor(.outlineVariant)
            Text("No species found")
                .font(.bodyMedium)
                .foregroundColor(.onSurfaceVariant)
            Text("Try adjusting your search or filters")
                .font(.sectionLabel)
                .textCase(.uppercase)
                .tracking(1.0)
                .foregroundColor(.outline)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
        .padding(.horizontal, AppSpacing.pagePadding)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Collapsible filter panel
// ─────────────────────────────────────────────────────────────────────────────

struct FilterPanelView: View {

    let filterDefs: [(id: String, label: String)]
    @Binding var activeFilters: Set<String>
    let countForFilter: (String) -> Int
    let filteredCount: Int

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.outlineVariant.opacity(0.4))
                .frame(height: 0.5)

            HStack {
                Text("Filter by survey")
                    .font(.sectionLabel)
                    .textCase(.uppercase)
                    .tracking(1.0)
                    .foregroundColor(.outline)
                Spacer()
            }
            .padding(.horizontal, AppSpacing.pagePadding)
            .padding(.top, 14)
            .padding(.bottom, 6)

            VStack(spacing: 0) {
                ForEach(filterDefs, id: \.id) { filter in
                    FilterRowView(
                        label: filter.label,
                        count: countForFilter(filter.id),
                        isActive: activeFilters.contains(filter.id)
                    ) {
                        toggleFilter(filter.id)
                    }

                    Rectangle()
                        .fill(Color.outlineVariant.opacity(0.25))
                        .frame(height: 0.5)
                        .padding(.leading, AppSpacing.pagePadding)
                }

                HStack {
                    Spacer()
                    Text("\(filteredCount)")
                        .font(.custom("Inter_18pt-SemiBold", size: 16))
                        .foregroundColor(activeFilters.isEmpty ? .onSurfaceVariant : .appPrimary)
                        .monospacedDigit()
                }
                .padding(.horizontal, AppSpacing.pagePadding)
                .padding(.vertical, 12)
            }

            Rectangle()
                .fill(Color.outlineVariant.opacity(0.4))
                .frame(height: 0.5)
        }
    }

    private func toggleFilter(_ id: String) {
        withAnimation(.easeInOut(duration: 0.15)) {
            if activeFilters.contains(id) {
                activeFilters.remove(id)
            } else {
                activeFilters.insert(id)
            }
        }
    }
}

// ── Single filter row ─────────────────────────────────────────────────────────

struct FilterRowView: View {

    let label: String
    let count: Int
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {

                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(
                            isActive ? Color.appPrimary : Color.outline,
                            lineWidth: 1.5
                        )
                        .frame(width: 18, height: 18)

                    if isActive {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.appPrimary)
                            .frame(width: 18, height: 18)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .animation(.easeInOut(duration: 0.12), value: isActive)

                Text(label)
                    .font(.bodyText)
                    .foregroundColor(isActive ? .appPrimary : .onSurface)

                Spacer()

                Text("\(count)")
                    .font(.inatCount)
                    .foregroundColor(isActive ? .appPrimary : .onSurfaceVariant)
                    .monospacedDigit()
            }
            .padding(.horizontal, AppSpacing.pagePadding)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Banner
// ─────────────────────────────────────────────────────────────────────────────

struct BannerView: View {

    let totalCount: Int
    let filteredCount: Int
    let isFiltered: Bool
    @Binding var searchText: String
    let hasActiveFilters: Bool
    @Binding var showFilters: Bool
    @Binding var showPortugueseNames: Bool

    var subtitleText: String {
        isFiltered
            ? "\(filteredCount) OF \(totalCount) SPECIES · SURVEY-CONFIRMED"
            : "\(totalCount) SPECIES · SURVEY-CONFIRMED"
    }

    var body: some View {
        VStack(spacing: 0) {

            // ── Photo block ───────────────────────────────────────────────────
            ZStack(alignment: .bottomLeading) {

                Image("bannerList")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: UIScreen.main.bounds.width, height: 280)
                    .clipped()

                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.72), location: 0),
                        .init(color: .black.opacity(0.15), location: 0.65),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: 280)

                VStack(alignment: .leading, spacing: 0) {
                    Text("Snakes of")
                        .font(.custom("Manrope-Medium", size: 18))
                        .foregroundColor(.white.opacity(0.90))

                    Text("Carajás")
                        .font(.custom("Manrope-Bold", size: 48))
                        .foregroundColor(.white)
                        .padding(.top, -2)

                    HStack(alignment: .center) {
                        Text(subtitleText)
                            .font(.custom("Inter-Medium", size: 11))
                            .foregroundColor(.white.opacity(0.75))
                            .tracking(0.8)
                            .animation(.easeInOut(duration: 0.2), value: subtitleText)

                        Spacer()

                        // ── "Local name" pill button ──────────────────────────
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showPortugueseNames.toggle()
                            }
                        } label: {
                            Text("Local name")
                                .font(.custom("Inter_18pt-Regular", size: 13))
                                .foregroundColor(
                                    showPortugueseNames
                                        ? .white
                                        : .white.opacity(0.70)
                                )
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    showPortugueseNames
                                        ? Color.white.opacity(0.22)
                                        : Color.white.opacity(0.12)
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, AppSpacing.pagePadding)
                .padding(.bottom, 20)
            }
            .frame(height: 280)
            .clipped()

            // ── Search bar + filter icon ──────────────────────────────────────
            HStack(spacing: 8) {
                BannerSearchBar(text: $searchText)

                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        showFilters.toggle()
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(hasActiveFilters ? .appPrimary : .outline)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppSpacing.pagePadding)
            .padding(.vertical, 12)
            .background(Color.appBackground)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Banner search bar
// ─────────────────────────────────────────────────────────────────────────────

struct BannerSearchBar: View {

    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundColor(.outline)

            TextField("Search species...", text: $text)
                .font(.custom("Inter-Regular", size: 16))
                .foregroundColor(.onSurface)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.outline)
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color.surfaceContainerLow)
        .cornerRadius(AppRadius.large)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Species row
// ─────────────────────────────────────────────────────────────────────────────

struct SpeciesRowView: View {

    let species: Species
    let showPortugueseNames: Bool
    let isSeen: Bool

    var body: some View {
        HStack(spacing: 12) {

            ThumbnailView(
                scientificName: species.scientificName,
                url: species.inatImageURL,
                isSeen: isSeen,
                needsCredit: species.imageStatus == "needs_outreach"
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(species.displayName)
                    .font(.listSpeciesName)
                    .foregroundColor(.onSurface)
                    .lineLimit(2)

                if showPortugueseNames, let localName = species.localName {
                    Text(localName)
                        .font(.listScientificName)
                        .foregroundColor(.appSecondary)
                        .lineLimit(1)
                }

                Text(species.scientificName)
                    .font(.listScientificName)
                    .italic()
                    .foregroundColor(.onSurfaceVariant)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.outlineVariant)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, AppSpacing.pagePadding)
        .background(Color.appBackground)
        .contentShape(Rectangle())
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Thumbnail
// ─────────────────────────────────────────────────────────────────────────────

struct ThumbnailView: View {

    let scientificName: String
    let url: String?
    let isSeen: Bool
    let needsCredit: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {

            // ── Base image ────────────────────────────────────────────────────
            CachedSpeciesImage(
                scientificName: scientificName,
                remoteURL: url,
                contentMode: .fill
            )
            .frame(width: AppSpacing.thumbnailSize, height: AppSpacing.thumbnailSize)

            // ── Needs-credit overlay (DEBUG builds only) ──────────────────────
            #if DEBUG
            if needsCredit {
                ZStack {
                    Color.white.opacity(0.50)
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.orange)
                }
            }
            #endif

            // ── Seen indicator ────────────────────────────────────────────────
            if isSeen {
                ZStack {
                    Circle()
                        .fill(Color(hex: "5FDB63"))
                        .frame(width: 24, height: 24)
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            } else {
                Circle()
                    .fill(Color.black.opacity(0.18))
                    .frame(width: 24, height: 24)
            }
        }
        .frame(width: AppSpacing.thumbnailSize, height: AppSpacing.thumbnailSize)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.thumbnailRadius))
    }
}
