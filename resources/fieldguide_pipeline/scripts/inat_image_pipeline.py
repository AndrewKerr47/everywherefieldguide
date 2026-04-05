#!/usr/bin/env python3
"""
inat_image_pipeline.py
Field Guide Pipeline — Image Pipeline

For each species in master_dataset.csv, fetches up to 3 commercially
licenced images via a three-tier source cascade:
    Tier 1 — iNaturalist (research-grade, ordered by votes)
    Tier 2 — GBIF occurrence media
    Tier 3 — Wikimedia Commons

Only images with commercially permitted licences are included:
    cc0, cc-by, cc-by-sa, cc-by-nd
NC variants and empty/unknown licences are blocked.

Source diversity is preferred: Image 0 = hero (iNat), Image 1 = preferably
GBIF, Image 2 = preferably Wikimedia. Slots backfill from other sources if
preferred source has no usable image.

Outputs:
    image_credits.json   — image credits conforming to image_credits_schema.md
                           (filename configurable via --output)

Usage:
    python3 inat_image_pipeline.py
    python3 inat_image_pipeline.py --output carajas_image_credits.json
    python3 inat_image_pipeline.py --output carajas_image_credits.json --email you@email.com

Reads:
    master_dataset.csv   — species list with inat_taxon_url column
                           Optional column: gbif_taxon_key (skips GBIF resolve API call)

Filters (per rules/inat_filters.md):
    quality_grade = research
    captive       = false
    photos        = true
    order_by      = votes
    per_page      = 10

Rate limiting (per rules/inat_filters.md):
    0.6s between observation-list API calls
    0.4s between individual licence-verification calls
    User-Agent header on all requests
"""

import os
import sys
import re
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

INAT_API = "https://api.inaturalist.org/v1"
GBIF_API = "https://api.gbif.org/v1"
WIKI_API = "https://commons.wikimedia.org/w/api.php"

API_DELAY    = 0.6   # seconds between list/search API calls
VERIFY_DELAY = 0.4   # seconds between individual verification calls

INAT_MAX_OBS     = 10  # max observations to check per species on iNat
GBIF_MAX_OCC     = 20  # max occurrences to check per species on GBIF
WIKI_MAX_RESULTS = 5   # max Wikimedia search results to check per species

MAX_IMAGES = 3

# ── Licence tables ────────────────────────────────────────────────────────────

PERMITTED_LICENCES = {"cc0", "cc-by", "cc-by-sa", "cc-by-nd"}

LICENCE_LABELS = {
    "cc0":      "CC0",
    "cc-by":    "CC BY",
    "cc-by-sa": "CC BY-SA",
    "cc-by-nd": "CC BY-ND",
}

LICENCE_URLS = {
    "cc0":      "",
    "cc-by":    "https://creativecommons.org/licenses/by/4.0/",
    "cc-by-sa": "https://creativecommons.org/licenses/by-sa/4.0/",
    "cc-by-nd": "https://creativecommons.org/licenses/by-nd/4.0/",
}

