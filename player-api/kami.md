# Kami (Pets)

Kamis are the core entities in Kamigotchi — your on-chain pets. This page covers leveling, naming, sacrificing, equipment, item usage, skill management, and ONYX-based premium operations.

---

## level()

Level up a Kami.

| Property | Value |
|----------|-------|
| **System ID** | `system.kami.level` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `kamiID` | `uint256` | Entity ID of the Kami to level up |

### Description

Levels up the specified Kami if it has accumulated enough XP. XP is earned from harvesting, quests, and other gameplay activities. Each level may increase base stats.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256 kamiID) returns (bytes)"];
const system = await getSystem("system.kami.level", ABI, operatorSigner);

const tx = await system.executeTyped(kamiEntityId);
await tx.wait();
console.log("Kami leveled up!");
```

### Notes

- Reverts with `"Insufficient XP"` if the Kami doesn't have enough XP for the next level.
- XP thresholds are calculated dynamically: `cost = BASE * MULT^(level-1)`. Production values: BASE = 40 XP (level 1→2), MULT = 1.259 (i.e. each level costs ~25.9% more than the previous). For example: level 1→2 costs 40 XP, level 2→3 costs ~50 XP, level 5→6 costs ~100 XP, and so on.

---

## name()

Name or rename a Kami.

| Property | Value |
|----------|-------|
| **System ID** | `system.kami.name` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `kamiID` | `uint256` | Entity ID of the Kami |
| `name` | `string` | New name for the Kami |

### Description

Sets or updates the Kami's display name. Free to call (no ONYX cost). For ONYX-based renaming, see [onyx.rename()](#onyxrename).

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256 kamiID, string name) returns (bytes)"];
const system = await getSystem("system.kami.name", ABI, operatorSigner);

const tx = await system.executeTyped(kamiEntityId, "Sparkles");
await tx.wait();
```

### Notes

- Name must be 1–16 characters (bytes). Names must be unique across all Kamis. Costs 1 Holy Dust (item index 11011) and the Kami must be in room 11.
- See also: [onyx.rename()](#onyxrename) for premium rename.

---

## sacrificeCommit()

Sacrifice a Kami to receive a petpet.

| Property | Value |
|----------|-------|
| **System ID** | `system.kami.sacrifice.commit` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `kamiIndex` | `uint32` | Index of the Kami in the account's Kami list |

### Description

Commits a Kami to the sacrifice process. The Kami is consumed, and a commit ID is generated. Use `sacrificeReveal()` to reveal the resulting loot/petpet.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint32 kamiIndex) returns (uint256)"];
const system = await getSystem("system.kami.sacrifice.commit", ABI, operatorSigner);

const tx = await system.executeTyped(kamiIndex);
const receipt = await tx.wait();
console.log("Sacrifice committed — use sacrificeReveal() to reveal loot");
```

> **Note:** This is a **destructive action** — the Kami is permanently consumed.

---

## sacrificeReveal()

Reveal loot from a committed sacrifice.

| Property | Value |
|----------|-------|
| **System ID** | `system.kami.sacrifice.reveal` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `commitID` | `uint256` | Commit ID from `sacrificeCommit()` |

### Description

Reveals the loot/petpet generated from a sacrifice commit. For batch reveals, use `executeTypedBatch()`.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = [
  "function executeTyped(uint256 commitID)",
  "function executeTypedBatch(uint256[] commitIDs)",
];
const system = await getSystem("system.kami.sacrifice.reveal", ABI, operatorSigner);

// Single reveal
const tx = await system.executeTyped(commitId);
await tx.wait();
console.log("Sacrifice loot revealed!");

// Batch reveal
const txBatch = await system.executeTypedBatch([commitId1, commitId2]);
await txBatch.wait();
```

---

## equipment.equip()

Equip an item to a Kami.

| Property | Value |
|----------|-------|
| **System ID** | `system.kami.equip` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `kamiID` | `uint256` | Entity ID of the Kami |
| `itemIndex` | `uint32` | Index of the item in inventory |

### Description

Equips an item from the player's inventory onto the specified Kami. The item is removed from inventory and applied to the Kami's equipment slot. Items provide stat boosts.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256 kamiID, uint32 itemIndex) returns (uint256)"];
const system = await getSystem("system.kami.equip", ABI, operatorSigner);

