#!/usr/bin/env python3
"""
fix_boa.py
Carajás Field Guide — Targeted Boa constrictor fix
----------------------------------------------------
Corrects the iNaturalist taxon URL and image for Boa constrictor,
which was incorrectly linked to Boa imperator (Central American form)
after the taxonomic split.

Correct taxon: Boa constrictor constrictor (Amazonian nominate subspecies)
iNat ID: 115434

Usage (run from AK_fieldGuide/ folder):
    python3 fix_boa.py
"""

import json
import sys
from pathlib import Path

import requests

# ── Paths ─────────────────────────────────────────────────────────────────────

SCRIPT_DIR   = Path(__file__).parent
SPECIES_JSON = SCRIPT_DIR / "CarajasFieldGuide/CarajasFieldGuide/Resources/species.json"

# ── Correct taxon ─────────────────────────────────────────────────────────────

CORRECT_TAXON_ID  = 115434
CORRECT_TAXON_URL = "https://www.inaturalist.org/taxa/115434-Boa-constrictor-constrictor"
INAT_API          = "https://api.inaturalist.org/v1"

# ── Fetch correct image URL ───────────────────────────────────────────────────

def fetch_image_url(taxon_id: int) -> str:
    """Fetch the default medium photo URL for a taxon from iNat API."""
    try:
        r = requests.get(f"{INAT_API}/taxa/{taxon_id}", timeout=15)
        r.raise_for_status()
        taxon = r.json().get("results", [{}])[0]
        photo = taxon.get("default_photo")
        if photo:
            url = photo.get("medium_url") or photo.get("square_url")
            if url:
                return url
    except Exception as e:
        print(f"  ✗ API error fetching image: {e}")
    return None

# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    if not SPECIES_JSON.exists():
        print(f"✗ species.json not found at:\n  {SPECIES_JSON}")
        print("  Make sure you run this from the AK_fieldGuide/ folder.")
        sys.exit(1)

    with open(SPECIES_JSON, encoding="utf-8") as f:
        species_list = json.load(f)

    # Find Boa constrictor
    target = next(
        (s for s in species_list if s.get("scientific_name") == "Boa constrictor"),
        None
    )

    if not target:
        print("✗ 'Boa constrictor' not found in species.json")
        sys.exit(1)

    print("Found: Boa constrictor")
    print(f"  Current inat_taxon_url : {target.get('inat_taxon_url')}")
    print(f"  Current inat_image_url : {target.get('inat_image_url')}")
    print()

    # Fix taxon URL
    target["inat_taxon_url"] = CORRECT_TAXON_URL
    print(f"  ✓ inat_taxon_url updated to:\n    {CORRECT_TAXON_URL}")

    # Fetch and fix image URL
    print(f"\n  Fetching image from iNat taxon {CORRECT_TAXON_ID}...")
    image_url = fetch_image_url(CORRECT_TAXON_ID)

    if image_url:
        target["inat_image_url"] = image_url
        print(f"  ✓ inat_image_url updated to:\n    {image_url}")
    else:
        print("  ⚠️  Could not fetch image URL — inat_image_url unchanged")
        print("     Check https://www.inaturalist.org/taxa/115434 manually")

    # Write back
    with open(SPECIES_JSON, "w", encoding="utf-8") as f:
        json.dump(species_list, f, ensure_ascii=False, indent=2)

    print(f"\n✓ species.json updated at:\n  {SPECIES_JSON}")
    print("\n  Next step: Cmd+R in Xcode to pick up the updated species.json")

if __name__ == "__main__":
    main()
