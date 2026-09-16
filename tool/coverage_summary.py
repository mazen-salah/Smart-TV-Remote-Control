#!/usr/bin/env python3
"""Summarise lcov coverage as Markdown.

Prints a total and the least-covered files. Generated localizations are
excluded because they are not hand-written. Used by CI to fill the job
summary, and useful locally after `flutter test --coverage`:

    python3 tool/coverage_summary.py
"""
import sys

EXCLUDE = ("lib/l10n/", "tool/")


def parse(path):
    per = {}
    current = None
    with open(path) as handle:
        for line in handle:
            line = line.strip()
            if line.startswith("SF:"):
                current = line[3:]
            elif line.startswith("LF:") and current:
                per.setdefault(current, [0, 0])[1] = int(line[3:])
            elif line.startswith("LH:") and current:
                per.setdefault(current, [0, 0])[0] = int(line[3:])
    return per


def relevant(path):
    return not any(part in path for part in EXCLUDE)


def main():
    lcov = sys.argv[1] if len(sys.argv) > 1 else "coverage/lcov.info"
    try:
        per = parse(lcov)
    except FileNotFoundError:
        print(f"No coverage file at `{lcov}`.")
        return 0

    rows = [
        (hit / found if found else 1.0, hit, found, path)
        for path, (hit, found) in per.items()
        if relevant(path)
    ]
    hit = sum(row[1] for row in rows)
    found = sum(row[2] for row in rows)
    if not found:
        print("No coverable lines found.")
        return 0

    print(f"## Coverage: {100 * hit / found:.1f}% ({hit}/{found} lines)")
    print()
    print("Generated localizations are excluded.")
    print()
    print("<details><summary>Least covered files</summary>")
    print()
    print("| File | Covered |")
    print("| --- | --- |")
    for ratio, file_hit, file_found, path in sorted(rows)[:15]:
        short = path.split("/lib/", 1)[-1]
        short = short if short.startswith("lib/") else f"lib/{short}"
        print(f"| `{short}` | {100 * ratio:.0f}% ({file_hit}/{file_found}) |")
    print()
    print("</details>")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
