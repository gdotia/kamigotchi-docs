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
- XP thresholds per level are ⚠️ TBD — verify with Asphodel team.

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

- Name length limits and character restrictions are ⚠️ TBD — verify with Asphodel team.
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
| `kamiIndex` | `uint256` | Index of the Kami in the account's Kami list |

### Description

Commits a Kami to the sacrifice process. The Kami is consumed, and a commit ID is generated. Use `sacrificeReveal()` to reveal the resulting loot/petpet.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256 kamiIndex) returns (bytes)"];
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
| `commitIDs` | `uint256[]` | Array of commit IDs from `sacrificeCommit()` |

### Description

Reveals the loot/petpet generated from one or more sacrifice commits. Supports batched reveals.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256[] commitIDs) returns (bytes)"];
const system = await getSystem("system.kami.sacrifice.reveal", ABI, operatorSigner);

const commitIds = [commitId1, commitId2];
const tx = await system.executeTyped(commitIds);
await tx.wait();
console.log("Sacrifice loot revealed!");
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
| `itemIndex` | `uint256` | Index of the item in inventory |

### Description

Equips an item from the player's inventory onto the specified Kami. The item is removed from inventory and applied to the Kami's equipment slot. Items provide stat boosts.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256 kamiID, uint256 itemIndex) returns (bytes)"];
const system = await getSystem("system.kami.equip", ABI, operatorSigner);

const tx = await system.executeTyped(kamiEntityId, itemIndex);
await tx.wait();
```

### Notes

- Each Kami has limited equipment slots. Equipping to a full slot will revert.
- Equipment slot types are ⚠️ TBD — verify with Asphodel team.

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

const ABI = ["function executeTyped(uint256 kamiID, string slotType) returns (bytes)"];
const system = await getSystem("system.kami.unequip", ABI, operatorSigner);

const tx = await system.executeTyped(kamiEntityId, "head"); // ⚠️ TBD — verify slot names
await tx.wait();
```

### Notes

- Valid slot type strings are ⚠️ TBD — verify with Asphodel team (e.g., `"head"`, `"body"`, `"weapon"`).

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
| `itemIndex` | `uint256` | Index of the item in inventory |

### Description

Uses a consumable item on a Kami. Common use cases include feeding (restoring health) and applying buffs. The item is consumed from inventory.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256 kamiID, uint256 itemIndex) returns (bytes)"];
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
| `kamiID` | `uint256` | Entity ID of the **target** (enemy) Kami |
| `itemIndex` | `uint256` | Index of the item in inventory |

### Description

Casts a combat item at an enemy Kami. Used in PvP or PvE scenarios to apply debuffs or deal damage.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256 kamiID, uint256 itemIndex) returns (bytes)"];
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
| `kamiID` | `uint256` | Entity ID of the Kami |
| `skillIndex` | `uint256` | Index of the skill to upgrade |

### Description

Upgrades the specified skill on a Kami. Requires the Kami to have available skill points.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256 kamiID, uint256 skillIndex) returns (bytes)"];
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

- ONYX cost per rename is ⚠️ TBD — verify with Asphodel team.
- Requires $ONYX approval to the system contract prior to calling.

---

## onyx.revive()

Revive a dead Kami using $ONYX.

| Property | Value |
|----------|-------|
| **System ID** | `system.kami.onyx.revive` |
| **Wallet** | 🔐 Owner |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `kamiIndex` | `uint256` | Index of the dead Kami in account's Kami list |

### Description

Revives a Kami that has died (health reached 0). Costs $ONYX. The Kami is restored with ⚠️ TBD stats (likely partial health).

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

// Must use OWNER wallet
const ABI = ["function executeTyped(uint256 kamiIndex) returns (bytes)"];
const system = await getSystem("system.kami.onyx.revive", ABI, ownerSigner);

const tx = await system.executeTyped(deadKamiIndex);
await tx.wait();
console.log("Kami revived!");
```

### Notes

- ONYX cost is ⚠️ TBD — verify with Asphodel team.
- Requires $ONYX approval to the system contract.

---

## onyx.respec()

Respec a Kami's skills using $ONYX.

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
