#!/usr/bin/env python3
"""
inat_sightings.py
Field Guide Pipeline — iNaturalist Sightings Fetcher

For each species in master_dataset.csv, fetches georeferenced research-grade
wild observations within the target bounding box from iNaturalist.

Outputs:
    inat_sightings.json   — sightings per species for map pins in the app
    master_dataset.csv    — updated in place with inat_observations counts

Usage:
    python3 inat_sightings.py --swlat -6.8 --swlng -50.5 --nelat -5.8 --nelng -49.5
    python3 inat_sightings.py  (reads bounding box from bbox.json if present)

Filters applied (per rules/inat_filters.md):
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

SCRIPT_DIR    = os.path.dirname(os.path.abspath(__file__))
CSV_PATH      = os.path.join(SCRIPT_DIR, "master_dataset.csv")
BBOX_PATH     = os.path.join(SCRIPT_DIR, "bbox.json")
SIGHTINGS_OUT = os.path.join(SCRIPT_DIR, "inat_sightings.json")

INAT_API      = "https://api.inaturalist.org/v1"
HEADERS       = {"User-Agent": "FieldGuidePipeline/1.0"}
API_DELAY     = 0.6
MAX_SIGHTINGS = 200   # max observations to fetch per species

# ── Argument parsing ──────────────────────────────────────────────────────────

def get_bounding_box():
    """
    Resolve bounding box from arguments or bbox.json file.
    bbox.json format: {"swlat": -6.8, "swlng": -50.5, "nelat": -5.8, "nelng": -49.5}
    """
    parser = argparse.ArgumentParser(
        description="Fetch iNaturalist sightings within a bounding box"
    )
    parser.add_argument("--swlat", type=float, help="SW corner latitude")
    parser.add_argument("--swlng", type=float, help="SW corner longitude")
    parser.add_argument("--nelat", type=float, help="NE corner latitude")
    parser.add_argument("--nelng", type=float, help="NE corner longitude")
    args = parser.parse_args()

    if all([args.swlat, args.swlng, args.nelat, args.nelng]):
        return args.swlat, args.swlng, args.nelat, args.nelng

    if os.path.exists(BBOX_PATH):
        with open(BBOX_PATH) as f:
            bbox = json.load(f)
        print(f"Loaded bounding box from bbox.json")
        return bbox["swlat"], bbox["swlng"], bbox["nelat"], bbox["nelng"]

    print("ERROR: No bounding box supplied.")
    print("Either pass --swlat --swlng --nelat --nelng arguments,")
    print("or create a bbox.json file in the same folder.")
    sys.exit(1)


# ── iNat helpers ─────────────────────────────────────────────────────────────

def extract_taxon_id(url):
    """Extract numeric taxon ID from an iNat taxon URL."""
    import re
    if not url or str(url).strip().lower() in ("nan", "none", ""):
        return None
    m = re.search(r"/taxa/(\d+)", str(url))
    return m.group(1) if m else None


def fetch_obs_count(taxon_id, swlat, swlng, nelat, nelng):
    """Fetch observation count within bounding box."""
    params = {
        "taxon_id":     taxon_id,
        "quality_grade":"research",
        "captive":      "false",
        "geo":          "true",
        "nelat": nelat, "nelng": nelng,
        "swlat": swlat, "swlng": swlng,
        "per_page":     0,
        "only_id":      "true",
    }
    try:
        r = requests.get(f"{INAT_API}/observations",
                         params=params, headers=HEADERS, timeout=15)
        r.raise_for_status()
        return r.json().get("total_results", 0)
    except Exception as e:
        print(f"    Count error: {e}")
        return None


def fetch_sightings(taxon_id, swlat, swlng, nelat, nelng):
    """Fetch georeferenced observations within bounding box."""
    params = {
        "taxon_id":     taxon_id,
        "quality_grade":"research",
        "captive":      "false",
        "geo":          "true",
        "nelat": nelat, "nelng": nelng,
        "swlat": swlat, "swlng": swlng,
        "per_page":     MAX_SIGHTINGS,
        "page":         1,
        "order":        "desc",
        "order_by":     "created_at",
    }
    try:
        r = requests.get(f"{INAT_API}/observations",
                         params=params, headers=HEADERS, timeout=15)
        r.raise_for_status()
        results = r.json().get("results", [])
    except Exception as e:
        print(f"    Sightings error: {e}")
        return []

    sightings = []
    for obs in results:
        loc = obs.get("location")
        if not loc:
            continue
        try:
            lat, lng = [float(x) for x in loc.split(",")]
        except Exception:
            continue
        sightings.append({
            "lat":  round(lat, 6),
            "lng":  round(lng, 6),
            "date": obs.get("observed_on"),
        })
    return sightings


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    swlat, swlng, nelat, nelng = get_bounding_box()

    print(f"Bounding box: SW({swlat}, {swlng}) → NE({nelat}, {nelng})")
    print()

    if not os.path.exists(CSV_PATH):
        print(f"ERROR: master_dataset.csv not found at {CSV_PATH}")
        sys.exit(1)

    df = pd.read_csv(CSV_PATH)
    print(f"Loaded {len(df)} species from master_dataset.csv")
    print(f"Fetching sightings and observation counts...")
    print("-" * 60)

    sightings_output = []
    obs_counts       = {}

    for _, row in df.iterrows():
        name      = str(row.get("scientific_name", "")).strip()
        taxon_url = str(row.get("inat_taxon_url", ""))
        taxon_id  = extract_taxon_id(taxon_url)

        if not taxon_id:
            print(f"  SKIP  (no taxon ID)  {name}")
            sightings_output.append({
                "scientific_name": name,
                "sightings": []
            })
            obs_counts[name] = None
            continue

        # Observation count
        count = fetch_obs_count(taxon_id, swlat, swlng, nelat, nelng)
        time.sleep(API_DELAY)

        # Sightings
        sightings = fetch_sightings(taxon_id, swlat, swlng, nelat, nelng)
        time.sleep(API_DELAY)

        obs_counts[name] = count if count and count > 0 else None

        print(f"  {str(count or 0):>5} obs  {len(sightings):>3} sightings  {name}")

        sightings_output.append({
            "scientific_name": name,
            "sightings":       sightings,
        })

    # ── Write sightings JSON ──────────────────────────────────────────────────
    with open(SIGHTINGS_OUT, "w", encoding="utf-8") as f:
        json.dump(sightings_output, f, indent=2, ensure_ascii=False)
    print()
    print(f"inat_sightings.json saved — {len(sightings_output)} species")

    # ── Update master_dataset.csv with observation counts ────────────────────
    df["inat_observations"] = df["scientific_name"].map(obs_counts)
    df.to_csv(CSV_PATH, index=False)
    print(f"master_dataset.csv updated with inat_observations counts")

    # ── Summary ───────────────────────────────────────────────────────────────
    with_sightings    = sum(1 for s in sightings_output if s["sightings"])
    without_sightings = sum(1 for s in sightings_output if not s["sightings"])
    print()
    print(f"SUMMARY")
    print(f"  Species with sightings in bbox:    {with_sightings}")
    print(f"  Species with no sightings in bbox: {without_sightings}")
    print()
    print("Next step: run inat_image_pipeline.py")


if __name__ == "__main__":
    main()
