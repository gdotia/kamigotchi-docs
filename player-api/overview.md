# Player API — Overview & Setup

The Kamigotchi Player API is a set of on-chain **System contracts** that handle all game actions. This page covers how to set up your environment and call any system.

If you are starting from zero, run through [Agent Bootstrap](../agent-bootstrap.md) first, then come back here.

---

## Prerequisites

- **Node.js** v18+ and **ethers.js v6**
- **ESM mode** enabled (`"type": "module"` in `package.json`)
- **Environment variables** set for `OWNER_PRIVATE_KEY` and `OPERATOR_PRIVATE_KEY`
- A wallet with $ETH on Yominet for gas (see [Chain Configuration](../chain-configuration.md))
- The World contract address

```bash
npm init -y
npm install ethers
npm pkg set type=module
```

---

## Quick Start

```javascript
import { ethers } from "ethers";

// --- Configuration ---
const RPC_URL = "https://jsonrpc-yominet-1.anvil.asia-southeast.initia.xyz";
const WORLD_ADDRESS = "0x2729174c265dbBd8416C6449E0E813E88f43D0E7";

// --- Provider & Signer ---
const provider = new ethers.JsonRpcProvider(RPC_URL, {
  chainId: 428962654539583,
  name: "Yominet",
});

function mustEnv(name) {
  const value = process.env[name];
  if (!value || !value.startsWith("0x")) {
    throw new Error(`Missing ${name}. Set it in your shell before running.`);
  }
  return value;
}

// Operator wallet for regular gameplay
const operatorSigner = new ethers.Wallet(mustEnv("OPERATOR_PRIVATE_KEY"), provider);

// Owner wallet for privileged actions (register, NFTs, ONYX)
const ownerSigner = new ethers.Wallet(mustEnv("OWNER_PRIVATE_KEY"), provider);

// --- World Contract ---
const WORLD_ABI = [
  "function systems() view returns (address)",
  "function systems(uint256) view returns (address)", // legacy worlds
];
const SYSTEMS_COMPONENT_ABI = [
  "function getEntitiesWithValue(uint256) view returns (uint256[])",
];
const world = new ethers.Contract(WORLD_ADDRESS, WORLD_ABI, provider);

// --- Helper: Resolve System Address ---
async function getSystemAddress(systemId) {
  const hash = ethers.keccak256(ethers.toUtf8Bytes(systemId));

  // Legacy deployment path (systems(uint256) -> address)
  try {
    const legacyAddr = await world["systems(uint256)"](hash);
    if (legacyAddr !== ethers.ZeroAddress) return legacyAddr;
  } catch (_) {}

  // Current Yominet path:
  // World.systems() -> SystemsComponent (systemAddress -> systemId)
  const systemsComponentAddr = await world["systems()"]();
  const systemsComponent = new ethers.Contract(
    systemsComponentAddr,
    SYSTEMS_COMPONENT_ABI,
    provider
  );
  const entities = await systemsComponent.getEntitiesWithValue(hash);
  if (entities.length === 0) throw new Error(`System not found: ${systemId}`);
  return ethers.getAddress(ethers.toBeHex(entities[0], 20));
}

// --- Helper: Get System Contract ---
async function getSystem(systemId, abi, signer) {
  const address = await getSystemAddress(systemId);
  return new ethers.Contract(address, abi, signer);
}
```

> **Important:** In ethers v6, pass `chainId` as a number (not `BigInt`) in the provider network object.

---

## Wallet Model

Kamigotchi uses two wallets per player:

| Wallet | Purpose | Used For |
|--------|---------|----------|
| **Owner** | Primary wallet, holds NFTs | `register`, `set.name`, `set.operator`, `onyx.rename` (currently disabled)/`onyx.respec` (currently disabled), ERC721 stake/unstake, ERC20 portal, trade, item transfer, `kamimarket.buy`, `newbievendor.buy`, `auction.buy`, gacha tickets, gacha mint/reroll |
| **Operator** | Delegated session wallet | move, chat, harvest, quest, craft, `set.pfp`, `set.bio`, `onyx.revive`, `kamimarket.list`, `kamimarket.offer`, `kamimarket.acceptoffer`, `kamimarket.cancel`, `kami.send`, etc. |

> **Note:** The operator wallet is set during `register()` and can be changed with `set.operator()`. In the official client, Privy manages the operator wallet as an embedded wallet.

### New Player Path

