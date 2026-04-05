# Licence Rules
## Carajás Field Guide — Reusable Pipeline

---

## Purpose

This document defines which image licences are permitted for commercial
use in the app, the priority chain for image sources, and how credit
lines are formatted. Referenced by SYSTEM_PROMPT.md and the image
pipeline scripts.

---

## Commercial Use — Permitted Licences

The app is intended for commercial distribution. Only images carrying
the following licences may be used without explicit photographer permission:

| Licence Code | Display Label | Notes |
|---|---|---|
| cc0 | CC0 | Public domain — no attribution required but always credit |
| cc-by | CC BY | Attribution required |
| cc-by-sa | CC BY-SA | Attribution + share-alike |
| cc-by-nd | CC BY-ND | Attribution + no derivatives. Thumbnails and resized display images are considered acceptable use under this licence |

---

## Blocked Licences

The following licences do NOT permit commercial use and must not be used
without explicit written permission from the photographer:

| Licence Code | Reason |
|---|---|
| cc-by-nc | Non-commercial only |
| cc-by-nc-sa | Non-commercial only |
| cc-by-nc-nd | Non-commercial only |
| All Rights Reserved | No licence granted |
| Empty / unknown | Treat as All Rights Reserved until verified |

---

## Image Source Priority Chain

For each species, attempt sources in this order. Move to the next source
only if the current source yields no commercially usable image.

1. **iNaturalist** — research-grade observations, ordered by vote count
   (highest quality first). Up to 10 photos checked per species.
2. **GBIF** — occurrence media attached to research observations.
   Up to 20 occurrences checked per species.
3. **Wikimedia Commons** — file namespace search by scientific name.
   Top 5 results checked per species.
4. **Manual outreach** — flag species for photographer contact if all
   three automated sources are exhausted.

---

## Multi-Image Rules

Each species may carry up to 3 images. All three must independently
pass the commercial licence filter.

- **Image 0** — primary / hero image. Best quality, clearest ID shot.
- **Image 1** — supplementary. Ideally a different angle, life stage,
  or habitat context from a different source than Image 0.
- **Image 2** — supplementary. Further diversity of source or subject.

Do not fill all 3 slots from a single source if alternatives exist.
Prefer source diversity across the 3 slots.

Species with only 1 or 2 usable images proceed normally — the images
array simply contains fewer entries.

---

## Verification for Empty Licence Codes

When a source returns an empty or null licence code:
1. Fetch the individual observation/occurrence record directly
2. Check the observation-level licence field
3. Check the photo-level licence field
4. Parse the attribution string for CC licence text
5. If still unresolved after all four checks — treat as blocked

---

## Credit Line Format

Each image gets a pre-formatted credit line for display in the app.
Format by source:

| Source | Format |
|---|---|
| iNaturalist | `© {observer} via iNaturalist ({licence_label})` |
| GBIF | `© {observer} via GBIF ({licence_label})` |
| Wikimedia | `© {author} / Wikimedia Commons ({licence_label})` |
| Explicit permission | `© {photographer name}, used with permission` |

If observer/author name is unavailable, omit the name and credit
the platform only: e.g. `via iNaturalist (CC BY)`.

---

## needs_outreach Flag

Species where all automated sources are exhausted receive:
- `image_status: "needs_outreach"`
- Empty credit fields
- Existing iNat image URL retained for display (if present)
- White 50% overlay + warning icon in DEBUG builds only

---

## Version Log

| Version | Date       | Changes                          |
|---------|------------|----------------------------------|
| 1.0     | March 2026 | Initial version — Carajás Field Guide pipeline |