# Normalise raw licence strings from all three sources to internal codes.
# iNat uses short codes directly; GBIF uses full URIs; Wikimedia uses
# display labels. All keys are lowercased before lookup.
_LICENCE_MAP = {
    # iNat short codes
    "cc0":              "cc0",
    "cc-by":            "cc-by",
    "cc-by-sa":         "cc-by-sa",
    "cc-by-nd":         "cc-by-nd",
    # Wikimedia versioned short names (spaces and hyphens both common)
    "cc by 4.0":        "cc-by",
    "cc by 3.0":        "cc-by",
    "cc by 2.0":        "cc-by",
    "cc by-sa 4.0":     "cc-by-sa",
    "cc by-sa 3.0":     "cc-by-sa",
    "cc by-sa 2.0":     "cc-by-sa",
    "cc by-nd 4.0":     "cc-by-nd",
    "cc by-nd 3.0":     "cc-by-nd",
    "cc-by-4.0":        "cc-by",
    "cc-by-3.0":        "cc-by",
    "cc-by-2.0":        "cc-by",
    "cc-by-sa-4.0":     "cc-by-sa",
    "cc-by-sa-3.0":     "cc-by-sa",
    "cc-by-sa-2.0":     "cc-by-sa",
    "cc-by-nd-4.0":     "cc-by-nd",
    "cc-by-nd-3.0":     "cc-by-nd",
    "cc0 1.0":          "cc0",
    "cc0-1.0":          "cc0",
    "pd":               "cc0",
    "public domain":    "cc0",
    # GBIF full URIs (http and https)
    "http://creativecommons.org/publicdomain/zero/1.0/":   "cc0",
    "https://creativecommons.org/publicdomain/zero/1.0/":  "cc0",
    "http://creativecommons.org/licenses/by/4.0/":         "cc-by",
    "https://creativecommons.org/licenses/by/4.0/":        "cc-by",
    "http://creativecommons.org/licenses/by/3.0/":         "cc-by",
    "https://creativecommons.org/licenses/by/3.0/":        "cc-by",
    "http://creativecommons.org/licenses/by/2.0/":         "cc-by",
    "https://creativecommons.org/licenses/by/2.0/":        "cc-by",
    "http://creativecommons.org/licenses/by-sa/4.0/":      "cc-by-sa",
    "https://creativecommons.org/licenses/by-sa/4.0/":     "cc-by-sa",
    "http://creativecommons.org/licenses/by-sa/3.0/":      "cc-by-sa",
    "https://creativecommons.org/licenses/by-sa/3.0/":     "cc-by-sa",
    "http://creativecommons.org/licenses/by-sa/2.0/":      "cc-by-sa",
    "https://creativecommons.org/licenses/by-sa/2.0/":     "cc-by-sa",
    "http://creativecommons.org/licenses/by-nd/4.0/":      "cc-by-nd",
    "https://creativecommons.org/licenses/by-nd/4.0/":     "cc-by-nd",
    "http://creativecommons.org/licenses/by-nd/3.0/":      "cc-by-nd",
    "https://creativecommons.org/licenses/by-nd/3.0/":     "cc-by-nd",
}


# ── Helpers ───────────────────────────────────────────────────────────────────

def normalise_licence(raw):
    """
    Return a permitted licence code for raw, or None if blocked/unknown.
    Handles iNat short codes, GBIF URIs, and Wikimedia display labels.
    """
    if not raw:
        return None
    s = str(raw).strip().lower()

    # Direct table lookup
    if s in _LICENCE_MAP:
        return _LICENCE_MAP[s]

    # NC variants — explicitly blocked regardless of other matches
    if re.search(r"\bnc\b|by-nc|by_nc", s):
        return None

    # URI pattern matching (catches versioned URIs not in the table)
    if re.search(r"publicdomain/zero", s):
        return "cc0"
    if re.search(r"licenses/by-nd", s):
        return "cc-by-nd"
    if re.search(r"licenses/by-sa", s):
        return "cc-by-sa"
    if re.search(r"licenses/by/", s):
        return "cc-by"

    # Wikimedia label patterns not caught by table (e.g. "CC-BY-SA-4.0")
    s_nodot = re.sub(r"[\s\-_]", "", s)  # "ccbysa40"
    if s_nodot.startswith("ccbynd"):
        return "cc-by-nd"
    if s_nodot.startswith("ccbysa"):
        return "cc-by-sa"
    if s_nodot.startswith("ccby"):
        return "cc-by"
    if s_nodot in ("cc0", "cc01", "cc010"):
        return "cc0"

    return None


def is_permitted(code):
    return code in PERMITTED_LICENCES


def extract_taxon_id(url):
    """Extract numeric iNat taxon ID from a taxon URL."""
    if not url or str(url).strip().lower() in ("nan", "none", ""):
        return None
    m = re.search(r"/taxa/(\d+)", str(url))
    return m.group(1) if m else None


def nullable_str(val):
    if val is None:
        return None
    s = str(val).strip()
    return None if s.lower() in ("", "nan", "none", "null") else s


def build_credit_line(source, observer, licence_label):
    """
    Format a credit line per licence_rules.md.
    If observer is empty, credit the platform only.
    """
    if source == "inat":
        if observer:
            return f"© {observer} via iNaturalist ({licence_label})"
        return f"via iNaturalist ({licence_label})"
    elif source == "gbif":
        if observer:
            return f"© {observer} via GBIF ({licence_label})"
        return f"via GBIF ({licence_label})"
    elif source == "wikimedia":
        if observer:
            return f"© {observer} / Wikimedia Commons ({licence_label})"
        return f"via Wikimedia Commons ({licence_label})"
    else:
        return f"© {observer} ({licence_label})" if observer else f"({licence_label})"


