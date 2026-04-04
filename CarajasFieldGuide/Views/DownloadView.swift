import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// DownloadView.swift
// Carajás Field Guide
// Sprint 4 — localised (en + pt-BR)
// ─────────────────────────────────────────────────────────────────────────────

struct DownloadView: View {

    let onComplete: () -> Void

    @State private var phase: DownloadPhase = .idle
    @State private var downloaded: Int = 0
    @State private var total: Int = 0
    @State private var failedSpecies: [FailedDownload] = []
    @State private var retryingIndex: Int? = nil

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {

                Spacer()

                Image("mantella_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .padding(.bottom, 32)

                Text("Carajás Field Guide")
                    .font(.heroCommonName)
                    .foregroundColor(.primaryFixedDim)
                    .padding(.bottom, 8)

                Text("Snakes of Serra dos Carajás")
                    .font(.listSubtitle)
                    .foregroundColor(.primaryFixedDim)
                    .tracking(1.0)
                    .padding(.bottom, 48)

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
                .tint(.primaryFixedDim)
            Text("download.preparing",
                 comment: "Shown while the download screen is initialising")
                .font(.bodyText)
                .foregroundColor(.primaryFixedDim)
        }
    }

    private var downloadingView: some View {
        VStack(spacing: 20) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primaryFixedDim.opacity(0.3))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primaryFixedDim)
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

            Text(String(format: String(localized: "download.downloading",
                                       defaultValue: "Downloading species images… %1$lld of %2$lld"),
                        downloaded, total))
                .font(.sectionLabel)
                .foregroundColor(.primaryFixedDim)
                .monospacedDigit()
        }
    }

    private var retryView: some View {
        VStack(alignment: .leading, spacing: 24) {

            VStack(alignment: .leading, spacing: 6) {
                Text(String(format: String(localized: "download.failed_header",
                                           defaultValue: "%lld images couldn't be downloaded"),
                            failedSpecies.count))
                    .font(.bodyMedium)
                    .foregroundColor(.primaryFixedDim)

                Text("download.failed_body",
                     comment: "Body text on the retry screen")
                    .font(.bodyText)
                    .foregroundColor(.primaryFixedDim)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 12) {
                ForEach(Array(failedSpecies.enumerated()), id: \.element.scientificName) { index, failed in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(failed.scientificName)
                                .font(.listSpeciesName)
                                .foregroundColor(.primaryFixedDim)
                            Text(failed.englishName ?? "—")
                                .font(.listScientificName)
                                .foregroundColor(.primaryFixedDim)
                        }

                        Spacer()

                        if retryingIndex == index {
                            ProgressView()
                                .tint(.primaryFixedDim)
                                .frame(width: 44, height: 32)
                        } else if failed.succeeded {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.primaryFixedDim)
                                .frame(width: 44, height: 32)
                        } else {
                            Button(String(localized: "download.retry_one",
                                          defaultValue: "Retry")) {
                                Task { await retryOne(index: index) }
                            }
                            .font(.surveyPill)
                            .foregroundColor(.primaryFixedDim)
                            .frame(width: 44, height: 32)
                        }
                    }
                    .padding(.vertical, 4)

                    if index < failedSpecies.count - 1 {
                        Divider().background(Color.primaryFixedDim.opacity(0.3))
                    }
                }
            }

            VStack(spacing: 12) {
                let remaining = failedSpecies.filter { !$0.succeeded }
                if !remaining.isEmpty {
                    Button {
                        Task { await retryAll() }
                    } label: {
                        Text(String(format: String(localized: "download.retry_all",
                                                   defaultValue: "Retry all (%lld)"),
                                    remaining.count))
                            .font(.bodyMedium)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.primaryFixedDim)
                            .cornerRadius(AppRadius.large)
                    }
                }

                Button {
                    finish()
                } label: {
                    Text("download.continue_anyway",
                         comment: "Button to skip failed downloads and enter the app")
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
                .foregroundColor(.primaryFixedDim)

            Text("download.complete",
                 comment: "Success heading after all images download")
                .font(.bodyMedium)
                .foregroundColor(.primaryFixedDim)

            Text("download.ready",
                 comment: "Success subtext after all images download")
                .font(.sectionLabel)
                .foregroundColor(.primaryFixedDim)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                finish()
            }
        }
    }

    // ── Download logic ────────────────────────────────────────────────────────

    private func startDownload() async {
        guard let species = loadSpecies() else {
            finish()
            return
        }

        let toDownload = species.filter { s in
            s.inatImageURL != nil &&
            !ImageCacheManager.shared.isCached(s.scientificName)
        }

        guard !toDownload.isEmpty else {
            finish()
            return
        }

        total = toDownload.count
        downloaded = 0
        phase = .downloading

        var failed: [FailedDownload] = []

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
