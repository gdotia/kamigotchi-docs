# Trading

Player-to-player trading allows exchanging items directly. Trades follow a create → execute → complete lifecycle with on-chain escrow.

---

## trade.create()

Create a new trade offer.

| Property | Value |
|----------|-------|
| **System ID** | `system.trade.create` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `buyIndices` | `uint256[]` | Item indices the maker wants to receive |
| `buyAmts` | `uint256[]` | Amounts for each buy item |
| `sellIndices` | `uint256[]` | Item indices the maker is offering |
| `sellAmts` | `uint256[]` | Amounts for each sell item |
| `targetID` | `uint256` | Target account entity ID (0 for open trade) |

### Description

Creates a trade offer. The **maker's sell items are transferred from inventory to a trade entity** (escrow) immediately upon creation. The trade enters `PENDING` status.

If `targetID` is non-zero, only that specific account can execute the trade. If zero, any player can take it.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = [
  "function executeTyped(uint256[] buyIndices, uint256[] buyAmts, uint256[] sellIndices, uint256[] sellAmts, uint256 targetID) returns (bytes)",
];
const system = await getSystem("system.trade.create", ABI, operatorSigner);

// I want to trade 5 of item #3 for 10 of item #7
const tx = await system.executeTyped(
  [7],   // items I want
  [10],  // amounts I want
  [3],   // items I'm offering
  [5],   // amounts I'm offering
  0      // open trade (anyone can take)
);
await tx.wait();
console.log("Trade created!");
```

### Notes

- **Sell items are immediately escrowed** — removed from your inventory when the trade is created.
- The `buyIndices`/`buyAmts` and `sellIndices`/`sellAmts` arrays must have matching lengths.
- Use `targetID = 0` for public trades, or specify an account entity ID for private trades.

---

## trade.execute()

Execute (accept) a pending trade.

| Property | Value |
|----------|-------|
| **System ID** | `system.trade.execute` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `tradeID` | `uint256` | Entity ID of the trade |

### Description

Called by the **taker** (not the maker) to accept a pending trade. The taker's items (matching the maker's `buyIndices`/`buyAmts`) are transferred to the trade entity. The trade moves to `EXECUTED` status.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256 tradeID) returns (bytes)"];
const system = await getSystem("system.trade.execute", ABI, operatorSigner);

const tx = await system.executeTyped(tradeEntityId);
await tx.wait();
console.log("Trade executed! Waiting for maker to complete.");
```

### Notes

- The caller **must not be the maker** — only the taker can execute.
- The trade must be in `PENDING` status.
- If the trade has a `targetID`, only that account can execute it.
- The taker must have the required items in inventory.

---

## trade.complete()

Complete an executed trade.

| Property | Value |
|----------|-------|
| **System ID** | `system.trade.complete` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `tradeID` | `uint256` | Entity ID of the trade |

### Description

Called by the **maker** to finalize the trade. Items are distributed to both parties:
- Maker receives the taker's items (buy items)
- Taker receives the maker's items (sell items)

The trade entity is resolved.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256 tradeID) returns (bytes)"];
const system = await getSystem("system.trade.complete", ABI, operatorSigner);

const tx = await system.executeTyped(tradeEntityId);
await tx.wait();
console.log("Trade completed! Items exchanged.");
```

### Notes

- Only the **maker** can complete the trade.
- The trade must be in `EXECUTED` status (taker has already called `execute()`).

---

## trade.cancel()

Cancel a pending trade.

| Property | Value |
|----------|-------|
| **System ID** | `system.trade.cancel` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `tradeID` | `uint256` | Entity ID of the trade |

### Description

Cancels a trade and **returns the escrowed items** to the maker's inventory. Only the maker can cancel, and only while the trade is in `PENDING` status.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256 tradeID) returns (bytes)"];
const system = await getSystem("system.trade.cancel", ABI, operatorSigner);

const tx = await system.executeTyped(tradeEntityId);
await tx.wait();
console.log("Trade cancelled — items returned to inventory.");
```

### Notes

- Only the **maker** can cancel.
- Trade must be in `PENDING` status — cannot cancel an `EXECUTED` trade.
- Escrowed sell items are returned to the maker's inventory.

---

## Trade Lifecycle

```
              Maker                          Taker
                │                              │
                ▼                              │
         trade.create()                        │
         Status: PENDING                       │
         (sell items escrowed)                 │
                │                              │
                │◄─────── trade.execute() ─────┘
                │         Status: EXECUTED
                │         (buy items escrowed)
                ▼
         trade.complete()
         Status: COMPLETED
         (items distributed)

    ─── OR ───

         trade.cancel()    (only from PENDING)
         Status: CANCELLED
         (sell items returned)
```

### Trade Statuses

| Status | Description | Actions Available |
|--------|-------------|-------------------|
| `PENDING` | Maker created, waiting for taker | `execute()` (taker), `cancel()` (maker) |
| `EXECUTED` | Taker accepted, waiting for maker to finalize | `complete()` (maker) |
| `COMPLETED` | Items exchanged, trade resolved | None |
| `CANCELLED` | Maker cancelled, items returned | None |

---

## Related Pages

- [Items & Crafting](items-and-crafting.md) — Item management
- [Account](account.md) — Account setup for trading
- [Social / Friends](social.md) — Trading with specific friends
