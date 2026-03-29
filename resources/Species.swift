import Foundation

// ─────────────────────────────────────────────────────────────────────────────
// Species.swift
// Carajás Field Guide
//
// Core data model. Every field mirrors the schema in MasterDoc v0.3 Section 8.1.
// All fields are optional except scientificName and taxonGroup.
// No force-unwrapping anywhere — nil fields are omitted from the UI entirely.
// ─────────────────────────────────────────────────────────────────────────────

struct Species: Codable, Identifiable, Hashable {

    // ── Identity ──────────────────────────────────────────────────────────────

    /// Stable unique identifier for list/navigation use.
    /// Derived from scientificName if not provided in JSON.
    var id: String { scientificName }

    /// Canonical accepted scientific name. Required. Never null.
    let scientificName: String

    /// Common English name. Shown as hero headline and list row primary label.
    let englishName: String?

    /// Portuguese or regional vernacular name. Used in search.
    let localName: String?

    /// Taxonomic group: snake / bird / amphibian / lizard / mammal
    let taxonGroup: String

    // ── Venom & safety ────────────────────────────────────────────────────────

    /// Four-state venom classification. Drives skull/smiley icon and colour.
    let venomStatus: VenomStatus?

    /// Venom type string (Hemotoxic / Neurotoxic / Cytotoxic).
    /// Appended as closing sentence in the About paragraph.
    let venomType: String?

    // ── Conservation ─────────────────────────────────────────────────────────

    /// IUCN Red List category. Drives (XX) badge colour.
    let iucnStatus: IUCNStatus?

    // ── Physical ─────────────────────────────────────────────────────────────

    /// Average body length in centimetres.
    let avgSizeCm: Double?

    /// Maximum recorded body length in centimetres.
    let maxSizeCm: Double?

    // ── Ecology ───────────────────────────────────────────────────────────────

    /// Habitat type(s). Controlled vocabulary: Forest, Riparian, Grassland,
    /// Wetland, Canga, Urban. Multiple values joined with " · " for display.
    let habitat: [String]?

    /// Free-text species description. Shown in About section.
    /// venomType is appended as a closing sentence by the UI — do not duplicate here.
    let description: String?

    // ── Survey presence ───────────────────────────────────────────────────────

    /// Array of surveys in which this species was recorded.
    /// Each survey renders as a tappable pill linking to its URL.
    let surveyPresence: [Survey]?

    // ── iNaturalist ───────────────────────────────────────────────────────────

    /// Observation count from iNaturalist. Used as relative visibility proxy.
    /// Not a measure of abundance.
    let inatObservations: Int?

    /// iNaturalist taxon page URL (not used for display in MVP — future use).
    let inatTaxonURL: String?

    /// Representative image URL loaded as hero image.
    /// May point to iNat, GBIF, or Wikimedia Commons depending on pipeline result.
    let inatImageURL: String?

    /// Georeferenced observation coordinates from iNaturalist within the
    /// Carajás bounding box. Empty array = no observations in region.
    /// Used to render the sightings map in SpeciesDetailView.
    let inatSightings: [InatSighting]?

    // ── Image credit ──────────────────────────────────────────────────────────

    /// Source platform for the hero image: "inat" / "gbif" / "wikimedia".
    /// Empty string or nil = no image resolved.
    let imageSource: String?

    /// Direct URL to the observation, occurrence, or Wikimedia file page.
    /// Tappable from the image credit block.
    let sourceURL: String?

    /// Observer/photographer name as it should appear in the credit line.
    let observer: String?

    /// URL to the observer's iNat profile, GBIF page, or Wikimedia author page.
    let observerURL: String?

    /// SPDX-style licence code: "cc0" / "cc-by" / "cc-by-sa" / "cc-by-nd".
    let licenceCode: String?

    /// Human-readable licence label: "CC0" / "CC BY" / "CC BY-SA" / "CC BY-ND".
    let licenceLabel: String?

    /// Canonical Creative Commons licence URL.
    let licenceURL: String?

    /// Pre-formatted credit string ready for display in the UI.
    /// e.g. "© jsilva via iNaturalist (CC BY)"
    /// Nil if no image was resolved.
    let creditLine: String?

    /// Pipeline resolution status: "ok" / "needs_outreach" / nil.
    let imageStatus: String?

    // ── Source ────────────────────────────────────────────────────────────────

    /// Survey citation and iNaturalist taxon reference. Shown in source footer.
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
// MARK: - InatSighting
// ─────────────────────────────────────────────────────────────────────────────

/// A single georeferenced iNaturalist observation.
/// Used to render pins on the species sightings map.
struct InatSighting: Codable, Hashable {

    /// Latitude in decimal degrees (WGS84).
    let lat: Double

    /// Longitude in decimal degrees (WGS84).
    let lng: Double

    /// Observation date as ISO-8601 string (YYYY-MM-DD). Optional — some
    /// iNat records have no date or only a partial date.
    let date: String?
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Computed display helpers
// ─────────────────────────────────────────────────────────────────────────────

extension Species {

    /// The name to use as the primary display label throughout the app.
    /// Falls back to scientificName if no English name is available.
    var displayName: String {
        englishName ?? scientificName
    }

    /// Habitat values joined for display in the fact row.
    /// e.g. ["Forest", "Riparian"] → "Forest · Riparian"
    var habitatDisplay: String? {
        guard let habitat, !habitat.isEmpty else { return nil }
        return habitat.joined(separator: " · ")
    }

    /// Size string for the fact row.
    /// Returns nil if both values are absent.
    var sizeDisplay: String? {
        switch (avgSizeCm, maxSizeCm) {
        case let (avg?, max?):
            return "Avg. \(formatCm(avg)) · max \(formatCm(max))"
        case let (avg?, nil):
            return "Avg. \(formatCm(avg))"
        case let (nil, max?):
            return "Max \(formatCm(max))"
        case (nil, nil):
            return nil
        }
    }

    /// Formats a cm value — removes trailing .0 for whole numbers.
    private func formatCm(_ value: Double) -> String {
        let formatted = value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
        return "\(formatted) cm"
    }

    /// Full about text with venom type appended as closing sentence.
    var aboutText: String? {
        description
    }

    /// Venom closing sentence for display as a separate styled paragraph.
    var venomClosingSentence: String? {
        guard let venomType else { return nil }
        return "\(venomType) venom."
    }

    /// Whether this species has any displayable quick facts.
    var hasQuickFacts: Bool {
        venomStatus != nil || sizeDisplay != nil || habitatDisplay != nil || iucnStatus != nil
    }

    /// Whether this species has any iNaturalist sightings to display on the map.
    var hasSightings: Bool {
        guard let inatSightings else { return false }
        return !inatSightings.isEmpty
    }

    /// Whether the hero image has a resolved credit to display.
    var hasImageCredit: Bool {
        guard let creditLine, !creditLine.isEmpty else { return false }
        return imageStatus == "ok"
    }
}