After registering, new players need to acquire their first Kami before they can participate in gameplay. The recommended first path is **Newbie Vendor** (one transaction, no reveal). Gacha is the main alternative path after funding in-game ETH (item 103). See the [Integration Guide](../integration-guide.md#step-5-get-your-first-kami) for the full walkthrough.

### Determining Which Wallet to Use

Each function in this documentation includes a **Wallet** badge:

- 🔐 **Owner** — Must be called from the owner wallet
- 🎮 **Operator** — Can be called from the operator wallet

---

## Payment Methods

Kamigotchi uses two distinct payment mechanisms depending on the system:

### Native ETH (`msg.value`)

Some systems accept payment as native ETH sent directly with the transaction (i.e., via `msg.value`). These are `payable` functions:

| System | Usage |
|--------|-------|
| `system.newbievendor.buy` | Buy first Kami from the Newbie Vendor at TWAP price |
| `system.kamimarket.buy` | Purchase Kami listing(s) from the marketplace |

```javascript
// Example: payable call with msg.value
const tx = await vendorSystem.executeTyped(kamiIndex, { value: price });
```

### In-Game ETH Balance (Item 103)

Certain systems use an **in-game ETH balance** (tracked as item index `103`) rather than `msg.value`. This balance is deposited into the game via `system.erc20.portal`:

| System | Usage |
|--------|-------|
| `system.buy.gacha.ticket` | Buy gacha tickets — debits from in-game ETH balance (NOT `msg.value`) |
| `system.kamimarket.offer` | WETH offer amount — requires WETH approval to KamiMarketVault |

To fund your in-game ETH balance, deposit WETH via the ERC20 portal:

```javascript
// 1. Approve WETH spend to the World contract
// 2. Deposit WETH as item 103
await portalSystem.deposit(103, depositAmount);
```

> **Key distinction:** If a system is `payable`, you send native ETH. If it deducts from inventory item 103, you must deposit WETH via the ERC20 portal first. Check each system's documentation for which method it uses.

---

## Calling Convention

All systems follow the MUD pattern:

### Option A: `executeTyped()` (Recommended)

Each system exposes a typed function with named parameters:

```javascript
const LEVEL_ABI = ["function executeTyped(uint256 kamiID) returns (bytes)"];
const levelSystem = await getSystem("system.kami.level", LEVEL_ABI, operatorSigner);

const tx = await levelSystem.executeTyped(kamiEntityId);
await tx.wait();
```

### Option B: `execute(bytes)` (Generic)

Encode arguments manually:

```javascript
const SYSTEM_ABI = ["function execute(bytes) returns (bytes)"];
const levelSystem = await getSystem("system.kami.level", SYSTEM_ABI, operatorSigner);

const calldata = ethers.AbiCoder.defaultAbiCoder().encode(
  ["uint256"],
  [kamiEntityId]
);
const tx = await levelSystem.execute(calldata);
await tx.wait();
```

---

## Gas Limits

Most calls work with default gas estimation, but some systems require **hardcoded gas limits**:

| System | Gas Limit | Reason |
|--------|-----------|--------|
| `system.account.move` | 1,200,000 | Upper bound for rooms with gates |
| `system.harvest.liquidate` | 7,500,000 | Complex liquidation logic |
| `system.kami.gacha.mint` | 4,000,000 + 3,000,000/kami | Scales with mint amount |

```javascript
// Example: setting gas limit explicitly
const tx = await moveSystem.executeTyped(roomIndex, {
  gasLimit: 1_200_000,
});
```

For systems with "Default" gas, ethers.js gas estimation works correctly on Yominet. No manual `gasLimit` override is needed.

---

## Error Handling

System calls revert with Solidity error messages. Wrap calls in try/catch:

```javascript
try {
  const tx = await system.executeTyped(args);
  const receipt = await tx.wait();
  console.log("Success:", receipt.hash);
} catch (error) {
  if (error.reason) {
    console.error("Revert reason:", error.reason);
  } else {
    console.error("Transaction failed:", error.message);
  }
}
```

Common revert reasons:

| Error | Cause |
|-------|-------|
| `"Not owner"` | Called an Owner-only function from operator wallet |
| `"Not registered"` | Account not yet registered |
| `"Insufficient XP"` | Kami doesn't have enough XP to level up |
| `"Already harvesting"` | Kami is already assigned to a harvest |

---

## Caching System Addresses

System addresses rarely change. Cache them to avoid repeated RPC calls:

```javascript
const systemCache = new Map();

async function getCachedSystem(systemId, abi, signer) {
  if (!systemCache.has(systemId)) {
    const address = await getSystemAddress(systemId);
    systemCache.set(systemId, address);
  }
  return new ethers.Contract(systemCache.get(systemId), abi, signer);
}
```

> **Note:** If a system is upgraded by the Asphodel team, you'll need to clear your cache. This is rare but possible in the MUD framework.

---

## Reading State

Use the **GetterSystem** for read-only queries (no gas cost):

```javascript
// Full ABI with struct fields — required for ethers.js to decode named return values.
// See contracts/ids-and-abis.md → Getter System for the complete reference.
const GETTER_ABI = [
  "function getKami(uint256 kamiId) view returns (tuple(uint256 id, uint32 index, string name, string mediaURI, tuple(tuple(int32 base, int32 shift, int32 boost, int32 sync) health, tuple(int32 base, int32 shift, int32 boost, int32 sync) power, tuple(int32 base, int32 shift, int32 boost, int32 sync) harmony, tuple(int32 base, int32 shift, int32 boost, int32 sync) violence) stats, tuple(uint32 face, uint32 hand, uint32 body, uint32 background, uint32 color) traits, string[] affinities, uint256 account, uint256 level, uint256 xp, uint32 room, string state))",
  "function getAccount(uint256 accountId) view returns (tuple(uint32 index, string name, int32 currStamina, uint32 room))",
];

const getterAddr = await getSystemAddress("system.getter"); // ID = keccak256("system.getter")
const getter = new ethers.Contract(getterAddr, GETTER_ABI, provider);

// Read without spending gas
const kamiData = await getter.getKami(kamiId);
const accountData = await getter.getAccount(accountId);
```

---

## Full Helper Module

Here's a reusable helper module for all examples in this documentation:

```javascript
// kamigotchi.js — Reusable helper module
import { ethers } from "ethers";

export const RPC_URL = "https://jsonrpc-yominet-1.anvil.asia-southeast.initia.xyz";
export const WORLD_ADDRESS = "0x2729174c265dbBd8416C6449E0E813E88f43D0E7";

export const provider = new ethers.JsonRpcProvider(RPC_URL, {
  chainId: 428962654539583,
  name: "Yominet",
});

function mustEnv(name) {
  const value = process.env[name];
  if (!value || !value.startsWith("0x")) {
    throw new Error(`Missing ${name}. Set it in your shell before running.`);
  }
  return value;
}

export const ownerSigner = new ethers.Wallet(mustEnv("OWNER_PRIVATE_KEY"), provider);
export const operatorSigner = new ethers.Wallet(mustEnv("OPERATOR_PRIVATE_KEY"), provider);

const WORLD_ABI = [
  "function systems() view returns (address)",
  "function systems(uint256) view returns (address)", // legacy worlds
];
const SYSTEMS_COMPONENT_ABI = [
  "function getEntitiesWithValue(uint256) view returns (uint256[])",
];
export const world = new ethers.Contract(WORLD_ADDRESS, WORLD_ABI, provider);

const systemCache = new Map();

export async function getSystemAddress(systemId) {
  if (!systemCache.has(systemId)) {
    const hash = ethers.keccak256(ethers.toUtf8Bytes(systemId));
    let addr = ethers.ZeroAddress;

    // Legacy deployment path
    try {
      addr = await world["systems(uint256)"](hash);
    } catch (_) {}

    // Current Yominet path
    if (addr === ethers.ZeroAddress) {
      const systemsComponentAddr = await world["systems()"]();
      const systemsComponent = new ethers.Contract(
        systemsComponentAddr,
        SYSTEMS_COMPONENT_ABI,
        provider
      );
      const entities = await systemsComponent.getEntitiesWithValue(hash);
      if (entities.length === 0) throw new Error(`System not found: ${systemId}`);
      addr = ethers.getAddress(ethers.toBeHex(entities[0], 20));
    }

    systemCache.set(systemId, addr);
  }
  return systemCache.get(systemId);
}

export async function getSystem(systemId, abi, signer) {
  const address = await getSystemAddress(systemId);
  return new ethers.Contract(address, abi, signer);
}
```

All code examples in this documentation import from this module:

```javascript
import {
  getSystem,
  provider,
  ownerSigner,
  operatorSigner,
} from "./kamigotchi.js";
```

Most API snippets assume these exports are already in scope.

---

## API Pages

| Page | Systems Covered |
|------|----------------|
| [Echo](echo.md) | `system.echo.kamis`, `system.echo.room` |
| [Kami](kami.md) | Level, name, sacrifice, equip, items, skills, ONYX, send |
| [Account](account.md) | Register, move, settings, chat |
| [Harvesting](harvesting.md) | Start, stop, collect, liquidate |
| [Quests](quests.md) | Accept, complete, drop |
| [Trading](trading.md) | Create, execute, complete, cancel |
| [Social / Friends](social.md) | Request, accept, cancel, block |
| [Items & Crafting](items-and-crafting.md) | Burn, craft, use, transfer, droptable |
| [Merchant Listings](listings.md) | Buy, sell |
| [Skills & Relationships](skills-and-relationships.md) | Skill upgrade/reset, NPC relationships |
| [Goals & Scavenge](goals-and-scavenge.md) | Contribute, claim |
| [Gacha / Minting](minting.md) | Mint, reveal, reroll, tickets |
| [Portal](portal.md) | ERC721 stake/unstake, ERC20 deposit/withdraw |
| [Entity Discovery](entity-discovery.md) | Entity ID derivation and lookup |
| [KamiSwap Marketplace](marketplace.md) | List, buy, offer, cancel |
