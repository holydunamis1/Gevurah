"""Download each source file at the pinned commit and check its sha256.

Usage:
  python3 tools/scripture/fetch_sources.py [--out DIR] [--local DIR_WITH_REPO_CLONES]

Files land in DIR (default tools/scripture/cache, ignored by git). With --local,
files are copied from a local clone of the repository at the pinned commit
instead of downloaded (DIR_WITH_REPO_CLONES holds one folder per repository name, e.g. ebible/). Exits non-zero if any checksum differs.
"""
import argparse
import hashlib
import json
import pathlib
import shutil
import sys
import urllib.request

HERE = pathlib.Path(__file__).resolve().parent


def sha256_of(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(HERE / "cache"))
    ap.add_argument("--local", default=None)
    args = ap.parse_args()
    cfg = json.loads((HERE / "sources.json").read_text(encoding="utf-8"))
    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    wanted = [(cfg["vref"]["path"], cfg["vref"]["sha256"], cfg["raw_base"], cfg["commit"], cfg["repo"])]
    for v in cfg["languages"].values():
        wanted.append((v["path"], v["sha256"], v.get("raw_base", cfg["raw_base"]), v.get("commit", cfg["commit"]), v.get("repo", cfg["repo"])))
    bad = 0
    for rel, expected, raw_base, commit, repo in wanted:
        dest = out / pathlib.Path(rel).name
        if not (dest.exists() and sha256_of(dest) == expected):
            if args.local:
                shutil.copy(pathlib.Path(args.local) / repo.split("/")[-1] / rel, dest)
            else:
                url = f"{raw_base}/{commit}/{rel}"
                with urllib.request.urlopen(url, timeout=120) as r, open(dest, "wb") as f:
                    shutil.copyfileobj(r, f)
        actual = sha256_of(dest)
        status = "ok" if actual == expected else "MISMATCH"
        if actual != expected:
            bad += 1
        print(f"{status}  {dest.name}  {actual}")
    if bad:
        print(f"{bad} file(s) differ from the recorded checksum", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
