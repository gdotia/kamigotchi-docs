# Kamigotchi Technical Documentation

Welcome to the **Kamigotchi** developer documentation. Kamigotchi is a fully on-chain pet-raising game built on the [MUD Entity Component System](https://mud.dev/) framework, deployed on **Yominet** — an Initia L2 rollup powered by OP Stack and Celestia DA.

This documentation covers the smart contract architecture, chain configuration, and the complete Player API for integrating with Kamigotchi.

---

## 📖 Table of Contents

### Getting Started

- [Architecture Overview](architecture.md) — MUD ECS design, World contract, Systems, Components, and Entities
- [Chain Configuration](chain-configuration.md) — Yominet network details, RPC, gas, wallets, and bridging
- [Integration Guide](integration-guide.md) — Step-by-step setup for third-party developers

### Contracts

- [Live Addresses](contracts/live-addresses.md) — Deployed contract addresses (testnet & mainnet)
- [System IDs & ABIs](contracts/ids-and-abis.md) — All 55 system IDs and ABI reference

### Player API

- [Overview & Setup](player-api/overview.md) — SDK setup, wallet model, and calling conventions
- [Echo](player-api/echo.md) — Force-emit Kami and Room data
- [Kami (Pets)](player-api/kami.md) — Level, name, sacrifice, items, equipment, skills
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
- [Portal (ERC721 / ERC20)](player-api/portal.md) — Deposit/withdraw NFTs and tokens

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
| World Contract (Testnet) | [`0x2729174c265dbBd8416C6449E0E813E88f43D0E7`](https://scan.initia.xyz/yominet-1/address/0x2729174c265dbBd8416C6449E0E813E88f43D0E7) |

---

> **Note:** Items marked with ⚠️ TBD require verification from the Asphodel team. If you encounter discrepancies, please reach out to the team for clarification.
