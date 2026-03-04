# Portal (ERC721 / ERC20)

The portal system bridges assets between on-chain wallets and the in-game world. Stake NFTs into the game, withdraw them back, and manage ERC-20 token deposits/withdrawals.

---

## ERC721 — Kami NFT Portal

### ERC721.kami.stake()

Deposit a Kami NFT from your wallet into the game world.

| Property | Value |
|----------|-------|
| **System ID** | `system.kami721.stake` |
| **Wallet** | 🔐 Owner |
| **Gas** | Default |

#### Parameters

| Name | Type | Description |
|------|------|-------------|
| `tokenIndex` | `uint32` | Index/token ID of the Kami NFT |

#### Description

Stakes a Kami NFT from the owner's wallet into the game world. The NFT is transferred to the World contract, and a corresponding Kami entity is created in-game. The Kami can then be used for harvesting, combat, and other activities.

#### Code Example

```javascript
import { ethers } from "ethers";
import { getSystem } from "./kamigotchi.js";

const KAMI721_ADDRESS = "0x5d4376b62fa8ac16dfabe6a9861e11c33a48c677";
const WORLD_ADDRESS = "0x2729174c265dbBd8416C6449E0E813E88f43D0E7";

// Step 1: Approve the World contract to transfer your NFT
const kami721 = new ethers.Contract(
  KAMI721_ADDRESS,
  ["function approve(address to, uint256 tokenId)"],
  ownerSigner
);
await (await kami721.approve(WORLD_ADDRESS, tokenId)).wait();

// Step 2: Stake into game
const ABI = ["function executeTyped(uint32 tokenIndex) returns (bytes)"];
const system = await getSystem("system.kami721.stake", ABI, ownerSigner);

const tx = await system.executeTyped(tokenId);
await tx.wait();
console.log("Kami staked into game world!");
```

#### Notes

- **Requires NFT approval** before staking — approve the World contract as the operator.
- Must use the **owner wallet** (the one that holds the NFT).
- For batch staking, see `ERC721.kami.batch.stake()` below.

---

### ERC721.kami.unstake()

Withdraw a Kami NFT from the game world back to your wallet.

| Property | Value |
|----------|-------|
| **System ID** | `system.kami721.unstake` |
| **Wallet** | 🔐 Owner |
| **Gas** | Default |

#### Parameters

| Name | Type | Description |
|------|------|-------------|
| `tokenIndex` | `uint32` | Index of the Kami in-game |

#### Description

Withdraws a Kami from the game world back to the owner's wallet as an ERC-721 NFT. The in-game Kami entity is removed, and the NFT is transferred back.

#### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

// Must use OWNER wallet
const ABI = ["function executeTyped(uint32 tokenIndex) returns (bytes)"];
const system = await getSystem("system.kami721.unstake", ABI, ownerSigner);

const tx = await system.executeTyped(kamiIndex);
await tx.wait();
console.log("Kami withdrawn to wallet!");
```

#### Notes

- The Kami must not be actively harvesting or in any locked state.
- Stop all harvests and remove equipment before unstaking.

---

### ERC721.kami.batch.stake()

Batch stake multiple Kami NFTs.

| Property | Value |
|----------|-------|
| **System ID** | `system.kami721.stake` |
| **Wallet** | 🔐 Owner |
| **Gas** | Default |

#### Parameters

| Name | Type | Description |
|------|------|-------------|
| `tokenIndices` | `uint32[]` | Array of Kami token IDs to stake |

#### Code Example

```javascript
import { ethers } from "ethers";
import { getSystem } from "./kamigotchi.js";

const KAMI721_ADDRESS = "0x5d4376b62fa8ac16dfabe6a9861e11c33a48c677";
const WORLD_ADDRESS = "0x2729174c265dbBd8416C6449E0E813E88f43D0E7";

// Approve all at once
const kami721 = new ethers.Contract(
  KAMI721_ADDRESS,
  ["function setApprovalForAll(address operator, bool approved)"],
  ownerSigner
);
await (await kami721.setApprovalForAll(WORLD_ADDRESS, true)).wait();

// Batch stake — uses executeBatch(), NOT executeTyped
const ABI = ["function executeBatch(uint32[] tokenIndices)"];
const system = await getSystem("system.kami721.stake", ABI, ownerSigner);

