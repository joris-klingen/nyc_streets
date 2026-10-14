"""Build the round 2 review page: embed the items and DOT evidence in template.html and copy the sheets.

Writes review_round2/app/index.html and review_round2/app/sheets2/*.jpg (published as the artifact's
files next to round 1's sheets/). Answers go to the artifact database, collection round2.
Usage (from repo root): python evidence/review_round2/app/build.py
"""
import csv, json, os, shutil
from PIL import Image

APP = "evidence/review_round2/app"
OUT = "evidence/review_round2/out"
KEEP = ["item_id", "kind", "priority", "street", "n_segments", "lion_counts", "lane_q", "prot_pipe", "prot_dot",
        "r1_protected_from", "r1_before_type", "streetview_1", "streetview_2", "streetview_3",
        "bike_events", "dot_events", "lion_before", "lion_after", "pre_project", "ask_lanes"]

rows = [{k: (r.get(k) or "") for k in KEEP} for r in csv.DictReader(open(os.path.join(OUT, "items.csv"), encoding="utf-8"))]
rows = [r for r in rows if os.path.exists(os.path.join(OUT, "sheets", r["item_id"] + ".jpg"))]
# proposed timelines come as JSON strings; flags as booleans
for r in rows:
    for k in ("bike_events", "dot_events"):
        r[k] = json.loads(r[k] or "[]")
    for k in ("pre_project", "ask_lanes"):
        r[k] = r[k] == "TRUE"
data = json.dumps(rows, ensure_ascii=False).replace("</", "<\\/")
ev_path = os.path.join(OUT, "dot_evidence.json")
evidence = json.load(open(ev_path, encoding="utf-8")) if os.path.exists(ev_path) else {}
evidence = {k: v for k, v in evidence.items() if k in {r["item_id"] for r in rows}}
ev_data = json.dumps(evidence, ensure_ascii=False).replace("</", "<\\/")
html = (open(os.path.join(APP, "template.html"), encoding="utf-8").read()
        .replace("/*DATA*/", data).replace("/*EVIDENCE*/", ev_data))
open(os.path.join(APP, "index.html"), "w", encoding="utf-8").write(html)

# sheets, recompressed to keep the publish within the size limits
dst = os.path.join(APP, "sheets2")
os.makedirs(dst, exist_ok=True)
for r in rows:
    im = Image.open(os.path.join(OUT, "sheets", r["item_id"] + ".jpg"))
    im.save(os.path.join(dst, r["item_id"] + ".jpg"), quality=72, optimize=True)
size = sum(os.path.getsize(os.path.join(dst, f)) for f in os.listdir(dst))
print(len(rows), "items;", len(evidence), "with DOT evidence;", round(size / 1e6, 1), "MB of sheets;", round(len(html) / 1e3), "kB page")