def parse_licence_from_attribution(text):
    """
    Last-resort: extract a CC licence from a free-text attribution string.
    Used in the iNat photo verification chain (step 4 of 4).
    """
    if not text:
        return None
    t = text.lower()
    if "publicdomain" in t or "public domain" in t or "cc0" in t:
        return "cc0"
    if "by-nc" in t or "by nc" in t:
        return None  # NC — blocked
    if "by-nd" in t or "by nd" in t:
        return "cc-by-nd"
    if "by-sa" in t or "by sa" in t:
        return "cc-by-sa"
    if "creativecommons" in t and "/by/" in t:
        return "cc-by"
    return None


# ── iNaturalist ───────────────────────────────────────────────────────────────

def fetch_inat_images(taxon_id, headers):
    """
    Query iNat for top-voted research-grade photos for a taxon.
    Returns a list of permitted-licence image candidate dicts, one per
    observation (best licenced photo per observation).
    """
    params = {
        "taxon_id":      taxon_id,
        "quality_grade": "research",
        "captive":       "false",
        "photos":        "true",
        "order_by":      "votes",
        "per_page":      INAT_MAX_OBS,
    }
    try:
        r = requests.get(f"{INAT_API}/observations",
                         params=params, headers=headers, timeout=15)
        r.raise_for_status()
        results = r.json().get("results", [])
    except Exception as e:
        print(f"      iNat query error: {e}")
        return []

    candidates = []

    for obs in results:
        obs_id       = obs.get("id")
        obs_url      = (f"https://www.inaturalist.org/observations/{obs_id}"
                        if obs_id else "")
        user         = obs.get("user") or {}
        observer     = user.get("login", "")
        observer_url = (f"https://www.inaturalist.org/people/{observer}"
                        if observer else "")
        obs_licence  = obs.get("license_code", "")

        for photo in obs.get("photos", []):
            photo_id    = photo.get("id")
            raw_licence = photo.get("license_code") or obs_licence

            licence_code = normalise_licence(raw_licence)

            # Empty licence — run four-step verification per licence_rules.md
            if not raw_licence and obs_id:
                licence_code = _verify_inat_photo_licence(
                    obs_id, photo_id, headers)
                time.sleep(VERIFY_DELAY)

            if not is_permitted(licence_code):
                continue

            # Build medium-size URL from the square thumbnail template
            url_template = photo.get("url", "")
            if "square" in url_template:
                photo_url = url_template.replace("square", "medium")
            elif url_template:
                photo_url = url_template
            elif photo_id:
                photo_url = (
                    f"https://inaturalist-open-data.s3.amazonaws.com"
                    f"/photos/{photo_id}/medium.jpeg"
                )
            else:
                continue

            licence_label = LICENCE_LABELS[licence_code]
            candidates.append({
                "photo_url":     photo_url,
                "source":        "inat",
                "source_url":    obs_url,
                "observer":      observer,
                "observer_url":  observer_url,
                "licence_code":  licence_code,
                "licence_label": licence_label,
                "licence_url":   LICENCE_URLS[licence_code],
                "credit_line":   build_credit_line("inat", observer,
                                                   licence_label),
            })
            break  # one image per observation is sufficient

    return candidates


def _verify_inat_photo_licence(obs_id, photo_id, headers):
    """
    Four-step licence verification for iNat photos with empty/null licence.
    Per licence_rules.md §Verification for Empty Licence Codes.
    Returns a normalised licence code or None.
    """
    try:
        r = requests.get(f"{INAT_API}/observations/{obs_id}",
                         headers=headers, timeout=15)
        r.raise_for_status()
        results = r.json().get("results", [])
        if not results:
            return None
        obs = results[0]

        # Step 1 — observation-level licence
        code = normalise_licence(obs.get("license_code"))
        if code:
            return code

        # Steps 2 & 3 — photo-level licence and attribution string
        for photo in obs.get("photos", []):
            if photo_id and photo.get("id") != photo_id:
                continue
            code = normalise_licence(photo.get("license_code"))
            if code:
                return code
            # Step 4 — parse attribution string
            code = parse_licence_from_attribution(photo.get("attribution", ""))
            if code:
                return code

    except Exception:
        pass

    return None  # Step 4 exhausted — treat as blocked