const tx = await system.executeBatch([tokenId1, tokenId2, tokenId3]);
await tx.wait();
```

---

### ERC721.kami.batch.unstake()

Batch unstake multiple Kamis.

| Property | Value |
|----------|-------|
| **System ID** | `system.kami721.unstake` |
| **Wallet** | 🔐 Owner |
| **Gas** | Default |

#### Parameters

| Name | Type | Description |
|------|------|-------------|
| `tokenIndices` | `uint32[]` | Array of in-game Kami indices to unstake |

#### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

// Batch unstake — uses executeBatch(), NOT executeTyped
const ABI = ["function executeBatch(uint32[] tokenIndices)"];
const system = await getSystem("system.kami721.unstake", ABI, ownerSigner);

const tx = await system.executeBatch([kamiIndex1, kamiIndex2, kamiIndex3]);
await tx.wait();
```

---

### ERC721.kami.batch.transfer()

Batch transfer Kamis to a single address.

| Property | Value |
|----------|-------|
| **System ID** | `system.kami721.transfer` |
| **Wallet** | 🔐 Owner |
| **Gas** | Default |

#### Parameters

| Name | Type | Description |
|------|------|-------------|
| `tokenIndices` | `uint256[]` | Array of Kami token indices to transfer |
| `to` | `address` | Recipient address |

#### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

// batchTransfer() is a named function, NOT executeTyped
const ABI = [
  "function batchTransfer(uint256[] tokenIndices, address to)",
];
const system = await getSystem("system.kami721.transfer", ABI, ownerSigner);

const tx = await system.batchTransfer(
  [kamiIndex1, kamiIndex2],
  recipientAddress
);
await tx.wait();
```

---

### ERC721.kami.batch.transferToMultiple()

Batch transfer Kamis to multiple addresses (1:1 mapping).

| Property | Value |
|----------|-------|
| **System ID** | `system.kami721.transfer` |
| **Wallet** | 🔐 Owner |
| **Gas** | Default |

#### Parameters

| Name | Type | Description |
|------|------|-------------|
| `tokenIndices` | `uint256[]` | Array of Kami token indices |
| `to` | `address[]` | Array of recipient addresses (matching length) |

#### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

// batchTransferToMany() is a named function, NOT executeTyped
const ABI = [
  "function batchTransferToMany(uint256[] tokenIndices, address[] to)",
];
const system = await getSystem("system.kami721.transfer", ABI, ownerSigner);

const tx = await system.batchTransferToMany(
  [kamiIndex1, kamiIndex2],
  [recipientAddr1, recipientAddr2]
);
await tx.wait();
```

---

## ERC20 — Token Portal

### ERC20.deposit()

Deposit an ERC-20 token into the game world.

| Property | Value |
|----------|-------|
| **System ID** | `system.erc20.portal` |
| **Wallet** | 🔐 Owner |
| **Gas** | Default |

#### Parameters

| Name | Type | Description |
|------|------|-------------|
| `itemIndex` | `uint32` | Game item index representing the ERC-20 token |
| `itemAmt` | `uint256` | Amount to deposit |

#### Description

Deposits ERC-20 tokens from the owner's wallet into the game world as in-game items. Requires prior ERC-20 approval.

#### Code Example

```javascript
import { ethers } from "ethers";
import { getSystem } from "./kamigotchi.js";

const ONYX_ADDRESS = "0x4BaDFb501Ab304fF11217C44702bb9E9732E7CF4";
const WORLD_ADDRESS = "0x2729174c265dbBd8416C6449E0E813E88f43D0E7";

// Step 1: Approve ERC-20 spend
const onyx = new ethers.Contract(
  ONYX_ADDRESS,
  ["function approve(address spender, uint256 amount) returns (bool)"],
  ownerSigner
);
await (await onyx.approve(WORLD_ADDRESS, ethers.MaxUint256)).wait();

// Step 2: Deposit into game — deposit() is a named function, NOT executeTyped
const ABI = [
  "function deposit(uint32 itemIndex, uint256 itemAmt)",
];
const system = await getSystem("system.erc20.portal", ABI, ownerSigner);

const tx = await system.deposit(onyxItemIndex, depositAmount);
await tx.wait();
console.log("ONYX deposited into game world!");
```

#### Notes

