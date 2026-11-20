"""Record, per language, which canonical verses have no text of their own.

Usage: python3 tools/scripture/verse_maps.py [--cache DIR]

The eBible corpus is aligned to one versification, so numbering is shared and
the only differences are verses a translation leaves empty or merges into a
neighbour. This writes tools/scripture/verse_maps.json so the later reader can
tell the player when a verse has no text in their language.
"""
import argparse
import json
import pathlib
import sys

import canon
import parse

HERE = pathlib.Path(__file__).resolve().parent


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cache", default=str(HERE / "cache"))
    args = ap.parse_args()
    cache = pathlib.Path(args.cache)
    cfg = json.loads((HERE / "sources.json").read_text(encoding="utf-8"))
    vref = parse.parse_vref((cache / "vref.txt").read_text(encoding="utf-8"))
    out = {"note": "Canonical verses with no text of their own, per language. Numbering is otherwise shared.", "languages": {}}
    english = None
    for lang, src in cfg["languages"].items():
        verses = parse.load_language(src, cache, vref)
        if lang == "en":
            english = verses
        missing = []
        if src.get("format") == "scrollmapper-json":
            # Numbered like English: list English verses this translation has no text for.
            missing = [parse.key(*k) for k in sorted(english) if k not in verses]
        else:
            for book, code, chapter, verse in vref:
                if book is not None and (book, chapter, verse) not in verses:
                    missing.append(parse.key(book, chapter, verse))
        out["languages"][lang] = {"present": len(verses), "missing": missing}
        print(f"{lang}: {len(verses)} verses with text, {len(missing)} empty")
    (HERE / "verse_maps.json").write_text(json.dumps(out, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
