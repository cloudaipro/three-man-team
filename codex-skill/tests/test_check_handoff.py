"""Regression tests for executable Three Man Team handoff contracts."""

import os
import shutil
import subprocess
import tempfile
import unittest


REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
CHECKERS = {
    "active-root": os.path.join(REPO_ROOT, "scripts", "check-handoff.sh"),
    "codex-template": os.path.join(
        REPO_ROOT, "codex-skill", "templates", "project", "scripts", "check-handoff.sh"
    ),
}


class CheckHandoffTests(unittest.TestCase):
    def make_project(self, source):
        root = tempfile.TemporaryDirectory()
        project = root.name
        os.makedirs(os.path.join(project, "scripts"))
        os.makedirs(os.path.join(project, "handoff"))
        checker = os.path.join(project, "scripts", "check-handoff.sh")
        shutil.copy2(source, checker)
        return root, project, checker

    def write(self, project, relative, text):
        with open(os.path.join(project, relative), "w", encoding="utf-8") as handle:
            handle.write(text)

    def run_check(self, checker, mode):
        return subprocess.run([checker, mode], text=True, capture_output=True)

    def valid_brief(self):
        return """# Architect Brief
## Step 1 — Guardrails
### Decisions
- Enforce the contract.
### Build Order
1. Add the checks.
### Out of Scope
- Do not deploy.
### Flags
- None.
### Cost Budget
- Architect: warning 85K / fresh-session checkpoint 100K; Builder: 75K / 90K; Reviewer: 50K / 60K.
### Owner Validation Batch
- Disposition: no device-only validation is required for this step.
### Definition of Done
- `true` exits zero.
## Builder Plan
- Implement the checks.
Architect approval: YES
"""

    def test_brief_requires_thresholds_and_owner_validation_disposition(self):
        for name, source in CHECKERS.items():
            with self.subTest(checker=name):
                temp, project, checker = self.make_project(source)
                with temp:
                    path = "handoff/ARCHITECT-BRIEF.md"
                    brief = self.valid_brief()
                    self.write(project, path, brief)
                    self.assertEqual(0, self.run_check(checker, "brief").returncode)

                    self.write(project, path, brief.replace("; Reviewer: 50K / 60K", ""))
                    failed = self.run_check(checker, "brief")
                    self.assertNotEqual(0, failed.returncode)
                    self.assertIn("Reviewer.*50K.*60K", failed.stdout)

                    self.write(
                        project, path,
                        brief.replace("Disposition: no device-only validation is required for this step.", "Validate later."),
                    )
                    failed = self.run_check(checker, "brief")
                    self.assertNotEqual(0, failed.returncode)
                    self.assertIn("explicit validation disposition", failed.stdout)

    def test_checkpoint_and_review_feedback_require_all_executable_fields(self):
        for name, source in CHECKERS.items():
            with self.subTest(checker=name):
                temp, project, checker = self.make_project(source)
                with temp:
                    checkpoint = """# Session Checkpoint — 2026-08-02
## Where We Stopped
Implemented the guardrails.
## Context Checkpoint
- Role: Builder
- Context reached: warning
- Fresh session next action: run the complete test suite.
## What Was Decided This Session
- Keep metadata top-level only.
## Still Open
- None.
## Resume Prompt
Read this checkpoint.
"""
                    self.write(project, "handoff/SESSION-CHECKPOINT.md", checkpoint)
                    self.assertEqual(0, self.run_check(checker, "checkpoint").returncode)
                    self.write(
                        project, "handoff/SESSION-CHECKPOINT.md",
                        checkpoint.replace("Implemented the guardrails.\n", ""),
                    )
                    failed = self.run_check(checker, "checkpoint")
                    self.assertNotEqual(0, failed.returncode)
                    self.assertIn("Where We Stopped' section is empty", failed.stdout)
                    self.write(
                        project, "handoff/SESSION-CHECKPOINT.md",
                        checkpoint.replace("- Fresh session next action: run the complete test suite.\n", ""),
                    )
                    self.assertNotEqual(0, self.run_check(checker, "checkpoint").returncode)
                    self.write(
                        project, "handoff/SESSION-CHECKPOINT.md",
                        checkpoint.replace("Context reached: warning", "Context reached: later"),
                    )
                    failed = self.run_check(checker, "checkpoint")
                    self.assertNotEqual(0, failed.returncode)
                    self.assertIn("valid context status", failed.stdout)

                    feedback = """# Review Feedback — Step 1
Date: 2026-08-02
Ready for Builder: YES
## Must Fix
- None.
## Should Fix
- None.
## Escalate to Architect
- None.
## Cleared
All checks passed.
"""
                    self.write(project, "handoff/REVIEW-FEEDBACK.md", feedback)
                    self.assertEqual(0, self.run_check(checker, "review-feedback").returncode)
                    self.write(
                        project, "handoff/REVIEW-FEEDBACK.md",
                        feedback.replace("## Escalate to Architect\n- None.\n", ""),
                    )
                    failed = self.run_check(checker, "review-feedback")
                    self.assertNotEqual(0, failed.returncode)
                    self.assertIn("Escalate to Architect", failed.stdout)

                    self.write(
                        project, "handoff/REVIEW-FEEDBACK.md",
                        "# Review Feedback — Step 1\nDate: 2026-08-02\nReady for Builder: YES\n"
                        "\n## Must Fix\n\n## Should Fix\n\n"
                        "## Escalate to Architect\n\n## Cleared\n",
                    )
                    failed = self.run_check(checker, "review-feedback")
                    self.assertNotEqual(0, failed.returncode)
                    self.assertIn("section is empty", failed.stdout)

                    self.write(
                        project, "handoff/REVIEW-FEEDBACK.md",
                        feedback.replace("All checks passed.", "[One sentence confirming what was reviewed and passed]"),
                    )
                    failed = self.run_check(checker, "review-feedback")
                    self.assertNotEqual(0, failed.returncode)
                    self.assertIn("unfilled template placeholders", failed.stdout)


if __name__ == "__main__":
    unittest.main()
