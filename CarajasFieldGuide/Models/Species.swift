import Foundation

// ─────────────────────────────────────────────────────────────────────────────
// Species.swift
// Carajás Field Guide
//
// Core data model. Every field mirrors the schema in MasterDoc v0.3 Section 8.1.
// All fields are optional except scientificName and taxonGroup.
// No force-unwrapping anywhere — nil fields are omitted from the UI entirely.
//
// Sprint 4: added applying(_ translation:) for runtime localisation patching.
// ─────────────────────────────────────────────────────────────────────────────

struct Species: Codable, Identifiable, Hashable {

    // ── Identity ──────────────────────────────────────────────────────────────

    var id: String { scientificName }
    let scientificName: String
    let englishName: String?
    let localName: String?
    let taxonGroup: String

    // ── Venom & safety ────────────────────────────────────────────────────────

    let venomStatus: VenomStatus?
    let venomType: String?

    // ── Conservation ──────────────────────────────────────────────────────────

    let iucnStatus: IUCNStatus?

    // ── Physical ──────────────────────────────────────────────────────────────

    let avgSizeCm: Double?
    let maxSizeCm: Double?

    // ── Ecology ───────────────────────────────────────────────────────────────

    let habitat: [String]?
    let description: String?

    // ── Survey presence ───────────────────────────────────────────────────────

    let surveyPresence: [Survey]?

    // ── iNaturalist ───────────────────────────────────────────────────────────

    let inatObservations: Int?
    let inatTaxonURL: String?
    let inatImageURL: String?
    let inatSightings: [InatSighting]?

    // ── Image credit ──────────────────────────────────────────────────────────

    let imageSource: String?
    let sourceURL: String?
    let observer: String?
    let observerURL: String?
    let licenceCode: String?
    let licenceLabel: String?
    let licenceURL: String?
    let creditLine: String?
    let imageStatus: String?

    // ── Source ────────────────────────────────────────────────────────────────

    let sourceNotes: String?

    // ── Coding keys ───────────────────────────────────────────────────────────

    enum CodingKeys: String, CodingKey {
        case scientificName    = "scientific_name"
        case englishName       = "english_name"
        case localName         = "local_name"
        case taxonGroup        = "taxon_group"
        case venomStatus       = "venom_status"
        case venomType         = "venom_type"
        case iucnStatus        = "iucn_status"
        case avgSizeCm         = "avg_size_cm"
        case maxSizeCm         = "max_size_cm"
        case habitat
        case description
        case surveyPresence    = "survey_presence"
        case inatObservations  = "inat_observations"
        case inatTaxonURL      = "inat_taxon_url"
        case inatImageURL      = "inat_image_url"
        case inatSightings     = "inat_sightings"
        case imageSource       = "image_source"
        case sourceURL         = "source_url"
        case observer
        case observerURL       = "observer_url"
        case licenceCode       = "licence_code"
        case licenceLabel      = "licence_label"
        case licenceURL        = "licence_url"
        case creditLine        = "credit_line"
        case imageStatus       = "image_status"
        case sourceNotes       = "source_notes"
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Translation patching
// ─────────────────────────────────────────────────────────────────────────────

extension Species {

    /// Returns a new Species with translatable fields replaced by the
    /// values in the given translation patch. Fields absent from the patch
    /// retain their original values from species.json.
    func applying(_ translation: SpeciesTranslation) -> Species {
        Species(
            scientificName: scientificName,
            englishName:    englishName,
            localName:      localName,
            taxonGroup:     taxonGroup,
            venomStatus:    venomStatus,
            venomType:      translation.venomType   ?? venomType,
            iucnStatus:     iucnStatus,
            avgSizeCm:      avgSizeCm,
            maxSizeCm:      maxSizeCm,
            habitat:        translation.habitat     ?? habitat,
            description:    translation.description ?? description,
            surveyPresence: surveyPresence,
            inatObservations: inatObservations,
            inatTaxonURL:   inatTaxonURL,
            inatImageURL:   inatImageURL,
            inatSightings:  inatSightings,
            imageSource:    imageSource,
            sourceURL:      sourceURL,
            observer:       observer,
            observerURL:    observerURL,
            licenceCode:    licenceCode,
            licenceLabel:   licenceLabel,
            licenceURL:     licenceURL,
            creditLine:     creditLine,
            imageStatus:    imageStatus,
            sourceNotes:    sourceNotes
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - InatSighting
// ─────────────────────────────────────────────────────────────────────────────

struct InatSighting: Codable, Hashable {
    let lat: Double
    let lng: Double
    let date: String?
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Computed display helpers
// ─────────────────────────────────────────────────────────────────────────────

extension Species {

    var displayName: String {
        // Use the Portuguese common name when pt-BR is active and available.
        // Fall back to English name, then scientific name.
        let isPtBR = LocaleManager.shared.current.identifier.hasPrefix("pt")
        if isPtBR, let local = localName { return local }
        return englishName ?? scientificName
    }

    var habitatDisplay: String? {
        guard let habitat, !habitat.isEmpty else { return nil }
        return habitat.joined(separator: " · ")
    }

    var sizeDisplay: String? {
        let locale = LocaleManager.shared.current
        let avg_label = LocaleManager.shared.localizedString("size.avg", defaultValue: "Avg.")
        let max_label = LocaleManager.shared.localizedString("size.max", defaultValue: "max")
        switch (avgSizeCm, maxSizeCm) {
        case let (avg?, max?):
            return "\(avg_label) \(formatCm(avg)) · \(max_label) \(formatCm(max))"
        case let (avg?, nil):
            return "\(avg_label) \(formatCm(avg))"
        case let (nil, max?):
            return "\(max_label) \(formatCm(max))"
        case (nil, nil):
            return nil
        }
    }

    private func formatCm(_ value: Double) -> String {
        let formatted = value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
        return "\(formatted) cm"
    }

    var aboutText: String? {
        description
    }

    var venomClosingSentence: String? {
        guard let venomType else { return nil }
        // "venom." suffix is already baked into the pt-BR venomType values
        // in translations.pt-BR.json (e.g. "Hemotóxico").
        // For English we append " venom." to match the original behaviour.
        let isPtBR = LocaleManager.shared.current.identifier.hasPrefix("pt")
        if isPtBR { return venomType }
        return "\(venomType) venom."
    }

    var hasQuickFacts: Bool {
        venomStatus != nil || sizeDisplay != nil || habitatDisplay != nil || iucnStatus != nil
    }

    var hasSightings: Bool {
        guard let inatSightings else { return false }
        return !inatSightings.isEmpty
    }

    var hasImageCredit: Bool {
        guard let creditLine, !creditLine.isEmpty else { return false }
        return imageStatus == "ok"
    }
}
