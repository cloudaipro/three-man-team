"""Safety tests for the permanent global Codex skill uninstaller."""

import os
import subprocess
import tempfile
import unittest


REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SCRIPT = os.path.join(REPO_ROOT, "scripts", "uninstall-global-codex-skill.sh")


class UninstallGlobalSkillTests(unittest.TestCase):
    def run_script(self, agents_root, *args):
        env = os.environ.copy()
        env["TMT_UNINSTALL_AGENTS_ROOT"] = agents_root
        return subprocess.run(
            [SCRIPT, *args], env=env, text=True, capture_output=True
        )

    def install_fixture(self, agents_root, name="three-man-team"):
        skill_dir = os.path.join(agents_root, "skills", "three-man-team")
        os.makedirs(skill_dir)
        with open(os.path.join(skill_dir, "SKILL.md"), "w", encoding="utf-8") as handle:
            handle.write(f'---\nname: "{name}"\n---\n')
        with open(os.path.join(skill_dir, "payload.txt"), "w", encoding="utf-8") as handle:
            handle.write("fixture")
        return skill_dir

    def test_dry_run_preserves_then_yes_permanently_removes_install(self):
        with tempfile.TemporaryDirectory() as agents_root:
            skill_dir = self.install_fixture(agents_root)
            preview = self.run_script(agents_root, "--dry-run")
            self.assertEqual(0, preview.returncode, preview.stderr)
            self.assertIn("would permanently delete", preview.stdout)
            self.assertTrue(os.path.isdir(skill_dir))

            removed = self.run_script(agents_root, "--yes")
            self.assertEqual(0, removed.returncode, removed.stderr)
            self.assertIn("permanently removed", removed.stdout)
            self.assertFalse(os.path.exists(skill_dir))

    def test_refuses_directory_without_three_man_team_marker(self):
        with tempfile.TemporaryDirectory() as agents_root:
            skill_dir = self.install_fixture(agents_root, name="different-skill")
            refused = self.run_script(agents_root, "--yes")
            self.assertEqual(1, refused.returncode)
            self.assertIn("Refusing to delete unrecognized directory", refused.stderr)
            self.assertTrue(os.path.isdir(skill_dir))


if __name__ == "__main__":
    unittest.main()
