> **Doc Class:** Agent Guidance
> **Canonical Source:** Derived from Core Resources in this repo and canonical sources listed in `resources/references/data-provenance.md`.
> **Freshness Rule:** Do not become source-of-truth for canonical values; link back to Core Resources for addresses, IDs, and tables.

# CLAUDE.md

## Purpose

Agent developer documentation for Kamigotchi — a fully on-chain game built on MUD/solecs ECS framework, deployed on Yominet (Initia L2 rollup).

For reusable skill metadata and general LLM navigation, see [SKILL.md](SKILL.md) and [LLM_USAGE.md](LLM_USAGE.md).

## Quick Start

First-time agents should run [Agent Bootstrap](guidance/agent-bootstrap.md) to register and acquire a first Kami, then refer to the [Integration Guide](guidance/integration-guide.md) for detailed contract interaction patterns.

### Finding the Right Doc

- **Setting up from a funded wallet:** [Agent Bootstrap](guidance/agent-bootstrap.md)
- **Detailed contract integration:** [Integration Guide](guidance/integration-guide.md)
- **Full Player API index:** [Player API Index](resources/player-api/README.md)
- **Understanding entity IDs:** [Entity Discovery](resources/player-api/entity-discovery.md)
- **Debugging a revert:** [Common Errors](resources/references/common-errors.md)
- **System IDs and ABIs:** [System IDs & ABIs](resources/contracts/ids-and-abis.md)
- **Game items, skills, rooms:** [Game Data Reference](resources/references/game-data.md)
- **Repo-local agent skills:** [AGENTS.md](AGENTS.md)

## Repo Structure

- `resources/contracts/` — System IDs, ABIs, component IDs, live deployed addresses
- `resources/player-api/` — 16 endpoint docs covering all player-facing systems (account, kami, harvesting, trading, gacha, etc.)
- `resources/references/` — Common revert errors, game data tables (items, rooms, skills, quests)
- `guidance/` — Agent bootstrap, integration guide, and helper tooling

## Key Concepts

- **ECS pattern:** World (registry) -> Systems (stateless logic) -> Components (data stores) -> Entities (uint256 IDs)
- **System resolution:** `keccak256("system.name")` -> query `SystemsComponent.getEntitiesWithValue(hash)` -> cast entity to address
- **Dual wallet model:** Owner (registration, NFT ops, spending) vs Operator (gameplay actions, delegated by owner via `system.account.set.operator`)
- **Entity IDs:** Account = `uint256(uint160(ownerAddress))`, Kami = `keccak256(abi.encodePacked("kami.id", kamiIndex))`
- **Chain:** Yominet, Chain ID `428962654539583`, ethers.js v6, ESM modules

## Verification

Official contracts: https://github.com/Asphodel-OS/kamigotchi.git (`packages/contracts/src/`)
- Systems: `src/systems/` (67 player-facing + admin prefixed with `_`)
- Components: `src/components/` (~90 files)
- Libraries: `src/libraries/` (LibItem, LibScavenge, LibAuction, etc.)
- Framework: `src/solecs/` (World, System, Component, BareComponent)

## Gotchas

- World is a REGISTRY, not a router — call system contracts directly, not through World
- Some systems use named functions instead of `execute()`: gacha `reveal()`, `reroll()`, newbie vendor `calcPrice()`
- `execute()` reverts with "not implemented" on GetterSystem, KamiGachaRevealSystem, KamiGachaRerollSystem — use their named functions
- Zero-value protection: `BareComponent._set()` reverts on zero-length values
- System IDs use dot notation: `system.account.register`, `component.value`
- PascalCase exceptions: `system.Kami721.IsInWorld`, `system.Kami721.Metadata`
- No faucet on Yominet — must bridge real ETH; fund both Owner and Operator wallets
- Components resolve via `world.components()`, NOT `world.systems()` — these are separate registries
- Stat component IDs use `component.stat.*` prefix (e.g., `component.stat.health`, not `component.health`)
- ethers.js gotcha: `Stat.shift` collides with `Array.shift()` — access stat fields by index (`h[0]`, `h[1]`, `h[2]`, `h[3]`), not by name

## Doc Conventions

- Each `resources/player-api/` doc covers: wallet type, function signature, parameters, common errors
- `resources/contracts/ids-and-abis.md`: non-standard entry points listed per system
- `resources/references/common-errors.md`: revert strings grouped by system domain
- World contract: `0x2729174c265dbBd8416C6449E0E813E88f43D0E7`
