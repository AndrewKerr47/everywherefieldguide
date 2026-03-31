#!/usr/bin/env python3
"""
merge_image_credits.py
Carajás Field Guide — merge image credits into species.json

Reads:
  - species.json              (existing species data)
  - carajas_image_credits.json (output from inat_image_pipeline.py v3)

Writes:
  - species.json              (updated in place)

Changes per species:
  - Adds: source, photo_url, source_url, observer, observer_url,
          licence_code, licence_label, licence_url, credit_line,
          image_status
  - Updates: inat_image_url → replaced with photo_url where pipeline
             found a better/different image
  - Species with no resolved image get image_status: "needs_outreach"
  - All other existing fields are untouched

Usage:
    python3 merge_image_credits.py

Place alongside both JSON files.
"""

import os
import json
import sys

SCRIPT_DIR   = os.path.dirname(os.path.abspath(__file__))
SPECIES_JSON = os.path.join(SCRIPT_DIR, "species.json")
CREDITS_JSON = os.path.join(SCRIPT_DIR, "carajas_image_credits.json")

# ── Load files ────────────────────────────────────────────────────────────────

if not os.path.exists(SPECIES_JSON):
    print(f"ERROR: species.json not found at {SPECIES_JSON}")
    sys.exit(1)

if not os.path.exists(CREDITS_JSON):
    print(f"ERROR: carajas_image_credits.json not found at {CREDITS_JSON}")
    sys.exit(1)

with open(SPECIES_JSON, "r", encoding="utf-8") as f:
    species_list = json.load(f)

with open(CREDITS_JSON, "r", encoding="utf-8") as f:
    credits_list = json.load(f)

# Build lookup dict by scientific_name
credits_by_name = {c["scientific_name"]: c for c in credits_list}

print(f"Loaded {len(species_list)} species from species.json")
print(f"Loaded {len(credits_list)} credit records from carajas_image_credits.json")
print()

# ── Merge ─────────────────────────────────────────────────────────────────────

updated     = 0
no_credit   = 0
source_tally = {"inat": 0, "gbif": 0, "wikimedia": 0}

for species in species_list:
    name   = species["scientific_name"]
    credit = credits_by_name.get(name)

    if credit:
        # Update inat_image_url with the pipeline-resolved photo URL
        # (may be from GBIF or Wikimedia, not just iNat)
        species["inat_image_url"] = credit.get("photo_url", species.get("inat_image_url"))

        # Add all new credit fields
        species["image_source"]   = credit.get("source", "")
        species["source_url"]     = credit.get("source_url", "")
        species["observer"]       = credit.get("observer", "")
        species["observer_url"]   = credit.get("observer_url", "")
        species["licence_code"]   = credit.get("licence_code", "")
        species["licence_label"]  = credit.get("licence_label", "")
        species["licence_url"]    = credit.get("licence_url", "")
        species["credit_line"]    = credit.get("credit_line", "")
        species["image_status"]   = "ok"

        src = credit.get("source", "")
        if src in source_tally:
            source_tally[src] += 1

        updated += 1
        print(f"  OK  [{src:10}]  {name}")

    else:
        # No credit resolved — flag for manual outreach
        species["image_source"]   = ""
        species["source_url"]     = ""
        species["observer"]       = ""
        species["observer_url"]   = ""
        species["licence_code"]   = ""
        species["licence_label"]  = ""
        species["licence_url"]    = ""
        species["credit_line"]    = ""
        species["image_status"]   = "needs_outreach"

        no_credit += 1
        print(f"  NEEDS OUTREACH       {name}")

# ── Write updated species.json ────────────────────────────────────────────────

with open(SPECIES_JSON, "w", encoding="utf-8") as f:
    json.dump(species_list, f, indent=2, ensure_ascii=False)

print()
print("=" * 60)
print(f"MERGE COMPLETE")
print(f"  Species updated with credit:  {updated}")
print(f"  Species needing outreach:     {no_credit}")
print()
print(f"  From iNat:       {source_tally['inat']}")
print(f"  From GBIF:       {source_tally['gbif']}")
print(f"  From Wikimedia:  {source_tally['wikimedia']}")
print()
print(f"species.json saved to: {SPECIES_JSON}")
print()
print("Next steps:")
print("  1. Copy updated species.json into Xcode project Resources/")
print("  2. Update SpeciesDetailView to display credit_line")
print("  3. Update DownloadView image pipeline for GBIF/Wikimedia URLs")
print("  4. Draft outreach messages for needs_outreach species")
