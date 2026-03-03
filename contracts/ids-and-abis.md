# System IDs & ABI References

Kamigotchi has **55 registered systems** in the World contract. Each system is identified by a human-readable string ID, hashed with `keccak256` for on-chain lookup.

---

## System ID Reference

### Account Systems

| System ID | Description | Wallet | Page |
|-----------|-------------|--------|------|
| `system.account.register` | Register a new account | Owner | [Account](../player-api/account.md) |
| `system.account.move` | Move to a room | Operator | [Account](../player-api/account.md) |
| `system.account.set.bio` | Set account bio | Operator | [Account](../player-api/account.md) |
| `system.account.set.name` | Rename account | Owner | [Account](../player-api/account.md) |
| `system.account.set.operator` | Update operator wallet | Owner | [Account](../player-api/account.md) |
| `system.account.set.pfp` | Set profile picture | Owner | [Account](../player-api/account.md) |
| `system.account.use.item` | Use item from inventory | Operator | [Items](../player-api/items-and-crafting.md) |

### Chat

| System ID | Description | Wallet | Page |
|-----------|-------------|--------|------|
| `system.chat` | Send chat message | Operator | [Account](../player-api/account.md) |

### Echo Systems

| System ID | Description | Wallet | Page |
|-----------|-------------|--------|------|
| `system.echo.kamis` | Force-emit Kami data | Operator | [Echo](../player-api/echo.md) |
| `system.echo.room` | Force-emit Room data | Operator | [Echo](../player-api/echo.md) |

### Kami Systems

| System ID | Description | Wallet | Page |
|-----------|-------------|--------|------|
| `system.kami.level` | Level up Kami | Operator | [Kami](../player-api/kami.md) |
| `system.kami.name` | Name/rename Kami | Operator | [Kami](../player-api/kami.md) |
| `system.kami.equip` | Equip item to Kami | Operator | [Kami](../player-api/kami.md) |
| `system.kami.unequip` | Unequip item from Kami | Operator | [Kami](../player-api/kami.md) |
| `system.kami.use.item` | Use item on Kami (feed) | Operator | [Kami](../player-api/kami.md) |
| `system.kami.cast.item` | Cast item on enemy Kami | Operator | [Kami](../player-api/kami.md) |
| `system.kami.sacrifice.commit` | Sacrifice Kami | Operator | [Kami](../player-api/kami.md) |
| `system.kami.sacrifice.reveal` | Reveal sacrifice loot | Operator | [Kami](../player-api/kami.md) |
| `system.kami.onyx.rename` | Rename Kami via ONYX | Owner | [Kami](../player-api/kami.md) |
| `system.kami.onyx.revive` | Revive dead Kami via ONYX | Owner | [Kami](../player-api/kami.md) |
| `system.kami.onyx.respec` | Respec Kami via ONYX | Owner | [Kami](../player-api/kami.md) |

### Skill Systems

| System ID | Description | Wallet | Page |
|-----------|-------------|--------|------|
| `system.skill.upgrade` | Upgrade Kami skill | Operator | [Skills](../player-api/skills-and-relationships.md) |
| `system.skill.respec` | Reset Kami skills | Operator | [Skills](../player-api/skills-and-relationships.md) |

### Harvest Systems

| System ID | Description | Wallet | Page |
|-----------|-------------|--------|------|
| `system.harvest.start` | Start harvesting | Operator | [Harvesting](../player-api/harvesting.md) |
| `system.harvest.stop` | Stop harvesting | Operator | [Harvesting](../player-api/harvesting.md) |
| `system.harvest.collect` | Collect harvest rewards | Operator | [Harvesting](../player-api/harvesting.md) |
| `system.harvest.liquidate` | Liquidate harvest | Operator | [Harvesting](../player-api/harvesting.md) |

### Item Systems

| System ID | Description | Wallet | Page |
|-----------|-------------|--------|------|
| `system.item.burn` | Burn items | Operator | [Items](../player-api/items-and-crafting.md) |
| `system.item.transfer` | Transfer items | Operator | [Items](../player-api/items-and-crafting.md) |
| `system.craft` | Craft item from recipe | Operator | [Items](../player-api/items-and-crafting.md) |
| `system.droptable.item.reveal` | Reveal droptable items | Operator | [Items](../player-api/items-and-crafting.md) |

### Quest Systems

| System ID | Description | Wallet | Page |
|-----------|-------------|--------|------|
| `system.quest.accept` | Accept a quest | Operator | [Quests](../player-api/quests.md) |
| `system.quest.complete` | Complete a quest | Operator | [Quests](../player-api/quests.md) |

### Trade Systems

| System ID | Description | Wallet | Page |
|-----------|-------------|--------|------|
| `system.trade.create` | Create a trade | Operator | [Trading](../player-api/trading.md) |
| `system.trade.execute` | Execute a trade (taker) | Operator | [Trading](../player-api/trading.md) |
| `system.trade.complete` | Complete a trade (maker) | Operator | [Trading](../player-api/trading.md) |
| `system.trade.cancel` | Cancel a trade (maker) | Operator | [Trading](../player-api/trading.md) |

### Social / Friend Systems

