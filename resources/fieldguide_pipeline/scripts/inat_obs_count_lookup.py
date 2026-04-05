#!/usr/bin/env python3
"""
inat_obs_count_lookup.py
Field Guide Pipeline — iNaturalist Observation Count Lookup

Standalone utility to update inat_observations counts in master_dataset.csv
without re-fetching sightings. Useful for refreshing counts on a dataset
that already has sightings, or for a quick count-only pass before running
the full inat_sightings.py pipeline.

Note: inat_sightings.py also updates observation counts as part of its run.
Use this script only when you need counts without sightings, or to refresh
counts on an existing dataset.

Usage:
    python3 inat_obs_count_lookup.py
    python3 inat_obs_count_lookup.py --swlat -6.8 --swlng -50.5 --nelat -5.8 --nelng -49.5

Reads bounding box from bbox.json if no arguments supplied.

Filters (per rules/inat_filters.md):
    quality_grade = research
    captive       = false
    geo           = true
"""

import os
import sys
import json
import time
import argparse

try:
    import requests
    import pandas as pd
except ImportError:
    print("ERROR: pip3 install requests pandas")
    sys.exit(1)

# ── Config ────────────────────────────────────────────────────────────────────

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CSV_PATH   = os.path.join(SCRIPT_DIR, "master_dataset.csv")
BBOX_PATH  = os.path.join(SCRIPT_DIR, "bbox.json")

INAT_API   = "https://api.inaturalist.org/v1"
HEADERS    = {"User-Agent": "FieldGuidePipeline/1.0"}
API_DELAY  = 0.6

# ── Helpers ───────────────────────────────────────────────────────────────────

def get_bounding_box():
    parser = argparse.ArgumentParser()
    parser.add_argument("--swlat", type=float)
    parser.add_argument("--swlng", type=float)
    parser.add_argument("--nelat", type=float)
    parser.add_argument("--nelng", type=float)
    args = parser.parse_args()

    if all([args.swlat, args.swlng, args.nelat, args.nelng]):
        return args.swlat, args.swlng, args.nelat, args.nelng

    if os.path.exists(BBOX_PATH):
        with open(BBOX_PATH) as f:
            bbox = json.load(f)
        return bbox["swlat"], bbox["swlng"], bbox["nelat"], bbox["nelng"]

    print("ERROR: No bounding box. Pass --swlat/swlng/nelat/nelng or create bbox.json")
    sys.exit(1)


def extract_taxon_id(url):
    import re
    if not url or str(url).strip().lower() in ("nan", "none", ""):
        return None
    m = re.search(r"/taxa/(\d+)", str(url))
    return m.group(1) if m else None


def fetch_count(taxon_id, swlat, swlng, nelat, nelng):
    params = {
        "taxon_id":      taxon_id,
        "quality_grade": "research",
        "captive":       "false",
        "geo":           "true",
        "nelat": nelat, "nelng": nelng,
        "swlat": swlat, "swlng": swlng,
        "per_page":      0,
        "only_id":       "true",
    }
    try:
        r = requests.get(f"{INAT_API}/observations",
                         params=params, headers=HEADERS, timeout=15)
        r.raise_for_status()
        return r.json().get("total_results", 0)
    except Exception as e:
        print(f"    Error: {e}")
        return None


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    swlat, swlng, nelat, nelng = get_bounding_box()

    if not os.path.exists(CSV_PATH):
        print(f"ERROR: master_dataset.csv not found at {CSV_PATH}")
        sys.exit(1)

    df = pd.read_csv(CSV_PATH)
    print(f"Loaded {len(df)} species")
    print(f"Bounding box: SW({swlat},{swlng}) → NE({nelat},{nelng})")
    print("-" * 60)

    counts = {}
    for _, row in df.iterrows():
        name      = str(row.get("scientific_name", "")).strip()
        taxon_url = str(row.get("inat_taxon_url", ""))
        taxon_id  = extract_taxon_id(taxon_url)

        if not taxon_id:
            print(f"  SKIP  (no taxon ID)   {name}")
            counts[name] = None
            continue

        count = fetch_count(taxon_id, swlat, swlng, nelat, nelng)
        time.sleep(API_DELAY)

        counts[name] = count if count and count > 0 else None
        status = f"{count:>5}" if count else " ZERO"
        print(f"  {status}  {name}")

    # Update CSV
    df["inat_observations"] = df["scientific_name"].map(counts)
    df.to_csv(CSV_PATH, index=False)

    resolved = sum(1 for v in counts.values() if v)
    print()
    print(f"COMPLETE — {resolved}/{len(df)} species have observations in bbox")
    print(f"master_dataset.csv updated with inat_observations")


if __name__ == "__main__":
    main()
