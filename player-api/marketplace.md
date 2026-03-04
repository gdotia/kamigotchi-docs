# KamiSwap — Kami Marketplace

KamiSwap is Kamigotchi's native on-chain Kami marketplace. Players can list Kamis for sale, make offers on specific Kamis or the collection, and purchase Kamis — all without leaving the game. New players can also buy their first Kami from the **Newbie Vendor** at a fair TWAP-derived price.

---

## Overview

KamiSwap has **6 player-facing systems**:

| System ID | Contract | Wallet | Description |
|-----------|----------|--------|-------------|
| `system.kamimarket.list` | KamiMarketListSystem | Operator | List a Kami for sale (ETH) |
| `system.kamimarket.buy` | KamiMarketBuySystem | Owner (payable) | Buy listed Kami(s) with ETH |
| `system.kamimarket.offer` | KamiMarketOfferSystem | Operator | Make a specific or collection offer (WETH) |
| `system.kamimarket.acceptoffer` | KamiMarketAcceptOfferSystem | Operator | Accept an offer |
| `system.kamimarket.cancel` | KamiMarketCancelSystem | Operator | Cancel a listing or offer |
| `system.newbievendor.buy` | NewbieVendorBuySystem | Owner (payable) | Buy first Kami from the Newbie Vendor |

There is also an **admin-only** registry system (`system.kamimarket.registry`) for configuring fees, vault, and enable/disable — not covered here.

### Key Design Principles

- **No escrow for listings** — Kami stays in the seller's wallet (marked as `LISTED` state)
- **No escrow for offers** — WETH stays in the buyer's wallet (approval-based via KamiMarketVault)
- **Listings use ETH (native)** — buyer sends ETH directly
- **Offers use WETH (ERC-20)** — buyer pre-approves WETH to the KamiMarketVault
- **Ownership transfer stays staked** — Kami is reassigned via `IDOwnsKami` component (no unstake/restake needed)
- **TWAP oracle** — every sale feeds into a time-weighted average price used by the Newbie Vendor

### Important Addresses

| Contract | Address | Description |
|----------|---------|-------------|
| **WETH** | `0xE1Ff7038eAAAF027031688E1535a055B2Bac2546` | ERC-20 wrapped ETH (bridged via LayerZero) — the underlying asset is also used as native gas, but WETH is the ERC-20 form |
| **KamiMarketVault** | *(resolve from World config — see below)* | Holds WETH approvals for offer settlement |

> **Finding the KamiMarketVault address:** The vault address is set dynamically via `KAMI_MARKET_VAULT` in the World contract's `ConfigComponent`. Query `LibConfig.getAddress(components, "KAMI_MARKET_VAULT")` on-chain, or read the `ConfigComponent` for the `KAMI_MARKET_VAULT` key to resolve it. The admin registry system (`system.kamimarket.registry`) sets this value at deployment.

### Fee Structure

The marketplace fee is configurable via the `KAMI_MARKET_FEE_RATE` config:

- Format: `[precision, numerator]` — fee = `price × numerator / 10^precision`
- Fee is deducted from the sale price; the seller receives `price - fee`
- Fee is sent to the treasury address (`KAMI_MARKET_FEE_RECIPIENT` config)

### Purchase Cooldown

After a Kami is purchased (via listing buy or offer acceptance), the Kami enters a **1-hour cooldown** (`KAMI_MARKET_PURCHASE_COOLDOWN` config, default 3600 seconds). During this cooldown, the Kami cannot be relisted or transferred.

### Soulbound Lock

Certain actions (e.g., Newbie Vendor purchase) apply a **soulbound lock** to a Kami via `LibSoulbound`. The lock stores an expiry timestamp (`block.timestamp + duration`). While soulbound, the Kami cannot be listed, have offers accepted, or be unstaked. The lock is checked with `LibSoulbound.verify()`, which reverts with `"kami is soulbound"` if the current time is before the expiry. The Newbie Vendor applies a 3-day soulbound lock.

---

## Entity ID Discovery

Order entity IDs (listings and offers) are **non-deterministic** — they are assigned by `world.getUniqueEntityId()` at creation time. You cannot derive them from known inputs.

