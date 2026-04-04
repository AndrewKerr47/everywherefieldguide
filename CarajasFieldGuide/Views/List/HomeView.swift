import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// HomeView.swift
// Sprint 4 — localised (en + pt-BR)
// SpeciesStore is now owned by CarajasFieldGuideApp and injected via
// environment so language switches reload descriptions across the whole app.
// ─────────────────────────────────────────────────────────────────────────────

struct HomeView: View {

    @Environment(SpeciesStore.self) private var store

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading {
                    loadingView
                } else if let error = store.loadError {
                    errorView(error)
                } else {
                    SpeciesListView(store: store)
                }
            }
            .navigationBarHidden(true)
        }
        .background(Color.appBackground)
        .tint(Color.appPrimary)
    }

    // ── Loading ───────────────────────────────────────────────────────────────

    private var loadingView: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ProgressView().tint(Color.appPrimary)
        }
    }

    // ── Error ─────────────────────────────────────────────────────────────────

    private func errorView(_ message: String) -> some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 32))
                    .foregroundColor(.iucnAmber)
                Text("home.error_title", comment: "Error screen heading when species JSON fails to load")
                    .font(.bodyMedium)
                    .foregroundColor(.onSurface)
                Text(message)
                    .font(.sourceFooter)
                    .foregroundColor(.outline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(SpeciesStore())
}
