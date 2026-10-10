# nyc_bikelane_history

Curated history of NYC bike lane facilities: when each street segment got which type of lane
(protected / conventional / shared), with the evidence for each date. Used by `5_NYC_bikelanes`
(treatment timing) and the gender & cycling work.

DOT's own install dates are often imprecise (1 January or the 1st of the month), are revised
between releases, and before 2025 did not record what a segment was *before* an upgrade. This
repo combines the DOT releases with manual Street View checks.

## Contents

```
manual/
  streetview_dot2020.csv       manual Street View checks on the DOT 2020 release (2,609 segments, all boroughs);
                               before-upgrade type in tf_bef_mod / ft_bef_mod (class code I/II/III), blank = unchanged
  streetview_initial_2019.csv  first pass on the 2019 release (superseded by dot2020)
  rules.csv                    coding rules used during the checks
  lookup_bikelane_types.xlsx   facility text -> class (I protected, II conventional, III shared)
  exported_at.txt              time of the last export from the Google Sheet
scripts/
  01_export_manual_sheet.R     export the Google Sheet "Manual Streetview NYC Bikelanes" to manual/
checks/                        quality checks from 2026-10 (see 5_NYC_bikelanes/notes/bikelane_dates_plan.md)
```

The Google Sheet is the entry form; the CSVs in `manual/` are the source of truth for analysis.
After editing the sheet, re-export and commit so git records every change:

```bash
Rscript scripts/01_export_manual_sheet.R
```

Raw DOT releases live in the shared data store: `Dropbox/1_research/data_NYC/streets/bike_routes/`
(see the `nyc_data` repo).

## Classification

Class I (protected) includes buffered lanes (confirmed 2026-10-10); curbside lanes are class II.
Note: `rules.csv` from the original checks codes buffered as II; the lookup table, which the
pipeline uses, codes it as I.

## Roadmap

See `5_NYC_bikelanes/notes/bikelane_dates_plan.md`, section 3:
build segment x facility spells from the DOT 2026 version history (`bikeid`, `prevbikeid`, `instdate`,
`ret_date`), apply the manual checks as overrides, record date precision, and check new projects
(2019 onward) at project level with pre-computed before/after Street View panoramas.
