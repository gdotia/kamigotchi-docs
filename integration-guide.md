# Integration Guide

This guide walks third-party developers through integrating with Kamigotchi's on-chain systems. By the end, you'll be able to register accounts, manage Kamis, and interact with the full game API.

If you want the shortest first-run path for a new bot developer, start with [Agent Bootstrap](agent-bootstrap.md) and return here for the full flow.

---

## Prerequisites

| Requirement | Details |
|-------------|---------|
| **Runtime** | Node.js v18+ (v20+ recommended) |
| **Library** | ethers.js v6 |
| **Module Mode** | ESM (`"type": "module"` in `package.json`) |
| **Environment** | `OWNER_PRIVATE_KEY` and `OPERATOR_PRIVATE_KEY` |
| **Wallet** | An EOA with $ETH on Yominet for gas |
| **Network** | Yominet (Chain ID: `428962654539583`) |

---

## Funding Your Wallet

**There is no faucet on Yominet.** You must bridge real ETH before you can transact.

Two options:

1. **In-game bridge** — Open the Kamigotchi client, go to Settings > Bridge (uses the Initia bridge).
2. **gas.zip** — A third-party bridge aggregator that supports Yominet.

**Cost summary:**

| Action | Cost | Currency |
|--------|------|----------|
| Gas (thousands of txs) | ~0.001 ETH | Native ETH |
| Newbie Vendor (first Kami) | 0.005-0.05 ETH | Native ETH (msg.value) |
| Gacha ticket (public) | 0.1 ETH each | In-game ETH (item 103, deposited via Portal) |
| Marketplace listing | Variable | Native ETH (msg.value) |
| Marketplace offer | Variable | WETH (approval-based) |

**Recommended starting budget:** 0.2-0.5 ETH bridged to Yominet.

> **Note:** Fund **both** your Owner and Operator wallets. Both need ETH for gas since they each submit transactions.

---

## Step 0: Create a Runnable Project

```bash
mkdir kamigotchi-agent
cd kamigotchi-agent
npm init -y
npm install ethers
npm pkg set type=module

# Linux/macOS
export OWNER_PRIVATE_KEY=0xYOUR_OWNER_PRIVATE_KEY
export OPERATOR_PRIVATE_KEY=0xYOUR_OPERATOR_PRIVATE_KEY
```

> **Windows PowerShell:** use `$env:OWNER_PRIVATE_KEY="0x..."` and `$env:OPERATOR_PRIVATE_KEY="0x..."`.

---

## Step 1: Connect to Yominet

```javascript
import { ethers } from "ethers";

// Network configuration
const RPC_URL = "https://jsonrpc-yominet-1.anvil.asia-southeast.initia.xyz";
const CHAIN = { chainId: 428962654539583, name: "Yominet" };

// Connect
const provider = new ethers.JsonRpcProvider(RPC_URL, CHAIN);

// Verify connection
const blockNumber = await provider.getBlockNumber();
console.log(`Connected to Yominet (block: ${blockNumber})`);
```

> **Important:** In ethers v6, use a numeric `chainId` in the provider network object.

---

## Step 2: Set Up Wallets

