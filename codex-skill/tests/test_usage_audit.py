"""Synthetic regression tests for the aggregate-only Codex usage audit."""

import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest


REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
MODULE_PATH = os.path.join(REPO_ROOT, "scripts", "codex-usage-audit.py")
SPEC = importlib.util.spec_from_file_location("codex_usage_audit", MODULE_PATH)
AUDIT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(AUDIT)


class UsageAuditTests(unittest.TestCase):
    def test_counts_only_final_cumulative_usage_per_session(self):
        with tempfile.TemporaryDirectory() as root:
            sample = os.path.join(root, "session.jsonl")
            events = [
                {"role": "builder", "message": "private prompt", "last_token_usage": {"input_tokens": 10, "cached_input_tokens": 3, "output_tokens": 2}},
                {"role": "builder", "response": "private response", "last_token_usage": {"input_tokens": 25, "cached_input_tokens": 7, "output_tokens": 5}},
            ]
            with open(sample, "w", encoding="utf-8") as handle:
                for event in events:
                    handle.write(json.dumps(event) + "\n")
            report = AUDIT.audit(root)
            self.assertEqual(1, report["sessions"])
            self.assertEqual(2, report["calls"])
            self.assertEqual(25, report["peak_input_tokens"])
            self.assertEqual({"input_tokens": 25, "cached_input_tokens": 7, "output_tokens": 5}, report["tokens"])
            self.assertEqual(25, report["roles"]["builder"]["input_tokens"])

    def test_unknown_shapes_and_invalid_lines_are_tolerated(self):
        with tempfile.TemporaryDirectory() as root:
            with open(os.path.join(root, "session.jsonl"), "w", encoding="utf-8") as handle:
                handle.write("not json\n")
                handle.write(json.dumps({"payload": {"last_token_usage": {"input_tokens": 4}}}) + "\n")
                handle.write(json.dumps({"last_token_usage": {"input_tokens": 4}}) + "\n")
            report = AUDIT.audit(root)
            self.assertEqual(1, report["sessions"])
            self.assertEqual(4, report["tokens"]["input_tokens"])
            self.assertEqual(0, report["tokens"]["output_tokens"])

    def test_invalid_token_fields_do_not_discard_prior_valid_cumulative_total(self):
        with tempfile.TemporaryDirectory() as root:
            with open(os.path.join(root, "session.jsonl"), "w", encoding="utf-8") as handle:
                handle.write(json.dumps({"last_token_usage": {
                    "input_tokens": "25", "cached_input_tokens": 7, "output_tokens": 5
                }}) + "\n")
                for invalid in (None, "unknown", [], {"count": 2}, True):
                    handle.write(json.dumps({"last_token_usage": {
                        "input_tokens": invalid, "cached_input_tokens": 99, "output_tokens": 99
                    }}) + "\n")
            report = AUDIT.audit(root)
            self.assertEqual(1, report["sessions"])
            self.assertEqual(1, report["calls"])
            self.assertEqual(
                {"input_tokens": 25, "cached_input_tokens": 7, "output_tokens": 5},
                report["tokens"],
            )

    def test_rendered_report_never_contains_message_content(self):
        with tempfile.TemporaryDirectory() as root:
            secret = "do-not-disclose-this-prompt"
            with open(os.path.join(root, "session.jsonl"), "w", encoding="utf-8") as handle:
                handle.write(json.dumps({"message": secret, "last_token_usage": {"input_tokens": 1}}) + "\n")
            rendered = json.dumps(AUDIT.audit(root))
            self.assertNotIn(secret, rendered)

    def test_cli_never_uses_nested_prompt_or_response_metadata_as_labels(self):
        with tempfile.TemporaryDirectory() as root:
            nested_role = "nested-private-role"
            nested_model = "nested-private-model"
            with open(os.path.join(root, "session.jsonl"), "w", encoding="utf-8") as handle:
                handle.write(json.dumps({
                    "role": "builder",
                    "model": "gpt-5.6-terra",
                    "message": {"role": nested_role, "model": nested_model},
                    "response": {"role": nested_role, "model": nested_model},
                    "last_token_usage": {"input_tokens": 1},
                }) + "\n")
            result = subprocess.run(
                [sys.executable, MODULE_PATH, root], text=True, capture_output=True, check=True
            )
            self.assertNotIn(nested_role, result.stdout)
            self.assertNotIn(nested_model, result.stdout)
            self.assertIn("gpt-5.6-terra", result.stdout)


if __name__ == "__main__":
    unittest.main()
