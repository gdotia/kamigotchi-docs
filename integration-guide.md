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
| **Wallets** | Two EOAs: Owner (with $ETH on Yominet) and Operator (with small $ETH for gas). For bots, you generate both wallets yourself — Privy is only used by the web UI client. |
| **Network** | Yominet (Chain ID: `428962654539583`) |

---

## Funding Your Wallet

**There is no faucet on Yominet.** You must bridge real ETH before you can transact.

Two options:

1. **In-game bridge** — Open the Kamigotchi client, go to Settings > Bridge (uses the Initia bridge).
2. **Initia Bridge** — Use the [Initia Bridge](https://app.initia.xyz/?openBridge=true) to bridge ETH from Ethereum mainnet to Yominet.

**Cost summary:**

| Action | Cost | Currency |
|--------|------|----------|
| Gas (thousands of txs) | ~0.001 ETH | Native ETH |
| KamiSwap (first Kami) | Variable | Native ETH (msg.value) |
| Gacha ticket (public) | $MUSU (GDA pricing) | In-game $MUSU (item 1, earned via harvesting) |
| Marketplace listing | Variable | Native ETH (msg.value) |
| Marketplace offer | Variable | WETH (approval-based) |

**Recommended starting budget:** 0.01 ETH bridged to Yominet.

> **Note:** For bots and programmatic integrations, you manage both wallets yourself — **Privy is only used by the web UI client**. Fund the Owner wallet for registration and privileged operations, and the Operator wallet with a small amount for gameplay gas.

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

Kamigotchi uses a **dual-wallet model**. The official game client handles this via [Privy](https://privy.io) — players connect their external wallet (Owner), and Privy auto-creates an embedded wallet (Operator). **For bots, Privy is not involved** — you generate both wallets yourself and pass the Operator address as a parameter when calling `AccountRegisterSystem`:

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

    // World.systems() returns the SystemsComponent (IUint256Component),
    // which maps systemAddress -> systemId. We reverse-lookup by value.
    const systemsComponentAddr = await world.systems();
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

Registration is called from the **Owner wallet** and takes the **Operator address** as a parameter. The Operator is not "assigned by Privy" for bots — you simply pass the address of the Operator wallet you generated.

```javascript
const REGISTER_ABI = [
  "function executeTyped(address operatorAddress, string name) returns (bytes)",
];
const GETTER_ABI = [
  "function getAccount(uint256 accountId) view returns (tuple(uint32 index, string name, int32 currStamina, uint32 room))",
];

const registerSystem = await getSystem(
  "system.account.register",
  REGISTER_ABI,
  ownerSigner // Must use Owner wallet — this becomes the account owner
);
const getter = await getSystem("system.getter", GETTER_ABI, provider);

const accountName = process.env.KAMI_ACCOUNT_NAME ?? "MyBot01";
const nameBytes = ethers.toUtf8Bytes(accountName).length;
if (nameBytes < 1 || nameBytes > 15) {
  throw new Error(
    `Invalid KAMI_ACCOUNT_NAME "${accountName}" (${nameBytes} bytes). Use 1-15 bytes.`
  );
}

const ownerAccountId = BigInt(ownerSigner.address);
const operatorAccountId = BigInt(operatorSigner.address);

async function hasAccount(accountId) {
  try {
    const account = await getter.getAccount(accountId);
    return account.name !== "";
  } catch {
    return false;
  }
}

if (await hasAccount(ownerAccountId)) {
  console.log("Owner already has a registered account — skipping register().");
} else {
  if (await hasAccount(operatorAccountId)) {
    throw new Error(
      "Operator address is already in use by another account. Generate a new operator wallet."
    );
  }

  const ownerBalance = await provider.getBalance(ownerSigner.address);
  if (ownerBalance === 0n) {
    throw new Error(
      `Owner has 0 ETH on Yominet (${ownerSigner.address}). Bridge ETH first, then retry register().`
    );
  }

  let gasEstimate;
  try {
    gasEstimate = await registerSystem.executeTyped.estimateGas(
      operatorSigner.address,
      accountName
    );
  } catch (err) {
    const reason =
      err?.info?.error?.message || err?.shortMessage || err?.reason || err?.message || "";
    if (reason.includes("does not exist")) {
      throw new Error(
        `Owner address ${ownerSigner.address} is not initialized on Yominet yet. Bridge ETH first, then retry register().`
      );
    }
    throw err;
  }

  const gasPrice = (await provider.getFeeData()).gasPrice ?? 2_500_000n;
  const minGasCost = gasEstimate * gasPrice;
  if (ownerBalance < minGasCost) {
    throw new Error(
      `Owner needs at least ${ethers.formatEther(minGasCost)} ETH for register() gas, has ${ethers.formatEther(ownerBalance)} ETH`
    );
  }

  const tx = await registerSystem.executeTyped(
    operatorSigner.address,
    accountName
  );
  const receipt = await tx.wait();
  console.log("Account registered! Tx:", receipt.hash);
}
```

> **What happens:** `AccountRegisterSystem.executeTyped(operatorAddress, name)` creates a new account entity owned by `msg.sender` (your Owner wallet) and sets the provided address as the Operator. The Operator can then sign routine gameplay transactions on behalf of the account.
>
> **If you see `missing revert data` or `fee payer address ... does not exist`:** pre-check `owner`/`operator` registration state, name length (1-15 bytes), and owner gas balance before sending the tx.

### Changing the Operator Later

If you need to rotate your Operator wallet, use `system.account.set.operator`:

```javascript
const SET_OPERATOR_ABI = [
  "function executeTyped(address newOperator) returns (bytes)",
];
const setOperatorSystem = await getSystem(
  "system.account.set.operator",
  SET_OPERATOR_ABI,
  ownerSigner // Must use Owner wallet
);

const newOperator = new ethers.Wallet(newOperatorPrivateKey, provider);
const tx = await setOperatorSystem.executeTyped(newOperator.address);
await tx.wait();
console.log("Operator updated to:", newOperator.address);
```

---

## Step 5: Get Your First Kami

After registering, you need at least one Kami to participate in gameplay (harvesting, quests, combat). There are four ways to acquire a Kami:

### Option A: KamiSwap Marketplace (Recommended for New Players)

The **KamiSwap** marketplace lets players buy Kamis listed by other players. This is the simplest way to get your first Kami — browse available listings and purchase one with native ETH.

See [KamiSwap — Marketplace](player-api/marketplace.md) for full details on browsing listings, buying, and making offers.

> **Finding your Kami after purchase:** Use `IDOwnsKamiComponent` to list your Kamis, or scan `getKamiByIndex()` (as shown in the [Complete Example](#complete-example-script) below). See [Entity Discovery — Enumerating Your Kamis](player-api/entity-discovery.md#enumerating-your-kamis) for the component-based approach.

### Option B: Gacha Minting

The standard gacha flow is: **earn $MUSU → buy a gacha ticket via auction → mint → reveal**.

> **Important:** Gacha tickets are purchased with **$MUSU** (item index 1) via the auction system (`system.auction.buy`) using Gradual Dutch Auction pricing. You must be on the vending machine tile.

```javascript
// 1. Buy a gacha ticket via auction (costs $MUSU — GDA pricing)
const BUY_ABI = ["function executeTyped(uint32 itemIndex, uint32 amt) returns (bytes)"];
const buySystem = await getSystem("system.auction.buy", BUY_ABI, ownerSigner);

await (await buySystem.executeTyped(10, 1)).wait(); // item 10 = Gacha Ticket
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

> **Pricing:** Gacha tickets are purchased with $MUSU via a Gradual Dutch Auction (GDA) on the vending machine tile. Price decays over time and resets on each purchase. See [Gacha / Minting](player-api/minting.md) for full details.

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

A single copy-paste-ready script that takes a fresh wallet through the entire first-run flow: connect, register, buy a Kami, move to a harvest room, start harvesting, wait, and collect.

```javascript
// complete-example.js — Full first-run bot script (ethers v6, ESM)
//
// Prerequisites:
//   npm init -y && npm install ethers && npm pkg set type=module
//   export OWNER_PRIVATE_KEY=0x...
//   export OPERATOR_PRIVATE_KEY=0x...
//   node complete-example.js

import { ethers } from "ethers";

// ============================================================
// Configuration
// ============================================================

const RPC_URL = "https://jsonrpc-yominet-1.anvil.asia-southeast.initia.xyz";
const WORLD_ADDRESS = "0x2729174c265dbBd8416C6449E0E813E88f43D0E7";
const CHAIN = { chainId: 428962654539583, name: "Yominet" };

// How long to harvest before collecting (in seconds).
// 120 s is enough to accumulate a small reward for demonstration.
const HARVEST_WAIT_SECONDS = 120;

// ============================================================
// Environment helpers
// ============================================================

function mustEnv(name) {
  const value = process.env[name];
  if (!value || !value.startsWith("0x")) {
    throw new Error(
      `Missing or invalid ${name}. Export it before running:\n  export ${name}=0xYOUR_KEY`
    );
  }
  return value;
}

// ============================================================
// Provider & wallets
// ============================================================

const provider = new ethers.JsonRpcProvider(RPC_URL, CHAIN);
const ownerSigner = new ethers.Wallet(mustEnv("OWNER_PRIVATE_KEY"), provider);
const operatorSigner = new ethers.Wallet(mustEnv("OPERATOR_PRIVATE_KEY"), provider);

// ============================================================
// System resolver (inlined — no external helper import)
// ============================================================

const world = new ethers.Contract(
  WORLD_ADDRESS,
  ["function systems() view returns (address)"],
  provider
);

const SYSTEMS_COMPONENT_ABI = [
  "function getEntitiesWithValue(uint256) view returns (uint256[])",
];

const systemCache = new Map();

async function getSystemAddress(systemId) {
  if (systemCache.has(systemId)) return systemCache.get(systemId);

  const hash = ethers.keccak256(ethers.toUtf8Bytes(systemId));

  // World.systems() returns the SystemsComponent (IUint256Component),
  // which maps systemAddress -> systemId. We reverse-lookup by value.
  const scAddr = await world.systems();
  const sc = new ethers.Contract(scAddr, SYSTEMS_COMPONENT_ABI, provider);
  const entities = await sc.getEntitiesWithValue(hash);
  if (entities.length === 0) {
    throw new Error(`System "${systemId}" not found in registry`);
  }
  const addr = ethers.getAddress(ethers.toBeHex(entities[0], 20));
  systemCache.set(systemId, addr);
  return addr;
}

async function getSystem(systemId, abi, signer) {
  const address = await getSystemAddress(systemId);
  return new ethers.Contract(address, abi, signer);
}

// ============================================================
// Entity ID helpers
// ============================================================

/** Kami entity ID: keccak256(abi.encodePacked("kami.id", uint32(kamiTokenIndex))) */
function getKamiEntityId(kamiTokenIndex) {
  return BigInt(
    ethers.keccak256(
      ethers.solidityPacked(["string", "uint32"], ["kami.id", kamiTokenIndex])
    )
  );
}

/** Harvest entity ID: keccak256(abi.encodePacked("harvest", uint256(kamiEntityId))) */
function getHarvestEntityId(kamiEntityId) {
  return BigInt(
    ethers.keccak256(
      ethers.solidityPacked(["string", "uint256"], ["harvest", kamiEntityId])
    )
  );
}

// ============================================================
// Main flow
// ============================================================

async function main() {
  // ----------------------------------------------------------
  // 1. Connect and check balances
  // ----------------------------------------------------------
  const blockNumber = await provider.getBlockNumber();
  console.log(`Connected to Yominet (block ${blockNumber})`);
  console.log("Owner:   ", ownerSigner.address);
  console.log("Operator:", operatorSigner.address);

  const [ownerBal, operatorBal] = await Promise.all([
    provider.getBalance(ownerSigner.address),
    provider.getBalance(operatorSigner.address),
  ]);
  console.log("Owner balance:   ", ethers.formatEther(ownerBal), "ETH");
  console.log("Operator balance:", ethers.formatEther(operatorBal), "ETH");

  if (ownerBal === 0n) throw new Error("Owner wallet has no ETH. Bridge funds first.");
  if (operatorBal === 0n) {
    console.warn("⚠️  Operator wallet has no ETH. It will need gas to send gameplay transactions.");
    console.warn("   Send a small amount of ETH to:", operatorSigner.address);
  }

  // ----------------------------------------------------------
  // 2. Register account (skip if already registered)
  // ----------------------------------------------------------
  const registerSystem = await getSystem(
    "system.account.register",
    ["function executeTyped(address operatorAddress, string name) returns (bytes)"],
    ownerSigner
  );
  const getterForRegister = await getSystem(
    "system.getter",
    [
      "function getAccount(uint256 accountId) view returns (tuple(uint32 index, string name, int32 currStamina, uint32 room))",
    ],
    provider
  );

  const accountName = process.env.KAMI_ACCOUNT_NAME ?? "MyBot01";
  const accountNameBytes = ethers.toUtf8Bytes(accountName).length;
  if (accountNameBytes < 1 || accountNameBytes > 15) {
    throw new Error(
      `Invalid KAMI_ACCOUNT_NAME "${accountName}" (${accountNameBytes} bytes). Use 1-15 bytes.`
    );
  }

  async function hasAccount(address) {
    try {
      const account = await getterForRegister.getAccount(BigInt(address));
      return account.name !== "";
    } catch {
      return false;
    }
  }

  if (await hasAccount(ownerSigner.address)) {
    console.log("Owner already registered — skipping.");
  } else {
    if (await hasAccount(operatorSigner.address)) {
      throw new Error(
        "Operator address already in use. Create a fresh operator wallet and retry."
      );
    }

    const regGas = await registerSystem.executeTyped.estimateGas(
      operatorSigner.address,
      accountName
    );
    const gasPrice = (await provider.getFeeData()).gasPrice ?? 2_500_000n;
    const minRegCost = regGas * gasPrice;
    if (ownerBal < minRegCost) {
      throw new Error(
        `Owner has ${ethers.formatEther(ownerBal)} ETH, but register() needs at least ${ethers.formatEther(minRegCost)} ETH for gas`
      );
    }

    try {
      const regTx = await registerSystem.executeTyped(
        operatorSigner.address,
        accountName
      );
      await regTx.wait();
      console.log("Account registered.");
    } catch (err) {
      const reason = err.reason || err.message || "";
      if (reason.includes("missing revert data")) {
        throw new Error(
          "register() reverted without reason. Re-check owner/operator registration state, name byte length (1-15), and owner ETH."
        );
      }
      throw err;
    }
  }

  // ----------------------------------------------------------
  // 3. Acquire first Kami via KamiSwap Marketplace
  // ----------------------------------------------------------
  // To get your first Kami, purchase one from the KamiSwap marketplace.
  // See the KamiSwap documentation for browsing listings and buying:
  // player-api/marketplace.md
  //
  // Example: buying a listing by ID (you'll need to discover listing IDs
  // from the marketplace — see the marketplace docs for querying listings)
  //
  // const buySystem = await getSystem(
  //   "system.kamimarket.buy",
  //   ["function executeTyped(uint256[] memory listingIDs) payable returns (bytes)"],
  //   ownerSigner
  // );
  // const buyTx = await buySystem.executeTyped([listingId], { value: listingPrice });
  // await buyTx.wait();

  // ----------------------------------------------------------
  // 4. Discover the Kami's entity ID via component lookup
  // ----------------------------------------------------------
  // Use the component.id.kami.owns component to find all Kamis owned by this
  // account. This is O(1) on-chain — no brute-force scanning required.
  // See: player-api/entity-discovery.md and contracts/ids-and-abis.md

  // Resolve a component address from the World's component registry.
  // Components resolve via world.components(), NOT world.systems().
  const worldForComponents = new ethers.Contract(
    WORLD_ADDRESS,
    ["function components() view returns (address)"],
    provider
  );

  async function getComponentAddress(componentName) {
    const hash = ethers.keccak256(ethers.toUtf8Bytes(componentName));
    const componentsRegistryAddr = await worldForComponents.components();
    const componentsRegistry = new ethers.Contract(
      componentsRegistryAddr,
      ["function getEntitiesWithValue(uint256) view returns (uint256[])"],
      provider
    );
    const entities = await componentsRegistry.getEntitiesWithValue(hash);
    if (entities.length === 0)
      throw new Error(`Component not found: ${componentName}`);
    return ethers.getAddress(ethers.toBeHex(entities[0], 20));
  }

  const accountEntityId = BigInt(ownerSigner.address);

  const OWNS_KAMI_ABI = [
    "function getEntitiesWithValue(uint256) view returns (uint256[])",
  ];
  const ownsKamiAddr = await getComponentAddress("component.id.kami.owns");
  const ownsKami = new ethers.Contract(ownsKamiAddr, OWNS_KAMI_ABI, provider);

  const myKamiIds = await ownsKami.getEntitiesWithValue(accountEntityId);
  if (myKamiIds.length === 0) {
    throw new Error(
      "No Kami found for this account. Buy one from KamiSwap or mint via Gacha first."
    );
  }

  const GETTER_ABI = [
    "function getKami(uint256 kamiId) view returns (tuple(uint256 id, uint32 index, string name, string mediaURI, tuple(tuple(int32 base, int32 shift, int32 boost, int32 sync) health, tuple(int32 base, int32 shift, int32 boost, int32 sync) power, tuple(int32 base, int32 shift, int32 boost, int32 sync) harmony, tuple(int32 base, int32 shift, int32 boost, int32 sync) violence) stats, tuple(uint32 face, uint32 hand, uint32 body, uint32 background, uint32 color) traits, string[] affinities, uint256 account, uint256 level, uint256 xp, uint32 room, string state))",
    "function getAccount(uint256 accountId) view returns (tuple(uint32 index, string name, int32 currStamina, uint32 room))",
  ];
  const getterAddr = await getSystemAddress("system.getter");
  const getter = new ethers.Contract(getterAddr, GETTER_ABI, provider);

  // Use the first owned Kami
  const kamiEntityId = myKamiIds[0];
  const kamiData = await getter.getKami(kamiEntityId);
  console.log(
    `Found Kami: entityId=${kamiEntityId} | index=${kamiData.index} | name=${kamiData.name || "(unnamed)"}`
  );
  console.log(`Owned Kamis total: ${myKamiIds.length}`);

  // ----------------------------------------------------------
  // 5. Move to a harvest room (Room 1 — Misty Riverside has a node)
  // ----------------------------------------------------------
  // New accounts start in Room 1 after registration, but if we've moved
  // before, make sure we're there now.
  const accountData = await getter.getAccount(accountEntityId);
  const currentRoom = accountData.room;

  if (Number(currentRoom) !== 1) {
    const moveSystem = await getSystem(
      "system.account.move",
      ["function executeTyped(uint32 roomIndex) returns (bytes)"],
      operatorSigner
    );
    const moveTx = await moveSystem.executeTyped(1, { gasLimit: 1_200_000 });
    await moveTx.wait();
    console.log("Moved to Room 1.");
  } else {
    console.log("Already in Room 1.");
  }

  // ----------------------------------------------------------
  // 6. Start harvesting
  // ----------------------------------------------------------
  // harvest.start params:
  //   kamiID    — entity ID of the Kami
  //   nodeIndex — harvest node index (node index matches room index; Room 1 = node 1)
  //   taxerID   — 0 for player-initiated harvests
  //   taxAmt    — 0 for player-initiated harvests
  const harvestStartSystem = await getSystem(
    "system.harvest.start",
    [
      "function executeTyped(uint256 kamiID, uint32 nodeIndex, uint256 taxerID, uint256 taxAmt) returns (bytes)",
    ],
    operatorSigner
  );

  try {
    const startTx = await harvestStartSystem.executeTyped(kamiEntityId, 1, 0, 0);
    await startTx.wait();
    console.log("Harvesting started on node 1.");
  } catch (err) {
    const reason = err.reason || err.message || "";
    if (reason.includes("already") || reason.includes("harvesting")) {
      console.log("Kami is already harvesting — skipping start.");
    } else {
      throw err;
    }
  }

  // ----------------------------------------------------------
  // 7. Wait for rewards to accumulate
  // ----------------------------------------------------------
  console.log(`Waiting ${HARVEST_WAIT_SECONDS}s for rewards to accumulate...`);
  await new Promise((resolve) => setTimeout(resolve, HARVEST_WAIT_SECONDS * 1000));

  // ----------------------------------------------------------
  // 8. Collect harvest rewards
  // ----------------------------------------------------------
  // Harvest entity ID is deterministic: keccak256("harvest", kamiEntityId)
  const harvestEntityId = getHarvestEntityId(kamiEntityId);

  const collectSystem = await getSystem(
    "system.harvest.collect",
    ["function executeTyped(uint256 id) returns (bytes)"],
    operatorSigner
  );

  const collectTx = await collectSystem.executeTyped(harvestEntityId);
  await collectTx.wait();
  console.log("Rewards collected! Harvest ID:", harvestEntityId.toString());

  console.log("Done. Your bot is registered, has a Kami, and is harvesting on Yominet.");
}

main().catch((err) => {
  console.error("Fatal error:", err.reason || err.message || err);
  process.exit(1);
});
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

> 📖 **Read next: [Entity Discovery](player-api/entity-discovery.md)** — Understanding how to derive entity IDs is essential for reading game state, building queries, and calling most systems. Read this before diving into individual API pages.

1. **Explore the API** — Browse the [Player API pages](player-api/overview.md) for full function documentation
2. **Check contracts** — See [Live Addresses](contracts/live-addresses.md) and [System IDs](contracts/ids-and-abis.md)
3. **Understand the chain** — Review [Chain Configuration](chain-configuration.md) for network details
4. **Read the architecture** — [Architecture Overview](architecture.md) explains the MUD ECS model

---

## Support

For questions, integration support, or to report issues, contact the Asphodel team directly.
