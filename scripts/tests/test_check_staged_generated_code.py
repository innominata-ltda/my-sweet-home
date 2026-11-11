"""Unit tests for check_staged_generated_code.py.

    python3 -m unittest discover -s scripts/tests
"""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from check_staged_generated_code import check_staged_generated  # noqa: E402


class TestCheckStagedGeneratedCode(unittest.TestCase):
    def test_no_files_no_errors(self):
        errors = check_staged_generated([], [])
        self.assertEqual(errors, [])

    def test_unstaged_companion_triggers_error(self):
        staged = ["lib/app/router.dart"]
        unstaged = ["lib/app/router.g.dart"]
        errors = check_staged_generated(staged, unstaged)
        self.assertTrue(any("router.g.dart" in e for e in errors))

    def test_unstaged_freezed_companion_triggers_error(self):
        staged = ["lib/features/item/model.dart"]
        unstaged = ["lib/features/item/model.freezed.dart"]
        errors = check_staged_generated(staged, unstaged)
        self.assertTrue(any("model.freezed.dart" in e for e in errors))

    def test_drift_tables_staged_with_unstaged_database_g(self):
        staged = ["lib/data/database/tables.dart"]
        unstaged = ["lib/data/database/database.g.dart"]
        errors = check_staged_generated(staged, unstaged)
        self.assertTrue(any("database.g.dart" in e for e in errors))


if __name__ == "__main__":
    unittest.main()