To discover order IDs:
1. **From transaction return value** — `execute()` and `executeTyped()` on list/offer systems return `abi.encode(id)` — decode the return data
2. **From events** — listen for marketplace events (`KAMI_LISTING`, `KAMI_OFFER`, `KAMI_COLLECTION_OFFER` entity types)
3. **From the indexer** — query the off-chain indexer for active orders

```javascript
// Example: get listing tx hash, then resolve listing ID from indexer/events
const listTx = await listSystem.executeTyped(kamiIndex, price, expiry);
const receipt = await listTx.wait();
console.log("Listing tx hash:", receipt.hash);
// Resolve listing ID from confirmed events/indexer output keyed by receipt.hash.
// Avoid staticCall-generated IDs in production because IDs are non-deterministic.
```

---

## Listing Flow

### 1. Create a Listing

List a Kami for sale at a fixed ETH price. The Kami must be `RESTING` and not soulbound. The Kami stays in your wallet but its state changes to `LISTED`, preventing it from being used in gameplay.

**System:** `system.kamimarket.list`  
**Wallet:** Operator  

```solidity
// Solidity ABI
function executeTyped(uint32 kamiIndex, uint256 price, uint256 expiry) returns (bytes)
// kamiIndex — the Kami's token index
// price    — listing price in wei (ETH), must be > 0
// expiry   — expiration timestamp (unix seconds), 0 = no expiration
// returns  — abi.encode(listingEntityId)
```

```javascript
const LIST_ABI = [
  "function executeTyped(uint32 kamiIndex, uint256 price, uint256 expiry) returns (bytes)",
];
const listSystem = await getSystem("system.kamimarket.list", LIST_ABI, operatorSigner);

const kamiIndex = 42;
const price = ethers.parseEther("0.1"); // 0.1 ETH
const expiry = 0; // never expires

const tx = await listSystem.executeTyped(kamiIndex, price, expiry);
const receipt = await tx.wait();
console.log("Kami listed!");
```

### 2. Buy a Listing

Buy one or more listed Kamis with ETH. This is an all-or-nothing batch operation — if any listing in the batch fails, the entire transaction reverts.

**System:** `system.kamimarket.buy`  
**Wallet:** Owner (payable)

```solidity
// Solidity ABI
function executeTyped(uint256[] memory listingIDs) payable returns (bytes)
// listingIDs — array of listing entity IDs to buy
// msg.value  — must be >= total price of all listings
// Excess ETH is refunded automatically
```

```javascript
const BUY_ABI = [
  "function executeTyped(uint256[] memory listingIDs) payable returns (bytes)",
];
const buySystem = await getSystem("system.kamimarket.buy", BUY_ABI, ownerSigner);

const listingIDs = [listingId1, listingId2]; // buy multiple at once
const totalPrice = ethers.parseEther("0.2"); // sum of listing prices

const tx = await buySystem.executeTyped(listingIDs, { value: totalPrice });
await tx.wait();
console.log("Kamis purchased!");
```

**What happens on buy:**
1. Verifies all listings are active, not expired, and buyer doesn't own them
2. Calculates total price and verifies `msg.value >= totalPrice`
3. For each listing: deducts fee, sends remainder to seller, reassigns Kami ownership
4. Feeds each sale price into the TWAP oracle
5. Refunds any excess ETH to the buyer
6. Kami enters 1-hour purchase cooldown

### 3. Cancel a Listing

Cancel your active listing to return the Kami to `RESTING` state.

**System:** `system.kamimarket.cancel`  
**Wallet:** Operator

```javascript
const CANCEL_ABI = [
  "function executeTyped(uint256 orderID) returns (bytes)",
];
const cancelSystem = await getSystem("system.kamimarket.cancel", CANCEL_ABI, operatorSigner);

const tx = await cancelSystem.executeTyped(listingEntityId);
await tx.wait();
console.log("Listing cancelled, Kami restored to RESTING");
```

---

## Offer Flow

### WETH Setup

Offers use **WETH** (not native ETH). Before making offers, the buyer must approve WETH spending to the **KamiMarketVault** contract:

