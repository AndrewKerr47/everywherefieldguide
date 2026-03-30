#!/usr/bin/env python3
"""
inat_image_pipeline.py
Carajás Field Guide — image pipeline v3

Priority chain per species:
  1. iNaturalist  — research-grade observations, up to MAX_PHOTOS attempts
  2. GBIF         — occurrence media, commercially licensed
  3. Wikimedia    — Commons API, commercially licensed
  4. Flag for manual outreach if all three fail

Licence rules:
  SAFE:    CC0, CC BY, CC BY-SA, CC BY-ND
  BLOCKED: CC BY-NC, CC BY-NC-SA, CC BY-NC-ND, All Rights Reserved, empty

Output:
  - carajas_snakes_master_dataset.csv  (updated with image/credit columns)
  - carajas_image_credits.json         (ready to merge into species.json)

Each resolved species gets a pre-formatted credit_line string, e.g.:
  "© jsilva via iNaturalist (CC BY)"
  "© João Silva / GBIF (CC BY 4.0)"
  "© File:Boa_constrictor.jpg / Wikimedia Commons (CC BY-SA 4.0)"

Usage:
    pip3 install requests pandas
    python3 inat_image_pipeline.py

Place alongside carajas_snakes_master_dataset.csv.
"""

import os
import re
import json
import time
import sys

try:
    import requests
    import pandas as pd
except ImportError:
    print("ERROR: pip3 install requests pandas")
    sys.exit(1)

# ── Config ────────────────────────────────────────────────────────────────────

SCRIPT_DIR  = os.path.dirname(os.path.abspath(__file__))
CSV_IN      = os.path.join(SCRIPT_DIR, "carajas_snakes_master_dataset.csv")
CSV_OUT     = os.path.join(SCRIPT_DIR, "carajas_snakes_master_dataset.csv")
JSON_OUT    = os.path.join(SCRIPT_DIR, "carajas_image_credits.json")

MAX_PHOTOS  = 10
INAT_DELAY  = 0.6
GBIF_DELAY  = 0.5
WIKI_DELAY  = 0.5
VERIFY_DELAY = 0.4

HEADERS     = {"User-Agent": "CarajasFieldGuide/1.0 (andrewkerresq@gmail.com)"}
INAT_API    = "https://api.inaturalist.org/v1"
GBIF_API    = "https://api.gbif.org/v1"
WIKI_API    = "https://commons.wikimedia.org/w/api.php"

SAFE_LICENCES = {"cc0", "cc-by", "cc-by-sa", "cc-by-nd", "cc"}
BLOCKED_LICENCES = {"cc-by-nc", "cc-by-nc-sa", "cc-by-nc-nd"}

LICENCE_LABELS = {
    "cc0":          "CC0",
    "cc-by":        "CC BY",
    "cc-by-sa":     "CC BY-SA",
    "cc-by-nd":     "CC BY-ND",
    "cc-by-nc":     "CC BY-NC",
    "cc-by-nc-sa":  "CC BY-NC-SA",
    "cc-by-nc-nd":  "CC BY-NC-ND",
}

LICENCE_URLS = {
    "cc0":          "https://creativecommons.org/publicdomain/zero/1.0/",
    "cc-by":        "https://creativecommons.org/licenses/by/4.0/",
    "cc-by-sa":     "https://creativecommons.org/licenses/by-sa/4.0/",
    "cc-by-nd":     "https://creativecommons.org/licenses/by-nd/4.0/",
    "cc-by-nc":     "https://creativecommons.org/licenses/by-nc/4.0/",
    "cc-by-nc-sa":  "https://creativecommons.org/licenses/by-nc-sa/4.0/",
    "cc-by-nc-nd":  "https://creativecommons.org/licenses/by-nc-nd/4.0/",
}

# ── Shared helpers ────────────────────────────────────────────────────────────

def extract_taxon_id(url):
    if not url or str(url) == "nan":
        return None
    m = re.search(r"/taxa/(\d+)", str(url))
    return m.group(1) if m else None

def is_safe(lc):
    return bool(lc) and lc.lower().strip() in SAFE_LICENCES

def is_blocked(lc):
    return bool(lc) and lc.lower().strip() in BLOCKED_LICENCES

def licence_label(lc):
    return LICENCE_LABELS.get(lc.lower().strip(), lc.upper()) if lc else ""

def licence_url(lc):
    return LICENCE_URLS.get(lc.lower().strip(), "") if lc else ""

