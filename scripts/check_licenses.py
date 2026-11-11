#!/usr/bin/env python3
"""Checks pubspec.yaml dependencies against the license policy.

Source of truth: assets/licenses/dependencies.md.
Runs without Flutter installed by parsing pubspec.yaml and the markdown table.

    python3 scripts/check_licenses.py
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
POLICY = ROOT / "assets" / "licenses" / "dependencies.md"
PUBSPEC = ROOT / "pubspec.yaml"

ALLOWED = {
    "mit", "bsd-2", "bsd-3", "apache-2.0", "isc", "sil ofl", "ofl", "cc by 4.0",
    "cc0", "unlicense", "bsd"
}
FORBIDDEN = {"gpl", "agpl", "lgpl", "sspl", "busl", "source-available", "non-commercial"}


def listed_packages() -> dict[str, str]:
    """Packages listed in policy table -> declared license."""
    out: dict[str, str] = {}
    if not POLICY.exists():
        return out
    for line in POLICY.read_text(encoding="utf-8").splitlines():
        if not line.startswith("| `"):
            continue
        cells = [c.strip() for c in line.strip("|").split("|")]
        if len(cells) < 2:
            continue
        for name in re.findall(r"`([a-z0-9_]+)`", cells[0]):
            out[name] = cells[1].lower()
    return out


def pubspec_packages() -> set[str]:
    if not PUBSPEC.exists():
        return set()
    names: set[str] = set()
    in_deps = False
    for line in PUBSPEC.read_text(encoding="utf-8").splitlines():
        if re.match(r"^(dependencies|dev_dependencies):", line):
            in_deps = True
            continue
        if re.match(r"^[a-z_]+:", line):
            in_deps = False
        if in_deps:
            m = re.match(r"^  ([a-z0-9_]+):", line)
            if m and m.group(1) not in {"sdk", "flutter"}:
                names.add(m.group(1))
    return names


def main() -> int:
    policy = listed_packages()
    if not policy:
        print("Could not read license policy table in assets/licenses/dependencies.md")
        return 1

    problems: list[str] = []
    for name, license_text in policy.items():
        if any(bad in license_text for bad in FORBIDDEN):
            problems.append(f"{name}: forbidden license in policy ({license_text})")
        elif not any(ok in license_text for ok in ALLOWED):
            problems.append(f"{name}: unrecognized license ({license_text}); update policy")

    if not PUBSPEC.exists():
        print(f"pubspec.yaml does not exist yet; {len(policy)} policy package(s) verified.")
    else:
        for name in sorted(pubspec_packages() - set(policy)):
            problems.append(f"{name}: present in pubspec.yaml but missing from license policy")

    for p in problems:
        print(f"  ERROR  {p}")
    if problems:
        print(f"check_licenses: {len(problems)} problem(s).")
        return 1
    print("check_licenses: license policy OK.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
