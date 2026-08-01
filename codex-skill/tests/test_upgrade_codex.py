"""Regression tests for Codex skill-location selection in ./upgrade."""

import os
import subprocess
import tempfile
import unittest


REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
UPGRADE = os.path.join(REPO_ROOT, "upgrade")


class CodexUpgradeLocationTests(unittest.TestCase):
    def run_upgrade(self, home, project, **extra_environment):
        bin_dir = os.path.join(home, "bin")
        os.makedirs(bin_dir, exist_ok=True)
        curl = os.path.join(bin_dir, "curl")
        with open(curl, "w", encoding="utf-8") as handle:
            handle.write("#!/bin/sh\nexit 0\n")
        os.chmod(curl, 0o755)

        environment = os.environ.copy()
        environment.update({"HOME": home, "PATH": bin_dir + os.pathsep + environment["PATH"]})
        environment.update(extra_environment)
        result = subprocess.run(
            [UPGRADE, "codex", "--dry-run", project],
            text=True,
            capture_output=True,
            env=environment,
        )
        self.assertEqual(0, result.returncode, result.stderr + result.stdout)
        return result.stdout

    def make_project(self, root):
        project = os.path.join(root, "project")
        os.makedirs(project)
        with open(os.path.join(project, "AGENTS.md"), "w", encoding="utf-8") as handle:
            handle.write("# Three Man Team\n")
        return project

    def test_repository_scoped_skill_has_priority(self):
        with tempfile.TemporaryDirectory() as root:
            home = os.path.join(root, "home")
            project = self.make_project(root)
            repo_skill = os.path.join(project, ".agents", "skills", "three-man-team")
            personal_skill = os.path.join(home, ".agents", "skills", "three-man-team")
            os.makedirs(repo_skill)
            os.makedirs(personal_skill)

            output = self.run_upgrade(home, project)

            self.assertIn("Skill dir:  " + repo_skill, output)

    def test_personal_skill_uses_agents_directory_without_codex_home_override(self):
        with tempfile.TemporaryDirectory() as root:
            home = os.path.join(root, "home")
            project = self.make_project(root)
            personal_skill = os.path.join(home, ".agents", "skills", "three-man-team")
            os.makedirs(personal_skill)

            output = self.run_upgrade(home, project)

            self.assertIn("Skill dir:  " + personal_skill, output)

    def test_existing_codex_home_skill_remains_supported(self):
        with tempfile.TemporaryDirectory() as root:
            home = os.path.join(root, "home")
            project = self.make_project(root)
            codex_home = os.path.join(root, "codex-home")
            codex_home_skill = os.path.join(codex_home, "skills", "three-man-team")
            os.makedirs(codex_home_skill)

            output = self.run_upgrade(home, project, CODEX_HOME=codex_home)

            self.assertIn("Skill dir:  " + codex_home_skill, output)

    def test_explicit_skill_directory_overrides_detected_installs(self):
        with tempfile.TemporaryDirectory() as root:
            home = os.path.join(root, "home")
            project = self.make_project(root)
            repo_skill = os.path.join(project, ".agents", "skills", "three-man-team")
            selected_skill = os.path.join(root, "selected", "skills", "three-man-team")
            os.makedirs(repo_skill)

            output = self.run_upgrade(
                home, project, TMT_CODEX_SKILL_DIR=selected_skill
            )

            self.assertIn("Skill dir:  " + selected_skill, output)


if __name__ == "__main__":
    unittest.main()