const tx = await system.executeTyped(kamiEntityId, itemIndex);
await tx.wait();
```

### Notes

- **Slot is automatic:** You only pass the `itemIndex` — the system reads the item's `For` field from the registry to determine the slot. For example, if the item has `For = "Kami_Pet_Slot"`, it goes into the Kami's Pet slot. You do **not** pass a slot parameter when equipping.
- **Slot conflict handling:** If the target slot is already occupied, the existing item is **automatically unequipped** (returned to your inventory) before the new item is equipped. No need to manually unequip first.
- **Capacity limit:** Each entity has a default equipment capacity of **1** total equipped item (across all slots), expandable via the `EQUIP_CAPACITY_SHIFT` bonus. Adding new equipment (not replacing) checks capacity — replacing an item in the same slot does not count as adding.
- **Kami state requirement:** The Kami must be in `"RESTING"` state to equip items. Harvesting or dead Kamis cannot be equipped.
- **Item consumed:** The item is consumed from your account's inventory when equipped, and returned when unequipped.
- Equipment slot types use the format `"{EntityType}_{SlotName}_Slot"` — e.g., `"Kami_Pet_Slot"`, `"Account_Badge_Slot"`. Currently all equipment items in the game use the `Kami_Pet_Slot`. See [Equipment Reference](../references/game-data.md#equipment) for the full list.

---

## equipment.unequip()

Unequip an item from a Kami.

| Property | Value |
|----------|-------|
| **System ID** | `system.kami.unequip` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `kamiID` | `uint256` | Entity ID of the Kami |
| `slotType` | `string` | Equipment slot type to unequip |

### Description

Removes the item from the specified slot and returns it to inventory.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256 kamiID, string slotType) returns (uint32)"];
const system = await getSystem("system.kami.unequip", ABI, operatorSigner);

const tx = await system.executeTyped(kamiEntityId, "Kami_Pet_Slot"); // slot string from item registry
await tx.wait();
```

### Notes

- Valid slot type strings follow the format `"{EntityType}_{SlotName}_Slot"` — e.g., `"Kami_Pet_Slot"`, `"Kami_Hat_Slot"`, `"Account_Badge_Slot"`. The slot value is defined on each equipment item in the registry's `For` field.

---

## item.use()

Use an item on a Kami (e.g., feed).

| Property | Value |
|----------|-------|
| **System ID** | `system.kami.use.item` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `kamiID` | `uint256` | Entity ID of the Kami |
| `itemIndex` | `uint32` | Index of the item in inventory |

### Description

Uses a consumable item on a Kami. Common use cases include feeding (restoring health) and applying buffs. The item is consumed from inventory.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256 kamiID, uint32 itemIndex) returns (bytes)"];
const system = await getSystem("system.kami.use.item", ABI, operatorSigner);

const tx = await system.executeTyped(kamiEntityId, foodItemIndex);
await tx.wait();
```

---

## item.cast()

Cast an item on an enemy Kami.

| Property | Value |
|----------|-------|
| **System ID** | `system.kami.cast.item` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `targetID` | `uint256` | Entity ID of the **target** (enemy) Kami |
| `itemIndex` | `uint32` | Index of the item in inventory |

### Description

Casts a combat item at an enemy Kami. Used in PvP or PvE scenarios to apply debuffs or deal damage.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256 targetID, uint32 itemIndex) returns (bytes)"];
const system = await getSystem("system.kami.cast.item", ABI, operatorSigner);

const tx = await system.executeTyped(enemyKamiId, combatItemIndex);
await tx.wait();
```

---

## skill.upgrade()

Upgrade a Kami's skill.

| Property | Value |
|----------|-------|
| **System ID** | `system.skill.upgrade` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `kamiID` | `uint256` | Entity ID of the Kami (contract parameter is `holderID`) |
| `skillIndex` | `uint32` | Index of the skill to upgrade |

### Description

Upgrades the specified skill on a Kami. Requires the Kami to have available skill points.

