# Player API — Overview & Setup

The Kamigotchi Player API is a set of on-chain **System contracts** that handle all game actions. This page covers how to set up your environment and call any system.

---

## Prerequisites

- **Node.js** v18+ and **ethers.js v6**
- A wallet with $ETH on Yominet for gas (see [Chain Configuration](../chain-configuration.md))
- The World contract address

```bash
npm install ethers
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
  chainId: 428962654539583n,
  name: "Yominet Testnet",
});

// Operator wallet for regular gameplay
const operatorSigner = new ethers.Wallet("YOUR_OPERATOR_PRIVATE_KEY", provider);

// Owner wallet for privileged actions (register, NFTs, ONYX)
const ownerSigner = new ethers.Wallet("YOUR_OWNER_PRIVATE_KEY", provider);

// --- World Contract ---
const WORLD_ABI = ["function systems(uint256) view returns (address)"];
const world = new ethers.Contract(WORLD_ADDRESS, WORLD_ABI, provider);

// --- Helper: Resolve System Address ---
async function getSystemAddress(systemId) {
  const hash = ethers.keccak256(ethers.toUtf8Bytes(systemId));
  return await world.systems(hash);
}

// --- Helper: Get System Contract ---
async function getSystem(systemId, abi, signer) {
  const address = await getSystemAddress(systemId);
  return new ethers.Contract(address, abi, signer);
}
```

---

## Wallet Model

Kamigotchi uses two wallets per player:

| Wallet | Purpose | Used For |
|--------|---------|----------|
| **Owner** | Primary wallet, holds NFTs | `register`, `set.name`, `set.pfp`, `set.operator`, all `onyx.*`, ERC721 stake/unstake |
| **Operator** | Delegated session wallet | Everything else — move, chat, harvest, trade, quest, craft, etc. |

> **Note:** The operator wallet is set during `register()` and can be changed with `set.operator()`. In the official client, Privy manages the operator wallet as an embedded wallet.

### Determining Which Wallet to Use

Each function in this documentation includes a **Wallet** badge:

- 🔐 **Owner** — Must be called from the owner wallet
- 🎮 **Operator** — Can be called from the operator wallet

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
| `system.kami.gacha.mint` | 4,000,000 + 3,000,000/pet | Scales with mint amount |

```javascript
// Example: setting gas limit explicitly
const tx = await moveSystem.executeTyped(roomIndex, {
  gasLimit: 1_200_000,
});
```

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
const GETTER_ABI = [
  "function getKami(uint256 kamiId) view returns (tuple)",
  "function getAccount(uint256 accountId) view returns (tuple)",
];

const getterAddr = await getSystemAddress("system.getter"); // ⚠️ TBD — verify system ID
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
  chainId: 428962654539583n,
  name: "Yominet Testnet",
});

const WORLD_ABI = ["function systems(uint256) view returns (address)"];
export const world = new ethers.Contract(WORLD_ADDRESS, WORLD_ABI, provider);

const systemCache = new Map();

export async function getSystemAddress(systemId) {
  if (!systemCache.has(systemId)) {
    const hash = ethers.keccak256(ethers.toUtf8Bytes(systemId));
    const addr = await world.systems(hash);
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
import { getSystem, provider } from "./kamigotchi.js";
```

---

## API Pages

| Page | Systems Covered |
|------|----------------|
| [Echo](echo.md) | `system.echo.kamis`, `system.echo.room` |
| [Kami (Pets)](kami.md) | Level, name, sacrifice, equip, items, skills, ONYX |
| [Account](account.md) | Register, move, settings, chat |
| [Harvesting](harvesting.md) | Start, stop, collect, liquidate |
| [Quests](quests.md) | Accept, complete |
| [Trading](trading.md) | Create, execute, complete, cancel |
| [Social / Friends](social.md) | Request, accept, cancel, block |
| [Items & Crafting](items-and-crafting.md) | Burn, craft, use, transfer, droptable |
| [Merchant Listings](listings.md) | Buy, sell |
| [Skills & Relationships](skills-and-relationships.md) | Skill upgrade/reset, NPC relationships |
| [Goals & Scavenge](goals-and-scavenge.md) | Contribute, claim |
| [Gacha / Minting](minting.md) | Mint, reveal, reroll, tickets |
| [Portal](portal.md) | ERC721 stake/unstake, ERC20 deposit/withdraw |
