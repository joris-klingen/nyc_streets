# TODO

*Last updated 2026-10-12. Roughly in order of payoff for the bike lane paper (`5_NYC_bikelanes`, plan in `notes/paper_plan_v2.md`).*

## Protection dates

- [x] **Re-run the paper pipeline with the overrides** (2026-10-13). `101 → 303` re-run; old vs new treatment and TWFE in `5_NYC_bikelanes/scripts/checks/303_compare_treatment_overrides.R` (output in `output/checks/`). 80 of 120 zone-directions change in at least one month; estimates move little.
- [ ] **Remaining disagreements outside the review.** After the upgrade-bug fix, 69 study-period segments still differ from the DOT 2026 history by more than a year, and 133 are protected in only one source. The 37 reviewed projects cover part of this; list what is left (`checks/02_pipeline_vs_dot_history.R` on the new windows) and decide whether a second review round is needed.
- [ ] **27 segments moved earlier with the bug fix** (2016 → 1978), where the manual sheet codes the pre-upgrade type as protected. Check them against Street View or the aerial sheets.
- [ ] **117 segments with overlapping time windows** in `bike_lanes_time_windows.RDS`, probably from appending the 2025 updates with both retired and current records. Find and fix the cause in `scripts/03_time_windows.R` (moved here from `5_NYC_bikelanes` 002 on 2026-10-13).
- [ ] **Build segment × facility spells from the DOT 2026 version history** (`bikeid`, `prevbikeid`, `instdate`, `ret_date`) as the base, with the manual sheet and review answers as overrides. This replaces the 2020 shapefile plus 2025 updates in `scripts/03_time_windows.R`.
- [ ] **LION 16d crosswalk duplicates** (`manual/segmentid_crosswalk_lion16d.csv`, moved from `5_NYC_bikelanes` 101): 37669 gets windows from three DOT segments, 37630 and 37533 from two, and 36563 already has windows of its own, so these four get overlapping windows. Keep one source per target.
- [ ] **Date precision flag** per segment: exact day / month only (1st of month) / year only (1 January) / verified (Street View or aerial). Needed for the robustness check that drops or shifts imprecise dates.
- [ ] **3 Av (M029):** reviewed as first seen 2026-04, with nothing visible up to 2024-09. Record the window (after 2024-09, by 2026-04) rather than a point date.

## Travel-lane panel (`lanes/`)

- [ ] **Apply the park-drive car-free dates to the lane panel.** West/East Drive go from 2 to 1 lane; date these at 2015-06 (north of 72nd St) and 2018-06 (rest), as in `manual/park_drive_dates.csv`.
- [ ] **Resolve the lane review list** (`lanes/out/lane_review.csv`: 869 segments on 89 streets; largest 1 Av, 2 Av, Columbus Av, 9 Av, Amsterdam Av).
  1. Use the DOT deck statements ("remove one travel lane …", `dot_projects/presentation_timing.csv` and the full PDFs) to confirm lane removals and their dates.
  2. Add a lane-count question to the review page for what remains; aerial photos show the lane markings.
- [ ] **447 segments with a protected lane from 2012-07 to 2016-02.** LION's first lane count (2016) may already be post-project; take the pre-project count from DOT decks ("Before: four moving lanes") or the aerial photos.
- [ ] **Aggregate the monthly lane panel to zone-directions** for the paper's mechanism analysis (lanes removed vs kept).

## DOT records (`dot_projects/`)

- [ ] **3 presentation PDFs return 404** (L Train CB6 decks 2018, Kent Ave). Look for them in the Wayback Machine.
- [ ] **Reduce noise in the matching:** crosstown projects that only touch an avenue are matched to it. Match on cross-street ranges as well as the street name.
- [ ] **Extend beyond the 37 review projects** if a second review round happens.

## Aerial imagery

- [ ] **Capture dates for other boroughs** (NYC OTI metadata lists per-borough dates for 2004–2014) if the work goes citywide.
- [ ] **Classifier** (parked 2026-10-11): PyTorch CPU is installed in `C:/code/nyc_aerial_venv`. Worth building only for citywide coverage. Design notes are in `aerial_labelling/README.md` and `pilot_aerial/README.md`: an obscured class; flight dates; labels by facility type; the 124 labelled projects plus the pilot as test set.
- [ ] **Unpainted parking-protected lanes are a blind spot** of the aerial reading (Columbus Av, M087). A classifier needs labelled examples of them.
