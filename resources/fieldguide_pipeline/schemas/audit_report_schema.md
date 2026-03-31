# Audit Report Schema
## Carajás Field Guide — Reusable Pipeline

---

## Purpose

This document defines the structure of `audit_report.md` — the human-
readable report generated at the end of each pipeline run. It surfaces
all flags, gaps, and issues that require human review before the dataset
is committed to Xcode.

The audit report is the final human checkpoint before `species.json`
goes into the app.

---

## Report Structure

The audit report is a markdown document with the following sections
in order:

---

### 1. Run Summary

```
# Audit Report — [Area Name] [Taxon Group]
Generated: [ISO-8601 datetime]
Pipeline version: [version]

## Run Summary
- Target area:        [Area name + bounding box]
- Taxon group:        [Group]
- Local language:     [Language for vernacular names]
- Papers approved:    [N]
- Species confirmed:  [N]
- Species from papers only: [N]
- Species from iNat only:   [N]
- Species from both:        [N]
- Images resolved:    [N] / [total] ([%])
- Needs outreach:     [N]
```

---

### 2. Approved Papers

Lists all papers used as sources, with their assigned survey IDs.

```
## Approved Papers

| ID | Citation | Tier | Species contributed |
|---|---|---|---|
| CN-1985 | Cunha et al. 1985... | 4 | 42 |
| UFSC-2023 | UFSC thesis... | 4 | 38 |
```

---

### 3. Duplicate Name Flags

Lists any cases where two or more species share the same English name
or the same local/vernacular name.

```
## Duplicate Name Flags
ACTION REQUIRED — resolve before release

### Duplicate English Names
- "Four-eyed Ground Snake" — used by:
  - Adelphostigma quadriocellata
  - Taeniophallus quadriocellatus
  Recommendation: [Claude's suggested resolution]

### Duplicate Local Names
- "cobra-de-chão-quatro-ocelos" — used by:
  - Adelphostigma quadriocellata
  - Taeniophallus quadriocellatus
  Recommendation: [Claude's suggested resolution]
```

If no duplicates: `No duplicate names found.`

---

### 4. Taxonomy Conflict Flags

Lists species where primary taxonomy authority and GBIF/iNat disagree
on the accepted name.

```
## Taxonomy Conflict Flags
ACTION REQUIRED — human resolution needed

- Chironius flavolineata / flavolineatus
  Primary authority (Reptile Database): Chironius flavolineatus
  iNaturalist: Chironius flavolineatus (taxon #29907)
  GBIF: Chironius flavolineata
  Recommendation: Use Chironius flavolineatus — matches iNat taxon ID
  Status: [RESOLVED / PENDING]
```

If no conflicts: `No taxonomy conflicts found.`

---

### 5. Missing Data Flags

Lists species with significant data gaps that may affect app quality.

```
## Missing Data Flags
REVIEW RECOMMENDED

### No description
Species with null description field (N total):
- Atractus tartarus
- Chironius exoletus
[...]

### No size data
Species with null avg_size_cm and max_size_cm (N total):
- [list]

### No IUCN status
Species with null iucn_status (N total):
- [list]

### No habitat
Species with null habitat (N total):
- [list]
```

---

### 6. Image Status

Full breakdown of image resolution results.

```
## Image Status

### Resolved (N species)
| Species | Source | Licence | Images |
|---|---|---|---|
| Bothrops atrox | inat | CC BY | 3 |
| Lachesis muta | gbif | CC BY-SA | 2 |
[...]

### Needs Outreach (N species)
Species where all automated sources were exhausted:
- Xenopholis undulatus
- Adelphostigma quadriocellata
[...]
Recommended action: Contact iNaturalist observers directly.
See licence_rules.md for outreach guidance.
```

---

### 7. iNat Taxon ID Issues

Lists species where the iNat taxon ID could not be resolved or where
the ID appears to be incorrect.

```
## iNat Taxon ID Issues

- Apostolepis quinquelineata — no numeric taxon ID found.
  iNat URL uses name-based fallback. Manual verification recommended.

- Dendrophidion dendrophis — API returned 422 error.
  Taxon ID 29212 may be inactive. Check iNat taxon page directly.
```

If no issues: `No iNat taxon ID issues found.`

---

### 8. Sign-off

```
## Sign-off

Reviewer: ______________________
Date: ______________________

Flags resolved:
  [ ] Duplicate names
  [ ] Taxonomy conflicts
  [ ] Image outreach initiated
  [ ] Missing data reviewed and accepted

Dataset approved for Xcode: [ ] Yes  [ ] No — pending [reason]
```

---

## Version Log

| Version | Date       | Changes                          |
|---------|------------|----------------------------------|
| 1.0     | March 2026 | Initial version — Carajás Field Guide pipeline |