def empty_result(name, status):
    return {
        "scientific_name": name,
        "source":          "",
        "photo_id":        "",
        "photo_url":       "",
        "source_url":      "",
        "observer":        "",
        "observer_url":    "",
        "licence_code":    "",
        "licence_label":   "",
        "licence_url":     "",
        "credit_line":     "",
        "status":          status,
    }

def build_credit_line(source, observer, licence_lbl, source_url):
    """Build a pre-formatted credit string for display in the app."""
    lc = f"({licence_lbl})" if licence_lbl else ""
    if source == "inat":
        return f"© {observer} via iNaturalist {lc}".strip()
    elif source == "gbif":
        return f"© {observer} via GBIF {lc}".strip() if observer else f"GBIF {lc}".strip()
    elif source == "wikimedia":
        return f"© {observer} / Wikimedia Commons {lc}".strip() if observer else f"Wikimedia Commons {lc}".strip()
    return f"© {observer} {lc}".strip()


# ── iNaturalist ───────────────────────────────────────────────────────────────

def verify_inat_licence(obs_url, photo_id):
    """Secondary lookup on individual observation for empty licence codes."""
    m = re.search(r"/observations/(\d+)", str(obs_url))
    if not m:
        return ""
    obs_id = m.group(1)
    try:
        r = requests.get(f"{INAT_API}/observations/{obs_id}",
                         headers=HEADERS, timeout=15)
        r.raise_for_status()
        data = r.json()
        time.sleep(VERIFY_DELAY)

        lc = (data.get("license_code") or "").lower().strip()
        if lc:
            return lc

        for photo in data.get("photos", []):
            if str(photo.get("id", "")) == str(photo_id):
                lc = (photo.get("license_code") or "").lower().strip()
                if lc:
                    return lc
                attr = (photo.get("attribution") or "").lower()
                for key, val in [
                    ("cc0", "cc0"), ("public domain", "cc0"),
                    ("cc by-nc-nd", "cc-by-nc-nd"), ("cc by-nc-sa", "cc-by-nc-sa"),
                    ("cc by-nc", "cc-by-nc"), ("cc by-nd", "cc-by-nd"),
                    ("cc by-sa", "cc-by-sa"), ("cc by", "cc-by"),
                    ("all rights reserved", "all-rights-reserved"),
                ]:
                    if key in attr:
                        return val
    except Exception as e:
        print(f"      iNat verify error: {e}")
    return ""


def try_inat(name, taxon_id):
    """Attempt to find a commercially usable photo on iNaturalist."""
    params = {
        "taxon_id": taxon_id, "quality_grade": "research",
        "photos": "true", "order_by": "votes",
        "per_page": MAX_PHOTOS, "page": 1,
    }
    try:
        r = requests.get(f"{INAT_API}/observations", params=params,
                         headers=HEADERS, timeout=15)
        r.raise_for_status()
        results = r.json().get("results", [])
    except Exception as e:
        print(f"    iNat API error: {e}")
        time.sleep(INAT_DELAY)
        return None

    time.sleep(INAT_DELAY)

    photos = []
    for obs in results:
        obs_url  = f"https://www.inaturalist.org/observations/{obs.get('id')}"
        user     = obs.get("user", {})
        username = user.get("login", "")
        user_url = f"https://www.inaturalist.org/people/{username}" if username else ""
        for photo in obs.get("photos", []):
            lc       = (photo.get("license_code") or "").lower().strip()
            p_url    = (photo.get("url") or "").replace("square", "medium")
            p_id     = str(photo.get("id", ""))
            photos.append((p_id, p_url, obs_url, username, user_url, lc))
            if len(photos) >= MAX_PHOTOS:
                break
        if len(photos) >= MAX_PHOTOS:
            break

    for i, (p_id, p_url, obs_url, username, user_url, lc) in enumerate(photos):
        tag = f"(photo {i+1}/{len(photos)})"

        if is_safe(lc):
            print(f"  iNat OK  [{lc:10}] {tag}  {name}")
            ll = licence_label(lc)
            return {
                "source": "inat", "photo_id": p_id, "photo_url": p_url,
                "source_url": obs_url, "observer": username,
                "observer_url": user_url, "licence_code": lc,
                "licence_label": ll, "licence_url": licence_url(lc),
                "credit_line": build_credit_line("inat", username, ll, obs_url),
            }
        elif is_blocked(lc):
            print(f"  iNat BLOCKED [{lc:8}] {tag}  {name}")
        else:
            print(f"  iNat EMPTY         {tag}  {name} — verifying...")
            verified = verify_inat_licence(obs_url, p_id)
            if is_safe(verified):
                print(f"    → VERIFIED OK [{verified}]")
                ll = licence_label(verified)
                return {
                    "source": "inat", "photo_id": p_id, "photo_url": p_url,
                    "source_url": obs_url, "observer": username,
                    "observer_url": user_url, "licence_code": verified,
                    "licence_label": ll, "licence_url": licence_url(verified),
                    "credit_line": build_credit_line("inat", username, ll, obs_url),
                }
            elif verified:
                print(f"    → VERIFIED BLOCKED [{verified}]")
            else:
                print(f"    → UNRESOLVED — treating as blocked")

    return None


