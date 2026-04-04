import SwiftUI
import SafariServices

// ─────────────────────────────────────────────────────────────────────────────
// SafariView.swift
// Carajás Field Guide
//
// Reusable SFSafariViewController wrapper.
// Placement: Utilities/SafariView.swift
//
// MIGRATION NOTE: Remove the SafariView struct from the bottom of
// SpeciesDetailView.swift after adding this file to the project.
// ─────────────────────────────────────────────────────────────────────────────

struct SafariView: UIViewControllerRepresentable {

    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let vc = SFSafariViewController(url: url)
        vc.preferredControlTintColor = UIColor(Color.appPrimary)
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
