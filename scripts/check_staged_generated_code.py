"""check_staged_generated_code.py — Fast pre-commit validation.

Runs in milliseconds:
1. Verifies that generated files (*.g.dart, *.freezed.dart) do not have unstaged changes while their source is staged.
2. Verifies that files with annotations/part were not modified after the last generation (source mtime > generated mtime).
3. Verifies formatting of staged .dart files.
"""
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PART_RE = re.compile(r"^\s*part\s+['\"]([^'\"]+\.(?:g|freezed)\.dart)['\"];", re.MULTILINE)


def get_staged_files() -> list[str]:
    res = subprocess.run(
        ["git", "diff", "--cached", "--name-only", "--diff-filter=ACMR"],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if res.returncode != 0:
        return []
    return [line.strip().replace("\\", "/") for line in res.stdout.splitlines() if line.strip()]


def get_unstaged_modified_files() -> list[str]:
    res = subprocess.run(
        ["git", "diff", "--name-only", "--diff-filter=M"],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if res.returncode != 0:
        return []
    return [line.strip().replace("\\", "/") for line in res.stdout.splitlines() if line.strip()]


def check_staged_generated(staged: list[str], unstaged_modified: list[str]) -> list[str]:
    errors = []
    staged_set = set(staged)
    unstaged_set = set(unstaged_modified)

    # 1. Check if generated files have unstaged working tree changes
    for u in unstaged_set:
        if u.endswith(".g.dart") or u.endswith(".freezed.dart"):
            source_candidates = [
                u.replace(".g.dart", ".dart"),
                u.replace(".freezed.dart", ".dart"),
            ]
            if any(s in staged_set for s in source_candidates) or (
                u == "lib/data/database/database.g.dart" and "lib/data/database/tables.dart" in staged_set
            ):
                errors.append(
                    f"Generated file '{u}' has unstaged changes. "
                    f"Run 'git add {u}' before committing."
                )

    # 2. For each staged .dart file, verify generated parts exist and are up to date
    for s in staged:
        if not s.startswith("lib/") or not s.endswith(".dart"):
            continue
        if s.endswith(".g.dart") or s.endswith(".freezed.dart"):
            continue

        file_path = ROOT / s
        if not file_path.is_file():
            continue

        try:
            content = file_path.read_text(encoding="utf-8")
        except Exception:
            continue

        parts = PART_RE.findall(content)
        if s == "lib/data/database/tables.dart":
            parts.append("database.g.dart")

        for part in parts:
            gen_path = file_path.parent / part
            rel_gen = gen_path.relative_to(ROOT).as_posix()

            if not gen_path.exists():
                errors.append(
                    f"File '{s}' references generated part '{rel_gen}' which does not exist on disk. "
                    f"Run 'make gen' and stage the generated file."
                )
                continue

            try:
                src_mtime = file_path.stat().st_mtime
                gen_mtime = gen_path.stat().st_mtime
                if src_mtime > gen_mtime + 1.0 and rel_gen not in staged_set:
                    errors.append(
                        f"'{s}' was modified after the last code generation (mtime newer than '{rel_gen}'). "
                        f"Run 'make gen' and include '{rel_gen}' in the commit."
                    )
            except OSError:
                pass

    return errors


def check_dart_formatting(staged: list[str]) -> list[str]:
    dart_files = [s for s in staged if s.endswith(".dart") and (ROOT / s).exists()]
    if not dart_files:
        return []

    if sys.platform == "win32":
        dart_cmd = [shutil.which("dart.bat") or "dart"]
    elif Path("/proc/version").exists() and shutil.which("cmd.exe"):
        dart_cmd = ["cmd.exe", "/c", "dart"]
    else:
        dart_cmd = ["dart"]

    res = subprocess.run(
        [*dart_cmd, "format", "--output=none", "--set-exit-if-changed", *dart_files],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if res.returncode != 0:
        return ["Dart files are not formatted. Run 'dart format' and stage the changes."]
    return []


def main() -> int:
    staged = get_staged_files()
    if not staged:
        return 0

    unstaged = get_unstaged_modified_files()
    errors = check_staged_generated(staged, unstaged)
    errors.extend(check_dart_formatting(staged))

    if errors:
        print("\n❌ [git hook: pre-commit] Validation failed:")
        for err in errors:
            print(f"   • {err}")
        print("\nTo fix: run 'make gen' / 'dart format' and stage changes with 'git add'.\n")
        return 1

    return 0


if __name__ == "__main__":
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.exit(main())
