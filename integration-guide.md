# Integration Guide

This guide walks third-party developers through integrating with Kamigotchi's on-chain systems. By the end, you'll be able to register accounts, manage Kamis, and interact with the full game API.

---

## Prerequisites

| Requirement | Details |
|-------------|---------|
| **Runtime** | Node.js v18+ |
| **Library** | ethers.js v6 (`npm install ethers`) |
| **Wallet** | An EOA with $ETH on Yominet for gas |
| **Network** | Yominet (Chain ID: `428962654539583`) |

---

## Step 1: Connect to Yominet

```javascript
import { ethers } from "ethers";

// Network configuration
const RPC_URL = "https://jsonrpc-yominet-1.anvil.asia-southeast.initia.xyz";
const CHAIN = { chainId: 428962654539583n, name: "Yominet" };

// Connect
const provider = new ethers.JsonRpcProvider(RPC_URL, CHAIN);

// Verify connection
const blockNumber = await provider.getBlockNumber();
console.log("Connected to Yominet (block:", blockNumber + ")");
```

---

## Step 2: Set Up Wallets

Kamigotchi uses a **dual-wallet model**. The official game client handles this via [Privy](https://privy.io) — players connect their external wallet (Owner), and Privy auto-creates an embedded wallet (Operator). For programmatic integrations, you manage both wallets directly:

```javascript
// Owner wallet — holds NFTs, registers account, does privileged operations
const ownerSigner = new ethers.Wallet(process.env.OWNER_PRIVATE_KEY, provider);

// Operator wallet — handles routine gameplay transactions
// (In the official client, this is Privy's embedded wallet)
const operatorSigner = new ethers.Wallet(process.env.OPERATOR_PRIVATE_KEY, provider);

console.log("Owner:", ownerSigner.address);
console.log("Operator:", operatorSigner.address);
```

> **Note:** In production, use secure key management. Never hardcode private keys.

---

## Step 3: Set Up World Contract Helper

```javascript
const WORLD_ADDRESS = "0x2729174c265dbBd8416C6449E0E813E88f43D0E7";
const WORLD_ABI = ["function systems(uint256) view returns (address)"];
const world = new ethers.Contract(WORLD_ADDRESS, WORLD_ABI, provider);

// Cache for system addresses
const systemCache = new Map();

async function getSystemAddress(systemId) {
  if (!systemCache.has(systemId)) {
    const hash = ethers.keccak256(ethers.toUtf8Bytes(systemId));
    const addr = await world.systems(hash);
    if (addr === ethers.ZeroAddress) {
      throw new Error(`System not found: ${systemId}`);
    }
    systemCache.set(systemId, addr);
  }
  return systemCache.get(systemId);
}

async function getSystem(systemId, abi, signer) {
  const address = await getSystemAddress(systemId);
  return new ethers.Contract(address, abi, signer);
}
```

---

## Step 4: Register an Account

```javascript
const REGISTER_ABI = [
  "function executeTyped(address operatorAddress, string name) returns (bytes)",
];

const registerSystem = await getSystem(
  "system.account.register",
  REGISTER_ABI,
  ownerSigner // Must use owner wallet
);

const tx = await registerSystem.executeTyped(
  operatorSigner.address,
  "MyBotAccount"
);
const receipt = await tx.wait();
console.log("Account registered! Tx:", receipt.hash);
```

---

## Step 5: Perform Basic Actions

### Move to a Room

```javascript
const MOVE_ABI = ["function executeTyped(uint32 roomIndex) returns (bytes)"];
const moveSystem = await getSystem(
  "system.account.move",
  MOVE_ABI,
  operatorSigner
);

const tx = await moveSystem.executeTyped(1, { gasLimit: 1_200_000 });
await tx.wait();
console.log("Moved to room 1");
```

### Start Harvesting

```javascript
const HARVEST_ABI = [
  "function executeTyped(uint256 kamiID, uint32 nodeIndex, uint256 taxerID, uint256 taxAmt) returns (bytes)",
];
const harvestSystem = await getSystem(
  "system.harvest.start",
  HARVEST_ABI,
  operatorSigner
);

const tx = await harvestSystem.executeTyped(myKamiId, harvestNodeIndex, 0, 0);
await tx.wait();
console.log("Harvesting started");
```

### Collect Harvest Rewards

```javascript
const COLLECT_ABI = [
  "function executeTyped(uint256 id) returns (bytes)",
];
const collectSystem = await getSystem(
  "system.harvest.collect",
  COLLECT_ABI,
  operatorSigner
);

const tx = await collectSystem.executeTyped(harvestId);
await tx.wait();
console.log("Rewards collected");
```

### Level Up a Kami

```javascript
const LEVEL_ABI = [
  "function executeTyped(uint256 kamiID) returns (bytes)",
];
const levelSystem = await getSystem(
  "system.kami.level",
  LEVEL_ABI,
  operatorSigner
);

const tx = await levelSystem.executeTyped(kamiId);
await tx.wait();
console.log("Kami leveled up!");
```

---

## Step 6: Read Game State

```javascript
const GETTER_ABI = [
  "function getKami(uint256 kamiId) view returns (tuple)",
  "function getAccount(uint256 accountId) view returns (tuple)",
];

const getterAddr = await getSystemAddress("system.getter");
const getter = new ethers.Contract(getterAddr, GETTER_ABI, provider);

// No gas cost — read-only
const kamiData = await getter.getKami(kamiId);
console.log("Kami data:", kamiData);
```

---

## Step 7: Stake a Kami NFT

```javascript
const KAMI721_ADDRESS = "0x5d4376b62fa8ac16dfabe6a9861e11c33a48c677";

// The ERC-721 token ID is also the tokenIndex for the stake system
const tokenIndex = tokenId; // For Kami721, token ID === token index

// Approve NFT transfer
const kami721 = new ethers.Contract(
  KAMI721_ADDRESS,
  ["function approve(address to, uint256 tokenId)"],
  ownerSigner
);
await (await kami721.approve(WORLD_ADDRESS, tokenIndex)).wait();

// Stake into game
const STAKE_ABI = ["function executeTyped(uint32 tokenIndex) returns (bytes)"];
const stakeSystem = await getSystem(
  "system.kami721.stake",
  STAKE_ABI,
  ownerSigner
);

await (await stakeSystem.executeTyped(tokenIndex)).wait();
console.log("Kami NFT staked into game!");
```

> **Note:** For Kami721 NFTs, the ERC-721 `tokenId` from the NFT contract IS the `tokenIndex` parameter passed to the stake system. They are the same value. The account must be in room 12 (Scrap Confluence / Bridge) to stake.

---

## What's Next

Now that you've registered, set up wallets, and can call systems — you'll need to work with **entity IDs** for real gameplay. Entity IDs are how Kamigotchi identifies everything: your account, your Kamis, active harvests, trades, and quests.

👉 **[Entity Discovery](player-api/entity-discovery.md)** — Learn how to derive and find all the entity IDs you need, with a complete helper library.

👉 **[Game Data Reference](references/game-data.md)** — Lookup tables for item indices, room indices, skill trees, quest chains, and harvest node data.

---

## Complete Example Script

```javascript
// complete-example.js
import { ethers } from "ethers";

// --- Config ---
const RPC_URL = "https://jsonrpc-yominet-1.anvil.asia-southeast.initia.xyz";
const WORLD_ADDRESS = "0x2729174c265dbBd8416C6449E0E813E88f43D0E7";

// --- Setup ---
const provider = new ethers.JsonRpcProvider(RPC_URL, {
  chainId: 428962654539583n,
  name: "Yominet",
});

const ownerSigner = new ethers.Wallet(process.env.OWNER_KEY, provider);
const operatorSigner = new ethers.Wallet(process.env.OPERATOR_KEY, provider);

const world = new ethers.Contract(
  WORLD_ADDRESS,
  ["function systems(uint256) view returns (address)"],
  provider
);

const cache = new Map();
async function sys(id, abi, signer) {
  if (!cache.has(id)) {
    const hash = ethers.keccak256(ethers.toUtf8Bytes(id));
    cache.set(id, await world.systems(hash));
  }
  return new ethers.Contract(cache.get(id), abi, signer);
}

// --- Main ---
async function main() {
  console.log("Owner:", ownerSigner.address);
  console.log("Operator:", operatorSigner.address);

  // 1. Register
  const reg = await sys(
    "system.account.register",
    ["function executeTyped(address, string) returns (bytes)"],
    ownerSigner
  );
  await (await reg.executeTyped(operatorSigner.address, "MyAccount")).wait();
  console.log("✅ Registered");

  // 2. Move to room 1
  const move = await sys(
    "system.account.move",
    ["function executeTyped(uint32) returns (bytes)"],
    operatorSigner
  );
  await (await move.executeTyped(1, { gasLimit: 1_200_000 })).wait();
  console.log("✅ Moved to room 1");

  // 3. Send a chat message
  const chat = await sys(
    "system.chat",
    ["function executeTyped(string) returns (bytes)"],
    operatorSigner
  );
  await (await chat.executeTyped("Hello from the API!")).wait();
  console.log("✅ Chat sent");

  console.log("🎮 Integration complete!");
}

main().catch(console.error);
```

---

## Gas Quick Reference

| Operation | Gas Limit | Notes |
|-----------|-----------|-------|
| Most systems | Default | Let the provider estimate |
| `account.move()` | 1,200,000 | Rooms with gates |
| `harvest.liquidate()` | 7,500,000 | Complex PvP logic |
| `pet.mint(n)` | 4M + 3M × n | Scales with mint count |

---

## Common Pitfalls

| Issue | Solution |
|-------|----------|
| `"Not owner"` revert | Use the **owner wallet** for privileged operations |
| `"Not registered"` revert | Call `register()` first |
| System address is `0x0` | Check the system ID string for typos |
| Transaction reverts silently | Wrap in try/catch and check `error.reason` |
| Stale UI data | Call `echo.kamis()` or `echo.room()` to force-emit |
| NFT staking fails | Approve the World contract first |
| ERC20 deposit fails | Approve the World contract for the token amount |

---

## Architecture Quick Reference

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ Owner Wallet │     │   World      │     │  Components  │
│ (register,   │────▶│  (registry)  │────▶│  (state)     │
│  NFTs, ONYX) │     │              │     │              │
└──────────────┘     │  ┌────────┐  │     │ Health       │
                     │  │System A│  │     │ Power        │
┌──────────────┐     │  │System B│  │     │ Inventory    │
│ Operator     │────▶│  │System C│  │     │ Position     │
│ Wallet       │     │  └────────┘  │     │ ...          │
│ (gameplay)   │     └──────────────┘     └──────────────┘
└──────────────┘
```

---

## Next Steps

1. **Explore the API** — Browse the [Player API pages](player-api/overview.md) for full function documentation
2. **Check contracts** — See [Live Addresses](contracts/live-addresses.md) and [System IDs](contracts/ids-and-abis.md)
3. **Understand the chain** — Review [Chain Configuration](chain-configuration.md) for network details
4. **Read the architecture** — [Architecture Overview](architecture.md) explains the MUD ECS model

---

## Support

For questions, integration support, or to report issues, contact the Asphodel team directly.
