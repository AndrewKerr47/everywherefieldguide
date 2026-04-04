import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// CachedSpeciesImage.swift
// Carajás Field Guide
//
// Local-first image loader for species photos.
//
// Resolution order:
//   1. Documents/species_images/<scientificName>.jpg  (instant, no network)
//   2. AsyncImage from remote URL                     (fallback if not cached)
//   3. Placeholder colour                             (no URL or load failure)
//
// Used by ThumbnailView (list rows) and HeroImageView (detail screen).
// ─────────────────────────────────────────────────────────────────────────────

struct CachedSpeciesImage: View {

    let scientificName: String
    let remoteURL: String?
    let contentMode: ContentMode

    init(
        scientificName: String,
        remoteURL: String?,
        contentMode: ContentMode = .fill
    ) {
        self.scientificName = scientificName
        self.remoteURL = remoteURL
        self.contentMode = contentMode
    }

    var body: some View {
        // 1. Try disk cache first — synchronous, no network
        if let cached = ImageCacheManager.shared.loadImage(for: scientificName) {
            Image(uiImage: cached)
                .resizable()
                .aspectRatio(contentMode: contentMode)

        // 2. Fall back to AsyncImage if not cached
        } else if let urlString = remoteURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                case .failure:
                    placeholder
                case .empty:
                    placeholder.overlay {
                        ProgressView()
                            .scaleEffect(0.6)
                            .tint(Color.outline)
                    }
                @unknown default:
                    placeholder
                }
            }

        // 3. No URL available
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Color.surfaceDim
    }
}
