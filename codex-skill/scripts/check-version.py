#!/usr/bin/env python3
"""Three Man Team — lightweight version checker.

Compares the local manifest version against the bundled releases registry.
Checks multiple locations for latest.json.

Usage:
  check-version.py <project-dir>
"""

import json
import os
import sys

SKILL_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Search order: bundled copy inside skill > repo root > next to skill
CANDIDATE_PATHS = [
    os.path.join(SKILL_DIR, "releases", "latest.json"),
    os.path.join(SKILL_DIR, "..", "..", "releases", "latest.json"),
    os.path.join(SKILL_DIR, "..", "releases", "latest.json"),
]


def get_local_version(project_dir: str) -> str | None:
    manifest_path = os.path.join(project_dir, "manifest.md")
    if os.path.exists(manifest_path):
        with open(manifest_path) as f:
            for line in f:
                if line.startswith("version:"):
                    return line.split(":", 1)[1].strip()
    return None


def get_latest_release() -> dict | None:
    for path in CANDIDATE_PATHS:
        resolved = os.path.abspath(path)
        if os.path.exists(resolved):
            with open(resolved) as f:
                return json.load(f)
    return None


def main():
    if len(sys.argv) < 2:
        print("Usage: check-version.py <project-dir>")
        sys.exit(1)

    project_dir = sys.argv[1]
    local_ver = get_local_version(project_dir)
    latest = get_latest_release()

    if not latest:
        print("Release registry not found in any expected location.")
        sys.exit(0)

    latest_ver = latest.get("latest", "")
    versions = latest.get("versions", [])

    if not local_ver:
        print(f"Current version: unknown (no manifest.md)")
        print(f"Latest available: {latest_ver}")
        print("Run setup-project.sh to create a manifest.")
        sys.exit(0)

    if local_ver == latest_ver:
        print(f"Current version: {local_ver} — up to date")
        sys.exit(0)

    updating = False
    for v in versions:
        if v["version"] == local_ver:
            updating = True
            continue
        if updating:
            flag = " [CRITICAL]" if v.get("critical") else ""
            print(f"  {v['version']} — released {v['released']}{flag}")

    print(f"\nCurrent version: {local_ver}")
    print(f"Latest available: {latest_ver}")
    print("Run the upgrade script to update.")


if __name__ == "__main__":
    main()