# ── GBIF ──────────────────────────────────────────────────────────────────────

# GBIF licence strings that map to our safe set
GBIF_LICENCE_MAP = {
    "http://creativecommons.org/publicdomain/zero/1.0/":       "cc0",
    "https://creativecommons.org/publicdomain/zero/1.0/":      "cc0",
    "http://creativecommons.org/licenses/by/4.0/":             "cc-by",
    "https://creativecommons.org/licenses/by/4.0/":            "cc-by",
    "http://creativecommons.org/licenses/by-sa/4.0/":          "cc-by-sa",
    "https://creativecommons.org/licenses/by-sa/4.0/":         "cc-by-sa",
    "http://creativecommons.org/licenses/by/2.0/":             "cc-by",
    "https://creativecommons.org/licenses/by/2.0/":            "cc-by",
    "http://creativecommons.org/licenses/by-sa/2.0/":          "cc-by-sa",
    "https://creativecommons.org/licenses/by-sa/2.0/":         "cc-by-sa",
    "http://creativecommons.org/licenses/by-nd/4.0/":          "cc-by-nd",
    "https://creativecommons.org/licenses/by-nd/4.0/":         "cc-by-nd",
    "CC0_1_0":                                                 "cc0",
    "CC_BY_4_0":                                               "cc-by",
    "CC_BY_SA_4_0":                                            "cc-by-sa",
    "CC_BY_ND_4_0":                                            "cc-by-nd",
    "CC_BY_2_0":                                               "cc-by",
    "CC_BY_SA_2_0":                                            "cc-by-sa",
}

def gbif_licence_to_code(raw):
    """Convert a GBIF licence string/URL to our internal code."""
    if not raw:
        return ""
    raw = raw.strip()
    if raw in GBIF_LICENCE_MAP:
        return GBIF_LICENCE_MAP[raw]
    raw_lower = raw.lower()
    if "publicdomain" in raw_lower or "cc0" in raw_lower:
        return "cc0"
    if "by-nc-nd" in raw_lower:
        return "cc-by-nc-nd"
    if "by-nc-sa" in raw_lower:
        return "cc-by-nc-sa"
    if "by-nc" in raw_lower:
        return "cc-by-nc"
    if "by-nd" in raw_lower:
        return "cc-by-nd"
    if "by-sa" in raw_lower:
        return "cc-by-sa"
    if "by" in raw_lower:
        return "cc-by"
    return ""


def try_gbif(name):
    """Search GBIF occurrence media for a commercially usable photo."""
    params = {
        "scientificName": name,
        "mediaType":      "StillImage",
        "limit":          20,
        "offset":         0,
    }
    try:
        r = requests.get(f"{GBIF_API}/occurrence/search", params=params,
                         headers=HEADERS, timeout=15)
        r.raise_for_status()
        results = r.json().get("results", [])
    except Exception as e:
        print(f"    GBIF API error: {e}")
        time.sleep(GBIF_DELAY)
        return None

    time.sleep(GBIF_DELAY)

    for occ in results:
        occ_key  = occ.get("key", "")
        occ_url  = f"https://www.gbif.org/occurrence/{occ_key}" if occ_key else ""
        recorder = occ.get("recordedBy", "") or occ.get("institutionCode", "") or ""

        for media in occ.get("media", []):
            if media.get("type") != "StillImage":
                continue

            raw_licence = media.get("license", "") or occ.get("license", "")
            lc = gbif_licence_to_code(raw_licence)
            photo_url = media.get("identifier", "")

            if not photo_url:
                continue

            if is_safe(lc):
                print(f"  GBIF OK  [{lc:10}]  {name}")
                ll = licence_label(lc)
                return {
                    "source": "gbif", "photo_id": str(occ_key),
                    "photo_url": photo_url, "source_url": occ_url,
                    "observer": recorder, "observer_url": "",
                    "licence_code": lc, "licence_label": ll,
                    "licence_url": licence_url(lc),
                    "credit_line": build_credit_line("gbif", recorder, ll, occ_url),
                }
            else:
                print(f"  GBIF BLOCKED [{lc or 'empty':8}]  {name}")

    print(f"  GBIF no usable photo  {name}")
    return None


