#!/usr/bin/env python3
"""
bounding_box_resolver.py
Field Guide Pipeline — Bounding Box Resolver

Resolves a named geographic area (national park, country, region) to a
lat/lng bounding box and writes bbox.json for use by other pipeline scripts.

Resolution order:
    1. Protected Planet API  — for named national parks / protected areas
    2. Nominatim (OSM)       — for countries, states, regions
    3. Manual entry          — user fallback if both APIs fail

Outputs:
    bbox.json   — bounding box coordinates consumed by inat_sightings.py
                  and inat_image_pipeline.py

Usage:
    python3 bounding_box_resolver.py "Serra dos Carajás"
    python3 bounding_box_resolver.py "Brazil"
    python3 bounding_box_resolver.py "Parque Nacional da Amazônia"
"""

import os
import sys
import json
import time

try:
    import requests
except ImportError:
    print("ERROR: pip3 install requests")
    sys.exit(1)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BBOX_OUT   = os.path.join(SCRIPT_DIR, "bbox.json")

HEADERS = {
    "User-Agent": "FieldGuidePipeline/1.0",
    "Accept-Language": "en",
}

# ── Protected Planet API ──────────────────────────────────────────────────────

def try_protected_planet(area_name):
    """
    Query Protected Planet (WDPA) for named protected areas.
    Returns (swlat, swlng, nelat, nelng) or None.
    Protected Planet API is free but rate-limited — no key required for basic queries.
    """
    print(f"  Trying Protected Planet for: '{area_name}'")
    try:
        r = requests.get(
            "https://api.protectedplanet.net/v3/protected_areas/search",
            params={"q": area_name, "per_page": 5},
            headers=HEADERS,
            timeout=15
        )
        r.raise_for_status()
        results = r.json().get("protected_areas", [])

        for area in results:
            # Try to get bounding box from the area's geometry
            geojson = area.get("geojson")
            if geojson:
                bbox = extract_bbox_from_geojson(geojson)
                if bbox:
                    name = area.get("name", "Unknown")
                    wdpa = area.get("wdpa_id", "")
                    print(f"  Found: {name} (WDPA ID: {wdpa})")
                    return bbox

            # Fallback: use centroid + 0.5 degree buffer
            lat = area.get("latitude")
            lng = area.get("longitude")
            if lat and lng:
                buf = 0.5
                name = area.get("name", "Unknown")
                print(f"  Found centroid for: {name} — applying 0.5° buffer")
                print(f"  WARNING: No exact boundary — verify bbox manually")
                return (
                    round(float(lat) - buf, 6),
                    round(float(lng) - buf, 6),
                    round(float(lat) + buf, 6),
                    round(float(lng) + buf, 6),
                )

    except Exception as e:
        print(f"  Protected Planet error: {e}")

    return None


def extract_bbox_from_geojson(geojson):
    """Extract SW/NE bounding box from a GeoJSON geometry."""
    try:
        if isinstance(geojson, str):
            geojson = json.loads(geojson)

        coords = []
        geom_type = geojson.get("type", "")

        if geom_type == "Point":
            coords = [geojson["coordinates"]]
        elif geom_type == "Polygon":
            coords = geojson["coordinates"][0]
        elif geom_type == "MultiPolygon":
            for poly in geojson["coordinates"]:
                coords.extend(poly[0])
        elif geom_type == "GeometryCollection":
            for geom in geojson.get("geometries", []):
                result = extract_bbox_from_geojson(geom)
                if result:
                    return result

        if not coords:
            return None

        lngs = [c[0] for c in coords]
        lats = [c[1] for c in coords]
        return (
            round(min(lats), 6),
            round(min(lngs), 6),
            round(max(lats), 6),
            round(max(lngs), 6),
        )
    except Exception:
        return None


# ── Nominatim (OpenStreetMap) ─────────────────────────────────────────────────

def try_nominatim(area_name):
    """
    Query Nominatim for a named place.
    Returns (swlat, swlng, nelat, nelng) or None.
    """
    print(f"  Trying Nominatim for: '{area_name}'")
    try:
        r = requests.get(
            "https://nominatim.openstreetmap.org/search",
            params={
                "q":              area_name,
                "format":         "json",
                "limit":          5,
                "polygon_geojson":"0",
            },
            headers=HEADERS,
            timeout=15
        )
        r.raise_for_status()
        results = r.json()
        time.sleep(1.0)  # Nominatim requires 1s between requests

        for result in results:
            bbox = result.get("boundingbox")
            if bbox and len(bbox) == 4:
                swlat = round(float(bbox[0]), 6)
                nelat = round(float(bbox[1]), 6)
                swlng = round(float(bbox[2]), 6)
                nelng = round(float(bbox[3]), 6)
                display = result.get("display_name", "Unknown")
                print(f"  Found: {display}")
                return swlat, swlng, nelat, nelng

    except Exception as e:
        print(f"  Nominatim error: {e}")

    return None


