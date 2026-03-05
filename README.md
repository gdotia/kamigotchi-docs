# Kamigotchi Technical Documentation

Welcome to the **Kamigotchi** developer documentation. Kamigotchi is a fully on-chain game built on the [MUD Entity Component System](https://mud.dev/) framework, deployed on **Yominet** — an Initia L2 rollup.
This documentation covers the smart contract architecture, chain configuration, and the complete Player API for integrating with Kamigotchi.

---

## 📖 Table of Contents

### Getting Started

- [Architecture Overview](architecture.md) — MUD ECS design, World contract, Systems, Components, and Entities
- [Chain Configuration](chain-configuration.md) — Yominet network details, RPC, gas, wallets, and bridging
- [Integration Guide](integration-guide.md) — Step-by-step setup for third-party developers
- [Agent Bootstrap](agent-bootstrap.md) — Copy-paste setup path for a first-time agent/bot script
- [Entity Discovery](player-api/entity-discovery.md) — How to find and derive entity IDs for gameplay

### Contracts

- [Live Addresses](contracts/live-addresses.md) — Deployed contract addresses
- [System IDs & ABIs](contracts/ids-and-abis.md) — All 67 system IDs and ABI reference

### Player API

- [Overview & Setup](player-api/overview.md) — SDK setup, wallet model, and calling conventions
- [Echo](player-api/echo.md) — Force-emit Kami and Room data
- [Kami](player-api/kami.md) — Level, name, sacrifice, items, equipment, skills
- [Account](player-api/account.md) — Register, move, settings, chat
- [Harvesting](player-api/harvesting.md) — Start, stop, collect, liquidate
- [Quests](player-api/quests.md) — Accept and complete quests
- [Trading](player-api/trading.md) — Create, execute, complete, cancel trades
- [Social / Friends](player-api/social.md) — Friend requests, accept, cancel, block
- [Items & Crafting](player-api/items-and-crafting.md) — Burn, craft, use, transfer, droptable reveal
- [Merchant Listings](player-api/listings.md) — Buy from and sell to NPC merchants
- [Skills & Relationships](player-api/skills-and-relationships.md) — Skill upgrade/reset, NPC relationship advancement
- [Goals & Scavenge](player-api/goals-and-scavenge.md) — Community goals, scavenge claims
- [Gacha / Minting](player-api/minting.md) — Mint, reveal, reroll Kamis; buy tickets
- [KamiSwap Marketplace](player-api/marketplace.md) — List, buy, offer, and trade Kamis on the in-game marketplace
- [Kamiden Indexer](player-api/indexer.md) — Off-chain gRPC indexer for marketplace listings, history, and real-time events
- [Portal (ERC721 / ERC20)](player-api/portal.md) — Deposit/withdraw NFTs and tokens

### References

- [Game Data Reference](references/game-data.md) — Lookup tables for items, rooms, nodes, skills, and quests
- [Common Errors](references/common-errors.md) — Common revert reasons by system

---

## 🔑 Key Concepts

| Concept | Description |
|---------|-------------|
| **World** | The MUD root contract. All systems register here. |
| **System** | A stateless contract that mutates component state via the World. |
| **Entity** | A `uint256` ID representing any game object (Kami, account, item, etc.). |
| **Component** | On-chain storage keyed by entity ID (e.g., `HealthComponent`, `PowerComponent`). |
| **Owner Wallet** | The player's main wallet — holds NFTs, registers accounts, spends $ONYX. |
| **Operator Wallet** | A delegated wallet for frequent in-game transactions (abstracted via Privy). |

---

## 🔗 Quick Links

| Resource | URL |
|----------|-----|
| Game | [kamigotchi.io](https://kamigotchi.io) |
| Block Explorer | [scan.initia.xyz/yominet-1](https://scan.initia.xyz/yominet-1) |
| World Contract | [`0x2729174c265dbBd8416C6449E0E813E88f43D0E7`](https://scan.initia.xyz/yominet-1/address/0x2729174c265dbBd8416C6449E0E813E88f43D0E7) |

---

## 📋 Glossary

| Term | Description |
|------|-------------|
| **Entity ID** (`uint256`) | A large numeric identifier for any game object (Kami, account, item, room, etc.). Generated deterministically via hashing. |
| **Index** (`uint32`) | A small positional index within a list (e.g., Kami index in an account, item index in the registry, room index in the world). |
| **Owner Wallet** | The player's primary wallet that holds NFTs and has admin privileges (register account, spend $ONYX, stake/unstake). |
| **Operator Wallet** | A delegated wallet for routine gameplay actions (move, harvest, equip, quest). Set via `system.account.set.operator`. |
| **System ID** | A human-readable string identifier for a game system (e.g., `system.kami.level`, `system.harvest.start`). Hashed with `keccak256` for on-chain lookup in the World contract. |
