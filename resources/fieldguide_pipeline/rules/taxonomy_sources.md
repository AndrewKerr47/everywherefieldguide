# Taxonomy Sources
## Carajás Field Guide — Reusable Pipeline

---

## Purpose

This document defines the authoritative taxonomy source to use per taxon
group for name validation, synonym resolution, and accepted name
determination. When databases disagree, the source listed here takes
precedence. Conflicts with lower-priority sources are flagged for human
review but do not block the pipeline.

---

## Authoritative Sources by Taxon Group

| Taxon Group | Primary Authority | Secondary Check | Notes |
|---|---|---|---|
| Snakes (Serpentes) | Reptile Database (reptile-database.org) | IUCN Red List | Most current accepted names for Neotropical species |
| Lizards (Sauria) | Reptile Database | IUCN Red List | |
| Turtles (Testudines) | Turtle Taxonomy Working Group (via Reptile Database) | IUCN Red List | |
| Amphibians (Amphibia) | AmphibiaWeb (amphibiaweb.org) | IUCN Red List | |
| Birds (Aves) | IOC World Bird List (worldbirdnames.org) | BirdLife International | Use IOC version current at time of pipeline run |
| Mammals (Mammalia) | Wilson & Reeder (via IUCN) | Mammal Diversity Database (ASM) | |
| All groups | GBIF Backbone Taxonomy | — | Used for taxon ID resolution when primary authority lacks API |

---

## Validation Steps

For each species name from the approved papers:

1. **Check primary authority** — confirm the name is accepted (not a
   synonym) in the primary authority for that taxon group
2. **Resolve synonyms** — if the paper uses an older synonym, record
   both: `scientific_name` = accepted name, `survey_taxon_original` =
   name as it appeared in the paper
3. **Check GBIF Backbone** — confirm a GBIF taxon ID exists and matches
   the accepted name. Use this ID for all GBIF API queries.
4. **Check iNaturalist** — confirm an iNat taxon page exists. Note if
   iNat uses a different spelling or synonym.
5. **Flag conflicts** — if primary authority and GBIF/iNat disagree on
   the accepted name, flag for human review. Do not resolve automatically.

---

## Common Conflict Patterns

These patterns recur frequently in Neotropical herpetology and should
be handled as follows:

**Genus reassignment** (e.g. Liophis → Erythrolamprus)
- Use the accepted name from primary authority
- Note the old genus in `survey_taxon_original`

**Subspecies collapsed to species**
- Use species-level name
- Note the subspecies in dataset notes

**Spelling variants** (e.g. flavolineata vs flavolineatus)
- Use the primary authority spelling
- Note the variant in dataset notes

**Split species** (one species becomes two)
- Use the accepted name for the population confirmed in the target area
- Flag if geographic assignment is ambiguous

---

## GBIF Taxon ID Resolution

When a species name does not directly match a GBIF taxon:

```
GET https://api.gbif.org/v1/species/match
  name={scientific_name}
  strict=false
```

Accept matches with `matchType: EXACT` or `matchType: FUZZY` where
`confidence >= 90`. Lower confidence matches require human review.

---

## iNaturalist Taxon ID Resolution

```
GET https://api.inaturalist.org/v1/taxa
  q={scientific_name}
  rank=species
```

Use the top result if `name` matches exactly. If iNat uses a different
accepted name, note the discrepancy and use the iNat taxon ID regardless
— iNat's internal taxonomy is used for all iNat API queries.

---

## Version Log

| Version | Date       | Changes                          |
|---------|------------|----------------------------------|
| 1.0     | March 2026 | Initial version — Carajás Field Guide pipeline |
