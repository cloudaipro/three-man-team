"""Regression tests for active Codex sub-agent spawn examples."""

import os
import unittest


REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ACTIVE_INSTRUCTIONS = (
    os.path.join(REPO_ROOT, "codex-skill", "SKILL.md"),
    os.path.join(REPO_ROOT, "codex-skill", "references", "role-templates", "ARCHITECT.md"),
)
VALID_NAMES = (
    "builder_step_${step}_attempt_${attempt}",
    "reviewer_step_${step}_attempt_${attempt}",
)
INVALID_NAMES = (
    "builder-step-${step}-attempt-${attempt}",
    "reviewer-step-${step}-attempt-${attempt}",
)


class SpawnContractTests(unittest.TestCase):
    def test_active_examples_are_fresh_unique_and_schema_safe(self):
        for path in ACTIVE_INSTRUCTIONS:
            with open(path, encoding="utf-8") as handle:
                contents = handle.read()
            self.assertIn('fork_turns: "none"', contents, path)
            self.assertIn("references/role-templates/BUILDER.md", contents, path)
            self.assertIn("references/role-templates/REVIEWER.md", contents, path)
            for name in VALID_NAMES:
                self.assertIn(name, contents, path)
            for name in INVALID_NAMES:
                self.assertNotIn(name, contents, path)


if __name__ == "__main__":
    unittest.main()
