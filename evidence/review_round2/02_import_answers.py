"""Turn the round 2 review answers into layers/bike_lanes/manual/round2_answers.csv.

Export first (Claude does this with the ArtifactData tool, action "list", collection "round2",
out_dir layers/bike_lanes/manual/review_export), which writes one JSON file per item to
layers/bike_lanes/manual/review_export/round2/. Each answer is joined to the item's segments, so
the CSV has one row per item and SegmentID. Reviewer ids are kept (opaque), names are not stored.
An answer holds:
  verdict          confirmed (the proposed timeline), confirmed_ours / confirmed_dot (date conflicts),
                   corrected (worked out from the reviewer's panorama log)
  bike_changes     facility changes: from, to, date, precision (verified = a DOT or pipeline day
                   that the reviewer's panoramas bracket, or a confirmed exact day; window = the
                   first panorama showing the change, between last_without and first_with)
  lane_changes     travel lanes before -> after, date, precision, last_before / first_after
  bus_changes      bus lane added / removed, as a window between two observations (date: first showing it)
  lanes_before_project   lanes before a protected lane installed before LION's first count
Travel lanes count moving lanes for cars only; bus lanes are ticked separately.
The CSV keeps the first change to Protected and the first lane change; observations stay in the JSON.
Usage (from repo root): python evidence/review_round2/02_import_answers.py
"""
import csv, glob, json
from collections import defaultdict

FIELDS = ["item_id", "kind", "street", "SegmentID", "verdict",
          "protected_date", "protected_precision", "protected_last_without", "protected_first_with", "before_type",
          "lanes_before", "lanes_after", "lanes_date", "lanes_precision", "lanes_last_before", "lanes_first_after",
          "bus_change", "bus_date", "bus_last_without", "bus_first_with",
          "lanes_before_project", "n_bike_changes", "n_lane_changes", "note", "by", "saved_at"]
segs = defaultdict(list)
for r in csv.DictReader(open("evidence/review_round2/out/item_segments.csv", encoding="utf-8")):
    segs[r["item_id"]].append(r["SegmentID"])

rows = []
for f in sorted(glob.glob("layers/bike_lanes/manual/review_export/round2/*.json")):
    a = json.load(open(f, encoding="utf-8"))
    bike = a.get("bike_changes") or []
    lanes = a.get("lane_changes") or []
    prot = next((c for c in bike if c.get("to") == "Protected"), {})
    lane = lanes[0] if lanes else {}
    bus = (a.get("bus_changes") or [{}])[0]
    row = {k: a.get(k, "") for k in ("item_id", "kind", "street", "verdict", "lanes_before_project", "note", "by", "saved_at")}
    row.update(protected_date=prot.get("date", ""), protected_precision=prot.get("precision", ""),
               protected_last_without=prot.get("last_without", ""), protected_first_with=prot.get("first_with", ""),
               before_type=prot.get("from", ""),
               lanes_before=lane.get("before", ""), lanes_after=lane.get("after", ""), lanes_date=lane.get("date", ""),
               lanes_precision=lane.get("precision", ""), lanes_last_before=lane.get("last_before", ""),
               lanes_first_after=lane.get("first_after", ""), n_bike_changes=len(bike), n_lane_changes=len(lanes),
               bus_change=("added" if bus.get("to") == "bus lane" else "removed") if bus else "", bus_date=bus.get("date", ""),
               bus_last_without=bus.get("last_without", ""), bus_first_with=bus.get("first_with", ""))
    rows += [dict(row, SegmentID=s) for s in segs.get(a["item_id"], [])]

with open("layers/bike_lanes/manual/round2_answers.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=FIELDS, extrasaction="ignore")
    w.writeheader()
    w.writerows(rows)
print(len({r["item_id"] for r in rows}), "answers,", len(rows), "segment rows -> layers/bike_lanes/manual/round2_answers.csv")
