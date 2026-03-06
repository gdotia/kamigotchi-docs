> **Doc Class:** Core Resource
> **Canonical Source:** This page is a short player entrypoint into the canonical Core Resources linked below.
> **Freshness Rule:** Keep this page brief and link-driven; mutable network values and marketplace behavior must stay canonical in the linked Core pages.

# Player Quick Start

This is the shortest manual path from a fresh wallet to a playable Kamigotchi account.

Use the linked Core pages for canonical network details, bridge notes, and marketplace behavior.

> **Building a bot or agent?** This guide is for browser players. See [Agent Bootstrap](../guidance/agent-bootstrap.md) instead.

## 1) Open the Game

Go to [kamigotchi.io](https://kamigotchi.io).

## 2) Connect a Wallet That Can Use Yominet

Use a supported EVM wallet such as MetaMask or Rabby.

For the current Yominet network settings and wallet setup notes, see [Chain Configuration](chain-configuration.md).

## 3) Get ETH onto Yominet

There is no faucet on Yominet. Bridge at least **0.01 ETH** to cover registration gas and your first Kami purchase.

Use one of these routes:

1. **In-game bridge (recommended):** Open Kamigotchi, then go to **Settings > Bridge**. See [Chain Configuration - Option 1: Kamigotchi In-Game Bridge](chain-configuration.md#option-1-kamigotchi-in-game-bridge-recommended).
2. **Official Initia Bridge:** Use [app.initia.xyz](https://app.initia.xyz/?openBridge=true). See [Chain Configuration - Option 2: Initia Bridge](chain-configuration.md#option-2-initia-bridge).

For source chain support and current network details, see [Chain Configuration](chain-configuration.md).

## 4) Register Your Account

Open the game, choose an account name (1-15 ASCII characters), and complete registration using your **Owner wallet**.

## 5) Buy Your First Kami

Use KamiSwap to buy your first Kami with your **Owner wallet** (native ETH) and start playing. New accounts (within 24 hours of registration) may also use the **Newbie Vendor** for a one-time discounted Kami purchase.

For trading behavior and buy flow details, see [KamiSwap Marketplace](player-api/marketplace.md).

## Next Paths

- If you want to automate instead of play manually, use [Agent Bootstrap](../guidance/agent-bootstrap.md).
- For the full reference layer, start from [Core Resources](README.md).

## What To Do After Buying Your Kami

1. **Start harvesting** — Send your Kami to a harvest node to earn $MUSU. See [Harvesting](player-api/harvesting.md).
2. **Level up** — Spend earned XP to level your Kami and allocate skill points. See [Kami](player-api/kami.md).
3. **Explore** — Move between rooms, complete quests, trade with other players.

### Wallet Roles

- **Owner wallet** — Registers your account, buys Kamis on KamiSwap, and handles privileged actions.
- **Operator wallet** — Handles routine gameplay (harvesting, trading, crafting). Auto-created by Privy for browser players.