# ── GBIF ──────────────────────────────────────────────────────────────────────

def resolve_gbif_taxon_key(scientific_name, headers):
    """
    Resolve a GBIF usageKey for a scientific name.
    Accepts EXACT or FUZZY matches with confidence >= 90.
    Per taxonomy_sources.md §GBIF Taxon ID Resolution.
    Returns an integer key or None.
    """
    try:
        r = requests.get(
            f"{GBIF_API}/species/match",
            params={"name": scientific_name, "strict": "false"},
            headers=headers,
            timeout=15
        )
        r.raise_for_status()
        data       = r.json()
        match_type = data.get("matchType", "")
        confidence = data.get("confidence", 0)
        if match_type in ("EXACT", "FUZZY") and confidence >= 90:
            return data.get("usageKey") or data.get("speciesKey")
    except Exception as e:
        print(f"      GBIF resolve error: {e}")
    return None


def fetch_gbif_images(gbif_taxon_key, headers):
    """
    Query GBIF occurrence search for StillImage media for a taxon.
    Returns a list of permitted-licence image candidate dicts.
    """
    params = {
        "taxonKey":  gbif_taxon_key,
        "mediaType": "StillImage",
        "limit":     GBIF_MAX_OCC,
    }
    try:
        r = requests.get(f"{GBIF_API}/occurrence/search",
                         params=params, headers=headers, timeout=15)
        r.raise_for_status()
        results = r.json().get("results", [])
    except Exception as e:
        print(f"      GBIF query error: {e}")
        return []

    candidates = []
    seen_urls  = set()

    for occ in results:
        occ_key = occ.get("key")
        occ_url = (f"https://www.gbif.org/occurrence/{occ_key}"
                   if occ_key else "")
        recorded_by = occ.get("recordedBy", "")

        for media in occ.get("media", []):
            if media.get("type") != "StillImage":
                continue

            photo_url = media.get("identifier", "")
            if not photo_url or photo_url in seen_urls:
                continue

            licence_code = normalise_licence(media.get("license", ""))
            if not is_permitted(licence_code):
                continue

            seen_urls.add(photo_url)
            observer = (nullable_str(media.get("rightsHolder"))
                        or nullable_str(media.get("creator"))
                        or recorded_by
                        or "")

            licence_label = LICENCE_LABELS[licence_code]
            candidates.append({
                "photo_url":     photo_url,
                "source":        "gbif",
                "source_url":    occ_url,
                "observer":      observer,
                "observer_url":  "",
                "licence_code":  licence_code,
                "licence_label": licence_label,
                "licence_url":   LICENCE_URLS[licence_code],
                "credit_line":   build_credit_line("gbif", observer,
                                                   licence_label),
            })

    return candidates


# ── Wikimedia Commons ─────────────────────────────────────────────────────────

def fetch_wikimedia_images(scientific_name, headers):
    """
    Search Wikimedia Commons file namespace for images of a species.
    Returns a list of permitted-licence image candidate dicts.
    """
    # Step 1 — search file namespace (ns=6)
    try:
        r = requests.get(
            WIKI_API,
            params={
                "action":     "query",
                "list":       "search",
                "srsearch":   scientific_name,
                "srnamespace":"6",
                "srlimit":    WIKI_MAX_RESULTS,
                "format":     "json",
            },
            headers=headers,
            timeout=15
        )
        r.raise_for_status()
        search_results = r.json().get("query", {}).get("search", [])
    except Exception as e:
        print(f"      Wikimedia search error: {e}")
        return []

    if not search_results:
        return []

    candidates = []

    # Step 2 — fetch image info (URL + licence metadata) for each result
    for hit in search_results:
        title = hit.get("title", "")
        if not title:
            continue

        time.sleep(VERIFY_DELAY)

        try:
            r = requests.get(
                WIKI_API,
                params={
                    "action":   "query",
                    "titles":   title,
                    "prop":     "imageinfo",
                    "iiprop":   "url|extmetadata",
                    "format":   "json",
                },
                headers=headers,
                timeout=15
            )
            r.raise_for_status()
            pages = r.json().get("query", {}).get("pages", {})
        except Exception as e:
            print(f"      Wikimedia imageinfo error ({title}): {e}")
            continue

        for page in pages.values():
            for ii in page.get("imageinfo", []):
                photo_url = ii.get("url", "")
                if not photo_url:
                    continue

                # Skip non-raster image types
                ext = photo_url.lower().split("?")[0].rsplit(".", 1)[-1]
                if ext not in ("jpg", "jpeg", "png", "gif", "webp",
                               "tif", "tiff"):
                    continue

                extmeta = ii.get("extmetadata", {})
                raw_licence = (
                    extmeta.get("LicenseShortName", {}).get("value", "")
                    or extmeta.get("License", {}).get("value", "")
                )
                licence_code = normalise_licence(raw_licence)
                if not is_permitted(licence_code):
                    continue

                # Strip HTML tags from author field
                author_html = extmeta.get("Artist", {}).get("value", "")
                author      = re.sub(r"<[^>]+>", "", author_html).strip()

                file_page = (
                    f"https://commons.wikimedia.org/wiki/"
                    f"{title.replace(' ', '_')}"
                )

                licence_label = LICENCE_LABELS[licence_code]
                candidates.append({
                    "photo_url":     photo_url,
                    "source":        "wikimedia",
                    "source_url":    file_page,
                    "observer":      author,
                    "observer_url":  "",
                    "licence_code":  licence_code,
                    "licence_label": licence_label,
                    "licence_url":   LICENCE_URLS[licence_code],
                    "credit_line":   build_credit_line("wikimedia", author,
                                                       licence_label),
                })

    return candidates


