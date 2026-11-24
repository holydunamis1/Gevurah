#!/usr/bin/env python3
"""Fails if a widget, screen or HUD file holds a user-facing string literal.

Text must come from AppLocalizations or from the caller. A literal is allowed
when, after removing interpolations, it holds no run of two letters (so '$a. $b'
and '' pass) and for strings on lines marked `// allow-literal`.
"""
import re
import sys
from pathlib import Path

ROOTS = ["app/lib/widgets", "app/lib/screens", "app/lib/game/hud"]
KEYS = r"(?:Text|SelectableText|label|semanticLabel|title|message|subtitle|hint|value|tooltip|retryLabel|reportLabel|backLabel|barrierLabel)"
PATTERN = re.compile(KEYS + r"""\s*[(:]\s*(?:const\s+)?(?:Text\()?\s*(r?)(['"])((?:\\.|(?!\2).)*)\2""")
INTERP = re.compile(r"\$\{[^}]*\}|\$[A-Za-z_]\w*")


def violations(path: Path):
    for no, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if "allow-literal" in line or line.lstrip().startswith(("//", "///", "import ", "assert")):
            continue
        for m in PATTERN.finditer(line):
            body = INTERP.sub("", m.group(3))
            if re.search(r"[A-Za-z]{2,}", body):
                yield no, m.group(0).strip()


def main(root: Path) -> int:
    bad = 0
    for r in ROOTS:
        for f in sorted((root / r).rglob("*.dart")):
            for no, text in violations(f):
                print(f"{f.relative_to(root)}:{no}: literal string: {text}")
                bad += 1
    if bad:
        print(f"{bad} literal string(s). Move them into app_en.arb.")
        return 1
    print("No literal user-facing strings.")
    return 0


if __name__ == "__main__":
    sys.exit(main(Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")))