```javascript
const WETH_ADDRESS = "0xE1Ff7038eAAAF027031688E1535a055B2Bac2546";
const WETH_ABI = [
  "function approve(address spender, uint256 amount) returns (bool)",
  "function allowance(address owner, address spender) view returns (uint256)",
];
const weth = new ethers.Contract(WETH_ADDRESS, WETH_ABI, ownerSigner);

// Approve only your intended max spend (safer than MaxUint256)
// vaultAddress is from KAMI_MARKET_VAULT config
const maxOfferSpend = ethers.parseEther("0.25"); // adjust to your strategy
const approveTx = await weth.approve(vaultAddress, maxOfferSpend);
await approveTx.wait();
console.log("WETH approved:", ethers.formatEther(maxOfferSpend), "WETH");
```

> **Note:** WETH on Yominet (`0xE1Ff...2546`) is bridged ETH via LayerZero — it's the same token used for gas. Players typically acquire WETH by wrapping their native ETH or bridging from other chains. See [Chain Configuration](../chain-configuration.md) for the WETH contract address and bridging details. Prefer exact/limited approvals and top up as needed.

### 1. Make a Specific Offer

Offer to buy a specific Kami at your chosen WETH price.

**System:** `system.kamimarket.offer`  
**Wallet:** Operator

```solidity
// Solidity ABI — generic entry point
function execute(bytes memory arguments) returns (bytes)
// arguments = abi.encode(bool isCollection, uint32 kamiIndex, uint256 price, uint32 quantity, uint256 expiry)

// Typed helpers:
function executeTypedOffer(uint32 kamiIndex, uint256 price, uint256 expiry) returns (bytes)
function executeTypedCollection(uint256 price, uint32 quantity, uint256 expiry) returns (bytes)
```

```javascript
const OFFER_ABI = [
  "function executeTypedOffer(uint32 kamiIndex, uint256 price, uint256 expiry) returns (bytes)",
  "function executeTypedCollection(uint256 price, uint32 quantity, uint256 expiry) returns (bytes)",
  "function execute(bytes) returns (bytes)",
];
const offerSystem = await getSystem("system.kamimarket.offer", OFFER_ABI, operatorSigner);

// Specific offer: target Kami index 42 at 0.08 WETH, no expiry
const tx = await offerSystem.executeTypedOffer(
  42,                             // kamiIndex
  ethers.parseEther("0.08"),      // price in WETH
  0                               // expiry (0 = never)
);
await tx.wait();
console.log("Specific offer created!");
```

### 2. Make a Collection Offer

Offer to buy **any** Kami at your chosen WETH price, with a quantity limit.

```javascript
// Collection offer: buy up to 5 Kamis at 0.05 WETH each, expires in 7 days
const expiry = Math.floor(Date.now() / 1000) + 7 * 24 * 3600;
const tx = await offerSystem.executeTypedCollection(
  ethers.parseEther("0.05"),      // price per Kami in WETH
  5,                               // quantity
  expiry
);
await tx.wait();
console.log("Collection offer created for 5 Kamis!");
```

### 3. Accept an Offer

Accept an incoming offer (specific or collection) and sell your Kami. WETH is pulled from the buyer via the vault.

**System:** `system.kamimarket.acceptoffer`  
**Wallet:** Operator

```solidity
// Single accept
function executeTyped(uint256 offerID, uint32 kamiIndex) returns (bytes)

// Batch accept (collection offers only — sell multiple Kamis to one offer)
function executeTyped(uint256 offerID, uint32[] memory kamiIndices) returns (bytes)

// Generic entry point (supports both single and batch)
function execute(bytes memory arguments) returns (bytes)
// arguments = abi.encode(bool isBatch, uint256 offerID, uint32 kamiIndex, uint32[] kamiIndices)
```

```javascript
const ACCEPT_ABI = [
  "function executeTyped(uint256 offerID, uint32 kamiIndex) returns (bytes)",
  "function execute(bytes) returns (bytes)",
];
const acceptSystem = await getSystem("system.kamimarket.acceptoffer", ACCEPT_ABI, operatorSigner);

// Accept a specific offer — sell Kami #42
const tx = await acceptSystem.executeTyped(offerEntityId, 42);
await tx.wait();
console.log("Offer accepted, Kami sold!");
```

**Batch accept (collection offers):**

