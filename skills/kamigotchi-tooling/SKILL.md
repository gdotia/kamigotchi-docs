---
name: kamigotchi-tooling
description: Use this skill when the task is building Kamigotchi bots, scripts, market or indexer tools, state readers, or contract-integration helpers. It routes to focused references for bootstrap, on-chain calls, entities, marketplace flows, and Kamiden usage.
---
> **Doc Class:** Agent Guidance
> **Canonical Source:** Derived from Core Resources in this repo and canonical sources listed in `../../resources/references/data-provenance.md`.
> **Freshness Rule:** Do not become source-of-truth for canonical values; link back to Core Resources for addresses, IDs, and tables.

# Kamigotchi Tooling Skill

Route yourself to the right reference based on your task. No scripts or templates are included — follow the links to the reference files and the canonical docs they point to.

For broader repo navigation, start with [../../SKILL.md](../../SKILL.md) or [../../LLM_USAGE.md](../../LLM_USAGE.md).

## Workflow by Task

### Bootstrap or Environment Setup

**You need:** owner/operator wallet model, bridge path, runtime env vars, smoke-test order.

→ Read [references/bootstrap-and-wallets.md](references/bootstrap-and-wallets.md)

Then follow the [Agent Bootstrap](../../guidance/agent-bootstrap.md) for the shortest end-to-end path from a Base-funded wallet to a registered account with a first Kami.

---

### On-Chain Tool Building

**You need:** system resolution, getter/value component reads, entity ID derivation, wallet selection, non-standard entry points.

→ Read [references/onchain-calls-and-entities.md](references/onchain-calls-and-entities.md)

Then refer to [Player API Overview](../../resources/player-api/overview.md) for the full system-call pattern and [Entity Discovery](../../resources/player-api/entity-discovery.md) for all entity derivation formulas.

---

### Marketplace or Indexer Tooling

**You need:** Kamiden gRPC setup, listing discovery, non-deterministic order IDs, buy/list/offer data flow.

→ Read [references/marketplace-and-indexer.md](references/marketplace-and-indexer.md)

Then refer to [KamiSwap Marketplace](../../resources/player-api/marketplace.md) and [Kamiden Indexer](../../resources/player-api/indexer.md) for full API details.

---

## Out of Scope for This Skill

- Gameplay loop automation or strategy (cron schedules, harvest optimization)
- No bootstrap or template scripts are provided — build from the reference files above
- Contract addresses and system IDs: always read from [Live Addresses](../../resources/contracts/live-addresses.md) and [System IDs & ABIs](../../resources/contracts/ids-and-abis.md)
