#!/usr/bin/env python3
"""
json_assembler.py
Field Guide Pipeline — JSON Assembly Script

Takes Claude's validated species CSV and merges all pipeline outputs
into a final species.json conforming to schemas/species_schema.md.

Inputs (all must be in the same folder as this script):
    master_dataset.csv       — validated species data from Claude (Steps 3–5)
    inat_sightings.json      — georeferenced observations from iNat (Step 6)
    carajas_image_credits.json — image credits from image pipeline (Step 7)

Outputs:
    species.json             — final app-ready species data
    image_credits.json       — standalone image attribution record
    assembly_report.txt      — validation results and any errors

Usage:
    pip3 install requests pandas
    python3 json_assembler.py

Place this script alongside all input files.
"""

import os
import json
import sys
import csv
from datetime import datetime

try:
    import pandas as pd
except ImportError:
    print("ERROR: pip3 install pandas")
    sys.exit(1)

# ── Config ────────────────────────────────────────────────────────────────────

SCRIPT_DIR      = os.path.dirname(os.path.abspath(__file__))
CSV_IN          = os.path.join(SCRIPT_DIR, "master_dataset.csv")
SIGHTINGS_IN    = os.path.join(SCRIPT_DIR, "inat_sightings.json")
CREDITS_IN      = os.path.join(SCRIPT_DIR, "carajas_image_credits.json")
SPECIES_OUT     = os.path.join(SCRIPT_DIR, "species.json")
CREDITS_OUT     = os.path.join(SCRIPT_DIR, "image_credits.json")
REPORT_OUT      = os.path.join(SCRIPT_DIR, "assembly_report.txt")

# ── Controlled vocabularies ───────────────────────────────────────────────────

VALID_TAXON_GROUPS = {
    "snake", "lizard", "turtle", "amphibian", "bird", "mammal"
}

VALID_VENOM_STATUSES = {
    "dangerous", "mild", "low_risk", "non_venomous"
}

VALID_IUCN_STATUSES = {
    "LC", "NT", "VU", "EN", "CR", "EW", "EX"
}

VALID_HABITAT_VALUES = {
    "Forest", "Riparian", "Grassland", "Wetland", "Canga",
    "Urban", "Aquatic", "Arboreal", "Fossorial", "Coastal", "Montane"
}

VALID_IMAGE_SOURCES = {
    "inat", "gbif", "wikimedia", "permission"
}

VALID_LICENCE_CODES = {
    "cc0", "cc-by", "cc-by-sa", "cc-by-nd"
}

VALID_IMAGE_STATUSES = {
    "ok", "needs_outreach"
}

# ── Helpers ───────────────────────────────────────────────────────────────────

def nullable_str(val):
    """Return None for empty, NaN, or 'null' string values."""
    if val is None:
        return None
    s = str(val).strip()
    if s == "" or s.lower() in ("nan", "null", "none"):
        return None
    return s

def nullable_int(val):
    """Return None for empty/NaN, otherwise int."""
    s = nullable_str(val)
    if s is None:
        return None
    try:
        return int(float(s))
    except (ValueError, TypeError):
        return None

def nullable_float(val):
    """Return None for empty/NaN, otherwise float."""
    s = nullable_str(val)
    if s is None:
        return None
    try:
        return float(s)
    except (ValueError, TypeError):
        return None

def parse_list(val, delimiter="|"):
    """Parse a delimited string into a list, stripping whitespace."""
    s = nullable_str(val)
    if s is None:
        return None
    items = [item.strip() for item in s.split(delimiter) if item.strip()]
    return items if items else None

def parse_survey_presence(val):
    """
    Parse survey presence from CSV.
    Expected format: 'ID1:Name1:URL1|ID2:Name2:URL2'
    e.g. 'CN-1985:Cunha et al. 1985:https://...|UFSC-2023:CNF Survey:https://...'
    """
    s = nullable_str(val)
    if s is None:
        return None
    surveys = []
    for entry in s.split("|"):
        parts = entry.strip().split(":", 2)
        if len(parts) >= 2:
            surveys.append({
                "id":   parts[0].strip(),
                "name": parts[1].strip(),
                "url":  parts[2].strip() if len(parts) > 2 else None
            })
    return surveys if surveys else None


# ── Validation ────────────────────────────────────────────────────────────────

class ValidationReport:
    def __init__(self):
        self.errors   = []   # blocking — must fix before release
        self.warnings = []   # non-blocking — review recommended
        self.info     = []   # informational

    def error(self, species, field, msg):
        self.errors.append(f"  ERROR   [{species}] {field}: {msg}")

    def warning(self, species, field, msg):
        self.warnings.append(f"  WARNING [{species}] {field}: {msg}")

    def note(self, msg):
        self.info.append(f"  INFO    {msg}")

    def has_errors(self):
        return len(self.errors) > 0

    def summary(self, total):
        lines = [
            f"Assembly Report — {datetime.now().strftime('%Y-%m-%d %H:%M')}",
            f"{'=' * 60}",
            f"Species processed: {total}",
            f"Errors:   {len(self.errors)}",
            f"Warnings: {len(self.warnings)}",
            f"",
        ]
        if self.errors:
            lines += ["ERRORS (must resolve before release):", ""] + self.errors + [""]
        if self.warnings:
            lines += ["WARNINGS (review recommended):", ""] + self.warnings + [""]
        if self.info:
            lines += ["INFO:", ""] + self.info + [""]
        lines += ["=" * 60]
        if self.has_errors():
            lines.append("STATUS: FAILED — resolve errors before using species.json")
        else:
            lines.append("STATUS: PASSED — species.json is ready for Xcode")
        return "\n".join(lines)


