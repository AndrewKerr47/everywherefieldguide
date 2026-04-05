import SwiftUI

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

    private func loc(_ key: String, _ fallback: String) -> String {
        LocaleManager.shared.localizedString(key, defaultValue: fallback)
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
                howToUseSection
                sectionDivider
                imageCreditsSection
                sectionDivider
                versionFooter
            }
            .padding(.bottom, 48)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(loc("about.nav_title", "About"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSafari) {
            if let url = safariURL {
                SafariView(url: url).ignoresSafeArea()
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Carajás Field Guide")
                .font(.custom("Manrope-Bold", size: 22))
                .foregroundColor(.appPrimary)
            Text(loc("about.header_subtitle", "Snakes of Serra dos Carajás"))
                .font(.custom("Inter_18pt-Regular", size: 13))
                .foregroundColor(.onSurfaceVariant)
            Text(loc("about.header_body", "A species-by-species reference for the confirmed snake fauna of the Serra dos Carajás, Pará, Brazil — one of the most biodiverse regions on Earth."))
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

    private var methodologySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(loc("about.methodology_title", "Survey-first data"))
            Text(loc("about.methodology_body", "Every species in this guide is confirmed by either a peer-reviewed field survey or by community observations sourced from iNaturalist. Use the filter panel to toggle species by data source — view survey records, iNaturalist observations, or the full confirmed list.\n\nWhere data is absent, fields are left blank — this guide does not estimate or extrapolate."))
                .font(.custom("Inter_18pt-Regular", size: 13))
                .foregroundColor(.onSurfaceVariant)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    }

    private var sourcesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel(loc("about.sources_title", "Data sources"))
            ForEach(surveySources) { source in
                surveyCard(source)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    }

    private var imageCreditsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(loc("about.credits_title", "Image credits"))
            Text(loc("about.credits_body", "Species photographs are reproduced under Creative Commons licence or with explicit permission from the original photographer. All images remain the property of their respective owners and are credited accordingly."))
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

    private var versionFooter: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(loc("about.version", "Version") + " \(appVersion)")
                .font(.custom("Inter_18pt-Regular", size: 11))
                .foregroundColor(.outline)
            Text(loc("about.built_by", "Built by Mantella"))
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
                        Text(loc("about.view_source", "View source"))
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

    // ── How to use this guide ─────────────────────────────────────────────────

    private var howToUseSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionLabel(loc("about.guide_title", "How to use this guide"))

            // 1. Venom risk
            VStack(alignment: .leading, spacing: 8) {
                guideSubsectionLabel(loc("about.guide_venom_title", "Venom risk"))
                VStack(spacing: 5) {
                    ForEach(VenomStatus.allCases, id: \.self) { status in
                        guideVenomRow(status)
                    }
                }
            }

            // 2. Conservation status
            VStack(alignment: .leading, spacing: 8) {
                guideSubsectionLabel(loc("about.guide_iucn_title", "Conservation status"))
                VStack(spacing: 5) {
                    ForEach(IUCNStatus.allCases, id: \.self) { status in
                        guideIUCNRow(status)
                    }
                }
            }

            // 3. Survey records
            VStack(alignment: .leading, spacing: 8) {
                guideSubsectionLabel(loc("about.guide_survey_title", "Survey records"))
                VStack(spacing: 5) {
                    guideSurveyRow(
                        name: "Cunha et al. 1985",
                        desc: loc("about.guide_survey_cn1985",
                                  "Confirmed in the 1985 Museu Goeldi field survey"))
                    guideSurveyRow(
                        name: "CNF Herpetofauna Survey 2015–2023",
                        desc: loc("about.guide_survey_cnf",
                                  "Confirmed in the 2015–2023 CNF herpetofauna survey"))
                }
            }

            // 4. iNaturalist observations
            VStack(alignment: .leading, spacing: 8) {
                guideSubsectionLabel(loc("about.guide_inat_title", "iNaturalist observations"))
                HStack(alignment: .center, spacing: 12) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.outlineVariant.opacity(0.20))
                            .frame(width: 120, height: 3)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.appSecondary)
                            .frame(width: 52, height: 3)
                    }
                    Text(loc("about.guide_inat_desc",
                             "Relative observation count within the guide area"))
                        .font(.custom("Inter_18pt-Regular", size: 12))
                        .foregroundColor(.onSurfaceVariant)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    }

    private func guideSubsectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.custom("Inter_18pt-SemiBold", size: 11))
            .foregroundColor(.onSurface)
    }

    private func guideVenomRow(_ status: VenomStatus) -> some View {
        HStack(spacing: 10) {
            Group {
                if status == .nonVenomous {
                    Image("icon_smile")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image("icon_skull")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                }
            }
            .frame(width: 18, height: 18)
            .foregroundColor(status.color)

            Text(status.label)
                .font(.custom("Inter_18pt-Regular", size: 13))
                .foregroundColor(.onSurface)
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(status.rowBackground)
        .cornerRadius(AppRadius.small)
    }

    private func guideIUCNRow(_ status: IUCNStatus) -> some View {
        HStack(spacing: 10) {
            Text(status.code)
                .font(.custom("Inter_18pt-SemiBold", size: 10))
                .foregroundColor(status.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.pill)
                        .stroke(status.color.opacity(0.60), lineWidth: 1)
                )
            Text(status.label)
                .font(.custom("Inter_18pt-Regular", size: 13))
                .foregroundColor(.onSurfaceVariant)
            Spacer()
        }
    }

    private func guideSurveyRow(name: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(name)
                .font(.surveyPill)
                .foregroundColor(.onSecondaryContainer)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.secondaryContainer)
                .cornerRadius(AppRadius.pill)
            Text(desc)
                .font(.custom("Inter_18pt-Regular", size: 12))
                .foregroundColor(.onSurfaceVariant)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    NavigationStack { AboutView() }
}
