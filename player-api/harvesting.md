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
import { getSystem, ownerSigner, operatorSigner } from "./kamigotchi.js";

const ABI = [
  "function executeTyped(uint256 kamiID, uint32 nodeIndex, uint256 taxerID, uint256 taxAmt) returns (bytes)",
  "function executeBatched(uint256[] kamiIDs, uint32 nodeIndex, uint256 taxerID, uint256 taxAmt) returns (bytes[])",
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

- The `nodeIndex` parameter corresponds to the room index — each harvest node shares an index with its room (see [Game Data](../references/game-data.md#harvest-nodes)).
- A newly purchased or minted Kami starts in the account's current room.
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
import { getSystem, ownerSigner, operatorSigner } from "./kamigotchi.js";

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
import { getSystem, ownerSigner, operatorSigner } from "./kamigotchi.js";

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
import { getSystem, ownerSigner, operatorSigner } from "./kamigotchi.js";

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
- This is a PvP action — use wisely!

#### Liquidation Requirements Checklist

All of the following must be true or the transaction reverts:

1. **Target harvest is active** — `victimHarvID` must be a valid, active harvest entity
2. **Your Kami is harvesting** — `killerID` must be in `"HARVESTING"` state
3. **Same node** — Your Kami must be actively harvesting on the **same harvest node** as the victim
4. **Same room** — Your account must be in the same room as the harvest node
5. **Healthy** — Your Kami must have health > 0 (synced at call time)
6. **Off cooldown** — Your Kami's liquidation cooldown must have expired
7. **Sufficient Violence** — Your Kami's Violence stat must meet the threshold to overpower the victim (`LibKill.isLiquidatableBy`). Reverts with `"kami lacks violence (weak)"` if insufficient

#### On Success

- The victim's harvest bounty is split — a portion goes to the victim as "salvage" (based on their Power), the rest becomes "spoils" for the attacker (based on attacker's Power)
- The attacker takes health "recoil" damage from the kill (based on strain and karma)
- The victim's Kami dies (state → `"DEAD"`) and their harvest stops
- The attacker's liquidation cooldown is reset

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

## Yield & Timing

Harvest rewards accumulate continuously over time. Understanding the yield formula helps optimize Kami placement.

### How Bounty Accrues

Harvest output (called **bounty**) is calculated each time a harvest is **synced** (on collect or stop). The formula in `LibHarvest.calcBounty()` is:

```
bounty = (rate × duration × boost) / precision
```

Where:
- **rate** = `fertility + intensity` (in MUSU/second, at 1e6 precision)
- **duration** = seconds since last sync (`block.timestamp - lastSyncTimestamp`)
- **boost** = base boost + bonus from skills/equipment (`HARV_BOUNTY_BOOST`)
- **precision** = combined precision divisor from config

### Fertility (Base Rate)

Fertility is the core harvest rate, driven by the Kami's **Power** stat:

```
fertility = (precision × power × ratio × efficacy) / 3600
```

- **Power** — Kami's total Power stat (base + bonuses from skills/equipment)
- **ratio** — Core fertility multiplier from `KAMI_HARV_FERTILITY` config
- **efficacy** — Affinity matchup bonus (see below)

### Efficacy (Affinity Matching)

Efficacy modifies fertility based on how well the Kami's **body and hand affinities** match the node's affinity:

- **Matching affinity** → Positive efficacy boost (harvest more)
- **Neutral affinity** → Reduced bonus
- **Opposing affinity** → Negative efficacy shift (harvest less)
- **Normal trait** → Gets half the matching bonus

Nodes can have one or two affinities (e.g., "Eerie, Scrap"). The system picks the most favorable matchup order — body affinity has more impact than hand affinity.

**Key takeaway:** Place Kamis on nodes whose affinity matches their body and hand types.

### Intensity (Time Bonus)

Intensity is a secondary yield component that **grows over time** and scales with the Kami's **Violence** stat:

```
intensity = (precision × (violence_base + minutes_elapsed) × boost) / (ratio × 3600)
```

- **violence_base** = config multiplier × Kami's Violence stat
- **minutes_elapsed** = minutes since the last intensity reset (rounded down)
- **boost** = base + `HARV_INTENSITY_BOOST` from skills/equipment

Intensity increases the longer a Kami stays on a node. It resets when a harvest is started or moved.

### When to Collect

- Bounty accrues **continuously** — there is no "ready" timer or fixed interval.
- **Collecting early** gives you whatever has accumulated so far; **collecting later** gives more.
- Calling `harvest.collect()` syncs the bounty (snapshots the accrued amount), resets the duration timer, and adds the bounty to the account's inventory.
- The Kami's **Health decreases** over time while harvesting (strain). If health reaches zero, the Kami is liquidated. Monitor health and collect/stop before it gets critical.
- Calling `harvest.stop()` automatically collects any remaining bounty before stopping.

### Harvest Node Data

Each node has a **Yield Index** (the item index granted — typically `1` for MUSU) and a **Scav Cost** (the stamina cost for scavenging at that node). Nodes also have a **Level Limit** — some beginner nodes cap the Kami level that can earn XP there.

See the [Harvest Nodes table](../references/game-data.md#harvest-nodes) for per-node affinity, yield index, and scav cost values.

### Summary

| Factor | Stat | Effect |
|--------|------|--------|
| Fertility | Power | Higher Power → faster base MUSU rate |
| Efficacy | Body/Hand affinity | Matching node affinity → bonus yield |
| Intensity | Violence | Higher Violence + longer time → bonus yield |
| Bounty boost | Skills/Equipment | Percentage multiplier on total output |
| Strain | Health/Harmony | Higher Harmony/skills → slower health drain |

---

## Related Pages

- [Kami](kami.md) — Kami stats that affect harvest performance
- [Account — move()](account.md#move) — Move to the room with harvest nodes
- [Echo](echo.md) — Force-emit room data to see harvest nodes
- [Items & Crafting](items-and-crafting.md) — Items earned from harvesting