# ── Image selection ───────────────────────────────────────────────────────────

def select_images(inat_candidates, gbif_candidates, wiki_candidates):
    """
    Select up to 3 images from the candidate pools with source diversity.

    Slot preference order (per licence_rules.md §Multi-Image Rules):
        Slot 0 (hero)    — iNat > GBIF > Wikimedia
        Slot 1 (supp.)   — GBIF > Wikimedia > iNat
        Slot 2 (supp.)   — Wikimedia > GBIF > iNat

    Each slot first tries to pick from a source not yet used.
    If all sources already used, relaxes the constraint and picks the
    next unused URL from any source.
    """
    pools = {
        "inat":      list(inat_candidates),
        "gbif":      list(gbif_candidates),
        "wikimedia": list(wiki_candidates),
    }

    slot_preference = [
        ["inat",      "gbif",      "wikimedia"],  # Slot 0
        ["gbif",      "wikimedia", "inat"     ],  # Slot 1
        ["wikimedia", "gbif",      "inat"     ],  # Slot 2
    ]

    selected    = []
    used_urls   = set()

    def next_unused(pool_list):
        for c in pool_list:
            if c["photo_url"] not in used_urls:
                return c
        return None

    for slot_idx in range(MAX_IMAGES):
        if len(selected) >= MAX_IMAGES:
            break

        used_sources = {img["source"] for img in selected}
        candidate    = None

        # First pass: prefer a source not yet used
        for src in slot_preference[slot_idx]:
            if src not in used_sources:
                candidate = next_unused(pools[src])
                if candidate:
                    break

        # Second pass: relax — any unused URL from any source
        if not candidate:
            for src in slot_preference[slot_idx]:
                candidate = next_unused(pools[src])
                if candidate:
                    break

        if candidate:
            selected.append(candidate)
            used_urls.add(candidate["photo_url"])

    return selected


# ── Argument parsing ──────────────────────────────────────────────────────────

