# Coding decisions

| Date | Decision | Applies to |
|---|---|---|
| 2026-10-10 | Buffered lanes (Buffered, Conventional/Curbside Buffered) count as class I (protected); Curbside is class II | `lookup_bikelane_types.xlsx` |
| 2026-10-10 | A blank pre-modification type in the manual sheet means the type did not change (sheet rule) | `5_NYC_bikelanes/scripts/data_management/002_import_bikelanes.R` |
| 2026-10-11 | Central Park drives count as protected from the date they became fully car-free, not from the painted bike lane (present throughout) or the earlier auto-limited dates. Manual sheet comments give e.g. "Autos limited 2012-09-15. Fully auto-free 2018-06-27" | park drives in `aerial_labelling/out/review_checklist.csv` (category park_drive_definition); to be applied as manual overrides |
| 2026-10-11 | Aerial labels are evidence, not ground truth: only Street View-confirmed dates enter the manual overrides | `aerial_labelling/` |
