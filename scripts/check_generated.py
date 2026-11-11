"""check_generated.py — Verifies whether generated code in lib/ is up to date."""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def main() -> int:
    # 1. Check modified uncommitted/unstaged files in lib/
    diff_res = subprocess.run(
        ["git", "diff", "--name-only", "lib/"],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    # 2. Check untracked generated files in lib/
    untracked_res = subprocess.run(
        ["git", "ls-files", "--others", "--exclude-standard", "lib/"],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )

    modified = [f.strip() for f in diff_res.stdout.splitlines() if f.strip()]
    untracked = [
        f.strip() for f in untracked_res.stdout.splitlines()
        if f.strip() and (f.endswith(".g.dart") or f.endswith(".freezed.dart"))
    ]

    changes = modified + untracked
    if changes:
        print("::error::Generated code is out of date or uncommitted changes exist in lib/; run 'make gen' and commit:")
        for c in changes:
            print(f"   M {c}")
        return 1

    print("Generated code is up to date.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
