# image_credits.json Schema
## Carajás Field Guide — Reusable Pipeline

---

## Purpose

This document defines the structure of `image_credits.json` — the
standalone credits file output by the image pipeline. It is merged into
`species.json` by `merge_image_credits.py` and also retained as an
independent audit record of all image attributions.

---

## Top-level Structure

`image_credits.json` is a JSON array. Each entry represents one species
with at least one resolved image.

```json
[
  { ...credits object... },
  { ...credits object... }
]
```

Species with `image_status: "needs_outreach"` are NOT included in this
file — they appear only in the audit report.

---

## Credits Object

```json
{
  "scientific_name": "Bothrops atrox",
  "image_status": "ok",
  "images": [
    {
      "photo_url": "https://inaturalist-open-data.s3.amazonaws.com/photos/28285205/medium.jpeg",
      "source": "inat",
      "source_url": "https://www.inaturalist.org/observations/12345678",
      "observer": "jsilva",
      "observer_url": "https://www.inaturalist.org/people/jsilva",
      "licence_code": "cc-by",
      "licence_label": "CC BY",
      "licence_url": "https://creativecommons.org/licenses/by/4.0/",
      "credit_line": "© jsilva via iNaturalist (CC BY)"
    },
    {
      "photo_url": "https://api.gbif.org/v1/image/...",
      "source": "gbif",
      "source_url": "https://www.gbif.org/occurrence/987654321",
      "observer": "Maria Santos",
      "observer_url": "",
      "licence_code": "cc-by-sa",
      "licence_label": "CC BY-SA",
      "licence_url": "https://creativecommons.org/licenses/by-sa/4.0/",
      "credit_line": "© Maria Santos via GBIF (CC BY-SA)"
    }
  ]
}
```

---

## Field Definitions

### Top-level fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `scientific_name` | string | YES | Must match the accepted name in species.json exactly |
| `image_status` | string | YES | Always `ok` in this file — `needs_outreach` species are excluded |
| `images` | array | YES | 1–3 image objects. See Image Object below. |

### Image Object fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `photo_url` | string | YES | Direct URL to medium-size image. Must be publicly accessible. |
| `source` | string | YES | One of: `inat` `gbif` `wikimedia` `permission` |
| `source_url` | string | NO | URL to observation, occurrence record, or Wikimedia file page. Empty string if not available. |
| `observer` | string | NO | Photographer or observer name. Empty string if not available. |
| `observer_url` | string | NO | URL to observer profile or author page. Empty string if not available. |
| `licence_code` | string | YES | One of: `cc0` `cc-by` `cc-by-sa` `cc-by-nd` |
| `licence_label` | string | YES | One of: `CC0` `CC BY` `CC BY-SA` `CC BY-ND` |
| `licence_url` | string | NO | Canonical Creative Commons URL. Empty string if CC0. |
| `credit_line` | string | YES | Pre-formatted attribution for display. See licence_rules.md for format. |

---

## Merge Behaviour

When `merge_image_credits.py` merges this file into `species.json`:

1. Match on `scientific_name` (exact, case-sensitive)
2. Set `species.images` = the `images` array from this file
3. Set `species.inat_image_url` = `images[0].photo_url` (backward compat)
4. Set `species.image_status` = `ok`
5. Species not found in this file get `image_status: "needs_outreach"`
   and an empty `images` array

---

## Validation Rules

Before writing `image_credits.json`, the pipeline validates:

1. Every entry has a unique `scientific_name`
2. Every entry has at least 1 image object
3. No entry has more than 3 image objects
4. Every image object has `photo_url`, `source`, `licence_code`,
   `licence_label`, and `credit_line`
5. `source` is one of the accepted values
6. `licence_code` is one of the permitted commercial licences
7. No two images in the same species entry share the same `photo_url`

---

## Version Log

| Version | Date       | Changes                          |
|---------|------------|----------------------------------|
| 1.0     | March 2026 | Initial version. Multi-image array replacing single-image structure. |
