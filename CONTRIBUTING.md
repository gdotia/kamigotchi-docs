> **Doc Class:** Agent Guidance
> **Canonical Source:** Repository contribution policy maintained in this file.
> **Freshness Rule:** Keep policy aligned with `README.md`, `resources/README.md`, and `resources/references/data-provenance.md`.

# Contributing

This repo uses a strict two-section model:

1. **Core Resources** (canonical protocol/game reference)
2. **Agent Guidance** (optional implementation workflows)

## Placement Rules

- Put canonical data in Core Resources.
- Put setup flows, runnable examples, and operational tooling in Agent Guidance.
- Do not place strategy/cron scheduling guidance in Core.
- Do not duplicate canonical numeric tables, addresses, or IDs in Guidance.

## Core Change Requirements

When changing Core pages, include all of the following in the same PR:

- Source citation (on-chain or upstream repo path)
- Verification timestamp
- Update to [data-provenance.md](resources/references/data-provenance.md) `Last verified` field

## PR Checklist

- [ ] Did you choose the correct `Doc Class`?
- [ ] If Core changed, did you update provenance metadata?
- [ ] Did you avoid duplicating canonical data in Guidance?
- [ ] Did you keep links valid?

## Validation Expectations

Before merge:

- Run the documentation validator:

```bash
./guidance/tools/validate-docs.sh
```

This validates:

- Relative markdown links.
- Exactly one `Doc Class` line per markdown file.
- Allowed `Doc Class` values.
- Core boundary spot-check for workflow-only scheduling language.

## Git Workflow

1. **Fork** the repository and create a feature branch from `main`.
2. **Branch naming:** `docs/topic-name` (e.g., `docs/fix-harvesting-formulas`, `docs/add-quest-rewards`).
3. **Commit messages:** Use present tense, describe what changed and why (e.g., "Add gas limit table to harvesting.md").
4. **One PR per topic** — keep changes focused. Don't mix unrelated doc updates.

## Writing Style

- Use plain, direct language. Avoid jargon unless defining it.
- Code examples should be complete and runnable (include imports).
- Use ethers.js v6 and ESM syntax in all JavaScript examples.
- Markdown formatting: ATX headings (`##`), fenced code blocks with language tags, pipe tables for structured data.
- Wallet types: use 🔐 **Owner** and 🎮 **Operator** badges consistently in API docs.

## Development Setup

```bash
# Clone and validate
git clone <your-fork-url>
cd kamigotchi-docs
./guidance/tools/validate-docs.sh
```

No build step or special tooling is required — the docs are plain Markdown files.
