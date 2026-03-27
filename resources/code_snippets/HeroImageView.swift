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

    let scientificName: String
    let imageURL: String?
    let commonName: String
    let portugueseName: String?
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
            .padding(.horizontal, AppSpacing.pagePadding)
            .padding(.bottom, 24) // bottom-6 = 24pt
        }
        .frame(height: AppSpacing.heroHeight)
        .clipped()
    }
}
