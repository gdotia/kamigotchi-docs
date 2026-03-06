#!/usr/bin/env bash
# validate-docs.sh — Documentation quality gatekeeper for kamigotchi-docs
#
# Three-stage validation:
#   Stage 1: Verify every .md file has exactly one Doc Class (Core Resource or Agent Guidance)
#   Stage 2: Check all relative markdown links resolve to existing files
#   Stage 3: Spot-check Core Resource files for workflow-only scheduling language
#
# Usage: ./guidance/tools/validate-docs.sh
# Exit:  0 on success, 1 on any validation failure
# Requires: python3
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

python3 - <<'PY'
from pathlib import Path
import os
import re
import sys

root = Path.cwd()
doc_class_re = re.compile(r"^> \*\*Doc Class:\*\* (.+)$", re.MULTILINE)
# Matches inline links: [text](url)
link_re = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
# Matches fenced code blocks for exclusion from link checking
code_fence_re = re.compile(r"```[\s\S]*?```")
# Scheduling/workflow language that should not appear in Core Resource docs
boundary_re = re.compile(r"cron|run every morning|every morning|daily automation|scheduled job", re.IGNORECASE)

md_files = sorted(
    path for path in root.rglob("*.md")
    if ".git" not in path.parts and "node_modules" not in path.parts
)

print("[1/3] Checking Doc Class metadata...")
core_files = []
for path in md_files:
    rel = path.relative_to(root).as_posix()
    text = path.read_text(encoding="utf-8")
    matches = doc_class_re.findall(text)
    if len(matches) != 1:
        print(f"FAIL: {rel} has {len(matches)} Doc Class lines (expected 1)")
        sys.exit(1)

    class_value = matches[0]
    if class_value not in {"Core Resource", "Agent Guidance"}:
        print(f"FAIL: {rel} has invalid Doc Class '{class_value}'")
        sys.exit(1)

    if class_value == "Core Resource":
        core_files.append(path)

print("[2/3] Checking markdown relative links...")
broken = []
for path in md_files:
    rel = path.relative_to(root).as_posix()
    text = code_fence_re.sub("", path.read_text(encoding="utf-8"))
    for match in link_re.finditer(text):
        raw = match.group(1).strip()
        if not raw or raw.startswith(("http://", "https://", "mailto:", "#")):
            continue

        target = re.split(r"[?#]", raw, maxsplit=1)[0].strip()
        target = target.strip("<>")
        if not target:
            continue

        resolved = Path(os.path.normpath(path.parent / target))
        if not resolved.exists():
            broken.append((rel, raw))

if broken:
    print("FAIL: Broken relative links found:")
    for rel, raw in broken:
        print(f"  {rel} -> {raw}")
    sys.exit(1)

print("[3/3] Spot-checking Core boundary language...")
violations = []
for path in core_files:
    rel = path.relative_to(root).as_posix()
    if rel == "resources/README.md":
        continue
    text = path.read_text(encoding="utf-8")
    if boundary_re.search(text):
        violations.append(rel)

if violations:
    print("FAIL: Potential workflow-only scheduling guidance found in Core docs:")
    for rel in violations:
        print(f"  {rel}")
    sys.exit(1)

print(f"PASS: Documentation checks succeeded ({len(md_files)} markdown files).")
PY
