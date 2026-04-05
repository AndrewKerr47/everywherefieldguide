#!/bin/bash
# run_pipeline.sh
# Field Guide Pipeline — Layer 2 Automation Script
#
# Runs all Python scripts in the correct order for a pipeline run.
# Claude handles Layer 1 (research, taxonomy, data population) — this
# script handles Layer 2 (mechanical API calls and JSON assembly).
#
# Prerequisites:
#   pip3 install requests pandas
#
# Usage:
#   bash run_pipeline.sh
#
# All input files must be present in the scripts/ folder before running:
#   - master_dataset.csv        (output from Claude Steps 3-5)
#   - bbox.json                 (from bounding_box_resolver.py, or manual)
#   - carajas_image_credits.json (output from inat_image_pipeline.py)
#
# Run order:
#   1. bounding_box_resolver.py  (if bbox.json not already present)
#   2. inat_sightings.py         (fetches sightings + obs counts)
#   3. inat_image_pipeline.py    (fetches images with licence checking)
#   4. json_assembler.py         (assembles final species.json)

set -e  # exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================"
echo "Field Guide Pipeline — Layer 2"
echo "========================================"
echo ""

# ── Step 0: Check dependencies ────────────────────────────────────────────────
echo "Checking dependencies..."
python3 -c "import requests, pandas" 2>/dev/null || {
    echo "ERROR: Missing dependencies. Run: pip3 install requests pandas"
    exit 1
}
echo "  OK"
echo ""

# ── Step 1: Bounding box ──────────────────────────────────────────────────────
if [ ! -f "bbox.json" ]; then
    echo "bbox.json not found."
    read -p "Enter area name to resolve (or press Enter to skip): " AREA
    if [ -n "$AREA" ]; then
        python3 bounding_box_resolver.py "$AREA"
    else
        echo "ERROR: bbox.json required. Run bounding_box_resolver.py first."
        exit 1
    fi
else
    echo "bbox.json found — skipping bounding box resolution."
    python3 -c "
import json
with open('bbox.json') as f:
    b = json.load(f)
print(f'  Area: {b.get(\"area_name\", \"unknown\")}')
print(f'  SW: ({b[\"swlat\"]}, {b[\"swlng\"]})')
print(f'  NE: ({b[\"nelat\"]}, {b[\"nelng\"]})')
"
fi
echo ""

# ── Step 2: Check master_dataset.csv ─────────────────────────────────────────
if [ ! -f "master_dataset.csv" ]; then
    echo "ERROR: master_dataset.csv not found."
    echo "Claude must complete Steps 3-5 first and output this file."
    exit 1
fi
echo "master_dataset.csv found."
SPECIES_COUNT=$(python3 -c "import pandas as pd; print(len(pd.read_csv('master_dataset.csv')))")
echo "  Species: $SPECIES_COUNT"
echo ""

# ── Step 3: iNat sightings + observation counts ───────────────────────────────
echo "----------------------------------------"
echo "Step 3: iNat sightings + observation counts"
echo "----------------------------------------"
python3 inat_sightings.py
echo ""

# ── Step 4: Image pipeline ────────────────────────────────────────────────────
echo "----------------------------------------"
echo "Step 4: Image pipeline (iNat → GBIF → Wikimedia)"
echo "----------------------------------------"
python3 inat_image_pipeline.py
echo ""

# ── Step 5: JSON assembly ─────────────────────────────────────────────────────
echo "----------------------------------------"
echo "Step 5: JSON assembly + validation"
echo "----------------------------------------"
python3 json_assembler.py
ASSEMBLY_EXIT=$?
echo ""

# ── Done ──────────────────────────────────────────────────────────────────────
echo "========================================"
if [ $ASSEMBLY_EXIT -eq 0 ]; then
    echo "PIPELINE COMPLETE"
    echo ""
    echo "Outputs:"
    echo "  species.json          — ready for Xcode"
    echo "  image_credits.json    — image attribution record"
    echo "  assembly_report.txt   — validation results"
    echo ""
    echo "Next: human review of assembly_report.txt"
    echo "      then copy species.json to Xcode Resources/"
else
    echo "PIPELINE COMPLETED WITH ERRORS"
    echo ""
    echo "Review assembly_report.txt and resolve errors before"
    echo "copying species.json to Xcode."
fi
echo "========================================"

exit $ASSEMBLY_EXIT
