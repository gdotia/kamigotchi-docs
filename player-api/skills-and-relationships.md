# Skills & NPC Relationships

Manage Kami skill upgrades and resets, and advance relationships with NPCs.

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

Upgrades a specific skill on a Kami. Skills provide passive or active bonuses during harvesting, combat, and other gameplay. Each upgrade costs skill points, which are earned by leveling up.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = [
  "function executeTyped(uint256 kamiID, uint256 skillIndex) returns (bytes)",
];
const system = await getSystem("system.skill.upgrade", ABI, operatorSigner);

const tx = await system.executeTyped(kamiEntityId, skillIndex);
await tx.wait();
console.log("Skill upgraded!");
```

### Notes

- Reverts if the Kami has no available skill points.
- Skill indices and descriptions are ⚠️ TBD — verify with Asphodel team.
- Skill levels may have caps.

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

Resets all skill investments on a Kami, returning all skill points for redistribution. May have restrictions (cooldown, cost, or limited uses).

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256 kamiID) returns (bytes)"];
const system = await getSystem("system.skill.respec", ABI, operatorSigner);

const tx = await system.executeTyped(kamiEntityId);
await tx.wait();
console.log("Skills reset — skill points returned!");
```

### Notes

- Respec restrictions (cooldown, cost) are ⚠️ TBD — verify with Asphodel team.
- For ONYX-based respec (bypasses restrictions), see [Kami — onyx.respec()](kami.md#onyxrespec).

---

## relationship.advance()

Advance a relationship with an NPC.

| Property | Value |
|----------|-------|
| **System ID** | `system.relationship.advance` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `npcIndex` | `uint256` | Index of the NPC |
| `stateIndex` | `uint256` | Target relationship state to advance to |

### Description

Advances the player's relationship with an NPC to the next level. NPCs have multiple relationship states (e.g., stranger → acquaintance → friend → ally). Higher relationship levels may unlock:

- Better merchant prices
- Exclusive quests
- Special items
- Story content

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = [
  "function executeTyped(uint256 npcIndex, uint256 stateIndex) returns (bytes)",
];
const system = await getSystem("system.relationship.advance", ABI, operatorSigner);

const tx = await system.executeTyped(npcIndex, targetRelationshipState);
await tx.wait();
console.log("NPC relationship advanced!");
```

### Notes

- Advancing may require specific items, quest completions, or other prerequisites.
- NPC indices and relationship states are ⚠️ TBD — verify with Asphodel team.
- The `stateIndex` must be the **next valid state** — skipping states will revert.
- Not all NPCs support relationship advancement.

---

## Skill System Overview

```
Level Up Kami
     │
     ▼
Earn Skill Points
     │
     ├─── skill.upgrade(kamiID, skillIndex)   → Invest points
     │
     ├─── skill.reset(kamiID)                 → Free respec
     │
     └─── onyx.respec(kamiID)                 → Paid respec (no restrictions)
```

### Skill Categories

⚠️ TBD — exact skill tree and categories need verification from the Asphodel team. Expected categories include:

- **Harvesting skills** — Improve resource yields
- **Combat skills** — Increase combat effectiveness
- **Utility skills** — Various passive bonuses

---

## NPC Relationship States

⚠️ TBD — exact state names and transitions need verification. Expected pattern:

| State | Benefits |
|-------|----------|
| Stranger | Default — basic interactions only |
| Acquaintance | Unlock basic quests |
| Friend | Better merchant prices |
| Ally | Exclusive items and quests |
| ⚠️ TBD | Additional states may exist |

---

## Related Pages

- [Kami](kami.md) — Kami management and ONYX operations
- [Merchant Listings](listings.md) — NPC merchant trading
- [Quests](quests.md) — NPC quests unlocked by relationships