def validate_species(obj, report):
    """Validate a single species object against the schema rules."""
    name = obj.get("scientific_name", "UNKNOWN")

    # Required fields
    if not obj.get("scientific_name"):
        report.error(name, "scientific_name", "required field is null")
    if not obj.get("taxon_group"):
        report.error(name, "taxon_group", "required field is null")

    # Controlled vocabulary
    tg = obj.get("taxon_group")
    if tg and tg not in VALID_TAXON_GROUPS:
        report.error(name, "taxon_group",
                     f"'{tg}' not in {sorted(VALID_TAXON_GROUPS)}")

    vs = obj.get("venom_status")
    if vs and vs not in VALID_VENOM_STATUSES:
        report.error(name, "venom_status",
                     f"'{vs}' not in {sorted(VALID_VENOM_STATUSES)}")

    iucn = obj.get("iucn_status")
    if iucn and iucn not in VALID_IUCN_STATUSES:
        report.error(name, "iucn_status",
                     f"'{iucn}' not in {sorted(VALID_IUCN_STATUSES)}")

    habitats = obj.get("habitat") or []
    for h in habitats:
        if h not in VALID_HABITAT_VALUES:
            report.warning(name, "habitat",
                           f"'{h}' not in controlled vocabulary")

    # Images
    images = obj.get("images") or []
    if len(images) > 3:
        report.error(name, "images", f"has {len(images)} images — max 3")

    for i, img in enumerate(images):
        slot = f"images[{i}]"
        for req in ("photo_url", "source", "licence_code",
                    "licence_label", "credit_line"):
            if not img.get(req):
                report.error(name, slot,
                             f"required field '{req}' is missing or null")
        src = img.get("source")
        if src and src not in VALID_IMAGE_SOURCES:
            report.error(name, slot,
                         f"source '{src}' not in {sorted(VALID_IMAGE_SOURCES)}")
        lc = img.get("licence_code")
        if lc and lc not in VALID_LICENCE_CODES:
            report.error(name, slot,
                         f"licence_code '{lc}' not in permitted commercial licences")

    # inat_image_url consistency
    if images:
        expected = images[0].get("photo_url")
        actual   = obj.get("inat_image_url")
        if expected and actual != expected:
            report.warning(name, "inat_image_url",
                           "does not match images[0].photo_url")

    # Warnings for missing recommended fields
    if not obj.get("english_name"):
        report.warning(name, "english_name", "null — no English name")
    if not obj.get("description"):
        report.warning(name, "description", "null — no description")
    if not obj.get("iucn_status"):
        report.warning(name, "iucn_status", "null — not assessed")
    if not obj.get("habitat"):
        report.warning(name, "habitat", "null — no habitat data")


# ── Main assembly ─────────────────────────────────────────────────────────────

