# species.json Schema
## Carajás Field Guide — Reusable Pipeline

---

## Purpose

This document defines the complete schema for `species.json` — the
primary data file consumed by the iOS app. Every field is defined with
its type, whether it is required or optional, its source, and accepted
values where applicable.

The JSON assembler script (`json_assembler.py`) validates all output
against this schema before writing the final file.

---

## Top-level Structure

`species.json` is a JSON array of species objects. Each object
represents one confirmed species.

```json
[
  { ...species object... },
  { ...species object... }
]
```

---

## Species Object Fields

### Identity

| Field | Type | Required | Source | Notes |
|---|---|---|---|---|
| `scientific_name` | string | YES | Approved paper / taxonomy authority | Accepted name per taxonomy_sources.md. Never a synonym. |
| `english_name` | string | NO | IUCN / iNat / literature | Common English name. Null if none established. |
| `local_name` | string | NO | Regional literature / iNat | Vernacular name in the prevalent local language for the area. Null if none established. |
| `taxon_group` | string | YES | User input | One of: `snake` `lizard` `turtle` `amphibian` `bird` `mammal` |
| `survey_taxon_original` | string | NO | Approved paper | Name as it appeared in the source paper if different from accepted name. |

### Venom & Safety (reptiles only)

| Field | Type | Required | Source | Notes |
|---|---|---|---|---|
| `venom_status` | string | NO | Literature / IUCN | One of: `dangerous` `mild` `low_risk` `non_venomous`. Null for non-reptile groups. |
| `venom_type` | string | NO | Literature | One of: `Hemotoxic` `Neurotoxic` `Cytotoxic` `Hemotoxic and Neurotoxic`. Null if non-venomous or unknown. |

### Conservation

| Field | Type | Required | Source | Notes |
|---|---|---|---|---|
| `iucn_status` | string | NO | IUCN Red List API | One of: `LC` `NT` `VU` `EN` `CR` `EW` `EX`. Null if not assessed. |

### Physical

| Field | Type | Required | Source | Notes |
|---|---|---|---|---|
| `avg_size_cm` | number | NO | Literature / IUCN | Average adult body length in centimetres. |
| `max_size_cm` | number | NO | Literature / IUCN | Maximum recorded body length in centimetres. |

### Ecology

| Field | Type | Required | Source | Notes |
|---|---|---|---|---|
| `habitat` | array of strings | NO | Literature / IUCN | Controlled vocabulary — see Habitat Values below. |
| `description` | string | NO | Claude-authored, citing sources | Free-text species description. Do not include venom type — appended by the UI. Null if insufficient data. |

### Survey Presence

| Field | Type | Required | Source | Notes |
|---|---|---|---|---|
| `survey_presence` | array of survey objects | NO | Approved papers | One entry per approved paper that confirms this species. See Survey Object below. |

### iNaturalist

| Field | Type | Required | Source | Notes |
|---|---|---|---|---|
| `inat_observations` | integer | NO | iNat API (bbox query) | Observation count within bounding box. Null if zero or not queried. |
| `inat_taxon_url` | string | NO | iNat API | Full URL to the iNat taxon page. |
| `inat_sightings` | array of sighting objects | NO | iNat API (bbox query) | Georeferenced observations within bbox. Empty array if none. See Sighting Object below. |

### Images

| Field | Type | Required | Source | Notes |
|---|---|---|---|---|
| `images` | array of image objects | NO | Image pipeline | Up to 3 images. Index 0 = primary/hero. See Image Object below. |
| `inat_image_url` | string | NO | Image pipeline | Primary image URL — mirrors `images[0].photo_url`. Retained for backward compatibility. |
| `image_status` | string | NO | Image pipeline | One of: `ok` `needs_outreach`. Null if not yet processed. |

### Source

| Field | Type | Required | Source | Notes |
|---|---|---|---|---|
| `source_notes` | string | NO | Claude-authored | Survey citation and iNat taxon reference. Shown in source footer. |

---

## Survey Object

```json
{
  "id": "CN-1985",
  "name": "Cunha et al. 1985",
  "url": "https://doi.org/..."
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | YES | Short unique identifier. Format: `INITIALS-YEAR` e.g. `CN-1985` `UFSC-2023` |
| `name` | string | YES | Display name for the survey pill |
| `url` | string | NO | DOI or direct URL to the paper |

---

## Sighting Object

```json
{
  "lat": -6.107783,
  "lng": -49.841889,
  "date": "2026-01-27"
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `lat` | number | YES | Decimal degrees WGS84 |
| `lng` | number | YES | Decimal degrees WGS84 |
| `date` | string | NO | ISO-8601 format YYYY-MM-DD. Null if not recorded. |

---

## Image Object

```json
{
  "photo_url": "https://...",
  "source": "inat",
  "source_url": "https://www.inaturalist.org/observations/12345",
  "observer": "jsilva",
  "observer_url": "https://www.inaturalist.org/people/jsilva",
  "licence_code": "cc-by",
  "licence_label": "CC BY",
  "licence_url": "https://creativecommons.org/licenses/by/4.0/",
  "credit_line": "© jsilva via iNaturalist (CC BY)"
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `photo_url` | string | YES | Direct URL to the medium-size image |
| `source` | string | YES | One of: `inat` `gbif` `wikimedia` `permission` |
| `source_url` | string | NO | URL to the observation, occurrence, or Wikimedia file page |
| `observer` | string | NO | Photographer/observer name for attribution |
| `observer_url` | string | NO | URL to the observer's profile or author page |
| `licence_code` | string | YES | SPDX-style code: `cc0` `cc-by` `cc-by-sa` `cc-by-nd` |
| `licence_label` | string | YES | Display label: `CC0` `CC BY` `CC BY-SA` `CC BY-ND` |
| `licence_url` | string | NO | Canonical Creative Commons licence URL |
| `credit_line` | string | YES | Pre-formatted attribution string for display in app |

---

## Habitat Values

Controlled vocabulary for the `habitat` array.
Multiple values allowed per species.

| Value | Meaning |
|---|---|
| `Forest` | Closed-canopy forest, terra firme or várzea |
| `Riparian` | River and stream margins, gallery forest |
| `Grassland` | Open grassland, campo, savanna |
| `Wetland` | Swamp, flooded areas, marsh |
| `Canga` | Ironstone outcrop vegetation (Carajás-specific) |
| `Urban` | Human-modified environments |
| `Aquatic` | Primarily water-dwelling |
| `Arboreal` | Primarily tree-dwelling |
| `Fossorial` | Primarily subterranean |
| `Coastal` | Coastal and mangrove habitats |
| `Montane` | High-altitude habitats |

---

## Validation Rules

The JSON assembler enforces these rules before writing the output file:

1. `scientific_name` and `taxon_group` must be present for every species
2. `taxon_group` must be one of the accepted values
3. `venom_status` must be one of the accepted values or null
4. `iucn_status` must be one of the accepted values or null
5. `images` array must contain 0–3 entries
6. Each image object must have `photo_url`, `source`, `licence_code`,
   `licence_label`, and `credit_line`
7. `source` in each image object must be one of the accepted values
8. `habitat` entries must be from the controlled vocabulary
9. No two species may share the same `scientific_name`
10. `inat_image_url` must mirror `images[0].photo_url` when images exist

---

## Version Log

| Version | Date       | Changes                          |
|---------|------------|----------------------------------|
| 1.0     | March 2026 | Initial version — Carajás Field Guide pipeline. Multi-image array added. |
