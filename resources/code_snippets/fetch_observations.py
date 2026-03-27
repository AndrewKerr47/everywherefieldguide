#!/usr/bin/env python3
"""
fetch_observations.py
Carajás Field Guide — iNaturalist Observations Pipeline
--------------------------------------------------------
Fetches up to 50 georeferenced observation coordinates per species
from the iNaturalist API and writes them into species.json as a new
`inat_sightings` field: [{lat, lng, date}, ...]

Usage (run from AK_fieldGuide/ folder on your Desktop):
    python3 fetch_observations.py

Writes to:
    CarajasFieldGuide/CarajasFieldGuide/Resources/species.json

Requirements:
    pip install requests
"""

import json
import re
import time
import sys
from pathlib import Path
from typing import Optional, List, Dict, Tuple

import requests

# ── Paths ────────────────────────────────────────────────────────────────────

SCRIPT_DIR   = Path(__file__).parent
SPECIES_JSON = SCRIPT_DIR / "CarajasFieldGuide/CarajasFieldGuide/Resources/species.json"

# ── iNat API config ───────────────────────────────────────────────────────────

INAT_API      = "https://api.inaturalist.org/v1"
MAX_PER_TAXON = 50      # observations to fetch per species
DELAY_SECS    = 1.1     # polite delay between API calls (iNat rate limit ~60/min)

# Bounding box for Serra dos Carajás region (Pará, Brazil)
# Wider than the park itself to catch nearby confirmed sightings
BBOX = {
    "swlat": -7.0,
    "swlng": -51.5,
    "nelat": -5.5,
    "nelng": -49.5,
}

# ── Helpers ───────────────────────────────────────────────────────────────────

def extract_taxon_id(url: str) -> Optional[int]:
    """
    Parse numeric taxon ID from an iNat taxa URL.
    Handles:
      https://www.inaturalist.org/taxa/32073-Anilius-scytale  → 32073
      https://www.inaturalist.org/taxa/Apostolepis%20quinquelineata → None (name-based)
    """
    if not url:
        return None
    match = re.search(r"/taxa/(\d+)", url)
    return int(match.group(1)) if match else None


def resolve_taxon_by_name(scientific_name: str) -> Optional[int]:
    """
    For species whose URL has no numeric ID, resolve via iNat taxa search.
    Returns the first exact-match taxon ID, or None.
    """
    print(f"  → Resolving taxon ID by name search: {scientific_name}")
    try:
        r = requests.get(
            f"{INAT_API}/taxa",
            params={"q": scientific_name, "rank": "species", "per_page": 5},
            timeout=15,
        )
        r.raise_for_status()
        results = r.json().get("results", [])
        for taxon in results:
            if taxon.get("name", "").lower() == scientific_name.lower():
                return taxon["id"]
        # If no exact match, return first result with a warning
        if results:
            print(f"    ⚠️  No exact match — using closest: {results[0]['name']} (ID {results[0]['id']})")
            return results[0]["id"]
    except Exception as e:
        print(f"    ✗ Name resolution failed: {e}")
    return None


