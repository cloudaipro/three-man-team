#!/usr/bin/env python3
"""Aggregate local Codex JSONL token usage without emitting conversation content."""

import argparse
import json
import os
from pathlib import Path

TOKEN_KEYS = ("input_tokens", "cached_input_tokens", "output_tokens")
ROLE_NAMES = {"architect", "builder", "reviewer"}


def token_usage(event):
    """Return only a top-level event-envelope usage object.

    Message and response payloads are intentionally opaque: recursively looking for
    metadata there can turn user-controlled prompt text into report labels.
    """
    usage = event.get("last_token_usage") if isinstance(event, dict) else None
    return usage if isinstance(usage, dict) else None


def identify_role(event):
    for key in ("role", "agent_role", "tmt_role"):
        value = event.get(key)
        if isinstance(value, str) and value.lower() in ROLE_NAMES:
            return value.lower()
    return "unknown"


def identify_model(event):
    for key in ("model", "model_name"):
        value = event.get(key)
        if isinstance(value, str) and value:
            return value
    return "unknown"


def numbers(usage):
    result = {}
    for key in TOKEN_KEYS:
        value = usage.get(key, 0)
        if isinstance(value, bool):
            return None
        if isinstance(value, int):
            number = value
        elif isinstance(value, str) and value.isdecimal():
            number = int(value)
        else:
            return None
        if number < 0:
            return None
        result[key] = number
    return result


def audit(root):
    totals = {key: 0 for key in TOKEN_KEYS}
    roles, models, sessions, events, calls, peak_input = {}, {}, 0, 0, 0, 0
    for path in Path(root).rglob("*.jsonl"):
        last, role = None, "unknown"
        try:
            lines = path.read_text(encoding="utf-8").splitlines()
        except (OSError, UnicodeDecodeError):
            continue
        for line in lines:
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue
            events += 1
            usage = token_usage(event)
            if usage is not None:
                candidate = numbers(usage)
                if candidate is None:
                    continue
                last, role = candidate, identify_role(event)
                model = identify_model(event)
                calls += 1
                peak_input = max(peak_input, last["input_tokens"])
                models[model] = models.get(model, 0) + 1
        if last is not None:
            sessions += 1
            bucket = roles.setdefault(role, {key: 0 for key in TOKEN_KEYS})
            for key, value in last.items():
                totals[key] += value
                bucket[key] += value
    return {"sessions": sessions, "events_scanned": events, "calls": calls,
            "peak_input_tokens": peak_input, "tokens": totals, "roles": roles, "models": models,
            "cost_estimate": "unavailable: local JSONL has no authoritative price card"}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", nargs="?", default=os.path.join(os.environ.get("CODEX_HOME", os.path.expanduser("~/.codex")), "sessions"))
    args = parser.parse_args()
    report = audit(args.path)
    report["scope"] = "aggregate metadata only; prompt and response content are never emitted"
    print(json.dumps(report, indent=2, sort_keys=True))
