> **Doc Class:** Core Resource
> **Canonical Source:** Kamigotchi on-chain state (Yominet) and official contracts repository (`Asphodel-OS/kamigotchi`).
> **Freshness Rule:** Update this table whenever canonical values are changed, added, or re-verified.

# Data Provenance and Freshness

Use this page as the freshness authority for mutable game and protocol datasets.

| Domain | Canonical source | How to verify now | Where mirrored in docs | Owner | Last verified (date + commit/hash) |
|---|---|---|---|---|---|
| Item registry tables | On-chain registry components + `packages/contracts/deployment/world/data/items/items.csv` in official repo | Compare live registry reads with upstream CSV definitions | [references/game-data.md](game-data.md) | Docs maintainers | 2026-03-05 / `Asphodel-OS/kamigotchi@6412311f` |
| Room and node tables | On-chain room/node components + `packages/contracts/deployment/world/data/rooms/*.csv` | Query room/node component state and compare with upstream data files | [references/game-data.md](game-data.md) | Docs maintainers | 2026-03-05 / `Asphodel-OS/kamigotchi@6412311f` |
| Skill tables | On-chain skill registry + `packages/contracts/deployment/world/data/skills/skills.csv` | Query registry entries by index and compare tier/cost/effect fields | [references/game-data.md](game-data.md), [player-api/skills-and-relationships.md](../player-api/skills-and-relationships.md) | Docs maintainers | 2026-03-05 / `Asphodel-OS/kamigotchi@6412311f` |
| Quest tables | On-chain quest registry + `packages/contracts/deployment/world/data/quests/quests.csv` | Query quest registry indices and validate objective/reward metadata | [references/game-data.md](game-data.md), [player-api/quests.md](../player-api/quests.md) | Docs maintainers | 2026-03-05 / `Asphodel-OS/kamigotchi@6412311f` |
| Contract addresses | Yominet deployed contracts + World component lookups | Resolve addresses through World and compare with explorer/deployment references | [contracts/live-addresses.md](../contracts/live-addresses.md), [chain-configuration.md](../chain-configuration.md) | Docs maintainers | 2026-03-05 / Yominet + `Asphodel-OS/kamigotchi@6412311f` |
| System IDs and ABIs | `packages/contracts/src/systems/` in official repo + deployed system resolution | Hash system IDs, resolve addresses on-chain, and compare function signatures to source ABIs | [contracts/ids-and-abis.md](../contracts/ids-and-abis.md), [player-api/](../player-api/overview.md) | Docs maintainers | 2026-03-05 / `Asphodel-OS/kamigotchi@6412311f` |
| Marketplace entities/listings/offers | On-chain marketplace components + Kamiden indexer schemas | Validate event/component fields against indexer responses and source structs | [player-api/marketplace.md](../player-api/marketplace.md), [player-api/indexer.md](../player-api/indexer.md) | Docs maintainers | 2026-03-05 / `Asphodel-OS/kamigotchi@6412311f` |
| Indexer endpoints and proto contracts | Kamiden service definitions and generated proto clients in official repo | Re-generate or diff proto/client definitions against documented methods | [player-api/indexer.md](../player-api/indexer.md) | Docs maintainers | 2026-03-05 / `Asphodel-OS/kamigotchi@6412311f` |
