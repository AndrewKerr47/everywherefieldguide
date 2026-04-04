import SwiftUI
import WebKit

struct PrivacyPolicyView: View {

    private let policyURL = URL(string: "https://andrewkerr47.github.io/mantella-privacy/")!

    @State private var isLoading = true
    @State private var loadFailed = false

    private func loc(_ key: String, _ fallback: String) -> String {
        LocaleManager.shared.localizedString(key, defaultValue: fallback)
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            if loadFailed {
                fallbackView
            } else {
                WebView(url: policyURL, isLoading: $isLoading, loadFailed: $loadFailed)
                    .ignoresSafeArea(edges: .bottom)
                if isLoading {
                    ProgressView().tint(Color.appPrimary)
                }
            }
        }
        .navigationTitle(loc("privacy.nav_title", "Privacy Policy"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var fallbackView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(loc("privacy.nav_title", "Privacy Policy"))
                        .font(.custom("Manrope-Bold", size: 22))
                        .foregroundColor(.appPrimary)
                    Text("Carajás Field Guide · Mantella · 2026")
                        .font(.custom("Inter_18pt-Regular", size: 13))
                        .foregroundColor(.onSurfaceVariant)
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 24)
                Rectangle().fill(Color.outlineVariant.opacity(0.5)).frame(height: 0.5).padding(.horizontal, 20)
                VStack(alignment: .leading, spacing: 16) {
                    policySection(title: loc("privacy.section1_title", "Data we store locally"), body: loc("privacy.section1_body", "The app stores your seen species list and language preference on your device only using iOS UserDefaults. Species images are cached locally in your Documents directory. None of this data leaves your device."))
                    policySection(title: loc("privacy.section2_title", "Data we do not collect"), body: loc("privacy.section2_body", "We do not collect your name, email, location, device identifiers, or any personal information. There are no user accounts, advertising networks, or third-party trackers."))
                    policySection(title: loc("privacy.section3_title", "Third-party services"), body: loc("privacy.section3_body", "Species photographs are loaded from iNaturalist, GBIF (Global Biodiversity Information Facility), and Wikimedia Commons on first launch. Your download request may be subject to the privacy policies of these services. No other external services are used."))
                    policySection(title: loc("privacy.section4_title", "Future analytics"), body: loc("privacy.section4_body", "We may introduce anonymous usage analytics in a future update. This policy will be updated and users informed before any such change takes effect."))
                    policySection(title: loc("privacy.section5_title", "Contact"), body: loc("privacy.section5_body", "Questions? Contact us at andrewkerresq@gmail.com"))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .padding(.bottom, 48)
        }
    }

    private func policySection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased()).font(.custom("Inter_18pt-Regular", size: 9)).foregroundColor(.outline).kerning(1.2)
            Text(body).font(.custom("Inter_18pt-Regular", size: 13)).foregroundColor(.onSurfaceVariant).lineSpacing(4).fixedSize(horizontal: false, vertical: true)
        }
    }
}

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
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) { parent.isLoading = true }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { parent.isLoading = false }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { parent.isLoading = false; parent.loadFailed = true }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { parent.isLoading = false; parent.loadFailed = true }
    }
}

#Preview {
    NavigationStack { PrivacyPolicyView() }
}
