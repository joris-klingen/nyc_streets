"""Turn the round 2 review answers into layers/bike_lanes/manual/round2_answers.csv.

Export first (Claude does this with the ArtifactData tool, action "list", collection "round2",
out_dir layers/bike_lanes/manual/review_export), which writes one JSON file per item to
layers/bike_lanes/manual/review_export/round2/. Each answer row is joined to the item's segments,
so the CSV has one row per item and SegmentID. Reviewer ids are kept (opaque), names are not stored.
  protected_from / protected_last_without   YYYY-MM, "none", or empty (not asked); a window when both are set
  lanes_before / lanes_after / lanes_changed / lanes_last_before   travel lanes; lanes_changed YYYY-MM or "no change"
Usage (from repo root): python evidence/review_round2/02_import_answers.py
"""
import csv, glob, json
from collections import defaultdict

FIELDS = ["item_id", "kind", "street", "SegmentID", "protected_from", "protected_last_without", "before_type",
          "lanes_before", "lanes_after", "lanes_changed", "lanes_last_before", "note", "by", "saved_at"]
segs = defaultdict(list)
for r in csv.DictReader(open("evidence/review_round2/out/item_segments.csv", encoding="utf-8")):
    segs[r["item_id"]].append(r["SegmentID"])
answers = [json.load(open(f, encoding="utf-8")) for f in sorted(glob.glob("layers/bike_lanes/manual/review_export/round2/*.json"))]
rows = [dict(a, SegmentID=s) for a in answers for s in segs.get(a["item_id"], [])]
with open("layers/bike_lanes/manual/round2_answers.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=FIELDS, extrasaction="ignore")
    w.writeheader()
    w.writerows(rows)
print(len(answers), "answers,", len(rows), "segment rows -> layers/bike_lanes/manual/round2_answers.csv")