def fetch_observations(taxon_id: int, scientific_name: str) -> List[Dict]:
    """
    Fetch up to MAX_PER_TAXON georeferenced observations for a taxon,
    constrained to the Carajás bounding box.
    Returns list of {lat, lng, date} dicts.
    """
    params = {
        "taxon_id":   taxon_id,
        "per_page":   MAX_PER_TAXON,
        "page":       1,
        "order":      "desc",
        "order_by":   "created_at",
        "geoprivacy": "open",          # only publicly mapped observations
        "geo":        "true",          # must have coordinates
        **BBOX,
    }

    try:
        r = requests.get(f"{INAT_API}/observations", params=params, timeout=20)
        r.raise_for_status()
        data = r.json()
    except Exception as e:
        print(f"    ✗ API error: {e}")
        return []

    sightings = []
    for obs in data.get("results", []):
        loc = obs.get("location")          # "lat,lng" string or None
        if not loc:
            continue
        try:
            lat_str, lng_str = loc.split(",")
            lat = round(float(lat_str), 6)
            lng = round(float(lng_str), 6)
        except ValueError:
            continue
        observed_on = obs.get("observed_on")
        time_observed = obs.get("time_observed_at") or ""
        date = observed_on or time_observed[:10] or None
        sightings.append({"lat": lat, "lng": lng, "date": date})

    return sightings


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    # ── Load species.json ──────────────────────────────────────────────────────
    if not SPECIES_JSON.exists():
        print(f"✗ species.json not found at:\n  {SPECIES_JSON}")
        print("  Make sure you run this script from the AK_fieldGuide/ folder.")
        sys.exit(1)

    with open(SPECIES_JSON, encoding="utf-8") as f:
        species_list = json.load(f)

    print(f"✓ Loaded species.json — {len(species_list)} species\n")

    # ── Known data issues ──────────────────────────────────────────────────────
    # The source CSV has the wrong taxon ID for Micrurus hemprichii (uses 30517
    # which is M. spixii). Correct iNat IDs confirmed at inaturalist.org:
    #   Micrurus spixii      → 30517  (correct in CSV)
    #   Micrurus hemprichii  → 30560  (wrong in CSV — overridden here)
    # This script also corrects the inat_taxon_url field in species.json.
    TAXON_ID_OVERRIDES = {
        "Micrurus hemprichii": (30560, "https://www.inaturalist.org/taxa/30560-Micrurus-hemprichii"),
    }

    # ── Stats ──────────────────────────────────────────────────────────────────
    total         = len(species_list)
    resolved      = 0
    zero_sightings = []
    warnings      = []

    # ── Process each species ───────────────────────────────────────────────────
    for i, species in enumerate(species_list, 1):
        name = species.get("scientific_name", f"[row {i}]")
        url  = species.get("inat_taxon_url") or ""

        print(f"[{i:02d}/{total}] {name}")

        # Determine taxon ID — apply override if present
        if name in TAXON_ID_OVERRIDES:
            taxon_id, correct_url = TAXON_ID_OVERRIDES[name]
            species["inat_taxon_url"] = correct_url
            print(f"  ℹ️  Taxon ID corrected: {taxon_id} (CSV had wrong ID — url updated)")
            warnings.append(f"{name}: taxon ID corrected to {taxon_id}, inat_taxon_url updated")
        else:
            taxon_id = extract_taxon_id(url)
            if taxon_id is None:
                taxon_id = resolve_taxon_by_name(name)
                time.sleep(DELAY_SECS)

        if taxon_id is None:
            print(f"  ✗ Could not resolve taxon ID — skipping")
            species["inat_sightings"] = []
            warnings.append(f"{name}: taxon ID could not be resolved")
            continue

        # Fetch observations
        sightings = fetch_observations(taxon_id, name)
        species["inat_sightings"] = sightings

        count = len(sightings)
        if count == 0:
            print(f"  ⚠️  0 sightings in bounding box")
            zero_sightings.append(name)
        else:
            print(f"  ✓ {count} sighting{'s' if count != 1 else ''}")
            resolved += 1

        time.sleep(DELAY_SECS)

    # ── Write updated species.json ─────────────────────────────────────────────
    with open(SPECIES_JSON, "w", encoding="utf-8") as f:
        json.dump(species_list, f, ensure_ascii=False, indent=2)

    # ── Summary report ─────────────────────────────────────────────────────────
    print("\n" + "─" * 60)
    print(f"✓ species.json updated at:\n  {SPECIES_JSON}")
    print(f"\n── Summary ──────────────────────────────────────────────")
    print(f"  Species processed:      {total}")
    print(f"  With ≥1 sighting:       {resolved}")
    print(f"  With 0 sightings:       {len(zero_sightings)}")

    if zero_sightings:
        print(f"\n  Species with 0 sightings in bounding box:")
        for s in zero_sightings:
            print(f"    · {s}")
        print(f"\n  Note: 0-sighting species may have observations outside the")
        print(f"  bounding box. Check iNaturalist directly to confirm.")

    if warnings:
        print(f"\n  ⚠️  Warnings ({len(warnings)}):")
        for w in warnings:
            print(f"    · {w}")

    print("\n  Next step: Cmd+R in Xcode to pick up the updated species.json")
    print("─" * 60)


if __name__ == "__main__":
    main()
