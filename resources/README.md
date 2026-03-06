> **Doc Class:** Core Resource
> **Canonical Source:** Kamigotchi on-chain contracts on Yominet plus the official contracts repository (`Asphodel-OS/kamigotchi`).
> **Freshness Rule:** Any mutable value change must be verified against canonical sources and logged in `resources/references/data-provenance.md`.

# Core Resources

This section is the canonical reference layer.

Use Core Resources for:

- Contract addresses, system IDs, ABIs
- Chain/network configuration
- On-chain mechanics and protocol behavior
- Game registries and index tables
- Error semantics and entity derivation

## Core Index

### Entry Points

- [Player Quick Start](player-quick-start.md)

### Protocol and Network

- [Architecture Overview](architecture.md)
- [Chain Configuration](chain-configuration.md)
- [Live Addresses](contracts/live-addresses.md)
- [System IDs & ABIs](contracts/ids-and-abis.md)

### Player API (Canonical Interface Reference)

**Foundation:**

- [Overview & Setup](player-api/overview.md)
- [Entity Discovery](player-api/entity-discovery.md)
- [Echo](player-api/echo.md)

**Account & Kami:**

- [Account](player-api/account.md)
- [Kami](player-api/kami.md)
- [Skills & Relationships](player-api/skills-and-relationships.md)

**Gameplay:**

- [Harvesting](player-api/harvesting.md)
- [Quests](player-api/quests.md)
- [Goals & Scavenge](player-api/goals-and-scavenge.md)

**Economy:**

- [Items & Crafting](player-api/items-and-crafting.md)
- [Trading](player-api/trading.md)
- [Merchant Listings](player-api/listings.md)
- [KamiSwap Marketplace](player-api/marketplace.md)
- [Gacha / Minting](player-api/minting.md)

**Infrastructure:**

- [Kamiden Indexer](player-api/indexer.md)
- [Portal (ERC721 / ERC20)](player-api/portal.md)
- [Social / Friends](player-api/social.md)

### References & Lookup Tables

- [Game Data Reference](references/game-data.md) — Items, skills, rooms, quests, equipment, traits
- [Common Errors](references/common-errors.md) — Revert strings indexed by system
- [Data Provenance & Freshness](references/data-provenance.md) — Verification timestamps and canonical sources

## Scope Boundary

Core must not include prescriptive automation policy (cron schedules, "run every morning" directives, or bot strategy playbooks).
