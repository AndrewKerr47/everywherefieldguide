import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// LandingView.swift
// Carajás Field Guide
// Sprint 3 — hub screen, updated layout
//
// - App name block: upper-right area, left-aligned text, tighter spacing
// - Buttons: About + Privacy Policy, centred at bottom
// - Auto-advance: 5 seconds
// ─────────────────────────────────────────────────────────────────────────────

struct LandingView: View {

    @State private var isActive    = false
    @State private var opacity: Double = 0
    @State private var showAbout   = false
    @State private var showPrivacy = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if isActive {
                    HomeView()
                } else {
                    landingHub
                }
            }
            .navigationDestination(isPresented: $showAbout) {
                AboutView()
            }
            .navigationDestination(isPresented: $showPrivacy) {
                Text("Privacy Policy — coming soon")
                    .foregroundColor(.onSurfaceVariant)
                    .navigationTitle("Privacy Policy")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    // ── Landing hub ───────────────────────────────────────────────────────────
    private var landingHub: some View {
        ZStack {

            // ── Full-screen hero image ────────────────────────────────────────
            Image("landing_snakesCarajas")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()

            // ── Top vignette ──────────────────────────────────────────────────
            VStack {
                LinearGradient(
                    colors: [.black.opacity(0.50), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 320)
                .ignoresSafeArea()
                Spacer()
            }

            // ── Bottom vignette ───────────────────────────────────────────────
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.black.opacity(0.55), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: 180)
                .ignoresSafeArea()
            }

            // ── Content ───────────────────────────────────────────────────────
            VStack(spacing: 0) {

                // ── Spacer pushes text block down from top ────────────────────
                Spacer().frame(height: 120)

                // ── App name block — right-aligned, text left-aligned ─────────
                VStack(alignment: .leading, spacing: -4) {
                    Text("Snakes of")
                        .font(.custom("Manrope-Medium", size: 22))
                        .foregroundColor(.white.opacity(0.90))

                    Text("Carajás")
                        .font(.custom("Manrope-Bold", size: 56))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("Serra dos Carajás · Pará, Brazil")
                        .font(.custom("Inter_18pt-Regular", size: 12))
                        .foregroundColor(.white.opacity(0.65))
                        .padding(.top, 6)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 24)

                Spacer()

                // ── Hub buttons — evenly spaced around centre ─────────────────
                HStack(spacing: 0) {
                    Spacer()
                    hubButton(label: "About") {
                        showAbout = true
                    }
                    Spacer()
                    hubButton(label: "Privacy policy") {
                        showPrivacy = true
                    }
                    Spacer()
                }
                .padding(.bottom, 52)
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.4)) {
                opacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                guard !showAbout && !showPrivacy else { return }
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isActive = true
                }
            }
        }
    }

    // ── Hub button ────────────────────────────────────────────────────────────
    private func hubButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.custom("Inter_18pt-Regular", size: 14))
                .foregroundColor(.white.opacity(0.80))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.white.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LandingView()
}
