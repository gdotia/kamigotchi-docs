# Gacha / Minting

The gacha system lets players mint new Kamis using gacha tickets. Minting follows a commit-reveal pattern for fair randomness.

---

## Mint

Mint new Kamis using gacha tickets.

| Property | Value |
|----------|-------|
| **System ID** | `system.kami.gacha.mint` |
| **Wallet** | 🔐 Owner |
| **Gas** | **4,000,000 + 3,000,000 per Kami** |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `amount` | `uint256` | Number of Kamis to mint |

### Description

Commits a mint request for one or more Kamis. Consumes gacha tickets from the player's inventory. This is the **commit** phase of the commit-reveal pattern — the Kami's traits are not determined yet.

After minting, call `reveal()` to reveal the Kamis.

### Code Example

```javascript
import { getSystem, ownerSigner, operatorSigner } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256 amount) returns (bytes)"];
const system = await getSystem("system.kami.gacha.mint", ABI, ownerSigner);

const mintAmount = 3;
const gasLimit = 4_000_000 + 3_000_000 * mintAmount; // Scale with amount

const tx = await system.executeTyped(mintAmount, { gasLimit });
await tx.wait();
console.log("Mint committed! Use reveal() to reveal your Kamis.");
```

### Notes

- **Maximum 5 Kamis per mint transaction** — the contract enforces `require(amount <= 5)`. For larger mints, split across multiple transactions.
- **Gas scales with mint amount**: base 4M + 3M per Kami.
- Requires sufficient gacha tickets — buy with `buyPublic()` or `buyWL()`.
- Returns commit IDs needed for `reveal()`.

---

## Reveal

Reveal minted Kamis.

| Property | Value |
|----------|-------|
| **System ID** | `system.kami.gacha.reveal` |
| **Wallet** | 🌐 Any (no wallet restriction) |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `rawCommitIDs` | `uint256[]` | Array of commit IDs from mint |

### Description

Reveals the traits (species, stats, rarity) of Kamis from previous mint commits. This is the **reveal** phase — on-chain randomness determines each Kami's attributes.

> **Note:** This function is owner-agnostic — it can be called by **anyone**, not just the minter. The revealed Kamis are sent to the original minting account regardless of who calls `reveal()`.

### Code Example

```javascript
import { getSystem, ownerSigner, operatorSigner } from "./kamigotchi.js";

// reveal() is a named function, NOT executeTyped
const ABI = ["function reveal(uint256[] rawCommitIDs) external returns (uint256[])"];
const system = await getSystem("system.kami.gacha.reveal", ABI, operatorSigner);

const commitIds = [commitId1, commitId2, commitId3];
const tx = await system.reveal(commitIds);
await tx.wait();
console.log("Kamis revealed!");
```

### Notes

- **Wait at least 1 block between `mint()` and `reveal()`** for randomness security.
- Batch reveals are more gas-efficient.
- After revealing, use [echo.kamis()](echo.md) if the UI doesn't update.

---

## Reroll

Reroll Kamis.

| Property | Value |
|----------|-------|
| **System ID** | `system.kami.gacha.reroll` |
| **Wallet** | 🔐 Owner |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `kamiIDs` | `uint256[]` | Array of Kami entity IDs to reroll |

### Description

Rerolls one or more Kamis, re-randomizing their traits. The original Kami is replaced with a new random result. This is a second chance mechanic for players unhappy with their initial mint results.

### Code Example

```javascript
import { getSystem, ownerSigner, operatorSigner } from "./kamigotchi.js";

// reroll() is a named function, NOT executeTyped
const ABI = ["function reroll(uint256[] kamiIDs) external returns (uint256[])"];
const system = await getSystem("system.kami.gacha.reroll", ABI, ownerSigner);

const kamiIds = [kamiId1, kamiId2];
const tx = await system.reroll(kamiIds);
await tx.wait();
console.log("Kamis rerolled!");
```

### Notes

- Rerolling consumes 1 Reroll Ticket (item index 11) per Kami. The selected Kamis are deposited into the gacha pool and new ones are drawn.
- **Destructive** — the original Kami's traits are replaced permanently.
- Requires a subsequent `reveal()` call — rerolling creates commit entities that must be revealed (same as initial mint).

---

## Buy Gacha Tickets

### Gacha Funding Checklist

Before buying tickets, you must have in-game ETH (item 103). Follow these steps:

1. **Bridge ETH to Yominet** — use the Kamigotchi client bridge or gas.zip
2. **Wrap native ETH to WETH** — call `WETH.deposit()` on `0xE1Ff7038eAAAF027031688E1535a055B2Bac2546`
3. **Approve WETH** — call `WETH.approve(WORLD_ADDRESS, amount)`
4. **Deposit WETH as in-game ETH** — call `system.erc20.portal.deposit(103, amount)` — see [Portal](portal.md)
5. **Buy tickets** — call `buyPublic(amount)` on `system.buy.gacha.ticket`

Budget: **0.1 ETH per public ticket**.

### Prerequisites

> **⚠️ This system does NOT accept native ETH.** You must first deposit ETH into the game via `system.erc20.portal` (see [Portal](portal.md)). Tickets are paid from your **in-game ETH balance** (item index 103).
>
> If you haven't deposited ETH yet, your `buyPublic()` / `buyWL()` calls will revert with an insufficient balance error.

> **⚠️ This system does not support the generic `execute(bytes)` entry point.** Calling `GachaBuyTicketSystem.execute(bytes)` will always revert with `"not implemented"`. Use `buyPublic()` or `buyWL()` directly.

---

## Buy Gacha Tickets (Public)

Buy gacha tickets (public sale).

| Property | Value |
|----------|-------|
| **System ID** | `system.buy.gacha.ticket` |
| **Wallet** | 🔐 Owner |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `amount` | `uint256` | Number of tickets to buy |

### Description

Purchases gacha tickets from the public sale. Tickets are required for minting. Cost is paid in ETH (item index 103) — production price is 100 mETH (0.1 ETH) per ticket, configured via `MINT_PRICE_PUBLIC`.

### Code Example

```javascript
import { getSystem, ownerSigner, operatorSigner } from "./kamigotchi.js";

// buyPublic() is a named function, NOT executeTyped
const ABI = ["function buyPublic(uint256 amount)"];
const system = await getSystem("system.buy.gacha.ticket", ABI, ownerSigner);

const tx = await system.buyPublic(5); // Buy 5 tickets
await tx.wait();
console.log("Gacha tickets purchased!");
```

### Notes

- Public ticket price: 100 mETH (0.1 ETH) per ticket, paid from in-game ETH balance (item index 103). Max per account: 222 (configured via `MINT_MAX_PUBLIC`). Global cap: 3,000 total mints (`MINT_MAX_TOTAL`).
- **Requires deposited ETH** — deposit via `system.erc20.portal` first (see [Portal](portal.md)).

---

## Buy Gacha Tickets (Whitelist)

Buy gacha tickets (whitelist sale).

| Property | Value |
|----------|-------|
| **System ID** | `system.buy.gacha.ticket` |
| **Wallet** | 🔐 Owner |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| *(none)* | — | No additional parameters — whitelist status is checked via an on-chain `MINT_WHITELISTED` flag on the account |

### Description

Purchases gacha tickets during a whitelist/presale phase. Only eligible wallets can call this function. May offer discounted pricing or guaranteed allocation.

### Code Example

```javascript
import { getSystem, ownerSigner, operatorSigner } from "./kamigotchi.js";

// buyWL() is a named function with no parameters
const ABI = ["function buyWL() external"];
const system = await getSystem("system.buy.gacha.ticket", ABI, ownerSigner);

const tx = await system.buyWL();
await tx.wait();
console.log("Whitelist gacha tickets purchased!");
```

### Notes

- Whitelist is flag-based: admins set a `MINT_WHITELISTED` flag on eligible accounts. No Merkle proof or signature needed — the contract checks the flag directly. Price: 50 mETH (0.05 ETH) per ticket (`MINT_PRICE_WL`). Max 1 whitelist mint per account (`MINT_MAX_WL`).
- Whitelist sales typically have limited availability windows.

---

## Minting Lifecycle

```
  buyPublic()                       mint(amount)
  buyWL()                                │
         │                               ▼
         ▼                         Commit IDs generated
  Gacha Tickets                          │
  in Inventory                           ▼
         │                         reveal(commitIDs)
         │                               │
         └──────────────────▶             ▼
                                   Kamis Revealed!
                                         │
                                         ├── Keep → Play!
                                         │
                                         └── reroll(kamiIDs)
                                                  │
                                                  ▼
                                             New traits!
```

---

## Related Pages

- [Kami](kami.md) — Managing minted Kamis
- [Portal](portal.md) — Staking/unstaking Kami NFTs
- [Echo](echo.md) — Force-emit Kami data after minting
