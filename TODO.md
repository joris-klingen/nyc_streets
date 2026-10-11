# TODO

*Last updated 2026-10-12. Roughly in order of payoff for the bike lane paper (`5_NYC_bikelanes`, plan in `notes/paper_plan_v2.md`).*

## Protection dates

- [ ] **Re-run the paper pipeline with the overrides.** `manual/protection_overrides.csv` (37 projects, 294 segments) is already applied in `5_NYC_bikelanes/scripts/data_management/002_import_bikelanes.R`. `101 → 303` and the main models have not been re-run yet; the `101` fix is pushed.
- [ ] **Remaining disagreements outside the review.** After the upgrade-bug fix, 69 study-period segments still differ from the DOT 2026 history by more than a year, and 133 are protected in only one source. The 37 reviewed projects cover part of this; list what is left (`checks/02_pipeline_vs_dot_history.R` on the new windows) and decide whether a second review round is needed.
- [ ] **27 segments moved earlier with the bug fix** (2016 → 1978), where the manual sheet codes the pre-upgrade type as protected. Check them against Street View or the aerial sheets.
- [ ] **117 segments with overlapping time windows** in `bike_lanes_time_windows.RDS`, probably from appending the 2025 updates with both retired and current records. Find and fix the cause in `002`.
- [ ] **Build segment × facility spells from the DOT 2026 version history** (`bikeid`, `prevbikeid`, `instdate`, `ret_date`) as the base, with the manual sheet and review answers as overrides. This replaces the 2020 shapefile plus 2025 updates in `002`.
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

## Documentation

- [ ] **`aerial_labelling/README.md`:** the review-page section still lists a `confidence` field, which was removed. The "before acting on any conflict" steps are done; replace them with a short record of the outcome.
- [ ] **Main `README.md`:** add `lanes/`, `dot_projects/`, `manual/` (overrides, park dates, decisions) and the review page to the contents list. Replace the roadmap pointer with a link to this file.
- [ ] **`manual/decisions.md`:** add the buffered-before rule for the overrides (treatment starts at the buffered lane date) and the confirmations of 2026-10-12 (M010 2012-06; M068 and M124 always protected; M029 window).
