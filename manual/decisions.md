# Coding decisions

| Date | Decision | Applies to |
|---|---|---|
| 2026-10-10 | Buffered lanes (Buffered, Conventional/Curbside Buffered) count as class I (protected); Curbside is class II | `lookup_bikelane_types.xlsx` |
| 2026-10-10 | A blank pre-modification type in the manual sheet means the type did not change (sheet rule) | `5_NYC_bikelanes/scripts/data_management/002_import_bikelanes.R` |
| 2026-10-11 | Central Park drives count as protected from the date they became fully car-free, not from the painted bike lane (present throughout) or the earlier auto-limited dates. Manual sheet comments give e.g. "Autos limited 2012-09-15. Fully auto-free 2018-06-27" | park drives in `aerial_labelling/out/review_checklist.csv` (category park_drive_definition); to be applied as manual overrides |
| 2026-10-11 | Aerial labels are evidence, not ground truth: only Street View-confirmed dates enter the manual overrides | `aerial_labelling/` |
| 2026-10-12 | Projects reviewed with a buffered lane before protection: buffered counts as protected, so treatment starts at the buffered lane date (the earlier of the pipeline date and the reviewed physical-protection date) | `manual/04_build_overrides.R` (rule "buffered counts as protected", 4 projects) |
| 2026-10-12 | M010 1 Av: protected from 2012-06 | `manual/protection_overrides.csv` |
| 2026-10-12 | M068 Broadway and M124 Willis Av Bridge approach: always protected (protected before the review period) | `manual/04_build_overrides.R` (`always_protected`) |
| 2026-10-12 | M029 3 Av: first seen protected 2026-04, nothing visible up to 2024-09. Record as a window (after 2024-09, by 2026-04), not a point date; the overrides still carry 2026-04 until date windows are supported | `manual/protection_overrides.csv`; see TODO (3 Av) |