> **Note:** The contract parameter is named `holderID` (since the system also supports account skills), but for Kami skill upgrades you pass the Kami's entity ID.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256 kamiID, uint32 skillIndex) returns (bytes)"];
const system = await getSystem("system.skill.upgrade", ABI, operatorSigner);

const tx = await system.executeTyped(kamiEntityId, skillIndex);
await tx.wait();
```

> **Note:** See also [Skills & Relationships](skills-and-relationships.md) for more detail on the skill system.

---

## skill.reset()

Reset all skills on a Kami (respec).

| Property | Value |
|----------|-------|
| **System ID** | `system.skill.respec` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `kamiID` | `uint256` | Entity ID of the Kami |

### Description

Resets all skill points on a Kami, allowing them to be redistributed. May have a cooldown or cost.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256 kamiID) returns (bytes)"];
const system = await getSystem("system.skill.respec", ABI, operatorSigner);

const tx = await system.executeTyped(kamiEntityId);
await tx.wait();
```

> **Note:** For ONYX-based respec, see [onyx.respec()](#onyxrespec).

---

## onyx.rename()

Rename a Kami using $ONYX.

> **⚠️ Currently Disabled:** This system reverts with 'Onyx Features are temporarily disabled.' Calls will fail until re-enabled.

| Property | Value |
|----------|-------|
| **System ID** | `system.kami.onyx.rename` |
| **Wallet** | 🔐 Owner |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `kamiID` | `uint256` | Entity ID of the Kami |
| `name` | `string` | New name |

### Description

Premium rename operation that costs $ONYX. Use the free `name()` function for the first rename; this is for subsequent renames or special naming.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

// Must use OWNER wallet
const ABI = ["function executeTyped(uint256 kamiID, string name) returns (bytes)"];
const system = await getSystem("system.kami.onyx.rename", ABI, ownerSigner);

const tx = await system.executeTyped(kamiEntityId, "MegaSparkles");
await tx.wait();
```

### Notes

- ONYX cost per rename is 5,000 $ONYX (item index 100). Same name validation as `name()`: 1–16 characters, must be unique, Kami must be in room 11.
- Requires $ONYX approval to the system contract prior to calling.

---

## onyx.revive()

Revive a dead Kami using $ONYX.

| Property | Value |
|----------|-------|
| **System ID** | `system.kami.onyx.revive` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `kamiIndex` | `uint256` | Index of the dead Kami in account's Kami list |

> **Note:** Internally interpreted as a uint32 Kami index. Pass the Kami's numeric index, not its entity ID.

### Description

Revives a Kami that has died (health reached 0). Costs 33 $ONYX shards (item index 100). The Kami's state is set from `"DEAD"` to `"RESTING"` and health is restored to 33.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256 id) returns (bytes)"];
const system = await getSystem("system.kami.onyx.revive", ABI, operatorSigner);

const tx = await system.executeTyped(deadKamiIndex);
await tx.wait();
console.log("Kami revived!");
```

### Notes

- ONYX cost is 33 shards per revive. Health is restored to 33.
- Requires $ONYX approval to the system contract.

---

## onyx.respec()

Respec a Kami's skills using $ONYX.

> **⚠️ Currently Disabled:** This system reverts with 'Onyx Features are temporarily disabled.' Calls will fail until re-enabled.

| Property | Value |
|----------|-------|
| **System ID** | `system.kami.onyx.respec` |
| **Wallet** | 🔐 Owner |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `kamiID` | `uint256` | Entity ID of the Kami |

### Description

Resets all skill points on a Kami via $ONYX payment. Differs from the free `skill.reset()` in that it may bypass cooldowns or other restrictions.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

// Must use OWNER wallet
const ABI = ["function executeTyped(uint256 kamiID) returns (bytes)"];
const system = await getSystem("system.kami.onyx.respec", ABI, ownerSigner);

const tx = await system.executeTyped(kamiEntityId);
await tx.wait();
```

---

## Related Pages

- [Harvesting](harvesting.md) — Kami-based harvesting
- [Minting](minting.md) — Acquiring new Kamis via gacha
- [Portal](portal.md) — Staking/unstaking Kami NFTs
- [Skills & Relationships](skills-and-relationships.md) — Skill system details
- [Echo](echo.md) — Force-emit Kami data if state is stale