- The `itemIndex` maps an in-game item to a specific ERC-20 contract. The mapping is stored in the `TokenPortalSystem` contract's local storage (`itemAddrs` and `itemScales` mappings), initialized from the item registry. Items must be of type `"ERC20"`. The primary token is ONYX (item index 100). The conversion scale and token address are set per item via `setItem()` or `initItem()` admin calls. Set via registry — query the `TokenPortalSystem` contract for current item→ERC-20 mappings.
- Requires ERC-20 `approve()` before depositing.

---

### ERC20.withdraw()

Withdraw ERC-20 tokens from the game world.

| Property | Value |
|----------|-------|
| **System ID** | `system.erc20.portal` |
| **Wallet** | 🔐 Owner |
| **Gas** | Default |

#### Parameters

| Name | Type | Description |
|------|------|-------------|
| `itemIndex` | `uint32` | Game item index representing the ERC-20 token |
| `itemAmt` | `uint256` | Amount to withdraw |

#### Description

Initiates a withdrawal of ERC-20 tokens from the game world back to the owner's wallet. Withdrawals may have a **pending period** before they can be claimed.

#### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

// withdraw() is a named function, NOT executeTyped
const ABI = [
  "function withdraw(uint32 itemIndex, uint256 itemAmt) returns (uint256)",
];
const system = await getSystem("system.erc20.portal", ABI, ownerSigner);

const tx = await system.withdraw(onyxItemIndex, withdrawAmount);
await tx.wait();
console.log("Withdrawal initiated — use ERC20.claim() after the pending period.");
```

---

### ERC20.claim()

Claim a pending ERC-20 withdrawal.

| Property | Value |
|----------|-------|
| **System ID** | `system.erc20.portal` |
| **Wallet** | 🔐 Owner |
| **Gas** | Default |

#### Parameters

| Name | Type | Description |
|------|------|-------------|
| `receiptID` | `uint256` | Entity ID of the withdrawal receipt |

#### Description

Claims a pending ERC-20 withdrawal after the required waiting period has elapsed. Tokens are transferred from the World contract to the owner's wallet.

#### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

// claim() is a named function, NOT executeTyped
const ABI = ["function claim(uint256 receiptID)"];
const system = await getSystem("system.erc20.portal", ABI, ownerSigner);

const tx = await system.claim(withdrawalReceiptId);
await tx.wait();
console.log("ERC-20 tokens claimed to wallet!");
```

---

### ERC20.cancel()

Cancel a pending ERC-20 withdrawal.

| Property | Value |
|----------|-------|
| **System ID** | `system.erc20.portal` |
| **Wallet** | 🔐 Owner |
| **Gas** | Default |

#### Parameters

| Name | Type | Description |
|------|------|-------------|
| `receiptID` | `uint256` | Entity ID of the withdrawal receipt |

#### Description

Cancels a pending withdrawal. The tokens are returned to the player's in-game inventory instead of being sent to the wallet.

#### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

// cancel() is a named function, NOT executeTyped
const ABI = ["function cancel(uint256 receiptID)"];
const system = await getSystem("system.erc20.portal", ABI, ownerSigner);

const tx = await system.cancel(withdrawalReceiptId);
await tx.wait();
console.log("Withdrawal cancelled — tokens returned to game inventory.");
```

---

## Portal Flow Summary

### ERC-721 (Kami NFTs)

```
  Wallet                              Game World
    │                                     │
    │── approve() + kami.stake() ────────▶ │  (NFT → Game Entity)
    │                                     │
    │◀──────────── kami.unstake() ─────── │  (Game Entity → NFT)
    │                                     │
    │── kami.batch.transfer() ──────────▶  │  (Transfer in-game)
```

### ERC-20 (Tokens)

```
  Wallet                              Game World
    │                                     │
    │── approve() + ERC20.deposit() ────▶ │  (Tokens → Items)
    │                                     │
    │◀── ERC20.withdraw() ────────────── │  (Items → Pending)
    │                                     │
    │◀── ERC20.claim() ──────────────── │  (Pending → Wallet)
    │                                     │
    │              ERC20.cancel() ──────▶ │  (Pending → Items)
```

---

## Related Pages

- [Kami](kami.md) — Managing staked Kamis
- [Minting](minting.md) — Minting new Kamis via gacha
- [Chain Configuration](../chain-configuration.md) — Network and token details
- [Live Addresses](../contracts/live-addresses.md) — Contract addresses for approvals
