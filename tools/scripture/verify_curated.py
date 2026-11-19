"""The data gate: every bundled verse must equal its source, byte for byte.

Usage: python3 tools/scripture/verify_curated.py [--cache DIR]

Reads the bundled assets and, independently of build_curated.py, looks each
verse up by line number in the raw source file and compares the bytes. Also
checks structure: every curated verse exists in every language, ids are
unique, notices exist, and every moment has enough verses.
"""
import argparse
import json
import pathlib
import sys

import align
import canon
import parse

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
ASSETS = ROOT / "app/assets"
MIN_PER_MOMENT = {"preBout": 26, "corner": 8, "tenCount": 6, "win": 8, "loss": 8, "daily": 50, "card": 30}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cache", default=str(HERE / "cache"))
    args = ap.parse_args()
    cache = pathlib.Path(args.cache)
    cfg = json.loads((HERE / "sources.json").read_text(encoding="utf-8"))
    corrections = json.loads((HERE / "corrections.json").read_text(encoding="utf-8"))["corrections"]
    corr = {(c["language"], c["ref"]): c for c in corrections}
    errors = []

    vref_lines = (cache / "vref.txt").read_text(encoding="utf-8").splitlines()
    line_of = {}
    for i, raw in enumerate(vref_lines):
        code, cv = raw.split()
        if code in canon.BY_CODE:
            ch, vs = cv.split(":")
            line_of[(canon.BY_CODE[code][0], int(ch), int(vs))] = i

    curated = json.loads((ASSETS / "verses/curated.json").read_text(encoding="utf-8"))["verses"]
    refs_cfg = json.loads((HERE / "curated_refs.json").read_text(encoding="utf-8"))
    ok_v1 = {parse.parse_ref(r) for r in refs_cfg.get("psalm_verse1_ok", [])}
    for v in curated:
        r = (v["ref"]["book"], v["ref"]["chapter"], v["ref"]["verse"])
        if r[0] == 19 and r[2] == 1 and r not in ok_v1:
            errors.append(f"{v['id']}: verse 1 of a Psalm may carry a heading in some translations")
    vref_all = parse.parse_vref((cache / "vref.txt").read_text(encoding="utf-8"))
    english = None
    ids = [v["id"] for v in curated]
    if len(ids) != len(set(ids)):
        errors.append("duplicate curated ids")
    counts = {m: 0 for m in MIN_PER_MOMENT}
    for v in curated:
        for m in v["moments"]:
            if m not in counts:
                errors.append(f"unknown moment {m} on {v['id']}")
            else:
                counts[m] += 1
    for m, need in MIN_PER_MOMENT.items():
        if counts[m] < need:
            errors.append(f"moment {m} has {counts[m]} verses, needs at least {need}")

    checked = 0
    for lang, src in cfg["languages"].items():
        bundle = json.loads((ASSETS / f"verses/{lang}.json").read_text(encoding="utf-8"))
        if bundle["translationId"] != src["translation_id"] or bundle["licenseId"] != src["license_id"]:
            errors.append(f"{lang}: bundle ids differ from sources.json")
        notice = json.loads((ASSETS / f"licenses/{lang}.json").read_text(encoding="utf-8"))
        if notice["id"] != src["license_id"] or not notice["sourceName"] or not notice["license"]:
            errors.append(f"{lang}: licence notice missing or wrong")
        if "Creative Commons" in notice["license"] and not notice["attribution"]:
            errors.append(f"{lang}: licence needs an attribution line")
        parsed = parse.parse_corpus((cache / pathlib.Path(src["path"]).name).read_text(encoding="utf-8"), vref_all)
        if lang == "en":
            english = parsed
        shifts = align.chapter_shifts(parsed, english)
        raw_lines = (cache / pathlib.Path(src["path"]).name).read_bytes().decode("utf-8").split("\n")
        for v in curated:
            ref = (v["ref"]["book"], v["ref"]["chapter"], v["ref"]["verse"])
            k = parse.key(*ref)
            text = bundle["verses"].get(k)
            if text is None:
                errors.append(f"{lang}: {v['id']} ({k}) missing from bundle")
                continue
            try:
                local = align.local_ref(ref, shifts)
            except ValueError as e:
                errors.append(f"{lang}: {v['id']}: {e}")
                continue
            source_line = raw_lines[line_of[local]].rstrip("\r")
            expected = source_line
            code = canon.BOOKS[ref[0] - 1][1]
            c = corr.get((lang, f"{code} {ref[1]}:{ref[2]}"))
            if c is not None:
                if c["from"] != source_line:
                    errors.append(f"{lang}: correction for {k} no longer matches the source")
                expected = c["to"]
            if text != expected or not text.strip() or text.strip() == "<range>":
                errors.append(f"{lang}: {v['id']} ({k}) differs from source")
            checked += 1
        extra = set(bundle["verses"]) - {parse.key(v["ref"]["book"], v["ref"]["chapter"], v["ref"]["verse"]) for v in curated}
        if extra:
            errors.append(f"{lang}: bundle has verses that are not curated: {sorted(extra)[:3]}")
    for e in errors:
        print("ERROR", e, file=sys.stderr)
    print(f"checked {checked} verse texts across {len(cfg['languages'])} languages; {len(errors)} problem(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