| System ID | Description | Wallet | Page |
|-----------|-------------|--------|------|
| `system.friend.request` | Send friend request | Operator | [Social](../player-api/social.md) |
| `system.friend.accept` | Accept friend request | Operator | [Social](../player-api/social.md) |
| `system.friend.cancel` | Cancel/remove/unblock | Operator | [Social](../player-api/social.md) |
| `system.friend.block` | Block an account | Operator | [Social](../player-api/social.md) |

### Listing / Merchant Systems

| System ID | Description | Wallet | Page |
|-----------|-------------|--------|------|
| `system.listing.buy` | Buy from NPC merchant | Operator | [Listings](../player-api/listings.md) |
| `system.listing.sell` | Sell to NPC merchant | Operator | [Listings](../player-api/listings.md) |

### Gacha / Minting Systems

| System ID | Description | Wallet | Page |
|-----------|-------------|--------|------|
| `system.kami.gacha.mint` | Mint Kami with gacha ticket | Operator | [Minting](../player-api/minting.md) |
| `system.kami.gacha.reveal` | Reveal minted Kami | Operator | [Minting](../player-api/minting.md) |
| `system.kami.gacha.reroll` | Reroll Kami | Operator | [Minting](../player-api/minting.md) |
| `system.buy.gacha.ticket` | Buy gacha tickets | Operator | [Minting](../player-api/minting.md) |

### Portal Systems

| System ID | Description | Wallet | Page |
|-----------|-------------|--------|------|
| `system.kami721.stake` | Stake Kami NFT into game | Owner | [Portal](../player-api/portal.md) |
| `system.kami721.unstake` | Unstake Kami NFT from game | Owner | [Portal](../player-api/portal.md) |
| `system.kami721.transfer` | Transfer Kami NFT | Owner | [Portal](../player-api/portal.md) |
| `system.erc20.portal` | ERC20 deposit/withdraw | Owner | [Portal](../player-api/portal.md) |

### NPC / Relationship Systems

| System ID | Description | Wallet | Page |
|-----------|-------------|--------|------|
| `system.relationship.advance` | Advance NPC relationship | Operator | [Skills & Relationships](../player-api/skills-and-relationships.md) |

### Goal & Scavenge Systems

| System ID | Description | Wallet | Page |
|-----------|-------------|--------|------|
| `system.goal.contribute` | Contribute to goal | Operator | [Goals](../player-api/goals-and-scavenge.md) |
| `system.goal.claim` | Claim goal reward | Operator | [Goals](../player-api/goals-and-scavenge.md) |
| `system.scavenge.claim` | Claim scavenge points | Operator | [Goals](../player-api/goals-and-scavenge.md) |

### Auction Systems

| System ID | Description | Wallet | Page |
|-----------|-------------|--------|------|
| `system.auction.buy` | Buy from auction | Operator | ⚠️ TBD |

---

## Resolving System Addresses

All system addresses are resolved from the World contract using the hashed system ID:

```javascript
import { ethers } from "ethers";

const WORLD_ADDRESS = "0x2729174c265dbBd8416C6449E0E813E88f43D0E7";
const WORLD_ABI = ["function systems(uint256) view returns (address)"];

const provider = new ethers.JsonRpcProvider(
  "https://jsonrpc-yominet-1.anvil.asia-southeast.initia.xyz"
);
const world = new ethers.Contract(WORLD_ADDRESS, WORLD_ABI, provider);

async function getSystemAddress(systemStringId) {
  const hash = ethers.keccak256(ethers.toUtf8Bytes(systemStringId));
  return await world.systems(hash);
}

// Examples
const kamiLevelAddr = await getSystemAddress("system.kami.level");
const harvestStartAddr = await getSystemAddress("system.harvest.start");
```

---

## ABI Pattern

All systems follow the same ABI pattern inherited from `solecs/System.sol`:

```solidity
interface ISystem {
    // Generic entry point — calldata is ABI-encoded arguments
    function execute(bytes memory arguments) external returns (bytes memory);

    // Typed entry point — varies per system
    // e.g., for KamiLevelSystem:
    // function executeTyped(uint256 kamiID) external returns (bytes memory);
}
```

### Common ABI Fragment

```javascript
// This ABI works for calling any system's execute() function
const SYSTEM_ABI = [
  "function execute(bytes) returns (bytes)",
  "function executeTyped(uint256) returns (bytes)", // varies per system
];
```

> **Note:** The `executeTyped()` signature differs per system. Refer to individual [Player API](../player-api/overview.md) pages for exact typed signatures.

---

## Getter System

The **GetterSystem** provides read-only view functions (no gas required):

```javascript
const GETTER_ABI = [
  "function getKami(uint256 kamiId) view returns (tuple)",
  "function getAccount(uint256 accountId) view returns (tuple)",
];

// Resolve GetterSystem address first, then call
const getterAddr = await getSystemAddress("system.getter"); // ⚠️ TBD — verify system ID
const getter = new ethers.Contract(getterAddr, GETTER_ABI, provider);

const kamiData = await getter.getKami(kamiEntityId);
const accountData = await getter.getAccount(accountEntityId);
```

> **Note:** ⚠️ The exact GetterSystem ID and full return type signatures need verification from the Asphodel team.

---

## Related Pages

- [Live Addresses](live-addresses.md) — Core contract addresses
- [Player API Overview](../player-api/overview.md) — How to call systems
- [Architecture Overview](../architecture.md) — MUD ECS model
