# Field Guide Pipeline
## Version 1.0 — March 2026

A reusable system for building scientifically rigorous, commercially
deployable species datasets for mobile field guide applications.

---

## Architecture

The pipeline is split into two layers:

**Layer 1 — Claude-led (research & editorial)**
Handles literature search, taxonomy validation, species data population,
and audit report generation. Runs interactively with human checkpoints.

**Layer 2 — Python-led (mechanical & repeatable)**
Handles iNaturalist queries, image retrieval with licence checking, and
JSON assembly. Fully automated once `master_dataset.csv` is ready.

---

## File Structure

```
fieldguide_pipeline/
├── SYSTEM_PROMPT.md              — Claude system prompt (load into Claude Project)
│
├── rules/
│   ├── paper_quality_tiers.md   — Journal tiers, qualifying criteria
│   ├── licence_rules.md         — Permitted licences, image source priority
│   ├── inat_filters.md          — iNat API parameters and taxon group IDs
│   └── taxonomy_sources.md      — Authoritative taxonomy per taxon group
│
├── schemas/
│   ├── species_schema.md        — species.json field definitions
│   ├── image_credits_schema.md  — image_credits.json structure
│   └── audit_report_schema.md   — audit report structure
│
├── scripts/
│   ├── run_pipeline.sh          — runs all Layer 2 scripts in order
│   ├── bounding_box_resolver.py — resolves area name to lat/lng bbox
│   ├── inat_sightings.py        — fetches sightings + obs counts from iNat
│   ├── inat_obs_count_lookup.py — standalone obs count refresh utility
│   ├── inat_image_pipeline.py   — fetches images (iNat → GBIF → Wikimedia)
│   ├── merge_image_credits.py   — merges credits into species.json
│   └── json_assembler.py        — assembles final species.json
│
└── outputs/                     — generated per project run (not committed)
    ├── bbox.json
    ├── master_dataset.csv
    ├── inat_sightings.json
    ├── carajas_image_credits.json
    ├── species.json
    ├── image_credits.json
    ├── assembly_report.txt
    ├── paper_validation_log.md
    └── audit_report.md
```

---

## Quick Start

### Step 1 — Set up Claude Project

1. Create a new Claude Project
2. Set `SYSTEM_PROMPT.md` as the system prompt
3. Upload all files from `rules/` and `schemas/` to the project knowledge

### Step 2 — Start a pipeline run

Trigger Claude with the four inputs:

```
AREA: Serra dos Carajás National Forest, Pará, Brazil
TAXON GROUP: reptiles & amphibians
LOCAL LANGUAGE: Portuguese
CONTACT EMAIL: yourname@email.com
```

Claude will work through Steps 1–5, pausing at each human checkpoint.

### Step 3 — Human checkpoints

Claude pauses at four points requiring human input:

| Checkpoint | What to review | Time estimate |
|---|---|---|
| 1 — Paper validation | 2–5 paper assessments | 15–30 min |
| 2 — Taxonomy conflicts | Flagged name conflicts only | 5–15 min |
| 3 — Image proof sheet | Thumbnail scan | 10 min |
| 4 — Audit report sign-off | Full report review | 20–30 min |

### Step 4 — Run Layer 2 scripts

Once Claude outputs `master_dataset.csv` (after Checkpoint 1 approval):

```bash
cd scripts/
pip3 install requests pandas
bash run_pipeline.sh
```

This runs:
1. `bounding_box_resolver.py` — resolves area to lat/lng
2. `inat_sightings.py` — fetches sightings and obs counts
3. `inat_image_pipeline.py` — fetches commercial-licence images
4. `json_assembler.py` — assembles and validates species.json

### Step 5 — Copy to Xcode

```bash
cp outputs/species.json path/to/XcodeProject/Resources/species.json
```

---

## Dependencies

```bash
pip3 install requests pandas
```

Python 3.9+ required.

---

## Human Checkpoint Detail

### Checkpoint 1 — Paper Validation
Claude presents 2–5 paper assessments. You approve or reject each.
Minimum 1 approval required to proceed. You may substitute papers
Claude did not find.

### Checkpoint 2 — Taxonomy Conflicts
Only flagged conflicts are presented. Each requires a decision:
accept Claude's recommendation or override with a specific name.

### Checkpoint 3 — Image Proof Sheet
Claude generates an HTML file showing thumbnails for every resolved
species. Scan for obvious species mismatches. Flag any errors.

### Checkpoint 4 — Audit Report Sign-off
Review `audit_report.md`. Resolve all duplicate name flags. Accept
or defer missing data items. Sign off before Xcode handover.

---

## Adding a New Area / Taxon

1. Start a new Claude session with the same Project
2. Supply the new inputs (area, taxon group, local language, email)
3. Follow the same step sequence
4. All scripts are reusable — only `master_dataset.csv` changes per run

---

## Version Log

| Version | Date       | Changes |
|---------|------------|---------|
| 1.0     | March 2026 | Initial release — built from Carajás Field Guide pipeline |