```javascript
// Accept a collection offer — sell Kamis #10, #15, #22 in one tx
const kamiIndices = [10, 15, 22];
const batchArgs = ethers.AbiCoder.defaultAbiCoder().encode(
  ["bool", "uint256", "uint32", "uint32[]"],
  [true, offerEntityId, 0, kamiIndices]
);
const tx = await acceptSystem.execute(batchArgs);
await tx.wait();
console.log("Batch accepted — 3 Kamis sold!");
```

**What happens on accept:**
1. Verifies offer is active, not expired, and seller doesn't own the offer
2. Verifies seller owns the Kami and it's `RESTING` or `LISTED` (not soulbound)
3. For collection offers: decrements remaining quantity
4. WETH is pulled from buyer → fee to treasury, remainder to seller
5. Kami ownership reassigned via `IDOwnsKami`
6. Sale price fed into TWAP oracle

### 4. Cancel an Offer

Cancel your active offer. No WETH is moved (approval-based, so nothing was escrowed).

```javascript
const tx = await cancelSystem.executeTyped(offerEntityId);
await tx.wait();
console.log("Offer cancelled");
```

---

## Newbie Vendor

The **Newbie Vendor** is a special system that lets **new players buy their first Kami** at a fair market price. This is the recommended way for new players to get started.

**System:** `system.newbievendor.buy`  
**Wallet:** Owner (payable)

### Rules

- **One-time purchase** — each account can only buy from the vendor once (`NEWBIE_VENDOR_PURCHASED` flag)
- **24-hour window** — only accounts created in the last 24 hours can use the vendor
- **TWAP pricing** — price is derived from the marketplace TWAP oracle (time-weighted average of recent sales)
- **Minimum price** — 0.005 ETH floor (`NEWBIE_VENDOR_MIN_PRICE` config)
- **Soulbound for 3 days** — purchased Kami cannot be listed, unstaked, or have offers accepted for 3 days
- **Display rotation** — admin stocks a pool of Kami indices; 3 are displayed at a time, cycling on a timer

```solidity
function executeTyped(uint32 kamiIndex) payable returns (bytes)
// kamiIndex — index of one of the 3 currently displayed Kamis
// msg.value — must be >= calcPrice() (TWAP-derived price)
```

```javascript
const VENDOR_ABI = [
  "function executeTyped(uint32 kamiIndex) payable returns (bytes)",
  "function calcPrice() view returns (uint256)",
];
const vendorSystem = await getSystem("system.newbievendor.buy", VENDOR_ABI, ownerSigner);

// Check the current price
const price = await vendorSystem.calcPrice();
console.log("Vendor price:", ethers.formatEther(price), "ETH");

// Resolve a valid vendor index from candidate indices before sending a paid tx
const candidates = (process.env.NEWBIE_VENDOR_CANDIDATES ?? "0,1,2")
  .split(",")
  .map((v) => Number(v.trim()))
  .filter((v) => Number.isInteger(v));

let kamiIndex = null;
for (const candidate of candidates) {
  try {
    await vendorSystem.executeTyped.staticCall(candidate, { value: price });
    kamiIndex = candidate;
    break;
  } catch (_) {}
}

if (kamiIndex === null) {
  throw new Error(
    "No valid vendor index found. Refresh display and set NEWBIE_VENDOR_CANDIDATES."
  );
}

console.log("Selected vendor index:", kamiIndex);
const tx = await vendorSystem.executeTyped(kamiIndex, { value: price });
await tx.wait();
console.log("First Kami purchased from the Newbie Vendor!");
```

### Choosing `kamiIndex`

1. Read candidate indices from your UI/indexer feed (or start with defaults `0,1,2`).
2. Set `NEWBIE_VENDOR_CANDIDATES` (comma-separated), for example `12,37,44` or `0,1,2`.
3. The snippet runs `executeTyped.staticCall` over candidates and picks the first currently valid index.
4. If no candidate passes, refresh vendor display data and retry.

> **Tip:** Use `calcPrice()` (a view function, no gas) to check the current vendor price before buying. Excess ETH is refunded automatically.

---

## Non-Standard Entry Points

The offer system uses **custom function names** instead of the standard `executeTyped()`:

| System | Entry Points | Signatures |
|--------|-------------|-----------|
| `system.kamimarket.offer` | `executeTypedOffer` / `executeTypedCollection` | `executeTypedOffer(uint32 kamiIndex, uint256 price, uint256 expiry)` / `executeTypedCollection(uint256 price, uint32 quantity, uint256 expiry)` |
| `system.kamimarket.acceptoffer` | `executeTyped` (overloaded) | `executeTyped(uint256 offerID, uint32 kamiIndex)` / `executeTyped(uint256 offerID, uint32[] kamiIndices)` |
| `system.newbievendor.buy` | `calcPrice` (view) | `calcPrice() view returns (uint256)` |

All other marketplace systems use the standard `executeTyped(...)` pattern.

---

## Complete Example: List → Buy Flow

```javascript
import { ethers } from "ethers";

const RPC_URL = "https://jsonrpc-yominet-1.anvil.asia-southeast.initia.xyz";
const WORLD_ADDRESS = "0x2729174c265dbBd8416C6449E0E813E88f43D0E7";

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

// Helper to resolve system contracts
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
async function sys(id, abi, signer) {
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

  return new ethers.Contract(addr, abi, signer);
}

async function main() {
  const price = ethers.parseEther("0.1");
  const mode = process.env.MARKET_MODE ?? "list";

  if (mode === "list") {
    const sellerOperator = new ethers.Wallet(mustEnv("SELLER_OPERATOR_KEY"), provider);

    // --- Seller lists Kami #42 for 0.1 ETH ---
    const listSys = await sys(
      "system.kamimarket.list",
      ["function executeTyped(uint32, uint256, uint256) returns (bytes)"],
      sellerOperator
    );
    const listTx = await listSys.executeTyped(42, price, 0);
    const listReceipt = await listTx.wait();
    console.log("✅ Kami #42 listed for 0.1 ETH. Tx:", listReceipt.hash);
    console.log("Resolve LISTING_ID from confirmed indexer/event output, then rerun with:");
    console.log("MARKET_MODE=buy LISTING_ID=<value>");
    return;
  }

  if (mode !== "buy") {
    throw new Error("MARKET_MODE must be 'list' or 'buy'");
  }

  if (!process.env.LISTING_ID) {
    throw new Error("Missing LISTING_ID for MARKET_MODE=buy");
  }
  const buyerOwner = new ethers.Wallet(mustEnv("BUYER_OWNER_KEY"), provider);
  const listingId = BigInt(process.env.LISTING_ID);

  // --- Buyer buys the listing ---
  const buySys = await sys(
    "system.kamimarket.buy",
    ["function executeTyped(uint256[]) payable returns (bytes)"],
    buyerOwner
  );
  const buyTx = await buySys.executeTyped([listingId], {
    value: price,
  });
  await buyTx.wait();
  console.log("✅ Kami #42 purchased!");
}

main().catch(console.error);
```

> **Run modes:** use `MARKET_MODE=list` to create a listing and capture its tx hash, then `MARKET_MODE=buy LISTING_ID=<id>` to purchase.  
> **Why `LISTING_ID` is externalized:** listing IDs come from `world.getUniqueEntityId()` and are non-deterministic. `staticCall` can drift from mined state under concurrency.

---

## ETH vs WETH Summary

| Operation | Currency | Method |
|-----------|----------|--------|
| Buy a listing | **ETH** (native) | `msg.value` — buyer sends ETH with the transaction |
| Make an offer | **WETH** (ERC-20) | Approval-based — buyer approves WETH to the vault beforehand |
| Accept an offer | **WETH** (ERC-20) | Vault pulls WETH from buyer and distributes to seller + treasury |
| Newbie Vendor | **ETH** (native) | `msg.value` — buyer sends ETH with the transaction |

> **Why the difference?** Listings are instant purchases (buyer initiates and pays in one tx), so native ETH works. Offers require the seller to accept later, so WETH's ERC-20 approval mechanism enables trustless settlement without escrow.

---

## Related Pages

- [Entity Discovery](entity-discovery.md) — How to find order entity IDs
- [Portal (ERC721 / ERC20)](portal.md) — Staking and unstaking Kami NFTs
- [Trading](trading.md) — Player-to-player item trades
- [Game Data Reference](../references/game-data.md) — WETH address, fee config, cooldown values
- [System IDs & ABIs](../contracts/ids-and-abis.md) — Complete system reference
