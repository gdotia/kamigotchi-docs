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
| `kamiID` | `uint256` | Entity ID of the Kami to assign to the harvest |
| `nodeIndex` | `uint32` | Index of the harvest node in the current room |
| `taxerID` | `uint256` | Taxer entity ID (pass `0` for player-initiated harvests) |
| `taxAmt` | `uint256` | Tax amount (pass `0` for player-initiated harvests) |

### Description

Assigns a Kami to a harvest node. For player-initiated harvests, pass `0, 0` for the `taxerID` and `taxAmt` parameters (taxation is for system-level use).

Kamis must be in the same room as the harvest node and not already harvesting elsewhere.

For batching multiple Kamis to the same node, use `executeBatched()` (see below).

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = [
  "function executeTyped(uint256 kamiID, uint32 nodeIndex, uint256 taxerID, uint256 taxAmt) returns (bytes)",
  "function executeBatched(uint256[] kamiIDs, uint32 nodeIndex, uint256 taxerID, uint256 taxAmt)",
];
const system = await getSystem("system.harvest.start", ABI, operatorSigner);

// Single Kami
const tx = await system.executeTyped(kamiId, harvestNodeIndex, 0, 0);
await tx.wait();
console.log("Harvesting started for Kami");

// Batch — multiple Kamis on the same node
const txBatch = await system.executeBatched(
  [kamiId1, kamiId2, kamiId3],
  harvestNodeIndex,
  0, 0
);
await txBatch.wait();
console.log("Harvesting started for 3 Kamis");
```

### Notes

- Kamis already assigned to a harvest will cause the transaction to revert.
- Each harvest node has a maximum capacity — check room data for availability.
- Move to the room first with [account.move()](account.md#move) before starting a harvest.
- **Batch variant:** `executeBatched(uint256[] kamiIDs, uint32 nodeIndex, uint256 taxerID, uint256 taxAmt)` starts harvests for multiple Kamis in one transaction.

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
| `id` | `uint256` | Harvest entity ID to stop |

### Description

Stops a single active harvest. The Kami is released and can be reassigned. Any uncollected rewards are collected automatically (collect-and-stop).

For batch stopping, use `executeBatched()` (see below).

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = [
  "function executeTyped(uint256 id) returns (bytes)",
  "function executeBatched(uint256[] ids) returns (bytes[])",
];
const system = await getSystem("system.harvest.stop", ABI, operatorSigner);

// Single harvest
const tx = await system.executeTyped(harvestId);
await tx.wait();
console.log("Harvest stopped");

// Batch — multiple harvests
const txBatch = await system.executeBatched([harvestId1, harvestId2]);
await txBatch.wait();
console.log("Harvests stopped");
```

### Notes

- Stopping a harvest collects rewards automatically.
- **Batch variant:** `executeBatched(uint256[] ids)` stops multiple harvests in one transaction — more gas-efficient than stopping one by one.

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
| `id` | `uint256` | Harvest entity ID to collect from |

### Description

Collects accumulated rewards (items, XP) from a single harvest. Can be called while the harvest is still active (partial collection) or after stopping.

For batch collecting, use `executeBatched()` (see below).

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = [
  "function executeTyped(uint256 id) returns (bytes)",
  "function executeBatched(uint256[] ids) returns (bytes[])",
];
const system = await getSystem("system.harvest.collect", ABI, operatorSigner);

// Single harvest
const tx = await system.executeTyped(harvestId);
await tx.wait();
console.log("Rewards collected!");

// Batch — multiple harvests
const txBatch = await system.executeBatched([harvestId1, harvestId2, harvestId3]);
await txBatch.wait();
console.log("All rewards collected!");
```

### Notes

- Rewards accumulate over time — collecting early is fine but yields less.
- **Batch variant:** `executeBatched(uint256[] ids)` collects from multiple harvests in one transaction — more gas-efficient.

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
| `victimHarvID` | `uint256` | Entity ID of the victim's harvest to liquidate |
| `killerID` | `uint256` | Entity ID of your Kami performing the liquidation |

### Description

Uses your Kami to liquidate another player's harvest. This is a competitive PvP mechanic — the liquidator's Kami must be strong enough to overpower the harvest. Rewards may be split between the liquidator and the original harvester.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = [
  "function executeTyped(uint256 victimHarvID, uint256 killerID) returns (bytes)",
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
- Liquidation requires: both Kamis must be on the same node, the attacker must be in `"HARVESTING"` state, healthy, and off cooldown, and the target's harvest must be active. The attacker's Violence stat must meet the threshold (`LibKill.isLiquidatableBy`). On success: the victim's harvest bounty is split — a portion goes to the victim as "salvage" (based on their Power), the rest becomes "spoils" for the attacker (based on attacker's Power). The attacker takes health "recoil" damage from the kill (based on strain and karma). The victim's Kami dies (state → `"DEAD"`) and their harvest stops. The attacker's cooldown is reset.
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
