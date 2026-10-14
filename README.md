# nyc_streets

Curated history of the NYC street network 2012 to now: what each street segment looked like at each
date (bike lanes, travel lanes, and later bus lanes, parking, traffic rules, Citi Bike stations, ...),
with the evidence for each date. Used by `5_NYC_bikelanes` (treatment timing) and the gender &
cycling work. Was `nyc_bikelane_history` until 2026-10-14.

Raw data (LION releases, DOT bike routes, snapshots of the current-state layout sets) is downloaded
and read by `nyc_traffic`; this repo adds what needs judgment: dating rules, manual review, and
evidence. Published layout data is often current state only, and its dates are imprecise: DOT's
bike lane install dates are often 1 January or the 1st of the month, are revised between releases,
and before 2025 did not record what a segment was *before* an upgrade. LION's lane counts were
recounted in 2024.

## Layout

```
spine/                           LION SegmentID across the quarterly releases -> stable segment key (planned)
layers/                          one folder per street attribute
  bike_lanes/
    manual/
      streetview_dot2020.csv       manual Street View checks on the DOT 2020 release (2,609 segments, all boroughs);
                                   before-upgrade type in tf_bef_mod / ft_bef_mod (class code I/II/III), blank = unchanged
      streetview_initial_2019.csv  first pass on the 2019 release (superseded by dot2020)
      rules.csv                    coding rules used during the checks
      lookup_bikelane_types.xlsx   facility text -> class (I protected, II conventional, III shared)
      exported_at.txt              time of the last export from the Google Sheet
      decisions.md                 dated coding decisions (buffered = protected, park drives, ...)
      streetview_review_answers.csv  answers from the review page (37 projects, 2026-10)
      review_export/               raw JSON export of the review page answers
      03_park_drive_dates.R        -> park_drive_dates.csv: Central Park drives car-free dates (2015-06 north of 72nd St, 2018-06 rest)
      04_build_overrides.R         -> protection_overrides.csv: segment-level protection dates from the review
                                   and park-drive dates (294 segments); applied in scripts/03_time_windows.R
      segmentid_crosswalk_lion16d.csv  DOT segments whose windows are copied to LION 16d SegmentIDs (18)
      aerial_capture_dates_manhattan.csv  flight dates of the Manhattan orthophotos
    scripts/
      01_export_manual_sheet.R     export the Google Sheet "Manual Streetview NYC Bikelanes" to manual/
      02_import_review_answers.py  review page export -> manual/streetview_review_answers.csv
      03_time_windows.R            build the segment x time-window facilities (Protected / Standard / Sharrows)
                                   -> nyc_traffic_data/derived/streets/bike_lanes/bike_lanes_time_windows.RDS
    checks/                        quality checks from 2026-10 (DOT releases, pipeline vs DOT history, upgrade bug)
  travel_lanes/                  travel-lane panel from 57 quarterly LION releases (citywide, Manhattan monthly);
                                 see its README
evidence/                        material used to date changes, shared by the layers
  pilot_aerial/                  blind test of dating lanes from orthophotos (30 segments); see its README
  aerial_labelling/              aerial labels for 124 Manhattan protected-lane projects, review list and the
                                 review page (review_app/); see its README
  dot_projects/                  DOT presentation catalogue, matched to the review projects, with timing
                                 sentences from the PDFs; see its README
```

All scripts run from the repo root. Outputs that other projects read go to
`nyc_traffic_data/derived/streets/<layer>/`; working files stay in the repo (`out/`).

### Review page

Street View date checks are entered on a private review page:
https://claude.ai/artifact/LNgqgjc1jKrH4Yf35vjX9i (share as Contributor so reviewers can save answers).
It shows per project the claimed dates, the aerial sheets, the matched DOT presentations and Street View links.
It is built by `evidence/aerial_labelling/review_app/build.py`, and the answers flow into `layers/bike_lanes/manual/` via
`layers/bike_lanes/scripts/02_import_review_answers.py` and `layers/bike_lanes/manual/04_build_overrides.R`.

The Google Sheet is the entry form; the CSVs in `layers/bike_lanes/manual/` are the source of truth for analysis.
After editing the sheet, re-export and commit so git records every change:

```bash
Rscript layers/bike_lanes/scripts/01_export_manual_sheet.R
```

The output is read in other projects (e.g. `5_NYC_bikelanes`) with `bikelane_windows_read()` from
`nyc_traffic`. All bike lane classification and dating happens in this repo:

```bash
Rscript layers/bike_lanes/scripts/03_time_windows.R
```

Raw DOT releases live in the shared data store: `Dropbox/1_research/nyc_traffic_data/streets/bike_routes/`
(see the `nyc_traffic` repo).

## Classification

Class I (protected) includes buffered lanes (confirmed 2026-10-10); curbside lanes are class II.
Note: `rules.csv` from the original checks codes buffered as II; the lookup table, which the
pipeline uses, codes it as I.

## Roadmap

Open work is listed in [TODO.md](TODO.md).
