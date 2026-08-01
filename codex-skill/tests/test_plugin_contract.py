"""Regression tests for the release-bound Codex plugin manifest contract."""

import importlib.util
import json
import os
import subprocess
import tempfile
import unittest


REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
MODULE_PATH = os.path.join(REPO_ROOT, "scripts", "check-codex-plugin.py")
SETUP = os.path.join(REPO_ROOT, "codex-skill", "scripts", "setup-project.sh")
with open(os.path.join(REPO_ROOT, "releases", "latest.json"), encoding="utf-8") as _registry_file:
    LATEST = json.load(_registry_file)["latest"].lstrip("v")
SPEC = importlib.util.spec_from_file_location("check_codex_plugin", MODULE_PATH)
CHECKER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECKER)


def valid_manifest(version="2.3.1"):
    return {
        "name": "three-man-team",
        "version": version,
        "skills": "./skills/",
        "interface": {"defaultPrompt": ["one", "two", "three"]},
    }


class PluginContractTests(unittest.TestCase):
    def test_release_version_and_cachebuster_are_accepted(self):
        self.assertEqual([], CHECKER.validate_manifest(valid_manifest(), "v2.3.1"))
        self.assertEqual(
            [], CHECKER.validate_manifest(valid_manifest("2.3.1+codex.local-20260801"), "v2.3.1")
        )

    def test_stale_version_is_rejected(self):
        errors = CHECKER.validate_manifest(valid_manifest("1.0.0"), "v2.3.1")
        self.assertTrue(any("plugin version" in error for error in errors))

    def test_obsolete_app_and_wrong_skill_path_are_rejected(self):
        manifest = valid_manifest()
        manifest["apps"] = "./.app.json"
        manifest["skills"] = "./skill/"
        errors = CHECKER.validate_manifest(manifest, "v2.3.1")
        self.assertTrue(any("apps" in error for error in errors))
        self.assertTrue(any("skills path" in error for error in errors))

    def test_temporary_staging_uses_resolved_plugin_root_and_cachebuster(self):
        with tempfile.TemporaryDirectory() as temporary:
            marketplace_root = os.path.join(temporary, "marketplace")
            plugin_root = os.path.join(temporary, "plugins")
            fake_codex = os.path.join(temporary, "codex")
            with open(fake_codex, "w", encoding="utf-8") as handle:
                handle.write("#!/bin/sh\nexit 0\n")
            os.chmod(fake_codex, 0o755)
            environment = os.environ.copy()
            environment.update({
                "TMT_MARKETPLACE_DIR": marketplace_root,
                "TMT_PLUGIN_ROOT": plugin_root,
                "TMT_CODEX_BIN": fake_codex,
                "TMT_PLUGIN_CACHEBUSTER": "test-refresh",
            })

            first = subprocess.run(
                [SETUP, "--plugin-only"], text=True, capture_output=True, env=environment
            )
            self.assertEqual(0, first.returncode, first.stderr + first.stdout)
            self.assertIn("Plugin installed in Codex", first.stdout)
            plugin_path = os.path.join(plugin_root, "three-man-team")
            self.assertTrue(os.path.isfile(os.path.join(plugin_path, "skills", "three-man-team", "SKILL.md")))
            self.assertFalse(os.path.exists(os.path.join(plugin_path, ".app.json")))
            with open(os.path.join(marketplace_root, "marketplace.json"), encoding="utf-8") as handle:
                entry = json.load(handle)["plugins"][0]
            self.assertEqual("./plugins/three-man-team", entry["source"]["path"])

            second = subprocess.run(
                [SETUP, "--plugin-only"], text=True, capture_output=True, env=environment
            )
            self.assertEqual(0, second.returncode, second.stderr + second.stdout)
            with open(os.path.join(plugin_path, ".codex-plugin", "plugin.json"), encoding="utf-8") as handle:
                self.assertEqual(LATEST + "+codex.test-refresh", json.load(handle)["version"])


if __name__ == "__main__":
    unittest.main()
