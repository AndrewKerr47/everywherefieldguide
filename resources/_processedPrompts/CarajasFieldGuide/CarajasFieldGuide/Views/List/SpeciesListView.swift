import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// SpeciesListView.swift
// Carajás Field Guide
//
// Species list with full-bleed banner header.
// Banner: bundled bannerImage.png, text overlaid bottom-left,
//   "Snakes of" (small) above "Carajás" (large), species count, search bar
//   bleeding into the list below.
// ─────────────────────────────────────────────────────────────────────────────

struct SpeciesListView: View {

    let store: SpeciesStore
    @State private var searchText = ""

    var filteredSpecies: [Species] {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return store.species
        }
        let query = searchText.lowercased()
        return store.species.filter {
            $0.scientificName.lowercased().contains(query) ||
            ($0.englishName?.lowercased().contains(query) ?? false) ||
            ($0.localName?.lowercased().contains(query) ?? false)
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {

                    // ── Banner ────────────────────────────────────────────────
                    BannerView(
                        speciesCount: store.speciesCount,
                        searchText: $searchText
                    )

                    // ── Species rows ──────────────────────────────────────────
                    if filteredSpecies.isEmpty {
                        emptyState
                    } else {
                        ForEach(filteredSpecies) { species in
                            NavigationLink(destination: SpeciesDetailView(species: species, store: store)) {
                                SpeciesRowView(species: species)
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

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28))
                .foregroundColor(.outlineVariant)
            Text("No species found")
                .font(.bodyMedium)
                .foregroundColor(.onSurfaceVariant)
            Text("Try searching by common or scientific name")
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
// MARK: - Banner
// ─────────────────────────────────────────────────────────────────────────────

struct BannerView: View {

    let speciesCount: Int
    @Binding var searchText: String

    var body: some View {
        VStack(spacing: 0) {

            // ── Photo block ───────────────────────────────────────────────────
            ZStack(alignment: .bottomLeading) {

                Image("landing_snakesCarajas")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: UIScreen.main.bounds.width, height: 280)
                    .clipped()

                // Gradient for text legibility
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

                // Text block — bottom left of image
                VStack(alignment: .leading, spacing: 0) {
                    Text("Snakes of")
                        .font(.custom("Manrope-Medium", size: 18))
                        .foregroundColor(.white.opacity(0.90))

                    Text("Carajás")
                        .font(.custom("Manrope-Bold", size: 48))
                        .foregroundColor(.white)
                        .padding(.top, -2)

                    Text("\(speciesCount) SPECIES · SURVEY-CONFIRMED")
                        .font(.custom("Inter-Medium", size: 11))
                        .foregroundColor(.white.opacity(0.75))
                        .tracking(0.8)
                        .padding(.top, 6)
                }
                .padding(.horizontal, AppSpacing.pagePadding)
                .padding(.bottom, 20)
            }
            .frame(height: 280)
            .clipped()

            // ── Search bar — on white surface below banner ────────────────────
            BannerSearchBar(text: $searchText)
                .padding(.horizontal, AppSpacing.pagePadding)
                .padding(.vertical, 12)
                .background(Color.appBackground)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Banner search bar
// ─────────────────────────────────────────────────────────────────────────────
// Sits at the bottom of the banner — warm off-white background,
// slightly translucent so it reads as part of the transition into the list.

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
        .background(Color.appBackground.opacity(0.92))
        .cornerRadius(AppRadius.large)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Species row
// ─────────────────────────────────────────────────────────────────────────────

struct SpeciesRowView: View {

    let species: Species

    var body: some View {
        HStack(spacing: 12) {

            ThumbnailView(url: species.inatImageURL)

            VStack(alignment: .leading, spacing: 4) {
                Text(species.displayName)
                    .font(.listSpeciesName)
                    .foregroundColor(.onSurface)
                    .lineLimit(2)

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

    let url: String?

    var body: some View {
        Group {
            if let urlString = url, let imageURL = URL(string: urlString) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    case .failure:
                        Color.surfaceDim
                    case .empty:
                        Color.surfaceDim.overlay {
                            ProgressView().scaleEffect(0.6).tint(Color.outline)
                        }
                    @unknown default:
                        Color.surfaceDim
                    }
                }
            } else {
                Color.surfaceDim
            }
        }
        .frame(width: AppSpacing.thumbnailSize, height: AppSpacing.thumbnailSize)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.thumbnailRadius))
    }
}
