# Goals & Scavenge

Community goals and scavenging mechanics for earning rewards through collective participation and exploration.

---

## goal.contribute()

Contribute to a community goal.

| Property | Value |
|----------|-------|
| **System ID** | `system.goal.contribute` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `goalIndex` | `uint256` | Index of the community goal |
| `amt` | `uint256` | Amount to contribute |

### Description

Contributes resources toward a community goal. Goals are collective objectives that all players work toward together. When the goal's total contributions reach the target threshold, all contributors can claim rewards.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = [
  "function executeTyped(uint256 goalIndex, uint256 amt) returns (bytes)",
];
const system = await getSystem("system.goal.contribute", ABI, operatorSigner);

const tx = await system.executeTyped(goalIndex, contributionAmount);
await tx.wait();
console.log("Contributed", contributionAmount, "to goal", goalIndex);
```

### Notes

- Contribution type (items, currency, etc.) depends on the goal — ⚠️ TBD.
- Your contribution amount is tracked for proportional reward distribution.
- Goals may have time limits or minimum contribution thresholds.

---

## goal.claim()

Claim reward from a completed goal.

| Property | Value |
|----------|-------|
| **System ID** | `system.goal.claim` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `goalIndex` | `uint256` | Index of the community goal |

### Description

Claims the player's share of rewards from a completed community goal. The reward amount may be proportional to the player's contribution. Can only be called after the goal has reached its target.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256 goalIndex) returns (bytes)"];
const system = await getSystem("system.goal.claim", ABI, operatorSigner);

const tx = await system.executeTyped(goalIndex);
await tx.wait();
console.log("Goal reward claimed!");
```

### Notes

- Reverts if the goal is not yet completed.
- Reverts if the player hasn't contributed to this goal.
- Can only claim once per goal.

---

## scavenge.claim()

Claim scavenge points.

| Property | Value |
|----------|-------|
| **System ID** | `system.scavenge.claim` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `scavBarID` | `uint256` | Entity ID of the scavenge bar |

### Description

Claims accumulated scavenge points from a scavenge bar. Scavenging is a passive exploration mechanic where players discover resources or rewards by interacting with the game world.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256 scavBarID) returns (bytes)"];
const system = await getSystem("system.scavenge.claim", ABI, operatorSigner);

const tx = await system.executeTyped(scavBarEntityId);
await tx.wait();
console.log("Scavenge points claimed!");
```

### Notes

- Scavenge bar mechanics and reward types are ⚠️ TBD — verify with Asphodel team.
- Scavenge bars may be room-specific or account-wide.

---

## Goal Lifecycle

```
  Goal Created (by game)
         │
         ▼
  ┌──────────────┐
  │ ACTIVE       │◄── goal.contribute(goalIndex, amt)
  │              │    (multiple players contribute)
  │ Progress: X% │
  └──────┬───────┘
         │ Target reached
         ▼
  ┌──────────────┐
  │ COMPLETED    │◄── goal.claim(goalIndex)
  │              │    (each contributor claims once)
  └──────────────┘
```

---

## Related Pages

- [Items & Crafting](items-and-crafting.md) — Items used for contributions or earned as rewards
- [Harvesting](harvesting.md) — Resource gathering for goal contributions
- [Account](account.md) — Account management
