> **Doc Class:** Agent Guidance
> **Canonical Source:** Derived from Core Resources in this repo and canonical sources listed in `resources/references/data-provenance.md`.
> **Freshness Rule:** Do not become source-of-truth for canonical values; link back to Core Resources for addresses, IDs, and tables.

# LLM Usage Guide

Instructions for LLMs using this repo as the primary Kamigotchi integration reference.

## First Load

- If your environment supports repo-backed skills, load [SKILL.md](SKILL.md) first.
- Use `guidance/` to answer workflow questions and generate runnable examples.
- Use `resources/` to answer canonical questions about addresses, ABIs, mechanics, IDs, and registries.

## Fast Routing By Task

- **Start from a funded wallet / reach first Kami quickly:** [Agent Bootstrap](guidance/agent-bootstrap.md)
- **Write low-level ethers.js integration code:** [Integration Guide](guidance/integration-guide.md)
- **Find the correct system ID, ABI, or non-standard entrypoint:** [System IDs & ABIs](resources/contracts/ids-and-abis.md)
- **Resolve entity IDs or decode returned `bytes` IDs:** [Entity Discovery](resources/player-api/entity-discovery.md)
- **Debug a revert or failed state transition:** [Common Errors](resources/references/common-errors.md)
- **Look up items, skills, rooms, quests, traits, or recipes:** [Game Data Reference](resources/references/game-data.md)
- **Check current chain/network details:** [Chain Configuration](resources/chain-configuration.md) and [Live Addresses](resources/contracts/live-addresses.md)
- **Answer manual browser-player questions:** [Player Quick Start](resources/player-quick-start.md)

## Working Rules

1. Decide whether the request is workflow-oriented or canonical.
2. Start in Guidance for workflow, but pull all mutable values from Core before finalizing an answer or script.
3. Prefer the repo's existing JavaScript style: ethers.js v6, ESM modules, and explicit Owner/Operator separation.
4. When a call fails, check the relevant Player API page and [Common Errors](resources/references/common-errors.md) before changing signatures or calldata.
5. If docs and runtime behavior appear to disagree, verify against the sources listed in [Data Provenance & Freshness](resources/references/data-provenance.md).

## Default Workflows

### Bootstrap a New Agent

1. Read [Agent Bootstrap](guidance/agent-bootstrap.md).
2. If the agent starts with ETH on Base, use [Yominet Bridge Tooling](guidance/tools/yominet-bridge/README.md).
3. Continue in [Integration Guide](guidance/integration-guide.md) once both Owner and Operator keys are available.
4. Use [Chain Configuration](resources/chain-configuration.md) and [Live Addresses](resources/contracts/live-addresses.md) for current network values.

### Build or Update Contract Scripts

1. Read [Integration Guide](guidance/integration-guide.md) for the runtime skeleton and helper patterns.
2. Pull exact IDs and ABIs from [System IDs & ABIs](resources/contracts/ids-and-abis.md).
3. Use the relevant Player API page under `resources/player-api/` for parameters, wallet role, and common errors.
4. Use [Entity Discovery](resources/player-api/entity-discovery.md) when returned IDs are encoded or when token IDs differ from entity IDs.

### Debug a Failure

1. Identify the target system and the required wallet role.
2. Check [Common Errors](resources/references/common-errors.md).
3. Confirm entity assumptions with [Entity Discovery](resources/player-api/entity-discovery.md).
4. Confirm the entrypoint shape in [System IDs & ABIs](resources/contracts/ids-and-abis.md).
5. Re-check the relevant Player API page for preconditions such as resting state, ownership, items, or balances.

## Protocol Rules That Commonly Trip Up Agents

- The World contract is a registry. Resolve systems from it, then call system contracts directly.
- Owner and Operator are different addresses in the agent flows documented here.
- There is no faucet on Yominet. Funding assumptions must be explicit.
- Some systems use named functions instead of `execute()`. Do not assume all systems share the same call shape.
- Components resolve through `world.components()`, not `world.systems()`.
- Kami entity IDs are not the same as Kami token indices.

## Output Expectations

- Prefer linking the exact doc used instead of copying large mutable tables into your response.
- Treat `guidance/` as operational help, not as the source of truth for addresses, IDs, or registries.
- When you mention live values such as addresses or indices, cite the Core page you pulled them from.
