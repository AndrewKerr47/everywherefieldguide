# iNaturalist Filters
## Carajás Field Guide — Reusable Pipeline

---

## Purpose

This document defines the iNaturalist API filter parameters used across
all pipeline scripts. Referenced by SYSTEM_PROMPT.md and the image
pipeline scripts. These filters ensure only scientifically credible,
wild observations are included.

---

## Species List Filters

When querying iNaturalist for confirmed species presence within the
target area, apply ALL of the following filters:

| Parameter | Value | Reason |
|---|---|---|
| `quality_grade` | `research` | Community ID consensus reached — minimum scientific credibility threshold |
| `captive` | `false` | Wild observations only — excludes zoo, captive breeding, and cultivated records |
| `geo` | `true` | Must have coordinates — enables bounding box filtering |
| `taxon_id` | [taxon group ID] | Restrict to target taxon group |
| `nelat`, `nelng`, `swlat`, `swlng` | [bounding box] | Restrict to target geographic area |

---

## Bounding Box Resolution

The pipeline resolves a named area (country, national park, region) to
a lat/lng bounding box before querying iNaturalist. Resolution order:

1. Protected Planet API — for named national parks and protected areas
2. Nominatim (OpenStreetMap) geocoding — for countries and regions
3. Manual coordinates — user-supplied fallback

The bounding box should be the tightest reasonable fit for the area.
Overly large bounding boxes (e.g. entire country for a small park survey)
will inflate observation counts and include irrelevant sightings.

---

## Observation Count Query

Used to populate `inat_observations` per species — the visibility bar
in the app detail screen.

```
GET /v1/observations
  taxon_id={taxon_id}
  nelat={NELat}&nelng={NELng}&swlat={SWLat}&swlng={SWLng}
  per_page=0
  only_id=true
```

Returns `total_results` — the observation count within the bounding box.
A count of 0 within the bounding box is valid and should be stored as
null (not zero) to distinguish "no records in area" from "not queried".

---

## Sightings Query

Used to populate `inat_sightings` — the map pin coordinates in the app.

```
GET /v1/observations
  taxon_id={taxon_id}
  quality_grade=research
  captive=false
  nelat={NELat}&nelng={NELng}&swlat={SWLat}&swlng={SWLng}
  per_page=200
  fields=id,observed_on,location
```

Store each result as:
```json
{ "lat": -6.107783, "lng": -49.841889, "date": "2026-01-27" }
```
Date may be null if the observation has no date recorded.

---

## Image Query

Used by the image pipeline to find commercially usable photos.

```
GET /v1/observations
  taxon_id={taxon_id}
  quality_grade=research
  captive=false
  photos=true
  order_by=votes
  per_page=10
```

`order_by=votes` returns the most community-endorsed observations first,
which correlates with photo quality and correct identification.

---

## Taxon Group IDs

Common taxon group iNaturalist IDs for reference:

| Group | iNat Taxon ID |
|---|---|
| Reptiles (Reptilia) | 26036 |
| Amphibians (Amphibia) | 20978 |
| Birds (Aves) | 3 |
| Mammals (Mammalia) | 40151 |
| Snakes (Serpentes) | 85553 |
| Turtles (Testudines) | 39532 |
| Lizards (Sauria) | 86214 |

For combined groups (e.g. reptiles + amphibians + turtles), run
separate queries per taxon ID and merge results, deduplicating by
scientific name.

---

## Rate Limiting

- Delay 0.6 seconds between observation list API calls
- Delay 0.4 seconds between individual observation verification calls
- Use User-Agent header: `CarajasFieldGuide/1.0 (contact@email.com)`
- Do not exceed 60 requests per minute

---

## Version Log

| Version | Date       | Changes                          |
|---------|------------|----------------------------------|
| 1.0     | March 2026 | Initial version — Carajás Field Guide pipeline |
