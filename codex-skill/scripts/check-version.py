#!/usr/bin/env python3
"""Three Man Team — offline Codex version check and acknowledgement.

Usage:
  check-version.py <project-dir>
  check-version.py <project-dir> --acknowledge <version>

The registry is newest-first. Reports are deliberately oldest-first so an
Architect can walk a project's missed releases in the order they shipped.
"""

from __future__ import print_function

import argparse
import json
import os
import sys
import tempfile

SKILL_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def candidate_paths():
    """Return registry locations, allowing tests to supply an isolated copy."""
    override = os.environ.get("TMT_RELEASES_PATH")
    paths = []
    if override:
        paths.append(override)
    paths.extend([
        os.path.join(SKILL_DIR, "releases", "latest.json"),
        os.path.join(SKILL_DIR, "..", "..", "releases", "latest.json"),
        os.path.join(SKILL_DIR, "..", "releases", "latest.json"),
    ])
    return paths


def read_marker(path, key):
    if not os.path.exists(path):
        return None
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            if line.startswith(key + ":"):
                return line.split(":", 1)[1].strip() or None
    return None


def get_local_version(project_dir):
    return read_marker(os.path.join(project_dir, "manifest.md"), "version")


def get_notified_version(project_dir):
    return read_marker(
        os.path.join(project_dir, "handoff", "SESSION-CHECKPOINT.md"),
        "version_notified",
    )


def get_latest_release():
    for path in candidate_paths():
        resolved = os.path.abspath(path)
        if os.path.exists(resolved):
            with open(resolved, encoding="utf-8") as handle:
                return json.load(handle)
    return None


def missed_releases(versions, local_version, notified_version):
    """Return newer releases in chronological order.

    A notification can be newer than the installed manifest after the user has
    completed an update walk but intentionally kept their manifest unchanged.
    """
    positions = {release.get("version"): index for index, release in enumerate(versions)}
    baseline = local_version
    if notified_version in positions and (
            baseline not in positions or positions[notified_version] < positions[baseline]):
        baseline = notified_version

    if baseline in positions:
        return list(reversed(versions[:positions[baseline]])), baseline
    return list(reversed(versions)), baseline


def write_acknowledgement(project_dir, version):
    checkpoint_dir = os.path.join(project_dir, "handoff")
    checkpoint_path = os.path.join(checkpoint_dir, "SESSION-CHECKPOINT.md")
    os.makedirs(checkpoint_dir, exist_ok=True)

    lines = []
    if os.path.exists(checkpoint_path):
        with open(checkpoint_path, encoding="utf-8") as handle:
            lines = handle.readlines()

    replaced = False
    for index, line in enumerate(lines):
        if line.startswith("version_notified:"):
            lines[index] = "version_notified: {0}\n".format(version)
            replaced = True
            break

    if not replaced:
        if lines and not lines[-1].endswith("\n"):
            lines[-1] += "\n"
        if lines and lines[-1].strip():
            lines.append("\n")
        lines.extend(["## Version Check\n", "version_notified: {0}\n".format(version)])

    descriptor, temporary_path = tempfile.mkstemp(
        prefix=".SESSION-CHECKPOINT.", dir=checkpoint_dir, text=True
    )
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            handle.writelines(lines)
        os.replace(temporary_path, checkpoint_path)
    except Exception:
        try:
            os.unlink(temporary_path)
        except OSError:
            pass
        raise


def main(argv=None):
    parser = argparse.ArgumentParser(description="Check or acknowledge Three Man Team releases.")
    parser.add_argument("project_dir")
    parser.add_argument("--acknowledge", metavar="VERSION")
    args = parser.parse_args(argv)

    latest = get_latest_release()
    if not latest:
        print("Release registry not found in any expected location.")
        return 0

    versions = latest.get("versions", [])
    latest_version = latest.get("latest", "")
    version_names = {release.get("version") for release in versions}
    local_version = get_local_version(args.project_dir)
    notified_version = get_notified_version(args.project_dir)

    if args.acknowledge:
        if args.acknowledge not in version_names:
            print("Cannot acknowledge unknown release: {0}".format(args.acknowledge), file=sys.stderr)
            return 1
        write_acknowledgement(args.project_dir, args.acknowledge)
        print("Acknowledged releases through {0}.".format(args.acknowledge))
        return 0

    if not local_version:
        print("Current version: unknown (no manifest.md)")
        print("Latest available: {0}".format(latest_version))
        print("Run setup-project.sh to create a manifest.")
        return 0

    missed, baseline = missed_releases(versions, local_version, notified_version)
    if not missed:
        suffix = ""
        if notified_version and notified_version != local_version:
            suffix = " (updates acknowledged through {0})".format(notified_version)
        print("Current version: {0} — up to date{1}".format(local_version, suffix))
        return 0

    for release in missed:
        flag = " [CRITICAL]" if release.get("critical") else ""
        print("  {0} — released {1}{2}".format(
            release.get("version", "unknown"), release.get("released", "unknown"), flag
        ))
    print("\nCurrent version: {0}".format(local_version))
    if baseline and baseline != local_version:
        print("Previously acknowledged through: {0}".format(baseline))
    print("Latest available: {0}".format(latest_version))
    print("Read each bundled release file, apply the relevant changes, then run:")
    print("  check-version.py {0} --acknowledge {1}".format(args.project_dir, latest_version))
    return 0


if __name__ == "__main__":
    sys.exit(main())