def main():
    report = ValidationReport()

    # ── Check input files ─────────────────────────────────────────────────────
    missing = []
    for path, name in [
        (CSV_IN,      "master_dataset.csv"),
        (SIGHTINGS_IN,"inat_sightings.json"),
        (CREDITS_IN,  "carajas_image_credits.json"),
    ]:
        if not os.path.exists(path):
            missing.append(name)

    if missing:
        print(f"ERROR: Missing input files: {', '.join(missing)}")
        print("Place all input files in the same folder as this script.")
        sys.exit(1)

    # ── Load inputs ───────────────────────────────────────────────────────────
    df = pd.read_csv(CSV_IN)
    print(f"Loaded {len(df)} species from master_dataset.csv")

    with open(SIGHTINGS_IN, "r", encoding="utf-8") as f:
        sightings_data = json.load(f)
    sightings_by_name = {s["scientific_name"]: s.get("sightings", [])
                         for s in sightings_data}
    print(f"Loaded sightings for {len(sightings_by_name)} species")

    with open(CREDITS_IN, "r", encoding="utf-8") as f:
        credits_data = json.load(f)
    credits_by_name = {c["scientific_name"]: c for c in credits_data}
    print(f"Loaded image credits for {len(credits_by_name)} species")
    print()

    # ── Check for duplicate scientific names ──────────────────────────────────
    dupes = df[df.duplicated("scientific_name", keep=False)]
    if not dupes.empty:
        for name in dupes["scientific_name"].unique():
            report.error(name, "scientific_name",
                         "duplicate entry in master_dataset.csv")

    # ── Build species objects ─────────────────────────────────────────────────
    species_list  = []
    credits_list  = []
    seen_names    = set()

    for _, row in df.iterrows():
        name = nullable_str(row.get("scientific_name"))
        if not name:
            report.error("UNKNOWN", "scientific_name",
                         "row with null scientific_name — skipped")
            continue
        if name in seen_names:
            continue
        seen_names.add(name)

        # ── Core fields ───────────────────────────────────────────────────────
        obj = {
            "scientific_name":      name,
            "english_name":         nullable_str(row.get("english_name")),
            "local_name":           nullable_str(row.get("local_name")),
            "taxon_group":          nullable_str(row.get("taxon_group")) or "snake",
            "survey_taxon_original":nullable_str(row.get("survey_taxon_original")),
            "venom_status":         nullable_str(row.get("venom_status")),
            "venom_type":           nullable_str(row.get("venom_type")),
            "iucn_status":          nullable_str(row.get("iucn_status")),
            "avg_size_cm":          nullable_float(row.get("avg_size_cm")),
            "max_size_cm":          nullable_float(row.get("max_size_cm")),
            "habitat":              parse_list(row.get("habitat")),
            "description":          nullable_str(row.get("description")),
            "survey_presence":      parse_survey_presence(
                                        row.get("survey_presence")),
            "inat_observations":    nullable_int(row.get("inat_observations")),
            "inat_taxon_url":       nullable_str(row.get("inat_taxon_url")),
            "source_notes":         nullable_str(row.get("source_notes")),
        }

        # ── iNat sightings ────────────────────────────────────────────────────
        raw_sightings = sightings_by_name.get(name, [])
        obj["inat_sightings"] = [
            {
                "lat":  s.get("lat"),
                "lng":  s.get("lng"),
                "date": s.get("date"),
            }
            for s in raw_sightings
            if s.get("lat") is not None and s.get("lng") is not None
        ]

        # ── Images ────────────────────────────────────────────────────────────
        credit = credits_by_name.get(name)
        if credit and credit.get("image_status") == "ok":
            raw_images = credit.get("images", [])[:3]

            images = []
            for img in raw_images:
                images.append({
                    "photo_url":    img.get("photo_url", ""),
                    "source":       img.get("source", ""),
                    "source_url":   img.get("source_url", ""),
                    "observer":     img.get("observer", ""),
                    "observer_url": img.get("observer_url", ""),
                    "licence_code": img.get("licence_code", ""),
                    "licence_label":img.get("licence_label", ""),
                    "licence_url":  img.get("licence_url", ""),
                    "credit_line":  img.get("credit_line", ""),
                })

            obj["images"]         = images
            obj["inat_image_url"] = images[0]["photo_url"] if images else None
            obj["image_status"]   = "ok"

            # Build credits output entry
            credits_list.append({
                "scientific_name": name,
                "image_status":    "ok",
                "images":          images,
            })

        else:
            obj["images"]         = []
            obj["inat_image_url"] = nullable_str(row.get("inat_image_url"))
            obj["image_status"]   = "needs_outreach"
            report.note(f"{name} — needs_outreach (no commercial image found)")

        # ── Remove survey_taxon_original if same as accepted name ─────────────
        if obj.get("survey_taxon_original") == name:
            obj["survey_taxon_original"] = None

        # ── Validate ──────────────────────────────────────────────────────────
        validate_species(obj, report)

        species_list.append(obj)

    # ── Duplicate name checks ─────────────────────────────────────────────────
    english_names = {}
    local_names   = {}
    for obj in species_list:
        n = obj["scientific_name"]
        en = obj.get("english_name")
        ln = obj.get("local_name")
        if en:
            english_names.setdefault(en, []).append(n)
        if ln:
            local_names.setdefault(ln, []).append(n)

    for en, names in english_names.items():
        if len(names) > 1:
            report.warning(", ".join(names), "english_name",
                           f'duplicate: "{en}" used by {len(names)} species')
    for ln, names in local_names.items():
        if len(names) > 1:
            report.warning(", ".join(names), "local_name",
                           f'duplicate: "{ln}" used by {len(names)} species')

    # ── Write outputs ─────────────────────────────────────────────────────────
    with open(SPECIES_OUT, "w", encoding="utf-8") as f:
        json.dump(species_list, f, indent=2, ensure_ascii=False)
    print(f"species.json written — {len(species_list)} species")

    with open(CREDITS_OUT, "w", encoding="utf-8") as f:
        json.dump(credits_list, f, indent=2, ensure_ascii=False)
    print(f"image_credits.json written — {len(credits_list)} species with images")

    report_text = report.summary(len(species_list))
    with open(REPORT_OUT, "w", encoding="utf-8") as f:
        f.write(report_text)
    print()
    print(report_text)

    # ── Exit code ─────────────────────────────────────────────────────────────
    sys.exit(1 if report.has_errors() else 0)


if __name__ == "__main__":
    main()