# ── Manual entry ──────────────────────────────────────────────────────────────

def manual_entry():
    """Prompt user for manual bounding box entry."""
    print()
    print("  Automatic resolution failed. Please enter coordinates manually.")
    print("  Tip: Use https://boundingbox.klokantech.com/ to find your bbox.")
    print()
    try:
        swlat = float(input("  SW corner latitude  (e.g. -6.8): "))
        swlng = float(input("  SW corner longitude (e.g. -50.5): "))
        nelat = float(input("  NE corner latitude  (e.g. -5.8): "))
        nelng = float(input("  NE corner longitude (e.g. -49.5): "))
        return swlat, swlng, nelat, nelng
    except (ValueError, KeyboardInterrupt):
        print("  Invalid input — exiting.")
        sys.exit(1)


# ── Validation ────────────────────────────────────────────────────────────────

def validate_bbox(swlat, swlng, nelat, nelng):
    """Basic sanity checks on the bounding box."""
    errors = []
    if not (-90 <= swlat <= 90):
        errors.append(f"swlat {swlat} out of range [-90, 90]")
    if not (-90 <= nelat <= 90):
        errors.append(f"nelat {nelat} out of range [-90, 90]")
    if not (-180 <= swlng <= 180):
        errors.append(f"swlng {swlng} out of range [-180, 180]")
    if not (-180 <= nelng <= 180):
        errors.append(f"nelng {nelng} out of range [-180, 180]")
    if swlat >= nelat:
        errors.append(f"swlat ({swlat}) must be less than nelat ({nelat})")
    if swlng >= nelng:
        errors.append(f"swlng ({swlng}) must be less than nelng ({nelng})")

    # Warn if bbox is very large (> 5 degrees in either dimension)
    warnings = []
    if (nelat - swlat) > 5:
        warnings.append(
            f"Latitude span {nelat - swlat:.1f}° is large — "
            f"consider a tighter bbox for better iNat results"
        )
    if (nelng - swlng) > 5:
        warnings.append(
            f"Longitude span {nelng - swlng:.1f}° is large — "
            f"consider a tighter bbox"
        )

    return errors, warnings


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 bounding_box_resolver.py \"Area Name\"")
        print("Example: python3 bounding_box_resolver.py \"Serra dos Carajás\"")
        sys.exit(1)

    area_name = " ".join(sys.argv[1:])
    print(f"Resolving bounding box for: '{area_name}'")
    print()

    # Resolution chain
    result = None

    result = try_protected_planet(area_name)
    if not result:
        time.sleep(1)
        result = try_nominatim(area_name)
    if not result:
        result = manual_entry()

    swlat, swlng, nelat, nelng = result

    # Validate
    errors, warnings = validate_bbox(swlat, swlng, nelat, nelng)

    if errors:
        print()
        print("ERRORS — bounding box is invalid:")
        for e in errors:
            print(f"  {e}")
        sys.exit(1)

    if warnings:
        print()
        print("WARNINGS:")
        for w in warnings:
            print(f"  {w}")

    # Write bbox.json
    bbox = {
        "area_name": area_name,
        "swlat": swlat,
        "swlng": swlng,
        "nelat": nelat,
        "nelng": nelng,
        "span_lat": round(nelat - swlat, 4),
        "span_lng": round(nelng - swlng, 4),
    }

    with open(BBOX_OUT, "w", encoding="utf-8") as f:
        json.dump(bbox, f, indent=2)

    print()
    print(f"BOUNDING BOX RESOLVED")
    print(f"  Area:   {area_name}")
    print(f"  SW:     ({swlat}, {swlng})")
    print(f"  NE:     ({nelat}, {nelng})")
    print(f"  Span:   {bbox['span_lat']}° lat × {bbox['span_lng']}° lng")
    print()
    print(f"bbox.json saved to: {BBOX_OUT}")
    print()
    print("Next step: run inat_sightings.py")


if __name__ == "__main__":
    main()