def parse_args():
    parser = argparse.ArgumentParser(
        description=(
            "Fetch commercially licenced images for each species via "
            "iNat → GBIF → Wikimedia cascade"
        )
    )
    parser.add_argument(
        "--output", "-o",
        default=os.path.join(SCRIPT_DIR, "image_credits.json"),
        help=(
            "Output JSON file path. "
            "Default: image_credits.json in script directory. "
            "Pass --output carajas_image_credits.json to match the "
            "filename expected by json_assembler.py."
        )
    )
    parser.add_argument(
        "--email",
        default="",
        help="Contact email for User-Agent header (recommended by iNat)"
    )
    parser.add_argument(
        "--csv",
        default=CSV_PATH,
        help="Path to master_dataset.csv (default: master_dataset.csv in script dir)"
    )
    return parser.parse_args()


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    args = parse_args()

    user_agent = (
        f"FieldGuidePipeline/1.0 ({args.email})"
        if args.email
        else "FieldGuidePipeline/1.0"
    )
    headers = {"User-Agent": user_agent}

    # ── Load species list ─────────────────────────────────────────────────────
    if not os.path.exists(args.csv):
        print(f"ERROR: master_dataset.csv not found at {args.csv}")
        sys.exit(1)

    df = pd.read_csv(args.csv)
    print(f"Loaded {len(df)} species from {os.path.basename(args.csv)}")
    print(f"Output: {args.output}")
    print("-" * 60)

    output           = []
    n_ok             = 0
    n_needs_outreach = 0
    needs_outreach_names = []

    for _, row in df.iterrows():
        name      = nullable_str(row.get("scientific_name"))
        if not name:
            print("  SKIP — row with no scientific_name")
            continue

        taxon_url = str(row.get("inat_taxon_url", ""))
        taxon_id  = extract_taxon_id(taxon_url)

        # Use gbif_taxon_key column if Claude populated it; else resolve via API
        gbif_raw = row.get("gbif_taxon_key")
        gbif_key = None
        if gbif_raw and nullable_str(str(gbif_raw)):
            try:
                gbif_key = int(float(str(gbif_raw)))
            except (ValueError, TypeError):
                pass

        print(f"  {name}")

        # ── Tier 1: iNaturalist ───────────────────────────────────────────────
        inat_candidates = []
        if taxon_id:
            inat_candidates = fetch_inat_images(taxon_id, headers)
            time.sleep(API_DELAY)
            print(f"      iNat:      {len(inat_candidates)} usable")
        else:
            print(f"      iNat:      SKIP (no taxon ID in inat_taxon_url)")

        # ── Tier 2: GBIF ──────────────────────────────────────────────────────
        if not gbif_key:
            gbif_key = resolve_gbif_taxon_key(name, headers)
            time.sleep(API_DELAY)

        gbif_candidates = []
        if gbif_key:
            gbif_candidates = fetch_gbif_images(gbif_key, headers)
            time.sleep(API_DELAY)
            print(f"      GBIF:      {len(gbif_candidates)} usable")
        else:
            print(f"      GBIF:      SKIP (taxon key not resolved)")

        # ── Tier 3: Wikimedia ─────────────────────────────────────────────────
        wiki_candidates = fetch_wikimedia_images(name, headers)
        time.sleep(API_DELAY)
        print(f"      Wikimedia: {len(wiki_candidates)} usable")

        # ── Select up to 3 with source diversity ──────────────────────────────
        selected = select_images(inat_candidates, gbif_candidates,
                                 wiki_candidates)

        if selected:
            sources = sorted({img["source"] for img in selected})
            print(f"      RESOLVED:  {len(selected)} image(s) — sources: {sources}")
            output.append({
                "scientific_name": name,
                "image_status":    "ok",
                "images":          selected,
            })
            n_ok += 1
        else:
            # needs_outreach — NOT written to image_credits.json per schema.
            # json_assembler.py will fall back to inat_image_url from
            # master_dataset.csv for display, if present.
            print(f"      NEEDS OUTREACH — no commercial licence found")
            n_needs_outreach += 1
            needs_outreach_names.append(name)

    # ── Write output ──────────────────────────────────────────────────────────
    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(output, f, indent=2, ensure_ascii=False)

    # ── Summary ───────────────────────────────────────────────────────────────
    total = n_ok + n_needs_outreach
    pct   = f"{n_ok / total * 100:.0f}%" if total else "—"

    print()
    print("=" * 60)
    print("IMAGE PIPELINE COMPLETE")
    print(f"  Species processed:   {total}")
    print(f"  Images resolved:     {n_ok} ({pct})")
    print(f"  Needs outreach:      {n_needs_outreach}")
    print()
    print(f"Output: {args.output}")

    if needs_outreach_names:
        print()
        print("Needs outreach:")
        for n in needs_outreach_names:
            print(f"    {n}")
        print()
        print("  Contact iNaturalist observers directly for commercial")
        print("  permission. See rules/licence_rules.md for guidance.")

    print("=" * 60)
    print()
    print("Next step: run json_assembler.py")
    print("  Note: json_assembler.py expects input file named")
    print("  carajas_image_credits.json. Pass --output with that name,")
    print("  or update CREDITS_IN in json_assembler.py to match.")


if __name__ == "__main__":
    main()
