import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// LandingView.swift
// Carajás Field Guide
//
// Full-screen landing screen shown after the system splash.
// Displays landing_snakesCarajas.png for 2 seconds then
// transitions to the main HomeView (species list).
// ─────────────────────────────────────────────────────────────────────────────

struct LandingView: View {

    @State private var isActive = false
    @State private var opacity: Double = 0

    var body: some View {
        if isActive {
            HomeView()
        } else {
            landing
        }
    }

    // ── Landing screen ────────────────────────────────────────────────────────
    private var landing: some View {
        ZStack {
            // Full-screen image — bundled asset, no network dependency
            Image("landing_snakesCarajas")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()

            // Subtle vignette at very bottom for MANTELLA wordmark legibility
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.black.opacity(0.5), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: 120)
                .ignoresSafeArea()
            }
        }
        .opacity(opacity)
        .onAppear {
            // Fade in
            withAnimation(.easeIn(duration: 0.4)) {
                opacity = 1.0
            }
            // After 2 seconds, fade out and advance to list
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    opacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isActive = true
                }
            }
        }
    }
}

#Preview {
    LandingView()
}
