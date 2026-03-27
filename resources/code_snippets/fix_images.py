#!/usr/bin/env python3
"""
fix_images.py
Fetches correct iNaturalist image URLs and writes them directly
into the Xcode project species.json.

Run from AK_fieldGuide folder:
  python3 fix_images.py
"""

import json, re, time, shutil, os
import requests

XCODE_JSON = "CarajasFieldGuide/CarajasFieldGuide/Resources/species.json"
BACKUP     = "species_backup_v2.json"
SLEEP      = 0.7

def get_taxon_id(url):
    if not url:
        return None
    m = re.search(r'/taxa/(\d+)', url)
    return m.group(1) if m else None

def fetch_image_url(taxon_id, scientific_name):
    """Try by ID first, then by name search."""
    # Try direct taxon fetch
    if taxon_id:
        try:
            r = requests.get(
                f"https://api.inaturalist.org/v1/taxa/{taxon_id}",
                headers={"User-Agent": "CarajasFieldGuide/1.0"},
                timeout=10
            )
            data = r.json()
            if data.get("results"):
                result = data["results"][0]
                photo = result.get("default_photo")
                if photo:
                    # Try medium_url first, then square_url
                    url = photo.get("medium_url") or photo.get("square_url")
                    if url:
                        return url, result.get("observations_count")
        except Exception as e:
            print(f"    ID fetch error: {e}")

    # Fallback: search by name
    try:
        r = requests.get(
            "https://api.inaturalist.org/v1/taxa",
            params={"q": scientific_name, "rank": "species", "per_page": 1},
            headers={"User-Agent": "CarajasFieldGuide/1.0"},
            timeout=10
        )
        data = r.json()
        if data.get("results"):
            for result in data["results"]:
                if result.get("name", "").lower() == scientific_name.lower():
                    photo = result.get("default_photo")
                    if photo:
                        url = photo.get("medium_url") or photo.get("square_url")
                        if url:
                            return url, result.get("observations_count")
    except Exception as e:
        print(f"    Name search error: {e}")

    return None, None

def main():
    if not os.path.exists(XCODE_JSON):
        print(f"ERROR: Cannot find {XCODE_JSON}")
        print(f"Make sure you're running from the AK_fieldGuide folder.")
        return

    with open(XCODE_JSON, encoding="utf-8") as f:
        species = json.load(f)

    shutil.copy(XCODE_JSON, BACKUP)
    print(f"Backed up to {BACKUP}")
    print(f"Processing {len(species)} species...\n")

    updated = 0
    no_photo = []

    for i, sp in enumerate(species):
        name = sp["scientific_name"]
        taxon_id = get_taxon_id(sp.get("inat_taxon_url") or "")
        print(f"[{i+1:02d}/{len(species)}] {name}")

        img_url, obs = fetch_image_url(taxon_id, name)

        if img_url:
            sp["inat_image_url"] = img_url
            if obs is not None:
                sp["inat_observations"] = obs
            print(f"         ✓ {img_url[:60]}...")
            updated += 1
        else:
            sp["inat_image_url"] = None
            print(f"         ✗ no photo found")
            no_photo.append(name)

        time.sleep(SLEEP)

    # Write back to Xcode JSON
    with open(XCODE_JSON, "w", encoding="utf-8") as f:
        json.dump(species, f, indent=2, ensure_ascii=False)

    # Also write to local copy
    with open("species.json", "w", encoding="utf-8") as f:
        json.dump(species, f, indent=2, ensure_ascii=False)

    print(f"\n{'='*60}")
    print(f"Done. {updated}/{len(species)} images found.")
    print(f"Written to: {XCODE_JSON}")
    print(f"Also written to: species.json")

    if no_photo:
        print(f"\nNo photo ({len(no_photo)}):")
        for n in no_photo:
            print(f"  - {n}")

    print(f"\nNow press Cmd+R in Xcode to rebuild.")

if __name__ == "__main__":
    main()
