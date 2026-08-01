"""Black-box regression tests for the offline Codex version checker."""

import json
import os
import subprocess
import sys
import tempfile
import unittest


REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
CHECKER = os.path.join(REPO_ROOT, "codex-skill", "scripts", "check-version.py")


class CheckVersionCliTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.project = os.path.join(self.tempdir.name, "project")
        os.makedirs(os.path.join(self.project, "handoff"))
        self.registry = os.path.join(self.tempdir.name, "latest.json")
        self.write_registry([
            {"version": "v2.3.2", "released": "2026-08-01", "critical": False},
            {"version": "v2.3.1", "released": "2026-07-26", "critical": True},
            {"version": "v2.3.0", "released": "2026-07-26", "critical": False},
        ])

    def tearDown(self):
        self.tempdir.cleanup()

    def write_registry(self, versions):
        with open(self.registry, "w", encoding="utf-8") as handle:
            json.dump({"latest": versions[0]["version"], "versions": versions}, handle)

    def write_manifest(self, version):
        with open(os.path.join(self.project, "manifest.md"), "w", encoding="utf-8") as handle:
            handle.write("version: {0}\n".format(version))

    def run_checker(self, *args):
        environment = os.environ.copy()
        environment["TMT_RELEASES_PATH"] = self.registry
        return subprocess.run(
            [sys.executable, CHECKER, self.project] + list(args),
            text=True,
            capture_output=True,
            check=False,
            env=environment,
        )

    def test_v230_reports_v231_then_v232_in_chronological_order(self):
        self.write_manifest("v2.3.0")
        result = self.run_checker()
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertLess(result.stdout.index("v2.3.1"), result.stdout.index("v2.3.2"))
        self.assertIn("[CRITICAL]", result.stdout)

    def test_acknowledgement_makes_an_older_manifest_current(self):
        self.write_manifest("v2.3.0")
        acknowledged = self.run_checker("--acknowledge", "v2.3.2")
        self.assertEqual(0, acknowledged.returncode, acknowledged.stderr)
        self.assertIn("Acknowledged releases through v2.3.2", acknowledged.stdout)

        current = self.run_checker()
        self.assertEqual(0, current.returncode, current.stderr)
        self.assertIn("up to date", current.stdout)
        checkpoint = os.path.join(self.project, "handoff", "SESSION-CHECKPOINT.md")
        with open(checkpoint, encoding="utf-8") as handle:
            self.assertIn("version_notified: v2.3.2", handle.read())

    def test_existing_notification_skips_already_walked_releases(self):
        self.write_manifest("v2.3.0")
        checkpoint = os.path.join(self.project, "handoff", "SESSION-CHECKPOINT.md")
        with open(checkpoint, "w", encoding="utf-8") as handle:
            handle.write("# Session Checkpoint\n\n## Version Check\nversion_notified: v2.3.1\n")

        result = self.run_checker()
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertNotIn("released 2026-07-26", result.stdout)
        self.assertIn("v2.3.2", result.stdout)

    def test_unknown_acknowledgement_fails_without_changing_checkpoint(self):
        self.write_manifest("v2.3.0")
        result = self.run_checker("--acknowledge", "v9.9.9")
        self.assertEqual(1, result.returncode)
        self.assertIn("unknown release", result.stderr)
        self.assertFalse(os.path.exists(os.path.join(self.project, "handoff", "SESSION-CHECKPOINT.md")))

    def test_missing_manifest_is_non_fatal(self):
        result = self.run_checker()
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn("unknown (no manifest.md)", result.stdout)


if __name__ == "__main__":
    unittest.main()
