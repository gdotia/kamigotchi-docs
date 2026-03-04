# Entity Discovery

How to find and derive the entity IDs you need for gameplay. This is the missing link between "I registered an account" and "now what?"

---

## The MUD ECS Pattern

In Kamigotchi's MUD Entity Component System, everything is an **entity** — a `uint256` identifier. Accounts, Kamis, harvests, trades, quests, rooms, items, and nodes are all entities.

Entity IDs are computed **deterministically** using one of two patterns:

| Pattern | How | Example |
|---------|-----|---------|
| **Address cast** | `uint256(uint160(address))` | Account entities |
| **Keccak hash** | `keccak256(abi.encodePacked(prefix, index))` | Kamis, harvests, rooms, nodes, items |

This means you can **derive** most entity IDs client-side without any on-chain calls.

---

## Account Entity ID

Your account entity ID is simply your **owner wallet address** cast to `uint256`:

```javascript
// Derive account entity ID from owner wallet address
function getAccountEntityId(ownerAddress) {
  return BigInt(ownerAddress);
}

// Example
const ownerAddress = "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045";
const accountId = BigInt(ownerAddress);
// => 1234...n (a large uint256)
```

**How it works:** In [`LibAccount.sol`](https://github.com/kamigotchi), the `create()` function calls `addressToEntity(ownerAddr)`, which is defined as:

```solidity
function addressToEntity(address addr) pure returns (uint256) {
  return uint256(uint160(addr));
}
```

The `getByOwner()` function uses the same derivation — it takes `uint256(uint160(owner))` and verifies the entity has the `"ACCOUNT"` shape.

> **Starting room:** After registration, the account's `IndexRoomComponent` is set to **1** (Misty Riverside). You can read the current room via `GetterSystem.getAccount(id).room`.

---

## Kami Entity IDs

### Deriving from Token Index

Every Kami has a **token index** (`uint32`). The entity ID is derived deterministically:

```solidity
// Solidity (from LibKami.sol)
function genID(uint32 kamiIndex) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked("kami.id", kamiIndex)));
}
```

```javascript
// JavaScript equivalent
import { ethers } from "ethers";

function getKamiEntityId(kamiIndex) {
  return BigInt(
    ethers.keccak256(
      ethers.solidityPacked(["string", "uint32"], ["kami.id", kamiIndex])
    )
  );
}

// Example: Kami with token index 42
const kamiId = getKamiEntityId(42);
```

### After Gacha Minting

The gacha mint is a two-step process: **commit** (mint) → **reveal**.

1. **`KamiGachaMintSystem.executeTyped(amount)`** — Commits to a gacha roll. Returns encoded commit IDs (not Kami IDs yet).
2. **`KamiGachaRevealSystem.reveal(commitIDs)`** — Reveals the actual Kamis. Returns an array of **Kami entity IDs**.

```javascript
// Step 1: Mint (commit)
const mintSystem = await getSystem(
  "system.kami.gacha.mint",
  ["function executeTyped(uint256 amount) returns (bytes)"],
  ownerSigner
);
const mintTx = await mintSystem.executeTyped(1);
const mintReceipt = await mintTx.wait();

// Decode commit IDs from return data
// The return value is abi.encode(uint256[])

// Step 2: Reveal (must wait ~1 block for randomness)
const revealSystem = await getSystem(
  "system.kami.gacha.reveal",
  ["function reveal(uint256[] commitIDs) returns (uint256[])"],
  ownerSigner // can be called by anyone
);
const revealTx = await revealSystem.reveal(commitIds);
const revealReceipt = await revealTx.wait();

// The return value contains the Kami entity IDs
```

### After Staking a Kami721 NFT

When staking an ERC-721 Kami, the **token ID from the NFT contract IS the token index** passed to the stake system:

```javascript
const tokenId = 42; // your Kami721 NFT token ID

// The entity ID for this Kami is:
const kamiEntityId = getKamiEntityId(tokenId);
// = keccak256(abi.encodePacked("kami.id", uint32(42)))
```

After staking via `system.kami721.stake`, the Kami entity is linked to your account entity.

### Enumerating Your Kamis

Use the **GetterSystem** to look up Kami data by index:

```javascript
const GETTER_ABI = [
  "function getKamiByIndex(uint32 index) view returns (tuple)",
  "function getKami(uint256 id) view returns (tuple)",
];
const getter = new ethers.Contract(getterSystemAddr, GETTER_ABI, provider);

// Look up Kami by its token index
const kamiData = await getter.getKamiByIndex(42);
console.log("Kami entity ID:", kamiData.id);
console.log("Account:", kamiData.account);  // 0 if unowned
console.log("State:", kamiData.state);      // "RESTING", "HARVESTING", "DEAD", "721_EXTERNAL"
```

To list all Kamis owned by your account, use the **`IDOwnsKamiComponent`** on-chain, or call `getKami()` with known entity IDs. The `LibAccount.getKamis(accID)` function returns all Kami entity IDs owned by an account — this can be queried through the component directly.

---

## Harvest Entity IDs

Harvest entity IDs are derived **deterministically from the Kami entity ID**:

```solidity
// Solidity (from LibHarvest.sol)
function genID(uint256 kamiID) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked("harvest", kamiID)));
}
```

```javascript
// JavaScript equivalent
function getHarvestEntityId(kamiEntityId) {
  return BigInt(
    ethers.keccak256(
      ethers.solidityPacked(["string", "uint256"], ["harvest", kamiEntityId])
    )
  );
}

// Example
const kamiId = getKamiEntityId(42);
const harvestId = getHarvestEntityId(kamiId);
```

### From the `harvest.start()` Return Value

The `HarvestStartSystem` also **returns the harvest entity ID** in its return value:

```javascript
const harvestSystem = await getSystem(
  "system.harvest.start",
  ["function executeTyped(uint256 kamiID, uint32 nodeIndex, uint256 taxerID, uint256 taxAmt) returns (bytes)"],
  operatorSigner
);

const tx = await harvestSystem.executeTyped(kamiId, nodeIndex, 0, 0);
const receipt = await tx.wait();

// The return value is abi.encode(harvestEntityId)
// But you can also just compute it:
const harvestId = getHarvestEntityId(kamiId);
```

### Key Insight

Each Kami can only have **one harvest at a time**. The harvest entity ID is always deterministic from the Kami ID, so you never need to store it — just recompute it when needed.

---

## Trade Entity IDs

Trade entity IDs are **generated on-chain** using `world.getUniqueEntityId()` (an auto-incrementing counter). They cannot be predicted client-side.

### From the `trade.create()` Return Value

```javascript
const tradeSystem = await getSystem(
  "system.trade.create",
  ["function executeTyped(uint32[] buyIndices, uint256[] buyAmts, uint32[] sellIndices, uint256[] sellAmts, uint256 targetID) returns (bytes)"],
  ownerSigner
);

const tx = await tradeSystem.executeTyped(
  [1],        // buy MUSU
  [1000n],    // amount
  [1001],     // sell Wooden Sticks
  [5n],       // amount
  0           // no target (open trade)
);
const receipt = await tx.wait();

// Decode the return value to get tradeId
// return abi.encode(id)
```

### From Events

The `TradeCreateSystem` emits a `TRADE_CREATE` event containing:
- Trade ID
- Maker account ID
- Target taker account ID
- Buy order (indices + amounts)
- Sell order (indices + amounts)

Parse the transaction receipt logs to extract the trade entity ID.

---

## Quest Entity IDs

Quest entity IDs (for *accepted* quests) are derived **deterministically** from the quest registry index and the account ID:

```solidity
// Solidity (from LibQuest.sol)
function genQuestID(uint32 index, uint256 accID) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked("quest.instance", index, accID)));
}
```

```javascript
// JavaScript equivalent
function getQuestEntityId(questIndex, accountEntityId) {
  return BigInt(
    ethers.keccak256(
      ethers.solidityPacked(
        ["string", "uint32", "uint256"],
        ["quest.instance", questIndex, accountEntityId]
      )
    )
  );
}

// Example: Quest index 1 for your account
const questId = getQuestEntityId(1, accountId);
```

### From the `quest.accept()` Return Value

The `QuestAcceptSystem` also returns the quest entity ID:

```javascript
const questSystem = await getSystem(
  "system.quest.accept",
  ["function executeTyped(uint32 index) returns (bytes)"],
  operatorSigner
);

const tx = await questSystem.executeTyped(1); // accept quest index 1
const receipt = await tx.wait();

// Return value is abi.encode(questID)
// But you can compute it: getQuestEntityId(1, accountId)
```

---

## Room, Node, and Item Entity IDs

These registry entities follow the same keccak hash pattern:

```javascript
// Room entity ID
function getRoomEntityId(roomIndex) {
  return BigInt(
    ethers.keccak256(
      ethers.solidityPacked(["string", "uint32"], ["room", roomIndex])
    )
  );
}

// Node entity ID (harvest nodes share the same index as their room)
function getNodeEntityId(nodeIndex) {
  return BigInt(
    ethers.keccak256(
      ethers.solidityPacked(["string", "uint32"], ["node", nodeIndex])
    )
  );
}

// Item entity ID (registry item)
function getItemEntityId(itemIndex) {
  return BigInt(
    ethers.keccak256(
      ethers.solidityPacked(["string", "uint32"], ["registry.item", itemIndex])
    )
  );
}

// Quest registry entity ID (not the same as an accepted quest instance)
function getQuestRegistryEntityId(questIndex) {
  return BigInt(
    ethers.keccak256(
      ethers.solidityPacked(["string", "uint32"], ["registry.quest", questIndex])
    )
  );
}
```

> **Note:** For rooms and nodes, the index used is the `uint32` room/node index (e.g., room 1, node 12). These are **not** the entity IDs — the entity IDs are the keccak hashes. You pass **indices** (not entity IDs) to most system calls like `account.move(roomIndex)` or `harvest.start(kamiID, nodeIndex, ...)`.

---

## Quick Reference: Entity ID Derivation

| Entity | Derivation | Deterministic? |
|--------|-----------|----------------|
| **Account** | `uint256(uint160(ownerAddress))` | ✅ Yes |
| **Kami** | `keccak256("kami.id", kamiIndex)` | ✅ Yes |
| **Harvest** | `keccak256("harvest", kamiEntityId)` | ✅ Yes |
| **Quest (instance)** | `keccak256("quest.instance", questIndex, accountId)` | ✅ Yes |
| **Trade** | `world.getUniqueEntityId()` — auto-increment | ❌ No (read from return value or events) |
| **Room** | `keccak256("room", roomIndex)` | ✅ Yes |
| **Node** | `keccak256("node", nodeIndex)` | ✅ Yes |
| **Item (registry)** | `keccak256("registry.item", itemIndex)` | ✅ Yes |
| **Quest (registry)** | `keccak256("registry.quest", questIndex)` | ✅ Yes |

---

## General Approach: Working with Return Values and Events

Most Kamigotchi systems return entity IDs in their `bytes` return value (encoded via `abi.encode`). The general workflow:

1. **Call a system** — e.g., `harvest.start()`, `trade.create()`, `quest.accept()`
2. **Read the return value** — Decode the `bytes` return to get the entity ID
3. **Or derive it** — For deterministic IDs, compute it client-side

For non-deterministic IDs (like trades), you can also parse **emitted events** from the transaction receipt. Kamigotchi uses a custom `LibEmitter` system for structured events like `TRADE_CREATE`, `TRADE_EXECUTE`, etc.

```javascript
// Example: Decoding a return value
const tx = await someSystem.executeTyped(args);
const receipt = await tx.wait();

// If you need the return value from a state-changing function,
// you can use staticCall to simulate first:
const returnData = await someSystem.executeTyped.staticCall(args);
const [entityId] = ethers.AbiCoder.defaultAbiCoder().decode(
  ["uint256"],
  returnData
);
```

---

## Complete Helper Library

```javascript
import { ethers } from "ethers";

export const EntityIds = {
  account(ownerAddress) {
    return BigInt(ownerAddress);
  },

  kami(kamiIndex) {
    return BigInt(
      ethers.keccak256(
        ethers.solidityPacked(["string", "uint32"], ["kami.id", kamiIndex])
      )
    );
  },

  harvest(kamiEntityId) {
    return BigInt(
      ethers.keccak256(
        ethers.solidityPacked(["string", "uint256"], ["harvest", kamiEntityId])
      )
    );
  },

  questInstance(questIndex, accountEntityId) {
    return BigInt(
      ethers.keccak256(
        ethers.solidityPacked(
          ["string", "uint32", "uint256"],
          ["quest.instance", questIndex, accountEntityId]
        )
      )
    );
  },

  room(roomIndex) {
    return BigInt(
      ethers.keccak256(
        ethers.solidityPacked(["string", "uint32"], ["room", roomIndex])
      )
    );
  },

  node(nodeIndex) {
    return BigInt(
      ethers.keccak256(
        ethers.solidityPacked(["string", "uint32"], ["node", nodeIndex])
      )
    );
  },

  item(itemIndex) {
    return BigInt(
      ethers.keccak256(
        ethers.solidityPacked(["string", "uint32"], ["registry.item", itemIndex])
      )
    );
  },

  questRegistry(questIndex) {
    return BigInt(
      ethers.keccak256(
        ethers.solidityPacked(["string", "uint32"], ["registry.quest", questIndex])
      )
    );
  },
};
```

---

## Inventory Discovery

The `GetterSystem.getAccount()` returns an `AccountShape` with four fields: `index`, `name`, `currStamina`, and `room`. **It does not include inventory.** You must query inventory separately.

### How Inventory Works

Each inventory entry is an entity with three components:

| Component | Description |
|-----------|-------------|
| `IDOwnsInventoryComponent` | The holder's entity ID (your account ID) |
| `IndexItemComponent` | The item's registry index (e.g., `1` for MUSU, `1001` for Wooden Stick) |
| `ValueComponent` | The quantity held |

Inventory entity IDs are **deterministic** — derived from the holder ID and item index:

```solidity
// Solidity (from LibInventory.sol)
function genID(uint256 holderID, uint32 itemIndex) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked("inventory.instance", holderID, itemIndex)));
}
```

```javascript
// JavaScript equivalent
function getInventoryEntityId(holderEntityId, itemIndex) {
  return BigInt(
    ethers.keccak256(
      ethers.solidityPacked(
        ["string", "uint256", "uint32"],
        ["inventory.instance", holderEntityId, itemIndex]
      )
    )
  );
}
```

### Reading a Specific Item Balance

If you know which item you're looking for, compute the inventory entity ID and read the `ValueComponent`:

```javascript
// Check how much MUSU (item index 1) the account holds
const accountId = BigInt(ownerAddress);
const musuInventoryId = getInventoryEntityId(accountId, 1);

// Read ValueComponent for this entity
const balance = await valueComponent.get(musuInventoryId);
console.log("MUSU balance:", balance.toString());
```

`LibInventory.getBalanceOf(components, holderID, itemIndex)` does exactly this internally.

### Enumerating All Inventory Items

To get **all** items held by an account, query the `IDOwnsInventoryComponent` for all entities with the account's ID as their value:

```javascript
// Get all inventory entity IDs for this account
const inventoryIds = await idOwnsInventoryComponent.getEntitiesWithValue(accountId);

// For each inventory entity, read the item index and quantity
for (const invId of inventoryIds) {
  const itemIndex = await indexItemComponent.get(invId);
  const quantity = await valueComponent.get(invId);
  console.log(`Item ${itemIndex}: ${quantity}`);
}
```

This mirrors `LibInventory.getAllForHolder(components, holderID)` which returns all inventory entity IDs where `IDOwnsInventoryComponent` matches the holder.

### Key Constants

Some commonly referenced item indices:

| Constant | Index | Item |
|----------|-------|------|
| `MUSU_INDEX` | 1 | $MUSU currency |
| `GACHA_TICKET_INDEX` | 10 | Gacha Ticket |
| `REROLL_TICKET_INDEX` | 11 | Reroll Ticket |
| `ONYX_INDEX` | 100 | Onyx Shard ($ONYX) |
| `OBOL_INDEX` | 1015 | Obol |

### Notes

- Inventory entities are **created lazily** — they only exist once a player has received at least one of that item.
- When a balance reaches zero, the inventory entity is **deleted** to reduce state bloat.
- The `TRANSFER_FEE` constant is set to 15 (used for inter-account item transfers).

---

## Equipment Discovery

Equipment instances are also deterministic entities, derived from the holder ID and slot string:

```javascript
function getEquipmentEntityId(holderEntityId, slot) {
  return BigInt(
    ethers.keccak256(
      ethers.solidityPacked(
        ["string", "uint256", "string"],
        ["equipment.instance", holderEntityId, slot]
      )
    )
  );
}

// Example: Check if a Kami has something in the Pet slot
const equipId = getEquipmentEntityId(kamiEntityId, "Kami_Pet_Slot");
```

To enumerate all equipment on an entity, query the `IDOwnsEquipmentComponent`:

```javascript
const equipIds = await idOwnsEquipmentComponent.getEntitiesWithValue(kamiEntityId);
for (const eqId of equipIds) {
  const itemIndex = await indexItemComponent.get(eqId);
  const slot = await forComponent.get(eqId);
  console.log(`Slot ${slot}: Item ${itemIndex}`);
}
```

---

## See Also

- [Game Data Reference](../references/game-data.md) — Lookup tables for item, room, node, skill, and quest indices
- [Overview & Setup](overview.md) — SDK setup and calling conventions
- [Integration Guide](../integration-guide.md) — Step-by-step walkthrough
