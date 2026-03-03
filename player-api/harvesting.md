# Harvesting

Harvesting is the core resource-gathering mechanic in Kamigotchi. Players assign Kamis to harvest nodes in rooms to earn items and XP over time.

---

## harvest.start()

Start harvesting at a node.

| Property | Value |
|----------|-------|
| **System ID** | `system.harvest.start` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `kamiIDs` | `uint256[]` | Array of Kami entity IDs to assign to the harvest |
| `nodeIndex` | `uint256` | Index of the harvest node in the current room |

### Description

Assigns one or more Kamis to a harvest node. Supports batching — multiple Kamis can be sent to the same node in a single transaction. Internally passes `0, 0` for `taxerID` and `taxAmt` (no taxation on player-initiated harvests).

Kamis must be in the same room as the harvest node and not already harvesting elsewhere.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = [
  "function executeTyped(uint256[] kamiIDs, uint256 nodeIndex) returns (bytes)",
];
const system = await getSystem("system.harvest.start", ABI, operatorSigner);

const kamiIds = [kamiId1, kamiId2, kamiId3];
const tx = await system.executeTyped(kamiIds, harvestNodeIndex);
await tx.wait();
console.log("Harvesting started for", kamiIds.length, "Kamis");
```

### Notes

- Kamis already assigned to a harvest will cause the transaction to revert.
- Each harvest node has a maximum capacity — check room data for availability.
- Move to the room first with [account.move()](account.md#move) before starting a harvest.

---

## harvest.stop()

Stop active harvests.

| Property | Value |
|----------|-------|
| **System ID** | `system.harvest.stop` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `harvestIDs` | `uint256[]` | Array of harvest entity IDs to stop |

### Description

Stops one or more active harvests. The Kamis are released and can be reassigned. Any uncollected rewards remain available for collection.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256[] harvestIDs) returns (bytes)"];
const system = await getSystem("system.harvest.stop", ABI, operatorSigner);

const harvestIds = [harvestId1, harvestId2];
const tx = await system.executeTyped(harvestIds);
await tx.wait();
console.log("Harvests stopped");
```

### Notes

- Stopping a harvest does NOT automatically collect rewards — call `harvest.collect()` separately.
- Batch stopping is more gas-efficient than stopping one by one.

---

## harvest.collect()

Collect rewards from harvests.

| Property | Value |
|----------|-------|
| **System ID** | `system.harvest.collect` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `harvestIDs` | `uint256[]` | Array of harvest entity IDs to collect from |

### Description

Collects accumulated rewards (items, XP) from one or more harvests. Can be called while the harvest is still active (partial collection) or after stopping.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256[] harvestIDs) returns (bytes)"];
const system = await getSystem("system.harvest.collect", ABI, operatorSigner);

const harvestIds = [harvestId1, harvestId2, harvestId3];
const tx = await system.executeTyped(harvestIds);
await tx.wait();
console.log("Rewards collected!");
```

### Notes

- Rewards accumulate over time — collecting early is fine but yields less.
- Batch collecting is more gas-efficient.

---

## harvest.liquidate()

Liquidate another player's harvest.

| Property | Value |
|----------|-------|
| **System ID** | `system.harvest.liquidate` |
| **Wallet** | 🎮 Operator |
| **Gas** | **7,500,000** (hardcoded) |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `harvestID` | `uint256` | Entity ID of the harvest to liquidate |
| `kamiID` | `uint256` | Entity ID of the Kami performing the liquidation |

### Description

Uses your Kami to liquidate another player's harvest. This is a competitive PvP mechanic — the liquidator's Kami must be strong enough to overpower the harvest. Rewards may be split between the liquidator and the original harvester.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = [
  "function executeTyped(uint256 harvestID, uint256 kamiID) returns (bytes)",
];
const system = await getSystem("system.harvest.liquidate", ABI, operatorSigner);

const tx = await system.executeTyped(targetHarvestId, myKamiId, {
  gasLimit: 7_500_000, // Required — complex liquidation logic
});
await tx.wait();
console.log("Harvest liquidated!");
```

### Notes

- **Gas limit of 7,500,000 is required** — the liquidation logic is computationally expensive.
- Liquidation conditions and rewards distribution are ⚠️ TBD — verify with Asphodel team.
- This is a PvP action — use wisely!

---

## Harvest Lifecycle

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ harvest.     │     │ harvest.     │     │ harvest.     │
│ start()      │────▶│ collect()    │────▶│ stop()       │
│              │     │ (partial)    │     │              │
└─────────────┘     └─────────────┘     └──────┬───────┘
                                               │
                                               ▼
                                        ┌─────────────┐
                                        │ harvest.     │
                                        │ collect()    │
                                        │ (final)      │
                                        └─────────────┘
```

You can also collect and stop in any order — collecting after stopping works fine.

---

## Related Pages

- [Kami](kami.md) — Kami stats that affect harvest performance
- [Account — move()](account.md#move) — Move to the room with harvest nodes
- [Echo](echo.md) — Force-emit room data to see harvest nodes
- [Items & Crafting](items-and-crafting.md) — Items earned from harvesting
