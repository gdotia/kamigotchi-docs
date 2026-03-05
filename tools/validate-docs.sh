#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mapfile -t md_files < <(rg --files -g '*.md' | sort)

echo "[1/3] Checking Doc Class metadata..."
for f in "${md_files[@]}"; do
  count=$(rg -n '^> \*\*Doc Class:\*\*' "$f" | wc -l | tr -d ' ')
  if [[ "$count" -ne 1 ]]; then
    echo "FAIL: $f has $count Doc Class lines (expected 1)"
    exit 1
  fi

  class_value=$(rg -n '^> \*\*Doc Class:\*\*' "$f" | head -n1 | sed -E 's/^.*Doc Class:\*\* //')
  if [[ "$class_value" != "Core Resource" && "$class_value" != "Agent Guidance" ]]; then
    echo "FAIL: $f has invalid Doc Class '$class_value'"
    exit 1
  fi
done

echo "[2/3] Checking markdown relative links..."
node - <<'NODE'
const fs = require('fs');
const path = require('path');

function walk(dir) {
  const out = [];
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    if (ent.name === '.git' || ent.name === 'node_modules') continue;
    const p = path.join(dir, ent.name);
    if (ent.isDirectory()) out.push(...walk(p));
    else if (ent.isFile() && p.endsWith('.md')) out.push(p);
  }
  return out;
}

const root = process.cwd();
const files = walk(root);
const bad = [];
const mdLinkRe = /\[[^\]]+\]\(([^)]+)\)/g;

for (const file of files) {
  let txt = fs.readFileSync(file, 'utf8');
  txt = txt.replace(/```[\s\S]*?```/g, '');

  let m;
  while ((m = mdLinkRe.exec(txt)) !== null) {
    const raw = m[1].trim();
    if (!raw) continue;
    if (raw.startsWith('http://') || raw.startsWith('https://') || raw.startsWith('mailto:')) continue;
    if (raw.startsWith('#')) continue;

    let target = raw.split(/[?#]/)[0];
    if (!target) continue;
    target = target.replace(/^<|>$/g, '');

    const resolved = path.resolve(path.dirname(file), target);
    if (!fs.existsSync(resolved)) {
      bad.push({ file: path.relative(root, file), target: raw });
    }
  }
}

if (bad.length) {
  console.error('FAIL: Broken relative links found:');
  for (const b of bad) console.error(`  ${b.file} -> ${b.target}`);
  process.exit(1);
}
NODE

echo "[3/3] Spot-checking Core boundary language..."
mapfile -t core_files < <(rg -l '^> \*\*Doc Class:\*\* Core Resource' -g '*.md' | sort)
if [[ "${#core_files[@]}" -gt 0 ]]; then
  # Allow policy language in core-resources.md; block workflow scheduling language everywhere else.
  boundary_hits=$(rg -n "cron|run every morning|every morning|daily automation|scheduled job" -i "${core_files[@]}" || true)
  if [[ -n "$boundary_hits" ]]; then
    disallowed_hits=$(printf "%s\n" "$boundary_hits" | rg -v '^core-resources\.md:' || true)
    if [[ -n "$disallowed_hits" ]]; then
      echo "FAIL: Potential workflow-only scheduling guidance found in Core docs:"
      printf "%s\n" "$disallowed_hits"
      exit 1
    fi
  fi
fi

echo "PASS: Documentation checks succeeded (${#md_files[@]} markdown files)."
