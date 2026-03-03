# Quests

Quests are objectives players can accept and complete for rewards. The quest system tracks progress on-chain.

---

## quest.accept()

Accept a quest.

| Property | Value |
|----------|-------|
| **System ID** | `system.quest.accept` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `index` | `uint256` | Index of the quest to accept |

### Description

Accepts a quest from the available quest list. The quest is added to the player's active quests. Quest availability may depend on the player's level, room, or other conditions.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256 index) returns (bytes)"];
const system = await getSystem("system.quest.accept", ABI, operatorSigner);

const tx = await system.executeTyped(questIndex);
await tx.wait();
console.log("Quest accepted!");
```

### Notes

- Players may have a limit on the number of active quests — ⚠️ TBD.
- Quest indices are defined in game data — ⚠️ verify quest list with Asphodel team.

---

## quest.complete()

Complete a quest.

| Property | Value |
|----------|-------|
| **System ID** | `system.quest.complete` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `id` | `uint256` | Entity ID of the active quest |

### Description

Completes an active quest and claims its rewards. The quest's completion conditions must already be met (e.g., required items collected, harvests completed, etc.). Reverts if conditions are not satisfied.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256 id) returns (bytes)"];
const system = await getSystem("system.quest.complete", ABI, operatorSigner);

const tx = await system.executeTyped(questEntityId);
await tx.wait();
console.log("Quest completed! Rewards claimed.");
```

### Notes

- The `id` parameter is the **entity ID** of the active quest (not the quest index used in `accept()`).
- Quest rewards (items, XP, etc.) are automatically added to the player's inventory/account.
- Quest completion conditions are checked on-chain — no way to cheat!

---

## Quest Lifecycle

```
Available Quest          Active Quest           Completed
    (index)                (entity ID)
       │                      │                     │
       ▼                      ▼                     ▼
  quest.accept(index) → quest.complete(entityId) → Rewards
```

> **Note:** `accept()` takes a quest **index** (from the quest catalog), while `complete()` takes the quest **entity ID** (assigned when the quest becomes active).

---

## Related Pages

- [Account](account.md) — General account management
- [Items & Crafting](items-and-crafting.md) — Items that may be quest requirements or rewards
- [Harvesting](harvesting.md) — Harvesting objectives in quests
