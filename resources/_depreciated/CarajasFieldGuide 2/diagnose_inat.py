#!/usr/bin/env python3
"""
diagnose_inat.py
Run this to see what the iNaturalist API is actually returning.
"""
import json, requests, time

with open("species.json", encoding="utf-8") as f:
    species = json.load(f)

for sp in species[:5]:
    name = sp["scientific_name"]
    taxon_url = sp.get("inat_taxon_url", "")
    
    # Extract taxon ID
    import re
    m = re.search(r'/taxa/(\d+)', taxon_url or "")
    taxon_id = m.group(1) if m else None
    
    print(f"\n{'='*60}")
    print(f"Species: {name}")
    print(f"Taxon URL: {taxon_url}")
    print(f"Taxon ID: {taxon_id}")
    
    if taxon_id:
        r = requests.get(
            f"https://api.inaturalist.org/v1/taxa/{taxon_id}",
            headers={"User-Agent": "CarajasFieldGuide/1.0"},
            timeout=10
        )
        data = r.json()
        if data.get("results"):
            result = data["results"][0]
            print(f"API name: {result.get('name')}")
            print(f"observations_count: {result.get('observations_count')}")
            print(f"default_photo: {result.get('default_photo')}")
            print(f"taxon_photos (first): {result.get('taxon_photos', [{}])[0] if result.get('taxon_photos') else 'none'}")
        else:
            print("No results returned")
    
    time.sleep(0.5)
