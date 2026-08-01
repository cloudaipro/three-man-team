#!/usr/bin/env python3
"""Validate the repository's skills-only Codex plugin release contract."""

from __future__ import print_function

import json
import re
import sys


def normalized_release_version(version):
    return version[1:] if version.startswith("v") else version


def validate_manifest(manifest, latest_version):
    expected = normalized_release_version(latest_version)
    errors = []
    if manifest.get("name") != "three-man-team":
        errors.append("plugin name must be three-man-team")
    version = manifest.get("version")
    pattern = r"^" + re.escape(expected) + r"(?:\+codex\.[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$"
    if not isinstance(version, str) or re.fullmatch(pattern, version) is None:
        errors.append(
            "plugin version must equal {0} or {0}+codex.<cachebuster>".format(expected)
        )
    if manifest.get("skills") != "./skills/":
        errors.append("plugin skills path must be ./skills/")
    if "apps" in manifest:
        errors.append("skills-only plugin must not declare apps")
    prompts = manifest.get("interface", {}).get("defaultPrompt", [])
    if not isinstance(prompts, list) or len(prompts) > 3:
        errors.append("plugin interface must contain at most three starter prompts")
    return errors


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    if len(argv) != 2:
        print("Usage: check-codex-plugin.py <plugin.json> <latest-version>", file=sys.stderr)
        return 2
    manifest_path, latest_version = argv
    try:
        with open(manifest_path, encoding="utf-8") as handle:
            manifest = json.load(handle)
    except (OSError, ValueError) as error:
        print("Cannot read plugin manifest: {0}".format(error), file=sys.stderr)
        return 1
    errors = validate_manifest(manifest, latest_version)
    if errors:
        for error in errors:
            print("✗ {0}".format(error))
        return 1
    print("  ✓ Codex plugin manifest matches release and skills-only contract")
    return 0


if __name__ == "__main__":
    sys.exit(main())
