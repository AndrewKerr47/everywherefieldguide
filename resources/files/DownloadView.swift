import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// DownloadView.swift
// Carajás Field Guide
//
// Shown on first launch only. Downloads all species images to the Documents
// directory before the user enters the app. On completion (or after retrying
// any failures) transitions to LandingView.
//
// States:
//   .idle        → waiting to start (auto-starts on appear)
//   .downloading → progress bar animating, X of Y label updating
//   .retrying    → failed images listed with individual retry buttons
//   .complete    → brief success state, then fades to LandingView
// ─────────────────────────────────────────────────────────────────────────────

struct DownloadView: View {

    // ── Completion callback ───────────────────────────────────────────────────

    /// Called when all images are downloaded (or skipped). App entry point
    /// sets this to transition to LandingView.
    let onComplete: () -> Void

    // ── State ─────────────────────────────────────────────────────────────────

    @State private var phase: DownloadPhase = .idle
    @State private var downloaded: Int = 0
    @State private var total: Int = 0
    @State private var failedSpecies: [FailedDownload] = []
    @State private var retryingIndex: Int? = nil

    // ── Body ──────────────────────────────────────────────────────────────────

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {

                Spacer()

                // ── Logo / brand ───────────────────────────────────────────────
                Image("mantella_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .padding(.bottom, 32)

                // ── Title ──────────────────────────────────────────────────────
                Text("Carajás Field Guide")
                    .font(.heroCommonName)
                    .foregroundColor(.appPrimary)
                    .padding(.bottom, 8)

                Text("Snakes of Serra dos Carajás")
                    .font(.listSubtitle)
                    .foregroundColor(.outline)
                    .tracking(1.0)
                    .padding(.bottom, 48)

                // ── Phase-specific content ─────────────────────────────────────
                switch phase {
                case .idle:
                    preparingView

                case .downloading:
                    downloadingView

                case .retrying:
                    retryView

                case .complete:
                    completeView
                }

                Spacer()
                Spacer()
            }
            .padding(.horizontal, AppSpacing.pagePadding)
        }
        .task {
            await startDownload()
        }
    }

    // ── Phase views ───────────────────────────────────────────────────────────

    private var preparingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.appPrimary)
            Text("Preparing…")
                .font(.bodyText)
                .foregroundColor(.onSurfaceVariant)
        }
    }

    private var downloadingView: some View {
        VStack(spacing: 20) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.outlineVariant)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.appSecondary)
                        .frame(
                            width: total > 0
                                ? geo.size.width * CGFloat(downloaded) / CGFloat(total)
                                : 0,
                            height: 6
                        )
                        .animation(.easeInOut(duration: 0.3), value: downloaded)
                }
            }
            .frame(height: 6)

            // Count label
            Text("Downloading species images… \(downloaded) of \(total)")
                .font(.sectionLabel)
                .foregroundColor(.onSurfaceVariant)
                .monospacedDigit()
        }
    }

    private var retryView: some View {
        VStack(alignment: .leading, spacing: 24) {

            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("\(failedSpecies.count) image\(failedSpecies.count == 1 ? "" : "s") couldn't be downloaded")
                    .font(.bodyMedium)
                    .foregroundColor(.onSurface)

                Text("Check your connection and retry, or continue — these species will show a placeholder image.")
                    .font(.bodyText)
                    .foregroundColor(.onSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Failed species list
            VStack(spacing: 12) {
                ForEach(Array(failedSpecies.enumerated()), id: \.element.scientificName) { index, failed in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(failed.scientificName)
                                .font(.listSpeciesName)
                                .foregroundColor(.onSurface)
                            Text(failed.englishName ?? "—")
                                .font(.listScientificName)
                                .foregroundColor(.onSurfaceVariant)
                        }

                        Spacer()

                        if retryingIndex == index {
                            ProgressView()
                                .tint(.appPrimary)
                                .frame(width: 44, height: 32)
                        } else if failed.succeeded {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.appSecondary)
                                .frame(width: 44, height: 32)
                        } else {
                            Button("Retry") {
                                Task { await retryOne(index: index) }
                            }
                            .font(.surveyPill)
                            .foregroundColor(.appPrimary)
                            .frame(width: 44, height: 32)
                        }
                    }
                    .padding(.vertical, 4)

                    if index < failedSpecies.count - 1 {
                        Divider().background(Color.outlineVariant)
                    }
                }
            }

            // Action buttons
            VStack(spacing: 12) {
                // Retry all remaining
                let remaining = failedSpecies.filter { !$0.succeeded }
                if !remaining.isEmpty {
                    Button {
                        Task { await retryAll() }
                    } label: {
                        Text("Retry all (\(remaining.count))")
                            .font(.bodyMedium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.appPrimary)
                            .cornerRadius(AppRadius.large)
                    }
                }

                // Continue anyway
                Button {
                    finish()
                } label: {
                    Text("Continue anyway")
                        .font(.bodyText)
                        .foregroundColor(.appPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
            }
        }
    }

    private var completeView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(.appSecondary)

            Text("All images downloaded")
                .font(.bodyMedium)
                .foregroundColor(.onSurface)

            Text("Ready to explore")
                .font(.sectionLabel)
                .foregroundColor(.onSurfaceVariant)
        }
        .onAppear {
            // Brief pause so the user sees the success state, then proceed
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                finish()
            }
        }
    }

    // ── Download logic ────────────────────────────────────────────────────────

    private func startDownload() async {
        // Load species list
        guard let species = loadSpecies() else {
            // Can't load JSON — skip download screen entirely
            finish()
            return
        }

        // Only download species that have an image URL and aren't already cached
        let toDownload = species.filter { s in
            s.inatImageURL != nil &&
            !ImageCacheManager.shared.isCached(s.scientificName)
        }

        guard !toDownload.isEmpty else {
            // All already cached — go straight to app
            finish()
            return
        }

        total = toDownload.count
        downloaded = 0
        phase = .downloading

        var failed: [FailedDownload] = []

        // Download concurrently in batches of 5 to avoid hammering the CDN
        let batchSize = 5
        for batchStart in stride(from: 0, to: toDownload.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, toDownload.count)
            let batch = Array(toDownload[batchStart..<batchEnd])

            await withTaskGroup(of: (Species, Bool).self) { group in
                for species in batch {
                    group.addTask {
                        guard
                            let urlString = species.inatImageURL,
                            let url = URL(string: urlString)
                        else { return (species, false) }

                        let success = await ImageCacheManager.shared.downloadAndCache(
                            scientificName: species.scientificName,
                            from: url
                        )
                        return (species, success)
                    }
                }

                for await (species, success) in group {
                    await MainActor.run {
                        if success {
                            downloaded += 1
                        } else {
                            failed.append(FailedDownload(
                                scientificName: species.scientificName,
                                englishName: species.englishName,
                                imageURL: species.inatImageURL
                            ))
                        }
                    }
                }
            }
        }

        await MainActor.run {
            if failed.isEmpty {
                phase = .complete
            } else {
                failedSpecies = failed
                phase = .retrying
            }
        }
    }

    private func retryOne(index: Int) async {
        guard index < failedSpecies.count else { return }
        let failed = failedSpecies[index]

        await MainActor.run { retryingIndex = index }

        guard
            let urlString = failed.imageURL,
            let url = URL(string: urlString)
        else {
            await MainActor.run { retryingIndex = nil }
            return
        }

        let success = await ImageCacheManager.shared.downloadAndCache(
            scientificName: failed.scientificName,
            from: url
        )

        await MainActor.run {
            retryingIndex = nil
            if success {
                failedSpecies[index].succeeded = true
                downloaded += 1
            }
            checkIfRetryComplete()
        }
    }

    private func retryAll() async {
        let indices = failedSpecies.indices.filter { !failedSpecies[$0].succeeded }
        for index in indices {
            await retryOne(index: index)
        }
    }

    private func checkIfRetryComplete() {
        if failedSpecies.allSatisfy({ $0.succeeded }) {
            phase = .complete
        }
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.imagesDownloaded)
        onComplete()
    }

    // ── JSON loader ───────────────────────────────────────────────────────────

    private func loadSpecies() -> [Species]? {
        guard
            let url = Bundle.main.url(forResource: "species", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else { return nil }
        return try? JSONDecoder().decode([Species].self, from: data)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Supporting types
// ─────────────────────────────────────────────────────────────────────────────

private enum DownloadPhase {
    case idle
    case downloading
    case retrying
    case complete
}

private struct FailedDownload {
    let scientificName: String
    let englishName: String?
    let imageURL: String?
    var succeeded: Bool = false
}
