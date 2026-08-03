"""Regression tests for Codex skill-location selection in ./upgrade."""

import os
import subprocess
import tempfile
import unittest


REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
UPGRADE = os.path.join(REPO_ROOT, "upgrade")
SETUP = os.path.join(REPO_ROOT, "codex-skill", "scripts", "setup-project.sh")


class CodexUpgradeLocationTests(unittest.TestCase):
    def run_upgrade(self, home, project, dry_run=True, **extra_environment):
        bin_dir = os.path.join(home, "bin")
        os.makedirs(bin_dir, exist_ok=True)
        curl = os.path.join(bin_dir, "curl")
        with open(curl, "w", encoding="utf-8") as handle:
            handle.write("#!/bin/sh\nexit 0\n")
        os.chmod(curl, 0o755)

        environment = os.environ.copy()
        environment.update({"HOME": home, "PATH": bin_dir + os.pathsep + environment["PATH"]})
        environment.update(extra_environment)
        command = [UPGRADE, "codex"]
        if dry_run:
            command.append("--dry-run")
        command.append(project)
        result = subprocess.run(
            command,
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

    def test_refresh_backup_is_outside_scanned_skills_directory(self):
        with tempfile.TemporaryDirectory() as root:
            home = os.path.join(root, "home")
            project = self.make_project(root)
            repo_skill = os.path.join(project, ".agents", "skills", "three-man-team")
            os.makedirs(repo_skill)
            with open(os.path.join(repo_skill, "old-version"), "w", encoding="utf-8") as handle:
                handle.write("preserve me\n")

            output = self.run_upgrade(home, project, dry_run=False)

            backup_root = os.path.join(project, ".agents", "skill-backups")
            backups = os.listdir(backup_root)
            self.assertEqual(1, len(backups))
            backup = os.path.join(backup_root, backups[0])
            self.assertTrue(os.path.isfile(os.path.join(backup, "old-version")))
            self.assertNotIn(".backup-", " ".join(os.listdir(os.path.dirname(repo_skill))))
            self.assertIn("previous version: " + backup, output)

    def test_explicit_role_migration_backs_up_custom_files_then_slms_them(self):
        with tempfile.TemporaryDirectory() as root:
            home = os.path.join(root, "home")
            project = self.make_project(root)
            for role in ("ARCHITECT", "BUILDER", "REVIEWER"):
                with open(os.path.join(project, role + ".md"), "w", encoding="utf-8") as handle:
                    handle.write("custom " + role + " persona\n")

            self.run_upgrade(home, project, dry_run=False, TMT_CODEX_SKILL_DIR=os.path.join(root, "skills", "three-man-team"), TMT_SKIP_PLUGIN_ADD="1")
            # Setup is additive: migration is the only authorization to replace a persona.
            output = subprocess.run(
                [UPGRADE, "codex", "--migrate-role-files", project], text=True,
                capture_output=True, env={**os.environ, "HOME": home, "TMT_CODEX_SKILL_DIR": os.path.join(root, "skills", "three-man-team"), "TMT_SKIP_PLUGIN_ADD": "1"}
            )
            self.assertEqual(0, output.returncode, output.stderr + output.stdout)
            backups = [name for name in os.listdir(project) if name.startswith(".tmt-codex-role-backup-")]
            self.assertEqual(1, len(backups))
            backup = os.path.join(project, backups[0])
            with open(os.path.join(backup, "ARCHITECT.md"), encoding="utf-8") as handle:
                self.assertIn("custom ARCHITECT persona", handle.read())
            with open(os.path.join(project, "ARCHITECT.md"), encoding="utf-8") as handle:
                self.assertIn("canonical workflow", handle.read())

    def test_role_migration_allocates_a_new_backup_when_timestamp_candidate_exists(self):
        with tempfile.TemporaryDirectory() as root:
            home = os.path.join(root, "home")
            project = self.make_project(root)
            for role in ("ARCHITECT", "BUILDER", "REVIEWER"):
                with open(os.path.join(project, role + ".md"), "w", encoding="utf-8") as handle:
                    handle.write("custom " + role + " persona\n")
            timestamp = "20260802-010203"
            existing = os.path.join(project, ".tmt-codex-role-backup-" + timestamp)
            os.makedirs(existing)
            with open(os.path.join(existing, "ARCHITECT.md"), "w", encoding="utf-8") as handle:
                handle.write("do not overwrite this backup\n")
            bin_dir = os.path.join(root, "bin")
            os.makedirs(bin_dir)
            with open(os.path.join(bin_dir, "date"), "w", encoding="utf-8") as handle:
                handle.write("#!/bin/sh\necho " + timestamp + "\n")
            os.chmod(os.path.join(bin_dir, "date"), 0o755)
            environment = {
                **os.environ,
                "HOME": home,
                "PATH": bin_dir + os.pathsep + os.environ["PATH"],
                "TMT_CODEX_SKILL_DIR": os.path.join(root, "skills", "three-man-team"),
                "TMT_SKIP_PLUGIN_ADD": "1",
            }
            result = subprocess.run(
                [UPGRADE, "codex", "--migrate-role-files", project],
                text=True, capture_output=True, env=environment,
            )
            self.assertEqual(0, result.returncode, result.stderr + result.stdout)
            with open(os.path.join(existing, "ARCHITECT.md"), encoding="utf-8") as handle:
                self.assertEqual("do not overwrite this backup\n", handle.read())
            allocated = existing + "-1"
            self.assertTrue(os.path.isdir(allocated))
            with open(os.path.join(allocated, "ARCHITECT.md"), encoding="utf-8") as handle:
                self.assertIn("custom ARCHITECT persona", handle.read())

    def test_fresh_setup_creates_lean_role_deltas_and_audit(self):
        with tempfile.TemporaryDirectory() as root:
            project = os.path.join(root, "project")
            os.makedirs(project)
            result = subprocess.run([SETUP, project], text=True, capture_output=True)
            self.assertEqual(0, result.returncode, result.stderr + result.stdout)
            with open(os.path.join(project, "BUILDER.md"), encoding="utf-8") as handle:
                self.assertIn("canonical workflow", handle.read())
            self.assertTrue(os.path.isfile(os.path.join(project, "scripts", "codex-usage-audit.py")))


if __name__ == "__main__":
    unittest.main()
