> **Doc Class:** Agent Guidance
> **Canonical Source:** Derived from Core Resources in this repo and canonical sources listed in `references/data-provenance.md`.
> **Freshness Rule:** Do not become source-of-truth for canonical values; link back to Core Resources for addresses, IDs, and tables.

# CLAUDE.md

## Purpose

Agent developer documentation for Kamigotchi — a fully on-chain virtual pet game built on MUD/solecs ECS framework, deployed on Yominet (Initia L2 rollup).

## Repo Structure

- `contracts/` — System IDs, ABIs, component IDs, live deployed addresses
- `player-api/` — 16 endpoint docs covering all player-facing systems (account, kami, harvesting, trading, gacha, etc.)
- `references/` — Common revert errors, game data tables (items, rooms, skills, quests)
- Top-level: `architecture.md`, `integration-guide.md`, `agent-bootstrap.md`, `chain-configuration.md`

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

- Each `player-api/` doc covers: wallet type, function signature, parameters, common errors
- `contracts/ids-and-abis.md`: non-standard entry points listed per system
- `references/common-errors.md`: revert strings grouped by system domain
- World contract: `0x2729174c265dbBd8416C6449E0E813E88f43D0E7`
