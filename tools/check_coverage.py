#!/usr/bin/env python3
"""Coverage gate (blueprint section 9): core at least 90, providers at least 80,
overall at least 75 percent of lines.

Reads app/coverage/lcov.info. Files under app/lib that no test imports are not in
the report, so each counts as fully uncovered using its non-blank, non-comment
lines. Generated localization files are left out. With --report it only prints.
"""
import re
import sys
from pathlib import Path

GATES = {"core": ("lib/core/", 90.0), "providers": ("lib/providers/", 80.0), "overall": ("lib/", 75.0)}
SKIP = re.compile(r"lib/l10n/app_localizations")


def parse(lcov: str):
    files, cur = {}, None
    for line in lcov.splitlines():
        if line.startswith("SF:"):
            cur = line[3:].replace("\\", "/")
            files[cur] = [0, 0]
        elif line.startswith("LF:") and cur:
            files[cur][0] = int(line[3:])
        elif line.startswith("LH:") and cur:
            files[cur][1] = int(line[3:])
    return files


def code_lines(path: Path) -> int:
    n = 0
    for raw in path.read_text(encoding="utf-8").splitlines():
        s = raw.strip()
        if s and not s.startswith(("//", "///", "import ", "export ", "part ")) and s not in ("{", "}", ");", "],", "]", ")"):
            n += 1
    return n


def measure(app: Path):
    report = parse((app / "coverage" / "lcov.info").read_text(encoding="utf-8"))
    by_rel = {}
    for sf, (lf, lh) in report.items():
        rel = sf if sf.startswith("lib/") else sf.split("/app/", 1)[-1]
        by_rel[rel] = (lf, lh)
    for f in (app / "lib").rglob("*.dart"):
        rel = f.relative_to(app).as_posix()
        if rel not in by_rel and not SKIP.search(rel):
            by_rel[rel] = (code_lines(f), 0)
    out = {}
    for name, (prefix, _) in GATES.items():
        lf = sum(v[0] for k, v in by_rel.items() if k.startswith(prefix) and not SKIP.search(k))
        lh = sum(v[1] for k, v in by_rel.items() if k.startswith(prefix) and not SKIP.search(k))
        out[name] = (100.0 * lh / lf if lf else 100.0, lf, lh)
    return out, by_rel


def main(argv):
    root = Path(argv[1]) if len(argv) > 1 and not argv[1].startswith("--") else Path(".")
    report_only = "--report" in argv
    result, by_rel = measure(root / "app")
    failed = False
    for name, (pct, lf, lh) in result.items():
        need = GATES[name][1]
        ok = pct >= need
        print(f"{name:10s} {pct:5.1f}%  ({lh}/{lf} lines)  need {need:.0f}%  {'ok' if ok else 'BELOW'}")
        failed = failed or not ok
    if failed:
        worst = sorted(((v[1] / v[0] if v[0] else 1.0, k) for k, v in by_rel.items() if v[0] >= 20 and k.startswith(("lib/core/", "lib/providers/"))))[:8]
        print("least covered files:")
        for ratio, k in worst:
            print(f"  {100 * ratio:5.1f}%  {k}")
    return 0 if (report_only or not failed) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