Kamigotchi uses a **dual-wallet model**. The official game client handles this via [Privy](https://privy.io) — players connect their external wallet (Owner), and Privy auto-creates an embedded wallet (Operator). For programmatic integrations, you manage both wallets directly:

```javascript
function mustEnv(name) {
  const value = process.env[name];
  if (!value || !value.startsWith("0x")) {
    throw new Error(`Missing ${name}. Set it before running this script.`);
  }
  return value;
}

// Owner wallet — holds NFTs, registers account, does privileged operations
const ownerSigner = new ethers.Wallet(mustEnv("OWNER_PRIVATE_KEY"), provider);

// Operator wallet — handles routine gameplay transactions
// (In the official client, this is Privy's embedded wallet)
const operatorSigner = new ethers.Wallet(mustEnv("OPERATOR_PRIVATE_KEY"), provider);

console.log("Owner:", ownerSigner.address);
console.log("Operator:", operatorSigner.address);
```

> **Note:** In production, use secure key management. Never hardcode private keys.

---

## Step 3: Set Up World Contract Helper

```javascript
const WORLD_ADDRESS = "0x2729174c265dbBd8416C6449E0E813E88f43D0E7";
const WORLD_ABI = [
  "function systems() view returns (address)",
  "function systems(uint256) view returns (address)", // legacy worlds
];
const SYSTEMS_COMPONENT_ABI = [
  "function getEntitiesWithValue(uint256) view returns (uint256[])",
];
const world = new ethers.Contract(WORLD_ADDRESS, WORLD_ABI, provider);

// Cache for system addresses
const systemCache = new Map();

async function getSystemAddress(systemId) {
  if (!systemCache.has(systemId)) {
    const hash = ethers.keccak256(ethers.toUtf8Bytes(systemId));

    // Legacy deployment path (systems(uint256) -> address)
    try {
      const legacyAddr = await world["systems(uint256)"](hash);
      if (legacyAddr !== ethers.ZeroAddress) {
        systemCache.set(systemId, legacyAddr);
        return legacyAddr;
      }
    } catch (_) {}

    // Current Yominet path:
    // World.systems() -> SystemsComponent, keyed by systemAddress -> systemId
    const systemsComponentAddr = await world["systems()"]();
    const systemsComponent = new ethers.Contract(
      systemsComponentAddr,
      SYSTEMS_COMPONENT_ABI,
      provider
    );
    const entities = await systemsComponent.getEntitiesWithValue(hash);
    if (entities.length === 0) {
      throw new Error(`System not found in registry: ${systemId}`);
    }
    const addr = ethers.getAddress(ethers.toBeHex(entities[0], 20));
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

## Step 5: Get Your First Kami

After registering, you need at least one Kami to participate in gameplay (harvesting, quests, combat). There are four ways to acquire a Kami:

### Option A: Newbie Vendor (Recommended for New Players)

The **Newbie Vendor** lets new accounts buy their first Kami at a fair TWAP-derived price. This is the simplest way to get started — one transaction, no reveal step.

```javascript
const VENDOR_ABI = [
  "function executeTyped(uint32 kamiIndex) payable returns (bytes)",
  "function calcPrice() view returns (uint256)",
];
const vendorSystem = await getSystem("system.newbievendor.buy", VENDOR_ABI, ownerSigner);

// Check the current vendor price (view call — no gas)
const price = await vendorSystem.calcPrice();
console.log("Vendor price:", ethers.formatEther(price), "ETH");

// Determine the currently valid index:
// - If your UI/indexer provides candidates, pass them in NEWBIE_VENDOR_CANDIDATES (comma-separated)
// - Otherwise probe default slot indices [0, 1, 2]
const candidates = (process.env.NEWBIE_VENDOR_CANDIDATES ?? "0,1,2")
  .split(",")
  .map((v) => Number(v.trim()))
  .filter((v) => Number.isInteger(v));

let kamiIndex = null;
for (const candidate of candidates) {
  try {
    // Preflight check to avoid spending gas on an invalid display index
    await vendorSystem.executeTyped.staticCall(candidate, { value: price });
    kamiIndex = candidate;
    break;
  } catch (_) {}
}

if (kamiIndex === null) {
  throw new Error(
    "No valid vendor index found. Refresh vendor display, update NEWBIE_VENDOR_CANDIDATES, and retry."
  );
}

console.log("Selected vendor index:", kamiIndex);
const tx = await vendorSystem.executeTyped(kamiIndex, { value: price });
await tx.wait();
console.log("First Kami purchased from the Newbie Vendor!");
```

> **Selecting `kamiIndex`:** this flow uses a concrete preflight probe (`executeTyped.staticCall`) to find a currently valid index from your candidate list before sending a paid tx.

> **Restrictions:** One purchase per account, only within 24 hours of registration. Minimum price 0.005 ETH. The purchased Kami is soulbound for 3 days (cannot be listed or unstaked). See [KamiSwap — Marketplace](player-api/marketplace.md) for full details.

> **Finding your Kami's entity ID after purchase:** After a successful vendor buy, you need the Kami's entity ID to use it in gameplay systems (harvesting, combat, etc.). The entity ID is derived as `keccak256(abi.encodePacked("kami.id", uint32(kamiTokenIndex)))`. You can find the `kamiTokenIndex` from the purchase transaction's events, or by querying your account's Kami list via the getter system. See [Entity Discovery](player-api/entity-discovery.md) for the full derivation helpers.

### Option B: Gacha Minting

The standard gacha flow is: **deposit ETH → buy a gacha ticket → mint → reveal**.

> **Important:** Gacha tickets are paid from your **in-game ETH balance** (item index 103), NOT native ETH. You must first deposit ETH via `system.erc20.portal` — see [Portal](player-api/portal.md).

```javascript
// 0. Deposit ETH into the game first (see Portal docs for full example)
// await portalSystem.deposit(103, ethers.parseEther("0.1"));

// 1. Buy a gacha ticket (costs in-game ETH — see minting docs for current price)
const BUY_ABI = ["function buyPublic(uint256 amount)"];
const buySystem = await getSystem("system.buy.gacha.ticket", BUY_ABI, ownerSigner);

await (await buySystem.buyPublic(1)).wait();
console.log("Gacha ticket purchased!");

// 2. Mint — commits the randomness (consumes the ticket)
const MINT_ABI = ["function executeTyped(uint256 amount) returns (bytes)"];
const mintSystem = await getSystem("system.kami.gacha.mint", MINT_ABI, ownerSigner);

const mintAmount = 1;

// Preflight only: staticCall can drift from mined results if state changes.
const encodedPreflightCommitIds = await mintSystem.executeTyped.staticCall(mintAmount, {
  gasLimit: 7_000_000,
});
const [preflightCommitIds] = ethers.AbiCoder.defaultAbiCoder().decode(
  ["uint256[]"],
  encodedPreflightCommitIds
);

const mintTx = await mintSystem.executeTyped(mintAmount, { gasLimit: 7_000_000 });
const mintReceipt = await mintTx.wait();
console.log("Mint committed!");

async function resolveCommitIds(mintTxHash, fallbackIds) {
  // Expected indexer response: { "commitIds": ["123", "456"] }
  const indexerBaseUrl = process.env.KAMIGOTCHI_INDEXER_URL;
  if (!indexerBaseUrl) return fallbackIds;

  const url = `${indexerBaseUrl}/gacha/commits?mintTxHash=${mintTxHash}`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Failed to fetch commit IDs from indexer (${res.status})`);

  const payload = await res.json();
  if (!Array.isArray(payload.commitIds) || payload.commitIds.length === 0) {
    throw new Error("Indexer response missing commitIds");
  }
  return payload.commitIds.map((v) => BigInt(v));
}

const commitIdArray = await resolveCommitIds(mintReceipt.hash, preflightCommitIds);
console.log("Commit IDs:", commitIdArray, "Mint tx:", mintReceipt.hash);

// 3. Reveal — determines the Kami's traits (species, stats, rarity)
// Note: there may be a minimum block delay between mint and reveal
const REVEAL_ABI = ["function reveal(uint256[] rawCommitIDs) external returns (uint256[])"];
const revealSystem = await getSystem("system.kami.gacha.reveal", REVEAL_ABI, ownerSigner);

const revealTx = await revealSystem.reveal(commitIdArray);
await revealTx.wait();
console.log("Kami revealed!");
```

> **Pricing:** Public tickets cost 0.1 ETH each (`MINT_PRICE_PUBLIC`). Whitelist tickets cost 0.05 ETH (`MINT_PRICE_WL`). Max 222 public mints per account, 3,000 total globally. See [Gacha / Minting](player-api/minting.md) for full details.

### Option C: Buy from the Marketplace or Trade

Use the in-game [KamiSwap Marketplace](player-api/marketplace.md) to buy a Kami from another player's listing, or use the [Trading](player-api/trading.md) system for direct player-to-player trades.

### Option D: Receive via ERC-721 Transfer + Stake

If someone sends you a Kami721 NFT directly (ERC-721 transfer), you'll need to **stake** it into the game before it becomes playable:

1. Approve the World contract for the NFT
2. Move to Room 12 (Scrap Confluence / Bridge)
3. Call `system.kami721.stake` with the token index

See [Step 8: Stake a Kami NFT](#step-8-stake-a-kami-nft) for the full code example.

---

## Step 6: Perform Basic Actions

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

## Step 7: Read Game State

```javascript
// Full ABI with struct fields — required for ethers.js to decode return values.
// See contracts/ids-and-abis.md → Getter System for the complete reference.
const GETTER_ABI = [
  "function getKami(uint256 kamiId) view returns (tuple(uint256 id, uint32 index, string name, string mediaURI, tuple(tuple(int32 base, int32 shift, int32 boost, int32 sync) health, tuple(int32 base, int32 shift, int32 boost, int32 sync) power, tuple(int32 base, int32 shift, int32 boost, int32 sync) harmony, tuple(int32 base, int32 shift, int32 boost, int32 sync) violence) stats, tuple(uint32 face, uint32 hand, uint32 body, uint32 background, uint32 color) traits, string[] affinities, uint256 account, uint256 level, uint256 xp, uint32 room, string state))",
  "function getAccount(uint256 accountId) view returns (tuple(uint32 index, string name, int32 currStamina, uint32 room))",
];

const getterAddr = await getSystemAddress("system.getter");
const getter = new ethers.Contract(getterAddr, GETTER_ABI, provider);

// No gas cost — read-only
const kamiData = await getter.getKami(kamiId);
console.log("Kami data:", kamiData);
```

---

## Step 8: Stake a Kami NFT

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
  chainId: 428962654539583,
  name: "Yominet",
});

function mustEnv(name) {
  const value = process.env[name];
  if (!value || !value.startsWith("0x")) {
    throw new Error(`Missing ${name}. Set it before running this script.`);
  }
  return value;
}

const ownerSigner = new ethers.Wallet(mustEnv("OWNER_PRIVATE_KEY"), provider);
const operatorSigner = new ethers.Wallet(mustEnv("OPERATOR_PRIVATE_KEY"), provider);

const world = new ethers.Contract(
  WORLD_ADDRESS,
  [
    "function systems() view returns (address)",
    "function systems(uint256) view returns (address)", // legacy worlds
  ],
  provider
);
const SYSTEMS_COMPONENT_ABI = [
  "function getEntitiesWithValue(uint256) view returns (uint256[])",
];

const cache = new Map();
async function sys(id, abi, signer) {
  if (!cache.has(id)) {
    const hash = ethers.keccak256(ethers.toUtf8Bytes(id));
    let addr = ethers.ZeroAddress;
    try {
      addr = await world["systems(uint256)"](hash);
    } catch (_) {}

    if (addr === ethers.ZeroAddress) {
      const systemsComponentAddr = await world["systems()"]();
      const systemsComponent = new ethers.Contract(
        systemsComponentAddr,
        SYSTEMS_COMPONENT_ABI,
        provider
      );
      const entities = await systemsComponent.getEntitiesWithValue(hash);
      if (entities.length === 0) throw new Error(`System not found: ${id}`);
      addr = ethers.getAddress(ethers.toBeHex(entities[0], 20));
    }

    cache.set(id, addr);
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

  // 3. Buy first Kami from Newbie Vendor (owner wallet, native ETH)
  const vendor = await sys(
    "system.newbievendor.buy",
    [
      "function executeTyped(uint32 kamiIndex) payable returns (bytes)",
      "function calcPrice() view returns (uint256)",
    ],
    ownerSigner
  );
  const price = await vendor.calcPrice();
  // Probe display slots to find a valid index
  let kamiIndex = null;
  for (const candidate of [0, 1, 2]) {
    try {
      await vendor.executeTyped.staticCall(candidate, { value: price });
      kamiIndex = candidate;
      break;
    } catch (_) {}
  }
  if (kamiIndex === null) throw new Error("No valid vendor index found");
  await (await vendor.executeTyped(kamiIndex, { value: price })).wait();
  console.log("✅ Purchased Kami from vendor (index:", kamiIndex, ")");

  // 4. Derive the Kami entity ID
  // After purchase, query account's Kami list or parse tx events to get kamiTokenIndex.
  // Entity ID formula: keccak256(abi.encodePacked("kami.id", uint32(kamiTokenIndex)))
  // For this example, assume kamiTokenIndex is known:
  // const kamiEntityId = BigInt(ethers.keccak256(
  //   ethers.solidityPacked(["string", "uint32"], ["kami.id", kamiTokenIndex])
  // ));

  // 5. Start harvesting (operator wallet)
  // Node index == room index. We're in room 1, so nodeIndex = 1.
  // Requires a valid kamiEntityId — uncomment below once you have it:
  // const harvest = await sys(
  //   "system.harvest.start",
  //   ["function executeTyped(uint256 kamiID, uint32 nodeIndex, uint256 taxerID, uint256 taxAmt) returns (bytes)"],
  //   operatorSigner
  // );
  // await (await harvest.executeTyped(kamiEntityId, 1, 0, 0)).wait();
  // console.log("✅ Harvesting started in room 1");

  console.log("🎮 Integration complete — register, move, and first Kami acquired!");
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
| `gacha.mint(n)` | 4M + 3M × n | Scales with mint count |

> **Default gas estimation:** For systems marked "Default" above, ethers.js gas estimation works correctly on Yominet. Only override `gasLimit` for the specific systems noted (move: 1.2M, liquidate: 7.5M, gacha mint: 4M+3M/kami).

---

## Transaction Management

When building bots or automated systems that send rapid transactions, you need to manage **nonces** and **gas settings** carefully. The official Kamigotchi client uses an internal `TxQueue` that handles this — here's how to replicate the key patterns.

### Gas Settings

Yominet uses a flat fee model. Hardcode these values — do **not** rely on `eth_gasPrice` or EIP-1559 estimation:

```javascript
const TX_OVERRIDES = {
  maxFeePerGas: 2500000n,       // 0.0025 gwei — Yominet's flat gas price
  maxPriorityFeePerGas: 0n,     // No priority fee needed
};

const tx = await system.executeTyped(args, {
  ...TX_OVERRIDES,
  gasLimit: 1_200_000,          // Set per-system (see Gas Quick Reference)
});
```

### Nonce Management

If you send multiple transactions without waiting for each to confirm, you **must** manage nonces manually. Otherwise the RPC will reject transactions with duplicate or out-of-order nonces.

```javascript
const signer = operatorSigner; // or ownerSigner, depending on the systems you call

// Fetch the current nonce once, then increment locally
let nonce = await provider.getTransactionCount(signer.address, "pending");

async function sendWithNonce(system, method, args, overrides = {}) {
  const tx = await system[method](...args, {
    ...TX_OVERRIDES,
    nonce: nonce,
    ...overrides,
  });
  nonce++; // Increment immediately — don't wait for confirmation
  return tx;
}
```

### Retry on Nonce Errors

Nonce errors (`NONCE_EXPIRED`, `account sequence mismatch`, `TRANSACTION_REPLACED`) mean your local nonce drifted from the chain. Reset from the network and retry:

```javascript
async function sendWithRetry(system, method, args, overrides = {}) {
  try {
    return await sendWithNonce(system, method, args, overrides);
  } catch (error) {
    const isNonceError =
      error?.code === "NONCE_EXPIRED" ||
      error?.code === "TRANSACTION_REPLACED" ||
      error?.message?.includes("account sequence");

    if (isNonceError) {
      // Reset nonce from network and retry once
      nonce = await provider.getTransactionCount(signer.address, "pending");
      return await sendWithNonce(system, method, args, overrides);
    }
    throw error;
  }
}
```

> **⚠️ Warning:** Sending multiple transactions without nonce management will cause failures. Always track nonces locally if you're sending faster than block confirmation time. The official client uses a mutex-protected queue with automatic nonce tracking — consider a similar pattern for production bots.

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
