> **Doc Class:** Agent Guidance
> **Canonical Source:** Repository contribution policy maintained in this file.
> **Freshness Rule:** Keep policy aligned with `README.md`, `core-resources.md`, and `references/data-provenance.md`.

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
- Update to [data-provenance.md](references/data-provenance.md) `Last verified` field

## PR Checklist

- [ ] Did you choose the correct `Doc Class`?
- [ ] If Core changed, did you update provenance metadata?
- [ ] Did you avoid duplicating canonical data in Guidance?
- [ ] Did you keep links valid?

## Validation Expectations

Before merge:

- Run the documentation validator:

```bash
./tools/validate-docs.sh
```

This validates:

- Relative markdown links.
- Exactly one `Doc Class` line per markdown file.
- Allowed `Doc Class` values.
- Core boundary spot-check for workflow-only scheduling language.
