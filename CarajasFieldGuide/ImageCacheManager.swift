import Foundation
import UIKit

// ─────────────────────────────────────────────────────────────────────────────
// ImageCacheManager.swift
// Carajás Field Guide
//
// Manages persistent local storage of species images in the app's Documents
// directory. Images are downloaded once on first launch and served from disk
// on all subsequent loads — no network required after initial download.
//
// Storage path: Documents/species_images/<scientificName>.jpg
// ─────────────────────────────────────────────────────────────────────────────

final class ImageCacheManager {

    // ── Singleton ─────────────────────────────────────────────────────────────

    static let shared = ImageCacheManager()
    private init() { ensureCacheDirectoryExists() }

    // ── Paths ─────────────────────────────────────────────────────────────────

    private let cacheFolder = "species_images"

    private var cacheDirectory: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(cacheFolder)
    }

    // ── Setup ─────────────────────────────────────────────────────────────────

    private func ensureCacheDirectoryExists() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: cacheDirectory.path) {
            try? fm.createDirectory(at: cacheDirectory,
                                    withIntermediateDirectories: true)
        }
    }

    // ── File naming ───────────────────────────────────────────────────────────

    /// Stable filename derived from scientific name.
    /// e.g. "Bothrops atrox" → "Bothrops_atrox.jpg"
    func fileName(for scientificName: String) -> String {
        let safe = scientificName
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "_")
        return "\(safe).jpg"
    }

    private func fileURL(for scientificName: String) -> URL {
        cacheDirectory.appendingPathComponent(fileName(for: scientificName))
    }

    // ── Read ──────────────────────────────────────────────────────────────────

    /// Returns true if an image is already saved locally for this species.
    func isCached(_ scientificName: String) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(for: scientificName).path)
    }

    /// Loads the cached image for a species. Returns nil if not yet downloaded.
    func loadImage(for scientificName: String) -> UIImage? {
        let url = fileURL(for: scientificName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    // ── Write ─────────────────────────────────────────────────────────────────

    /// Downloads an image from a remote URL and saves it to Documents.
    /// Returns true on success, false on any failure.
    func downloadAndCache(
        scientificName: String,
        from remoteURL: URL
    ) async -> Bool {
        do {
            let (data, response) = try await URLSession.shared.data(from: remoteURL)
            guard
                let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200,
                !data.isEmpty
            else { return false }

            // Normalise to JPEG to keep storage predictable
            guard
                let image = UIImage(data: data),
                let jpegData = image.jpegData(compressionQuality: 0.85)
            else { return false }

            try jpegData.write(to: fileURL(for: scientificName), options: .atomic)
            return true
        } catch {
            return false
        }
    }

    // ── Clear (dev/debug use only) ────────────────────────────────────────────

    /// Removes all cached images. Resets the download flag so first-launch
    /// screen reappears. Call from Settings/debug menu only.
    func clearAll() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        ensureCacheDirectoryExists()
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.imagesDownloaded)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - UserDefaults keys
// ─────────────────────────────────────────────────────────────────────────────

enum UserDefaultsKeys {
    /// Set to true once all images have been successfully downloaded.
    /// Gates the first-launch download screen.
    static let imagesDownloaded = "imagesDownloaded"
}
