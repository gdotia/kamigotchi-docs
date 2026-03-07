> **Doc Class:** Agent Guidance
> **Canonical Source:** Derived from `../../../resources/player-api/marketplace.md`, `../../../resources/player-api/indexer.md`, and linked Core pages.
> **Freshness Rule:** Treat this page as a routing summary; verify mutable values in the linked Core Resources before relying on them.

# Marketplace & Indexer Reference

Key facts for building marketplace tools and using the Kamiden off-chain indexer. Full API docs: [KamiSwap Marketplace](../../../resources/player-api/marketplace.md) and [Kamiden Indexer](../../../resources/player-api/indexer.md).

## Why You Need the Indexer

On-chain marketplace listings and offers use **non-deterministic entity IDs** — you cannot enumerate them by deriving IDs client-side. Kamiden (the off-chain gRPC indexer) solves this by indexing all relevant events.

Use Kamiden to:
- Discover active listings and their order IDs
- Look up offer history and trade history
- Subscribe to real-time game events

## Kamiden Setup

**Endpoint:** `https://api.prod.kamigotchi.io` (gRPC-Web, no auth required)

**Dependencies:**
```
npm install nice-grpc-web @bufbuild/protobuf
```

**Proto stubs:** No `.proto` source files in this repo — copy pre-generated TypeScript stubs from the official client:
```bash
git clone --depth 1 https://github.com/Asphodel-OS/kamigotchi.git /tmp/kamigotchi
# Copy stubs from /tmp/kamigotchi into your project
```

**Connection:**
```javascript
import { createChannel, createClient } from "nice-grpc-web";
import { KamidenServiceDefinition } from "./proto.js";
const channel = createChannel("https://api.prod.kamigotchi.io");
const client = createClient(KamidenServiceDefinition, channel);
```

Transport: gRPC-Web (not native gRPC). Node 18+ bots use `FetchTransport` (default) — no custom transport needed.

## Listing Discovery

Listings are created by `system.kamimarket.list` (Operator). Each listing has a non-deterministic entity ID assigned on-chain. **You must use Kamiden to enumerate them** — there is no on-chain enumeration method.

Key listing facts:
- No escrow — Kami stays in the seller's wallet, marked as `LISTED` state.
- Price is in native ETH (`msg.value` at buy time).
- Listings are cancelled via `system.kamimarket.cancel` (Operator).

## Non-Deterministic Order IDs

Marketplace offers also have non-deterministic entity IDs. When accepting or cancelling an offer, you need the offer entity ID from Kamiden — you cannot derive it from the buyer address or Kami ID alone.

Workflow for buying the cheapest listing:
1. Query Kamiden for active listings sorted by price.
2. Extract the listing entity ID from the Kamiden response.
3. Call `system.kamimarket.buy` (Owner, payable) with the listing entity ID(s) and `value: price`.

## Buy / List / Offer Data Flow

| Action | System | Wallet | Payment |
|--------|--------|--------|---------|
| List Kami | `system.kamimarket.list` | Operator | None (listing fee if configured) |
| Buy listed Kami | `system.kamimarket.buy` | Owner | Native ETH (`msg.value`) |
| Make offer | `system.kamimarket.offer` | Operator | WETH approval to KamiMarketVault |
| Accept offer | `system.kamimarket.acceptoffer` | Operator | None (WETH transferred from vault) |
| Cancel listing/offer | `system.kamimarket.cancel` | Operator | None |

**KamiMarketVault address** (needed for WETH approval):
```javascript
// Resolve from ValueComponent keyed by keccak256("is.config", "KAMI_MARKET_VAULT")
const vaultKey = BigInt(ethers.keccak256(
  ethers.solidityPacked(["string","string"], ["is.config","KAMI_MARKET_VAULT"])
));
const vaultEntityId = await valueComponent.getValue(vaultKey);
const vaultAddress = ethers.getAddress(ethers.toBeHex(vaultEntityId, 20));
```

## Newbie Vendor

New accounts can buy one Kami from the Newbie Vendor (Owner, payable) via `system.newbievendor.buy`. Use `calcPrice()` to read the current price before buying. This is a one-time path — use KamiSwap for all subsequent Kami purchases.