# ── Wikimedia Commons ─────────────────────────────────────────────────────────

WIKI_LICENCE_MAP = {
    "cc-zero":     "cc0",
    "cc0":         "cc0",
    "pd":          "cc0",
    "cc-by":       "cc-by",
    "cc-by-2.0":   "cc-by",
    "cc-by-3.0":   "cc-by",
    "cc-by-4.0":   "cc-by",
    "cc-by-sa-2.0": "cc-by-sa",
    "cc-by-sa-3.0": "cc-by-sa",
    "cc-by-sa-4.0": "cc-by-sa",
    "cc-by-nd-4.0": "cc-by-nd",
}

def wiki_licence_to_code(raw):
    if not raw:
        return ""
    raw = raw.lower().strip()
    if raw in WIKI_LICENCE_MAP:
        return WIKI_LICENCE_MAP[raw]
    if "nc" in raw:
        return "cc-by-nc"
    if "sa" in raw:
        return "cc-by-sa"
    if "nd" in raw:
        return "cc-by-nd"
    if raw.startswith("cc-by"):
        return "cc-by"
    if "zero" in raw or raw == "cc0" or raw == "pd":
        return "cc0"
    return ""


def try_wikimedia(name):
    """Search Wikimedia Commons for a commercially usable photo."""
    # Search for images tagged with the scientific name
    search_params = {
        "action":      "query",
        "list":        "search",
        "srnamespace": 6,           # File namespace
        "srsearch":    f'"{name}" filetype:bitmap',
        "srlimit":     10,
        "format":      "json",
    }
    try:
        r = requests.get(WIKI_API, params=search_params,
                         headers=HEADERS, timeout=15)
        r.raise_for_status()
        hits = r.json().get("query", {}).get("search", [])
    except Exception as e:
        print(f"    Wikimedia search error: {e}")
        time.sleep(WIKI_DELAY)
        return None

    time.sleep(WIKI_DELAY)

    if not hits:
        print(f"  Wikimedia no results  {name}")
        return None

    # For each hit, fetch full image info including licence
    titles = [h["title"] for h in hits[:5]]
    info_params = {
        "action":   "query",
        "titles":   "|".join(titles),
        "prop":     "imageinfo",
        "iiprop":   "url|extmetadata",
        "format":   "json",
    }
    try:
        r = requests.get(WIKI_API, params=info_params,
                         headers=HEADERS, timeout=15)
        r.raise_for_status()
        pages = r.json().get("query", {}).get("pages", {})
    except Exception as e:
        print(f"    Wikimedia info error: {e}")
        time.sleep(WIKI_DELAY)
        return None

    time.sleep(WIKI_DELAY)

    for page_id, page in pages.items():
        if page_id == "-1":
            continue
        title    = page.get("title", "")
        img_info = (page.get("imageinfo") or [{}])[0]
        photo_url = img_info.get("url", "")
        file_page = img_info.get("descriptionurl", "")
        meta      = img_info.get("extmetadata", {})

        # Extract licence from extmetadata
        licence_short = (meta.get("LicenseShortName", {}).get("value") or "").lower()
        artist        = meta.get("Artist", {}).get("value") or ""
        # Strip HTML tags from artist field
        artist = re.sub(r"<[^>]+>", "", artist).strip()

        lc = wiki_licence_to_code(licence_short)

        if not photo_url:
            continue

        if is_safe(lc):
            print(f"  Wikimedia OK  [{lc:10}]  {name}")
            ll = licence_label(lc)
            return {
                "source": "wikimedia", "photo_id": title,
                "photo_url": photo_url, "source_url": file_page,
                "observer": artist, "observer_url": file_page,
                "licence_code": lc, "licence_label": ll,
                "licence_url": licence_url(lc),
                "credit_line": build_credit_line("wikimedia", artist or title, ll, file_page),
            }
        else:
            print(f"  Wikimedia BLOCKED [{lc or licence_short or 'unknown':12}]  {name}")

    print(f"  Wikimedia no usable photo  {name}")
    return None


