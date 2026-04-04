import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// AboutView.swift
// Carajás Field Guide
// Sprint 4 — localised (en + pt-BR)
// ─────────────────────────────────────────────────────────────────────────────

struct AboutView: View {

    struct SurveySource: Identifiable {
        let id = UUID()
        let shortName: String
        let fullCitation: String
        let urlString: String
    }

    private let surveySources: [SurveySource] = [
        SurveySource(
            shortName: "Cunha et al. 1985",
            fullCitation: "Cunha, O.R. et al. (1985). Os Répteis da área de Carajás, Pará, Brasil — Testudines e Squamata I. Museu Paraense Emílio Goeldi.",
            urlString: "https://www.academia.edu/98379773/Os_R%C3%A9pteis_da_%C3%A1rea_de_Caraj%C3%A1s_Par%C3%A1_Brasil_Testudines_e_Squamata_I"
        ),
        SurveySource(
            shortName: "CNF Herpetofauna Survey 2015–2023",
            fullCitation: "UFSC / CNF (2023). Herpetofauna da área de proteção da Floresta Nacional de Carajás, Pará, Brasil. PECO0265-T, Repositório UFSC.",
            urlString: "https://repositorio.ufsc.br/bitstream/handle/123456789/268946/PECO0265-T.pdf?isAllowed=y&sequence=-1"
        ),
        SurveySource(
            shortName: "iNaturalist",
            fullCitation: "iNaturalist (2024). Community observation data for Serra dos Carajás, Pará, Brazil. iNaturalist.org.",
            urlString: "https://www.inaturalist.org"
        )
    ]

    @State private var safariURL: URL? = nil
    @State private var showSafari = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                headerSection
                sectionDivider
                methodologySection
                sectionDivider
                sourcesSection
                sectionDivider
                imageCreditsSection
                sectionDivider
                versionFooter
            }
            .padding(.bottom, 48)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(String(localized: "about.nav_title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSafari) {
            if let url = safariURL {
                SafariView(url: url).ignoresSafeArea()
            }
        }
    }

    // ── Header ────────────────────────────────────────────────────────────────
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Carajás Field Guide")
                .font(.custom("Manrope-Bold", size: 22))
                .foregroundColor(.appPrimary)
            Text("Snakes of Serra dos Carajás")
                .font(.custom("Inter_18pt-Regular", size: 13))
                .foregroundColor(.onSurfaceVariant)
            Text("A species-by-species reference for the confirmed snake fauna of the Serra dos Carajás, Pará, Brazil — one of the most biodiverse regions on Earth.")
                .font(.custom("Inter_18pt-Regular", size: 13))
                .foregroundColor(.onSurfaceVariant)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 24)
    }

    // ── Methodology ───────────────────────────────────────────────────────────
    private var methodologySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Survey-first data")
            Text("Every species in this guide is confirmed by either a peer-reviewed field survey or by community observations sourced from iNaturalist. Use the filter panel to toggle species by data source — view survey records, iNaturalist observations, or the full confirmed list.\n\nWhere data is absent, fields are left blank — this guide does not estimate or extrapolate.")
                .font(.custom("Inter_18pt-Regular", size: 13))
                .foregroundColor(.onSurfaceVariant)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    }

    // ── Data sources ──────────────────────────────────────────────────────────
    private var sourcesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("Data sources")
            ForEach(surveySources) { source in
                surveyCard(source)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    }

    // ── Image credits ─────────────────────────────────────────────────────────
    private var imageCreditsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Image credits")
            Text("Species photographs are reproduced under Creative Commons licence or with explicit permission from the original photographer. All images remain the property of their respective owners and are credited accordingly.")
                .font(.custom("Inter_18pt-Regular", size: 13))
                .foregroundColor(.onSurfaceVariant)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                openURL("https://www.inaturalist.org")
            } label: {
                HStack(spacing: 6) {
                    Text("iNaturalist.org")
                        .font(.custom("Inter_18pt-SemiBold", size: 12))
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(.appPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color.secondaryContainer)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    }

    // ── Version footer ────────────────────────────────────────────────────────
    private var versionFooter: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Version \(appVersion)")
                .font(.custom("Inter_18pt-Regular", size: 11))
                .foregroundColor(.outline)
            Text("Built by Mantella")
                .font(.custom("Inter_18pt-Regular", size: 11))
                .foregroundColor(.outline)
            Text("andrewkerresq@gmail.com")
                .font(.custom("Inter_18pt-Regular", size: 11))
                .foregroundColor(.outline)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    // ── Reusable components ───────────────────────────────────────────────────
    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.custom("Inter_18pt-Regular", size: 9))
            .foregroundColor(.outline)
            .kerning(1.2)
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(Color.outlineVariant.opacity(0.5))
            .frame(height: 0.5)
            .padding(.horizontal, 20)
    }

    private func surveyCard(_ source: SurveySource) -> some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack(alignment: .center) {
                Text(source.shortName)
                    .font(.custom("Inter_18pt-SemiBold", size: 11))
                    .foregroundColor(.onSecondaryContainer)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.secondaryContainer)
                    .clipShape(Capsule())

                Spacer()

                Button {
                    openURL(source.urlString)
                } label: {
                    HStack(spacing: 4) {
                        Text("View source")
                            .font(.custom("Inter_18pt-Regular", size: 11))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.appPrimary)
                }
                .buttonStyle(.plain)
            }

            Text(source.fullCitation)
                .font(.custom("Inter_18pt-Regular", size: 12))
                .foregroundColor(.onSurfaceVariant)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.outlineVariant, lineWidth: 1)
        )
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        safariURL = url
        showSafari = true
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
