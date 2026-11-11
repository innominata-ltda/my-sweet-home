#!/usr/bin/env python3
"""Verifies code coverage thresholds by layer.

    python3 scripts/check_coverage.py coverage/lcov.info

Fails when a layer falls below its required threshold. Generated files are ignored.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

# Order matters: the first matching rule applies
RULES: list[tuple[str, float]] = [
    (r"^lib/core/", 95.0),
    (r"^lib/features/ocr/domain/parser/", 95.0),
    (r"^lib/core/text/", 95.0),
    (r"^lib/core/recurrence/", 95.0),
    (r"^lib/[^/]+/domain/", 90.0),
    (r"^lib/features/[^/]+/domain/", 90.0),
    (r"^lib/data/", 85.0),
    (r"^lib/features/[^/]+/data/", 85.0),
    (r"^lib/features/[^/]+/presentation/", 60.0),
    (r"^lib/design_system/", 60.0),
]
IGNORE = re.compile(r"\.(g|freezed|config|gen)\.dart$|^lib/app/l10n/")


def parse_lcov(path: Path) -> dict[str, tuple[int, int]]:
    """Map: {file_path: (hit_lines, total_lines)}"""
    out: dict[str, tuple[int, int]] = {}
    current: str | None = None
    hit = total = 0
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("SF:"):
            current = line[3:].lstrip("./").replace('\\', '/')
            hit = total = 0
        elif line.startswith("DA:") and current:
            _, _, rest = line.partition(":")
            _, _, count = rest.partition(",")
            total += 1
            if count.strip() not in ("0", ""):
                hit += 1
        elif line.startswith("end_of_record") and current:
            out[current] = (hit, total)
            current = None
    return out


def layer_of(path: str) -> tuple[str, float] | None:
    for pattern, minimum in RULES:
        if re.match(pattern, path):
            return pattern, minimum
    return None


def main(argv: list[str]) -> int:
    if len(argv) != 1:
        print("Usage: check_coverage.py <lcov.info>")
        return 2
    lcov = Path(argv[0])
    if not lcov.exists():
        print(f"Missing coverage file: {lcov} — run `make test` first")
        return 1

    files = parse_lcov(lcov)
    layers: dict[str, list[float]] = {}
    for path, (hit, total) in files.items():
        if IGNORE.search(path) or total == 0:
            continue
        found = layer_of(path)
        if not found:
            continue
        pattern, minimum = found
        acc = layers.setdefault(pattern, [0.0, 0.0, minimum])
        acc[0] += hit
        acc[1] += total

    if not layers:
        print("No lib/ files found in coverage report")
        return 1

    failed = False
    print(f"{'Layer':<46} {'Coverage':>10} {'Minimum':>8}")
    print("-" * 66)
    for pattern, (hit, total, minimum) in sorted(layers.items()):
        pct = hit / total * 100
        mark = "OK " if pct >= minimum else "LOW "
        if pct < minimum:
            failed = True
        print(f"{pattern:<46} {pct:>9.1f}% {minimum:>7.0f}%  {mark}")
    print("-" * 66)
    if failed:
        print("Coverage below required threshold")
        return 1
    print("Coverage OK")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