# ── Main processor ────────────────────────────────────────────────────────────

def process_species(row):
    name      = row["scientific_name"]
    taxon_url = str(row.get("inat_taxon_url", ""))
    taxon_id  = extract_taxon_id(taxon_url)

    print(f"\n── {name}")

    # 1. iNaturalist
    if taxon_id:
        result = try_inat(name, taxon_id)
        if result:
            return {**empty_result(name, "ok"), **result, "status": "ok"}
    else:
        print(f"  iNat SKIP (no taxon ID)")

    # 2. GBIF
    result = try_gbif(name)
    if result:
        return {**empty_result(name, "ok"), **result, "status": "ok"}

    # 3. Wikimedia Commons
    result = try_wikimedia(name)
    if result:
        return {**empty_result(name, "ok"), **result, "status": "ok"}

    # All sources exhausted
    print(f"  ALL SOURCES EXHAUSTED — flagged for manual outreach")
    return empty_result(name, "needs_outreach")


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    if not os.path.exists(CSV_IN):
        print(f"ERROR: CSV not found at {CSV_IN}")
        sys.exit(1)

    df = pd.read_csv(CSV_IN)

    # Drop existing credit columns from previous runs
    credit_cols = [
        "source", "photo_id", "photo_url", "source_url",
        "observer", "observer_url",
        "licence_code", "licence_label", "licence_url",
        "credit_line", "image_status",
    ]
    for col in credit_cols:
        if col in df.columns:
            df = df.drop(columns=[col])

    print(f"Loaded {len(df)} species")
    print(f"Priority: iNaturalist → GBIF → Wikimedia Commons")
    print(f"=" * 70)

    results = []
    for _, row in df.iterrows():
        result = process_species(row)
        results.append(result)

    print(f"\n{'=' * 70}")

    results_df = pd.DataFrame(results)
    results_df = results_df.rename(columns={"status": "image_status"})

    ok       = results_df[results_df["image_status"] == "ok"]
    outreach = results_df[results_df["image_status"] == "needs_outreach"]

    print(f"\nRESULTS:")
    print(f"  Usable photos found:    {len(ok)} / {len(df)}  ({len(ok)/len(df)*100:.1f}%)")
    print(f"  Needs manual outreach:  {len(outreach)} / {len(df)}  ({len(outreach)/len(df)*100:.1f}%)")
    print()

    # Source breakdown
    for src in ["inat", "gbif", "wikimedia"]:
        n = len(ok[ok["source"] == src])
        if n:
            print(f"  From {src.upper():12}: {n} species")
    print()

    if len(outreach) > 0:
        print("NEEDS OUTREACH:")
        for _, r in outreach.iterrows():
            print(f"  {r['scientific_name']}")
        print()

    # ── Update CSV ────────────────────────────────────────────────────────────
    merged = df.merge(
        results_df[["scientific_name"] + credit_cols],
        on="scientific_name", how="left"
    )
    merged.to_csv(CSV_OUT, index=False)
    print(f"CSV saved to: {CSV_OUT}")

    # ── Write JSON ────────────────────────────────────────────────────────────
    json_out = []
    for _, r in results_df.iterrows():
        if r["image_status"] == "ok":
            json_out.append({
                "scientific_name": r["scientific_name"],
                "source":          r["source"],
                "photo_id":        r["photo_id"],
                "photo_url":       r["photo_url"],
                "source_url":      r["source_url"],
                "observer":        r["observer"],
                "observer_url":    r["observer_url"],
                "licence_code":    r["licence_code"],
                "licence_label":   r["licence_label"],
                "licence_url":     r["licence_url"],
                "credit_line":     r["credit_line"],
            })

    with open(JSON_OUT, "w", encoding="utf-8") as f:
        json.dump(json_out, f, indent=2, ensure_ascii=False)
    print(f"JSON saved to: {JSON_OUT}")
    print()
    print("Next steps:")
    print("  1. Contact observers for NEEDS OUTREACH species (step 2)")
    print("  2. Merge carajas_image_credits.json into species.json")
    print("  3. Update SpeciesDetailView to display credit_line")


if __name__ == "__main__":
    main()
