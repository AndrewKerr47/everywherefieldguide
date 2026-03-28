import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// LandingView.swift
// Carajás Field Guide
// Sprint 3 — hub screen, updated layout
//
// - App name block: upper-right area, left-aligned text, tighter spacing
// - Row 1: Privacy policy + About + flag accordion — padding 48
// - Row 2: version number right-aligned at 20% opacity
// - Auto-advance: 5 seconds
// - Flag accordion: slides up from behind at 56pt spacing, tap outside or select to close
// - Selected language persists via AppStorage
// ─────────────────────────────────────────────────────────────────────────────

struct LandingView: View {

    @State private var isActive           = false
    @State private var opacity: Double    = 0
    @State private var showAbout          = false
    @State private var showPrivacy        = false
    @State private var showLanguagePicker = false

    // ── Persisted language selection ──────────────────────────────────────────
    @AppStorage("selectedLanguage") private var selectedLanguage: String = LandingView.defaultLanguage

    // ── Supported languages ───────────────────────────────────────────────────
    struct AppLanguage: Identifiable {
        let id: String
        let assetName: String
    }

    private let languages: [AppLanguage] = [
        AppLanguage(id: "en", assetName: "flag_uk_circle"),
        AppLanguage(id: "pt", assetName: "flag_brazil_circle"),
        AppLanguage(id: "es", assetName: "flag_spain_circle"),
        AppLanguage(id: "fr", assetName: "flag_france_circle"),
        AppLanguage(id: "de", assetName: "flag_germany_circle")
    ]

    static var defaultLanguage: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        let supported = ["en", "pt", "es", "fr", "de"]
        return supported.contains(lang) ? lang : "en"
    }

    private var selectedFlag: String {
        languages.first { $0.id == selectedLanguage }?.assetName ?? "flag_uk_circle"
    }

    private var otherLanguages: [AppLanguage] {
        languages.filter { $0.id != selectedLanguage }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    // ── Body ──────────────────────────────────────────────────────────────────
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
                PrivacyPolicyView()
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

            // ── Tap outside to close accordion ────────────────────────────────
            if showLanguagePicker {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            showLanguagePicker = false
                        }
                    }
            }

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

                Spacer().frame(height: 120)

                // ── App name block ────────────────────────────────────────────
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

                // ── Two-row bottom block ──────────────────────────────────────
                VStack(alignment: .trailing, spacing: 12) {

                    // Row 1 — Privacy policy · About · Flag accordion
                    HStack(alignment: .center, spacing: 0) {

                        hubButton(label: "Privacy policy") { showPrivacy = true }
                        Spacer()
                        hubButton(label: "About") { showAbout = true }
                        Spacer()

                        // ── Flag accordion ────────────────────────────────────
                        ZStack(alignment: .bottom) {

                            // Other language flags — slide up from behind
                            ForEach(Array(otherLanguages.enumerated()), id: \.element.id) { index, lang in
                                Image(lang.assetName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 28)
                                    .clipShape(Circle())
                                    .offset(y: showLanguagePicker
                                            ? -CGFloat(index + 1) * 56
                                            : 0)
                                    .opacity(showLanguagePicker ? 1 : 0)
                                    .animation(
                                        .spring(response: 0.35, dampingFraction: 0.75)
                                        .delay(Double(index) * 0.06),
                                        value: showLanguagePicker
                                    )
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                            selectedLanguage = lang.id
                                            showLanguagePicker = false
                                        }
                                    }
                                    .zIndex(Double(otherLanguages.count - index))
                            }

                            // Selected flag — always on top
                            Image(selectedFlag)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 28)
                                .clipShape(Circle())
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        showLanguagePicker.toggle()
                                    }
                                }
                                .zIndex(Double(otherLanguages.count + 1))
                        }
                    }
                    .padding(.horizontal, 48)

                    // Row 2 — Version number, right-aligned
                    Text("v\(appVersion)")
                        .font(.custom("Inter_18pt-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.20))
                        .padding(.horizontal, 48)
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
