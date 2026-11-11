#!/usr/bin/env python3
"""Enforces icon set conventions and Font Awesome attribution requirements.

Rules checked:
  1. If `font_awesome_flutter` is in pubspec.yaml, CC BY 4.0 attribution must be
     present in assets/licenses/attributions.md.
  2. With Font Awesome present, `faIconNameMapping` is forbidden in lib/: dynamic
     lookup disables icon tree-shaking and violates the 60 MB budget (RNF-004).
  3. No file outside lib/design_system/icons/ imports icon packages directly: all access
     must go through the AppIcons facade (RN-011).

    python3 scripts/check_icon_licenses.py
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PUBSPEC = ROOT / "pubspec.yaml"
LIB = ROOT / "lib"
FACADE_DIR = ROOT / "lib" / "design_system" / "icons"
ATTRIBUTIONS = ROOT / "assets" / "licenses" / "attributions.md"

ICON_PACKAGES = (
    "font_awesome_flutter", "material_symbols_icons", "lucide_icons_flutter",
    "phosphor_flutter", "tabler_icons", "heroicons"
)


def main() -> int:
    problems: list[str] = []

    if not PUBSPEC.exists():
        print("pubspec.yaml does not exist yet; nothing to check.")
        return 0

    pubspec = PUBSPEC.read_text(encoding="utf-8")
    uses_fa = "font_awesome_flutter" in pubspec

    if uses_fa:
        if not ATTRIBUTIONS.exists():
            problems.append(
                "font_awesome_flutter in use but assets/licenses/attributions.md does not exist. "
                "Icons are under CC BY 4.0 and require visible attribution (RF-008)."
            )
        else:
            text = ATTRIBUTIONS.read_text(encoding="utf-8").lower()
            if "font awesome" not in text or "cc by 4.0" not in text:
                problems.append(
                    "attributions.md does not include Font Awesome attribution under CC BY 4.0."
                )

    if LIB.exists():
        for dart in LIB.rglob("*.dart"):
            source = dart.read_text(encoding="utf-8", errors="ignore")
            rel = dart.relative_to(ROOT)

            if uses_fa and "faIconNameMapping" in source:
                problems.append(
                    f"{rel}: uses faIconNameMapping (dynamic icon lookup). "
                    "This disables tree-shaking and violates RNF-004."
                )

            if FACADE_DIR in dart.parents:
                continue
            for pkg in ICON_PACKAGES:
                if re.search(rf"import\s+['\"]package:{pkg}/", source):
                    problems.append(
                        f"{rel}: imports '{pkg}' directly. Use the AppIcons facade "
                        "(lib/design_system/icons/) instead (RN-011)."
                    )

    for p in problems:
        print(f"  ERROR  {p}")
    if problems:
        print(f"check_icon_licenses: {len(problems)} problem(s).")
        return 1
    print("check_icon_licenses: icon license requirements OK.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
