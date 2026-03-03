# Merchant Listings

NPC merchants offer items for purchase and accept items for sale. Each merchant has a fixed inventory and pricing.

---

## listing.buy()

Buy items from an NPC merchant.

| Property | Value |
|----------|-------|
| **System ID** | `system.listing.buy` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `merchantIndex` | `uint256` | Index of the NPC merchant |
| `itemIndices` | `uint256[]` | Array of item indices in the merchant's inventory |
| `amts` | `uint256[]` | Array of amounts to buy for each item |

### Description

Purchases items from an NPC merchant's inventory. The cost is deducted from the player's in-game currency/items (depending on the merchant's pricing). Supports buying multiple items in a single transaction.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = [
  "function executeTyped(uint256 merchantIndex, uint256[] itemIndices, uint256[] amts) returns (bytes)",
];
const system = await getSystem("system.listing.buy", ABI, operatorSigner);

// Buy 3 of merchant item #0 and 1 of merchant item #2
const tx = await system.executeTyped(merchantIndex, [0, 2], [3, 1]);
await tx.wait();
console.log("Items purchased from merchant!");
```

### Notes

- `itemIndices` and `amts` arrays must have matching lengths.
- Merchant inventories and pricing are ⚠️ TBD — verify with Asphodel team.
- Merchants may have limited stock or require specific currencies.
- The player must be in the same room as the merchant — move with [account.move()](account.md#move) first.

---

## listing.sell()

Sell items to an NPC merchant.

| Property | Value |
|----------|-------|
| **System ID** | `system.listing.sell` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `merchantIndex` | `uint256` | Index of the NPC merchant |
| `itemIndices` | `uint256[]` | Array of item indices from the player's inventory |
| `amts` | `uint256[]` | Array of amounts to sell for each item |

### Description

Sells items from the player's inventory to an NPC merchant. The merchant pays the player with in-game currency/items based on its buy prices. Supports selling multiple items in a single transaction.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = [
  "function executeTyped(uint256 merchantIndex, uint256[] itemIndices, uint256[] amts) returns (bytes)",
];
const system = await getSystem("system.listing.sell", ABI, operatorSigner);

// Sell 10 of item #5 and 20 of item #12 to merchant
const tx = await system.executeTyped(merchantIndex, [5, 12], [10, 20]);
await tx.wait();
console.log("Items sold to merchant!");
```

### Notes

- Not all items may be sellable to a given merchant.
- Buy prices may differ from sell prices (merchants take a spread).
- The player must be in the merchant's room.

---

## Auction

In addition to merchant listings, Kamigotchi has an auction system:

### auction.buy()

Buy items from the auction house.

| Property | Value |
|----------|-------|
| **System ID** | `system.auction.buy` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

#### Parameters

| Name | Type | Description |
|------|------|-------------|
| `itemIndex` | `uint256` | Index of the auction item |
| `amt` | `uint256` | Amount to buy |

#### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = [
  "function executeTyped(uint256 itemIndex, uint256 amt) returns (bytes)",
];
const system = await getSystem("system.auction.buy", ABI, operatorSigner);

const tx = await system.executeTyped(auctionItemIndex, 1);
await tx.wait();
console.log("Auction item purchased!");
```

> **Note:** ⚠️ Auction system details (pricing model, listing mechanism) are TBD — verify with Asphodel team.

---

## Related Pages

- [Items & Crafting](items-and-crafting.md) — Managing inventory items
- [Account — move()](account.md#move) — Moving to merchant rooms
- [Skills & Relationships](skills-and-relationships.md) — NPC relationship effects on merchant pricing
