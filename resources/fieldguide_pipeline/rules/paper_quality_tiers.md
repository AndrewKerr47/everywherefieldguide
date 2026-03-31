# Paper Quality Tiers
## Carajás Field Guide — Reusable Pipeline

---

## Purpose

This document defines how Claude evaluates and selects peer-reviewed papers
for the species list pipeline. It is referenced by SYSTEM_PROMPT.md and
must not be modified without updating the version log at the bottom.

---

## Qualifying Criteria

A paper must meet ALL hard requirements to be considered.

### Hard Requirements
- Published in a peer-reviewed journal, or submitted as a peer-reviewed
  institutional thesis at a recognised university
- Primary data — original field survey. Review papers and meta-analyses
  are excluded unless no primary survey exists for the area
- Geographic scope explicitly overlaps the target area
- Species identifications are verifiable — voucher specimens deposited in
  a recognised collection, or photographic documentation cited with
  observer and location
- Survey methodology is described — methods, date range, and sampling
  effort are stated

### Disqualifying Flags
- No stated methodology
- Species listed without individual records, vouchers, or documentation
- Range map inference presented as confirmed presence
- Citizen science aggregation (e.g. raw iNaturalist export) presented as
  a primary survey without defined protocols
- Published in a known predatory journal (cross-reference Beall's List)
- Authors unaffiliated with any recognised research institution

---

## Publication Quality Tiers

When more than 5 qualifying papers exist, Claude selects using this tier
system. Higher tier always preferred over lower tier. Within the same
tier, prefer: (1) most recent, (2) broadest species/geographic coverage.

### Tier 1 — Top Generalist Journals
Nature, Science, PNAS, Current Biology, Nature Communications,
Nature Ecology & Evolution

### Tier 2 — Top Field / Taxon Journals
Molecular Ecology, Systematic Biology, Journal of Biogeography,
Zootaxa, Herpetologica, Herpetological Monographs,
Journal of Herpetology, Copeia, Amphibia-Reptilia,
The Auk, Ibis, Journal of Ornithology, Condor,
Mammalia, Journal of Mammalogy, Oryx,
Biotropica, Journal of Tropical Ecology

### Tier 3 — Regional / Specialist Journals
South American Journal of Herpetology,
Salamandra, Caldasia, Biota Neotropica,
Check List (Herpetology), Phyllomedusa,
Revista Brasileira de Zoologia,
Papéis Avulsos de Zoologia,
Herpetology Notes, ZooKeys

### Tier 4 — Institutional Theses and Reports
Peer-reviewed doctoral or master's theses from recognised universities.
Official survey reports commissioned by government bodies or protected
area management authorities (e.g. national park herpetofaunal inventories).
Museum monographs with stated methodology and voucher specimens.

### Tier 5 — Structured Citizen Science
iNaturalist projects with defined survey protocols, stated geographic
scope, and research-grade observations only.
Note: iNaturalist is always included as a supplementary source regardless
of tier — this tier applies only when a structured iNat project report
is being evaluated as a primary survey document.

---

## Selection Rules

1. Maximum 5 papers per pipeline run (excluding iNaturalist)
2. Minimum 1 approved paper required to proceed
3. iNaturalist is always included as a supplementary source alongside
   the approved papers — it is never the sole source
4. When reducing a larger candidate set to 5, apply tiers in order.
   Within the same tier: most recent first, then broadest coverage
5. Claude surfaces 2–3 best candidates to the human reviewer with a
   structured assessment. Human approves or rejects each paper.
   Human may substitute a paper Claude did not find.
6. Approved papers are the sole source of truth for the species list.
   Every species entry must cite which approved paper confirmed it.

---

## Structured Assessment Format

For each candidate paper, Claude outputs:

```
Paper: [Full citation]
DOI: [DOI or URL]
Journal: [Journal name]
Tier: [1–5]
Year: [Publication year]
Geographic scope: [How well it covers the target area]
Methodology: [Brief summary of survey methods]
Vouchers/documentation: [Yes / Partial / No]
Sampling effort stated: [Yes / No]
Open access: [Yes / No]
Confidence: [High / Medium / Low]
Recommendation: [Include / Review / Exclude]
Reason: [One sentence justification]
```

---

## Version Log

| Version | Date       | Changes                          |
|---------|------------|----------------------------------|
| 1.0     | March 2026 | Initial version — Carajás Field Guide pipeline |
