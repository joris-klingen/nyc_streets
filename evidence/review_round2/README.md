# Review round 2: protection dates and travel lanes (2026-10)

One Street View review for the open Manhattan questions on bike lane protection dates and on
travel-lane counts. Both use the same evidence (aerial sheets, DOT presentations, Street View time
travel), so one pass per piece of street answers both.

## Items

`01_queue.R` builds the queue from the bike lane windows (DOT 2026 build), the round 1 projects and
answers, and the lane review list of `layers/travel_lanes/02_manhattan_lane_panel.R`:

| Priority | Kind | What is asked |
|---|---|---|
| 1 | A `M###`: round 1 projects with segments on the lane review list, plus M029 (3 Av) | protection date (pre-filled from round 1 or DOT), travel lanes before / after and when they changed |
| 2 | B `L###`: lane review segments outside those projects, 3+ segments | travel lanes before / after and when; protection where a bike lane is involved |
| 3 | C `D###`: on-street segments whose protection date differs from the DOT 2026 history by more than a year | protection date and what was there before |
| 4 | B `L###` with 1–2 segments | as priority 2 |

Lane review segments are those LION cannot date: fewer or more lanes in 2024 than in 2016 without a
bike lane change that explains it, or a protected lane installed before LION's first lane count
(2016). The Central Park drives are not reviewed: their lane drop is dated at the car-free date
(2015-06 north of 72nd St, 2018-06 the rest) in `02_manhattan_lane_panel.R`. Governors Island
roads and off-street paths are left out.

Dates can be recorded as a window (first seen / last seen without), because panoramas are often
years apart.

## Steps

1. `Rscript evidence/review_round2/01_queue.R` -> `out/items.csv`, `out/item_segments.csv`,
   `out/points.csv`, `out/segment_lines.csv`
2. Aerial sheets: `python evidence/aerial_labelling/05_review_sheets.py <points> out/segment_lines.csv out/sheets <ids>`,
   with round 1's `aerial_labelling/out/projects.csv` as points for the `M###` items (their tiles are
   cached by id) and `out/points.csv` for the others (cached by location)
3. DOT evidence: `evidence/dot_projects/02_match_review.py out/items.csv out/dot_matches.csv`, then
   `03_fetch_extract.py out/dot_matches.csv out/dot_timing.csv` (timing and lane statements) and
   `04_review_evidence.py out/dot_matches.csv out/dot_timing.csv out/dot_evidence.json`
4. `python evidence/review_round2/app/build.py` -> `app/index.html`, `app/sheets2/`, published to the
   round 1 review page (same link), answers in collection `round2`
5. After the review: export the collection with the ArtifactData tool to
   `layers/bike_lanes/manual/review_export/round2/`, then `python evidence/review_round2/02_import_answers.py`
   -> `layers/bike_lanes/manual/round2_answers.csv` (one row per item and segment)

The answers are then applied in `layers/bike_lanes/manual/04_build_overrides.R` (protection dates) and
`layers/travel_lanes/02_manhattan_lane_panel.R` (lane counts and dates); that step is still to be written.
