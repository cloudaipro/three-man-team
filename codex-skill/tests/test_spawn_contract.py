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
REQUIRED_CHILD_ROUTE = 'model: "gpt-5.6-luna", reasoning_effort: "max"'
NORMAL_ROUTE_BLOCKS = {
    "codex-skill/SKILL.md": (
        (
            "Builder",
            "To spawn the Builder,",
            "To spawn the Reviewer,",
            "builder_step_${step}_attempt_${attempt}",
            "reviewer_step_${step}_attempt_${attempt}",
        ),
        (
            "Reviewer",
            "To spawn the Reviewer,",
            "**Bound context and validation.**",
            "reviewer_step_${step}_attempt_${attempt}",
            "builder_step_${step}_attempt_${attempt}",
        ),
    ),
    "codex-skill/references/role-templates/ARCHITECT.md": (
        (
            "Builder",
            "Spawn the Builder with a unique `task_name`",
            "## Briefing the Reviewer",
            "builder_step_${step}_attempt_${attempt}",
            "reviewer_step_${step}_attempt_${attempt}",
        ),
        (
            "Reviewer",
            "When the Builder signals done, spawn the Reviewer with a unique `task_name`",
            "## Context Budget",
            "reviewer_step_${step}_attempt_${attempt}",
            "builder_step_${step}_attempt_${attempt}",
        ),
    ),
}
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

    def test_every_child_route_is_role_bound_luna_max_with_no_alternative(self):
        for path in ACTIVE_INSTRUCTIONS:
            with open(path, encoding="utf-8") as handle:
                contents = handle.read()
            relative_path = os.path.relpath(path, REPO_ROOT)
            for role, start, end, task_name, other_task_name in NORMAL_ROUTE_BLOCKS[
                relative_path
            ]:
                self.assertEqual(1, contents.count(start), f"{path}: {role} route start")
                self.assertEqual(1, contents.count(end), f"{path}: {role} route end")
                self.assertLess(
                    contents.index(start),
                    contents.index(end),
                    f"{path}: {role} route block ordering",
                )
                role_block = contents.split(start, 1)[1].split(end, 1)[0]
                self.assertIn(task_name, role_block, f"{path}: {role} task name")
                self.assertNotIn(
                    other_task_name,
                    role_block,
                    f"{path}: {role} block must not be satisfied by the other role",
                )
                self.assertEqual(
                    1,
                    role_block.count(REQUIRED_CHILD_ROUTE),
                    f"{path}: {role} Luna/Max route",
                )
                self.assertIn("Luna is unavailable", role_block, path)
                self.assertIn("do not spawn", role_block, path)
                self.assertNotIn("gpt-5.6-terra", role_block, path)
                self.assertNotIn("main-session inheritance", role_block, path)
            self.assertNotIn('reasoning_effort: "medium"', contents, path)
            self.assertNotIn("**Critical Builder route", contents, path)
            self.assertNotIn("**Critical Reviewer route", contents, path)


if __name__ == "__main__":
    unittest.main()
