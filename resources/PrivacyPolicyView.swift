import SwiftUI
import WebKit

// ─────────────────────────────────────────────────────────────────────────────
// PrivacyPolicyView.swift
// Carajás Field Guide
// Sprint 3 — Privacy Policy screen
//
// Placement: Views/About/PrivacyPolicyView.swift
//
// Loads the hosted privacy policy in a WKWebView.
// Falls back to a plain-text summary if the URL is unreachable.
// ─────────────────────────────────────────────────────────────────────────────

struct PrivacyPolicyView: View {

    // ── Update this URL once GitHub Pages is live ─────────────────────────────
    private let policyURL = URL(string: "https://andrewkerr47.github.io/everywherefieldguide/privacy-policy.html")!

    @State private var isLoading = true
    @State private var loadFailed = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if loadFailed {
                fallbackView
            } else {
                WebView(url: policyURL, isLoading: $isLoading, loadFailed: $loadFailed)
                    .ignoresSafeArea(edges: .bottom)

                if isLoading {
                    ProgressView()
                        .tint(Color.appPrimary)
                }
            }
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }

    // ── Fallback if offline ───────────────────────────────────────────────────
    private var fallbackView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                VStack(alignment: .leading, spacing: 6) {
                    Text("Privacy Policy")
                        .font(.custom("Manrope-Bold", size: 22))
                        .foregroundColor(.appPrimary)
                    Text("Carajás Field Guide · Mantella · March 2026")
                        .font(.custom("Inter_18pt-Regular", size: 13))
                        .foregroundColor(.onSurfaceVariant)
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 24)

                Rectangle()
                    .fill(Color.outlineVariant.opacity(0.5))
                    .frame(height: 0.5)
                    .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 16) {
                    policySection(
                        title: "Data we store locally",
                        body: "The app stores your seen species list and language preference on your device only using iOS UserDefaults. Species images are cached locally in your Documents directory. None of this data leaves your device."
                    )
                    policySection(
                        title: "Data we do not collect",
                        body: "We do not collect your name, email, location, device identifiers, or any personal information. There are no user accounts, advertising networks, or third-party trackers."
                    )
                    policySection(
                        title: "Third-party services",
                        body: "Species photographs are loaded from iNaturalist on first launch. Your download request is subject to iNaturalist's own privacy policy. No other external services are used."
                    )
                    policySection(
                        title: "Future analytics",
                        body: "We may introduce anonymous usage analytics in a future update. This policy will be updated and users informed before any such change takes effect."
                    )
                    policySection(
                        title: "Contact",
                        body: "Questions? Contact us at hello@mantella.app"
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .padding(.bottom, 48)
        }
    }

    private func policySection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.custom("Inter_18pt-Regular", size: 9))
                .foregroundColor(.outline)
                .kerning(1.2)
            Text(body)
                .font(.custom("Inter_18pt-Regular", size: 13))
                .foregroundColor(.onSurfaceVariant)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - WKWebView wrapper
// ─────────────────────────────────────────────────────────────────────────────

struct WebView: UIViewRepresentable {

    let url: URL
    @Binding var isLoading: Bool
    @Binding var loadFailed: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.backgroundColor = UIColor(Color.appBackground)
        webView.scrollView.backgroundColor = UIColor(Color.appBackground)
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebView

        init(_ parent: WebView) { self.parent = parent }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.loadFailed = true
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.loadFailed = true
        }
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
