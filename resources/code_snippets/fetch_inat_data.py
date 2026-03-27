#!/usr/bin/env python3
"""
fetch_inat_data.py
Carajás Field Guide — iNaturalist Data Pipeline

Reads species.json, queries the iNaturalist API for each species,
and writes back the correct:
  - inat_image_url  (default_photo.medium_url from the taxon)
  - inat_observations (total observation count)
  - inat_taxon_url  (canonical URL confirmed from API)

Usage:
  python3 fetch_inat_data.py

Requirements:
  pip install requests

Output:
  Overwrites species.json in place with correct image URLs and counts.
  Creates species_backup.json before modifying.

Rate limiting:
  The iNaturalist API allows ~100 requests/minute unauthenticated.
  This script sleeps 0.7s between requests to stay well within limits.
  62 species ≈ ~45 seconds total runtime.
"""

import json
import time
import shutil
import sys
import os

try:
    import requests
except ImportError:
    print("ERROR: 'requests' not installed. Run: pip install requests")
    sys.exit(1)

SPECIES_JSON = "species.json"
BACKUP_JSON  = "species_backup.json"
INAT_API     = "https://api.inaturalist.org/v1/taxa/{taxon_id}"
INAT_SEARCH  = "https://api.inaturalist.org/v1/taxa?q={name}&rank=species&per_page=1"
SLEEP        = 0.7  # seconds between requests

def extract_taxon_id(url):
    """Extract numeric taxon ID from an iNaturalist URL."""
    if not url:
        return None
    import re
    m = re.search(r'/taxa/(\d+)', url)
    return m.group(1) if m else None

def fetch_by_id(taxon_id):
    """Fetch taxon data by numeric ID."""
    url = INAT_API.format(taxon_id=taxon_id)
    try:
        r = requests.get(url, timeout=10, headers={"User-Agent": "CarajasFieldGuide/1.0"})
        r.raise_for_status()
        data = r.json()
        if data.get("results"):
            return data["results"][0]
    except Exception as e:
        print(f"    ERROR fetching ID {taxon_id}: {e}")
    return None

def fetch_by_name(scientific_name):
    """Search for taxon by scientific name — fallback if no ID."""
    url = INAT_SEARCH.format(name=requests.utils.quote(scientific_name))
    try:
        r = requests.get(url, timeout=10, headers={"User-Agent": "CarajasFieldGuide/1.0"})
        r.raise_for_status()
        data = r.json()
        if data.get("results"):
            # Find exact match on name
            for result in data["results"]:
                if result.get("name", "").lower() == scientific_name.lower():
                    return result
            # Return first result if no exact match
            return data["results"][0]
    except Exception as e:
        print(f"    ERROR searching '{scientific_name}': {e}")
    return None

def get_image_url(taxon):
    """Extract medium image URL from taxon data."""
    photo = taxon.get("default_photo")
    if not photo:
        return None
    # Prefer medium, fall back to square
    url = photo.get("medium_url") or photo.get("square_url")
    return url

def get_obs_count(taxon):
    """Extract observation count from taxon data."""
    return taxon.get("observations_count")

def get_canonical_url(taxon):
    """Build canonical iNaturalist URL from taxon ID and name."""
    tid = taxon.get("id")
    name = taxon.get("name", "").replace(" ", "-")
    if tid:
        return f"https://www.inaturalist.org/taxa/{tid}-{name}"
    return None

def main():
    # Load species.json
    if not os.path.exists(SPECIES_JSON):
        print(f"ERROR: {SPECIES_JSON} not found. Run this script from the same folder as species.json.")
        sys.exit(1)

    with open(SPECIES_JSON, "r", encoding="utf-8") as f:
        species = json.load(f)

    # Backup
    shutil.copy(SPECIES_JSON, BACKUP_JSON)
    print(f"Backed up to {BACKUP_JSON}")
    print(f"Processing {len(species)} species...\n")

    updated = 0
    failed  = []

    for i, sp in enumerate(species):
        name = sp["scientific_name"]
        print(f"[{i+1:02d}/{len(species)}] {name}")

        taxon = None

        # Try by taxon ID first (faster, more reliable)
        taxon_id = extract_taxon_id(sp.get("inat_taxon_url") or "")
        if taxon_id:
            taxon = fetch_by_id(taxon_id)
            if taxon:
                print(f"         Found by ID #{taxon_id}")

        # Fall back to name search
        if not taxon:
            print(f"         Searching by name...")
            taxon = fetch_by_name(name)
            if taxon:
                print(f"         Found by name → ID #{taxon.get('id')}")

        if taxon:
            img_url  = get_image_url(taxon)
            obs      = get_obs_count(taxon)
            can_url  = get_canonical_url(taxon)
            tid      = taxon.get("id")

            sp["inat_image_url"]   = img_url
            sp["inat_observations"] = obs
            if can_url:
                sp["inat_taxon_url"] = can_url

            # Update source_notes with confirmed taxon ID
            if tid:
                src = sp.get("source_notes", "")
                import re
                src = re.sub(r'iNaturalist taxon #\d+', f'iNaturalist taxon #{tid}', src)
                if 'iNaturalist' not in src:
                    src = src + f' · iNaturalist taxon #{tid}'
                sp["source_notes"] = src

            print(f"         image: {'✓' if img_url else '✗ no photo'}")
            print(f"         obs:   {obs:,}" if obs else "         obs:   none")
            updated += 1
        else:
            print(f"         ✗ NOT FOUND on iNaturalist")
            failed.append(name)

        time.sleep(SLEEP)

    # Write updated JSON
    with open(SPECIES_JSON, "w", encoding="utf-8") as f:
        json.dump(species, f, indent=2, ensure_ascii=False)

    print(f"\n{'='*60}")
    print(f"Done. {updated}/{len(species)} species updated.")
    print(f"Output written to {SPECIES_JSON}")

    if failed:
        print(f"\nNot found on iNaturalist ({len(failed)}):")
        for name in failed:
            print(f"  - {name}")

    print(f"\nNext step: copy the updated {SPECIES_JSON} into your Xcode project Resources folder.")

if __name__ == "__main__":
    main()
