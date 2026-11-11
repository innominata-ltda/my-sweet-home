"""Unit tests for check_generated.py.

    python3 -m unittest discover -s scripts/tests
"""
import io
import sys
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import check_generated  # noqa: E402


class TestCheckGenerated(unittest.TestCase):
    @mock.patch("sys.stdout", new_callable=io.StringIO)
    @mock.patch("subprocess.run")
    def test_clean_state_returns_zero(self, mock_run, mock_stdout):
        mock_run.side_effect = [
            mock.Mock(stdout="", returncode=0),
            mock.Mock(stdout="", returncode=0),
        ]
        self.assertEqual(check_generated.main(), 0)

    @mock.patch("sys.stdout", new_callable=io.StringIO)
    @mock.patch("subprocess.run")
    def test_modified_file_returns_one(self, mock_run, mock_stdout):
        mock_run.side_effect = [
            mock.Mock(stdout="lib/app/router.g.dart\n", returncode=0),
            mock.Mock(stdout="", returncode=0),
        ]
        self.assertEqual(check_generated.main(), 1)


if __name__ == "__main__":
    unittest.main()
