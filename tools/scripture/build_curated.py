"""Extract the curated verses from the source files into app assets.

Usage: python3 tools/scripture/build_curated.py [--cache DIR]

Reads curated_refs.json, the cached source files (see fetch_sources.py), the
scripted corrections and notices.json. Writes app/assets/verses/curated.json,
app/assets/verses/{lang}.json and app/assets/licenses/{lang}.json. Exits
non-zero if any curated verse is missing in any language. Never hand-edit the
outputs: change the inputs and run this again.
"""
import argparse
import json
import pathlib
import sys

import align
import parse

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
MOMENTS = {"preBout", "corner", "tenCount", "win", "loss", "daily", "card"}


def dump(path, obj):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")


def load_corrections():
    data = json.loads((HERE / "corrections.json").read_text(encoding="utf-8"))
    out = {}
    for c in data["corrections"]:
        out[(c["language"], parse.parse_ref(c["ref"]))] = c
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cache", default=str(HERE / "cache"))
    args = ap.parse_args()
    cache = pathlib.Path(args.cache)
    cfg = json.loads((HERE / "sources.json").read_text(encoding="utf-8"))
    curated = json.loads((HERE / "curated_refs.json").read_text(encoding="utf-8"))["verses"]
    notices = json.loads((HERE / "notices.json").read_text(encoding="utf-8"))
    corrections = load_corrections()
    vref = parse.parse_vref((cache / "vref.txt").read_text(encoding="utf-8"))

    seen_ids = set()
    items = []
    for v in curated:
        if v["id"] in seen_ids:
            sys.exit(f"duplicate curated id {v['id']}")
        seen_ids.add(v["id"])
        bad = set(v["moments"]) - MOMENTS
        if bad or not v["moments"]:
            sys.exit(f"bad moments for {v['id']}: {v['moments']}")
        b, c, vs = parse.parse_ref(v["ref"])
        items.append((v, (b, c, vs)))

    dump(
        ROOT / "app/assets/verses/curated.json",
        {"verses": [{"id": v["id"], "ref": {"book": b, "chapter": c, "verse": vs}, "moments": v["moments"]} for v, (b, c, vs) in items]},
    )

    problems = 0
    applied = 0
    english = None
    maps = {}
    for lang, src in cfg["languages"].items():
        verses = parse.load_language(src, cache, vref)
        if lang == "en":
            english = verses
        shifts = align.chapter_shifts(verses, english)
        used = {}
        out = {}
        for v, ref in items:
            local = align.local_ref(ref, shifts)
            if local != ref:
                used[f"{ref[0]}.{ref[1]}"] = local[2] - ref[2]
            t = verses.get(local)
            if t is None:
                print(f"MISSING {lang} {v['ref']} ({v['id']})", file=sys.stderr)
                problems += 1
                continue
            corr = corrections.get((lang, ref))  # keyed by the English reference
            if corr is not None:
                if corr["from"] != t:
                    sys.exit(f"correction for {lang} {v['ref']} does not match the source text")
                t = corr["to"]
                applied += 1
            out[parse.key(*ref)] = t
        maps[lang] = used
        dump(
            ROOT / f"app/assets/verses/{lang}.json",
            {"language": lang, "translationId": src["translation_id"], "licenseId": src["license_id"], "verses": out},
        )
        n = notices["notices"][lang]
        dump(
            ROOT / f"app/assets/licenses/{lang}.json",
            {"id": n["id"], "sourceName": n["sourceName"], "license": n["license"], "attribution": n["attribution"], "link": n.get("link", notices["link"])},
        )
    dump(HERE / "alignment.json", {"note": "Per language: chapters (book.chapter) whose verses sit later than in English, and by how many. Computed by align.py.", "shifts": maps})
    print(f"{len(items)} curated verses, {len(cfg['languages'])} languages, {applied} corrections applied")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
