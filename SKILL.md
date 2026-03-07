---
name: kamigotchi-docs
description: Use this skill when the user wants to build or debug a Kamigotchi bot, integrate with Kamigotchi smart contracts on Yominet, bootstrap a new owner/operator setup, resolve ECS systems or entity IDs, or find canonical game data and revert semantics.
---
> **Doc Class:** Agent Guidance
> **Canonical Source:** Derived from Core Resources in this repo and canonical sources listed in `resources/references/data-provenance.md`.
> **Freshness Rule:** Do not become source-of-truth for canonical values; link back to Core Resources for addresses, IDs, and tables.

# Kamigotchi Docs

Use this repo as the working guide for Kamigotchi integrations. Start in Guidance for workflows, then pull exact values from Core Resources before you write or change code.

## Start Here

- **New agent from a Base-funded owner wallet:** [Agent Bootstrap](guidance/agent-bootstrap.md)
- **Low-level contract integration:** [Integration Guide](guidance/integration-guide.md)
- **System IDs and ABIs:** [System IDs & ABIs](resources/contracts/ids-and-abis.md)
- **Entity IDs and registry lookups:** [Entity Discovery](resources/player-api/entity-discovery.md)
- **Revert debugging:** [Common Errors](resources/references/common-errors.md)
- **Item, skill, room, quest, and trait indices:** [Game Data Reference](resources/references/game-data.md)

## Documentation Contract

- `resources/` is canonical for addresses, IDs, ABIs, mechanics, and lookup tables.
- `guidance/` explains workflows, runnable examples, and helper tooling.
- If Guidance mentions a mutable value, verify it in the linked Core page before relying on it.

## Default Workflow

1. Start with [Agent Bootstrap](guidance/agent-bootstrap.md) if the user is going from zero to a working account and first Kami.
2. Use [Integration Guide](guidance/integration-guide.md) for wallet setup, system resolution, and transaction patterns.
3. Pull exact contract details from [System IDs & ABIs](resources/contracts/ids-and-abis.md) and [Live Addresses](resources/contracts/live-addresses.md).
4. Use [Entity Discovery](resources/player-api/entity-discovery.md) whenever token indices, entity IDs, and returned `bytes` values might be confused.
5. Use [Common Errors](resources/references/common-errors.md) before changing code in response to a revert.

## Protocol Rules That Matter

- The World contract is a registry, not a router. Resolve systems, then call system contracts directly.
- Kamigotchi uses a dual-wallet model: Owner for registration and privileged actions, distinct Operator for routine gameplay.
- There is no faucet on Yominet. Agent bootstrap flows must bridge or otherwise fund real ETH.
- Some systems use named functions instead of `execute()`. Check [System IDs & ABIs](resources/contracts/ids-and-abis.md) before assuming a standard entrypoint.
- Kami token indices and Kami entity IDs are different values. Use [Entity Discovery](resources/player-api/entity-discovery.md) when converting between them.

## More Detail

Open [LLM_USAGE.md](LLM_USAGE.md) when you need the full navigation and workflow guide for LLM-driven work in this repo.
