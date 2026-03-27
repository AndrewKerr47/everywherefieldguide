import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// HomeView.swift
// Carajás Field Guide
//
// Root of the Home tab. Wraps content in a NavigationStack.
// Species list will be built in Prompt 03 (SpeciesListView).
// This placeholder establishes the NavigationStack and background colour.
//
// HTML ref background: bg-background = #faf9f6
// ─────────────────────────────────────────────────────────────────────────────

struct HomeView: View {

    var body: some View {
        NavigationStack {
            SpeciesListPlaceholder()
                // Suppress default NavigationStack chrome —
                // the list screen manages its own header layout
                .navigationBarHidden(true)
        }
        // Apply warm off-white background at the NavigationStack level
        // so it persists during push/pop transitions
        .background(Color.appBackground)
        // Ensure background extends under status bar and safe areas
        .tint(Color.appPrimary)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Placeholder (replaced by SpeciesListView in Prompt 03)
// ─────────────────────────────────────────────────────────────────────────────

struct SpeciesListPlaceholder: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 20) {

                // App wordmark placeholder
                VStack(spacing: 6) {
                    Text("Carajás")
                        .font(.custom("Manrope-Bold", size: 32))
                        .foregroundColor(.appPrimary)
                    Text("Field Guide")
                        .font(.custom("Manrope-Medium", size: 18))
                        .foregroundColor(.onSurfaceVariant)
                }

                Divider()
                    .frame(width: 60)
                    .background(Color.outlineVariant)

                // Status indicator
                VStack(spacing: 8) {
                    Text("SNAKES · CARAJÁS")
                        .font(.sectionLabel)
                        .textCase(.uppercase)
                        .tracking(1.0)
                        .foregroundColor(.outline)

                    Text("Species list loading in Prompt 03")
                        .font(.bodyText)
                        .foregroundColor(.onSurfaceVariant)

                    // Design token preview strip
                    HStack(spacing: 8) {
                        ForEach([
                            Color.appPrimary,
                            Color.appSecondary,
                            Color.venomDangerous,
                            Color.venomMild,
                            Color.venomLowRisk,
                            Color.iucnAmber,
                        ], id: \.self) { color in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(color)
                                .frame(width: 24, height: 24)
                        }
                    }
                    .padding(.top, 12)

                    Text("Design tokens loaded ✓")
                        .font(.sectionLabel)
                        .textCase(.uppercase)
                        .tracking(1.0)
                        .foregroundColor(.venomLowRisk)
                        .padding(.top, 4)
                }
            }
            .padding(AppSpacing.pagePadding)
        }
    }
}

#Preview {
    HomeView()
}
