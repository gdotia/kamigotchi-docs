# Chain Configuration

Kamigotchi is deployed on **Yominet**, an Initia L2 rollup built on the OP Stack with Celestia DA (Data Availability).

---

## Network Details

| Parameter | Value |
|-----------|-------|
| **Chain Name** | Yominet |
| **Chain ID (EVM)** | `428962654539583` |
| **RPC URL** | `https://jsonrpc-yominet-1.anvil.asia-southeast.initia.xyz` |
| **WebSocket RPC** | `wss://jsonrpc-ws-yominet-1.anvil.asia-southeast.initia.xyz` |
| **REST API** | `https://rest-yominet-1.anvil.asia-southeast.initia.xyz` |
| **Block Explorer** | [scan.initia.xyz/yominet-1](https://scan.initia.xyz/yominet-1) |
| **Gas Price** | Flat `0.0025 gwei` |
| **Native Token** | $ETH (bridged) |
| **Currency Symbol** | ETH |

---

## Adding Yominet to Your Wallet

### MetaMask (Manual)

1. Open MetaMask → Settings → Networks → Add Network
2. Fill in:
   - **Network Name:** Yominet
   - **RPC URL:** `https://jsonrpc-yominet-1.anvil.asia-southeast.initia.xyz`
   - **Chain ID:** `428962654539583`
   - **Currency Symbol:** ETH
   - **Block Explorer URL:** `https://scan.initia.xyz/yominet-1`
3. Click **Save**

### Programmatic (ethers.js v6)

```javascript
import { ethers } from "ethers";

const YOMINET = {
  chainId: 428962654539583,
  name: "Yominet",
};

const provider = new ethers.JsonRpcProvider(
  "https://jsonrpc-yominet-1.anvil.asia-southeast.initia.xyz",
  YOMINET
);
```

> **Note:** In ethers v6, pass `chainId` as a JavaScript number in the network object (not a `BigInt`).

### Supported Wallets

| Wallet | Supported |
|--------|-----------|
| MetaMask | ✅ |
| Rabby | ✅ |

---

## Bridging

ETH on Yominet is **bridged via LayerZero** from Ethereum mainnet. Both your **Owner wallet** and **Operator wallet** need ETH for gas.

> **There is no faucet.** You must bridge real ETH to Yominet to get gas tokens.

### Option 1: Kamigotchi In-Game Bridge (Recommended)

The Kamigotchi client includes a built-in bridge powered by the Initia bridge.

1. Open the Kamigotchi client
2. Go to **Settings > Bridge**
3. Select the amount of ETH to bridge from Ethereum mainnet
4. Confirm the transaction in your wallet
5. Wait for the bridge to complete — funds arrive as native ETH on Yominet

This is the simplest option if you already have the Kamigotchi client running.

### Option 2: gas.zip

[gas.zip](https://gas.zip) is a multi-chain gas bridge that supports Yominet.

1. Go to [gas.zip](https://gas.zip)
2. Select **Yominet** as the destination chain
3. Enter the destination wallet address (your Owner or Operator wallet)
4. Send ETH from any supported source chain
5. Funds arrive as native ETH on Yominet

### Recommended Funding Amounts

For a new bot developer, bridge **0.2-0.5 ETH**. Gas is extremely cheap (~0.001 ETH for thousands of transactions). The main ETH costs are:

- **Newbie Vendor purchases** — 0.005+ ETH per item (paid in native ETH via `msg.value`)
- **Gacha tickets** — 0.1 ETH each (requires WETH deposit to portal; see WETH section below)

---

## Gas

Yominet uses a **flat gas price** of `0.0025 gwei` (`2500000 wei`). This is extremely low compared to Ethereum mainnet.

```javascript
// Gas is cheap — but some systems need hardcoded gas limits:
// - account.move() (system.account.move):              1,200,000 gas (rooms with gates)
// - harvest.liquidate() (system.harvest.liquidate):     7,500,000 gas
// - gacha.mint() (system.kami.gacha.mint):               4,000,000 + 3,000,000 per kami
```

> **Note:** Always set appropriate gas limits for high-compute operations. The flat gas price means cost is minimal, but gas **limits** still matter for complex system calls.

---

## Currencies: Native ETH vs WETH vs In-Game Currencies

Yominet has several distinct currency types. Understanding the differences is critical for bot development.

| Currency | Type | Where It Lives | Used For |
|----------|------|---------------|----------|
| **Native ETH** | Gas token | Wallet balance | Gas fees, marketplace listing buys (`msg.value`), Newbie Vendor purchases (`msg.value`) |
| **WETH** | ERC-20 | Contract `0xE1Ff...2546` | Marketplace offers (approval-based), depositing into game as in-game ETH (item 103) via portal |
| **In-game ETH** | Inventory item | In-game (item 103) | Gacha tickets, other in-game ETH-denominated actions |
| **$MUSU** | Inventory item | In-game (item 1) | Merchant purchases, trade fees, NPC gifts, quest costs |
| **$ONYX** | ERC-20 | Contract `0x4BaD...7CF4` | Revive, rename (disabled), respec (disabled) |

> **Key distinction:** Native ETH is what you bridge in and use for gas. WETH is the ERC-20 wrapper used for smart contract interactions that require token approvals. In-game ETH (item 103) is a separate inventory item created by depositing WETH through the portal.

---

## WETH (Wrapped ETH)

| Token | Contract Address |
|-------|-----------------|
| **Wrapped ETH (WETH)** | [`0xE1Ff7038eAAAF027031688E1535a055B2Bac2546`](https://scan.initia.xyz/yominet-1/address/0xE1Ff7038eAAAF027031688E1535a055B2Bac2546) |

WETH is needed for marketplace offers (which use ERC-20 approvals) and for depositing ETH into the game as in-game ETH (item 103) via the portal.

### Wrapping and Unwrapping ETH

```javascript
const WETH_ADDRESS = "0xE1Ff7038eAAAF027031688E1535a055B2Bac2546";
const WETH_ABI = ["function deposit() payable", "function withdraw(uint256)"];
const weth = new ethers.Contract(WETH_ADDRESS, WETH_ABI, ownerSigner);

// Wrap native ETH into WETH
const tx = await weth.deposit({ value: ethers.parseEther("0.1") });
await tx.wait();

// Unwrap WETH back to native ETH
const unwrapTx = await weth.withdraw(ethers.parseEther("0.1"));
await unwrapTx.wait();
```

---

## $MUSU (In-Game Currency)

$MUSU is the **primary in-game currency** (item index 1). It is **not** an ERC-20 token — it exists only as an in-game inventory item.

### Earning $MUSU

- Harvesting at resource nodes

### $MUSU Uses

- Merchant purchases from in-game shops
- Trade fees on player-to-player trades
- NPC gifts (relationship building)
- Quest costs

> **Note:** $MUSU cannot be transferred on-chain as a token. It can only be traded between players using the in-game [Trading](player-api/trading.md) system.

---

## Game Currency: $ONYX

$ONYX is the in-game ERC-20 token used for premium operations.

| Contract Address |
|-----------------|
| [`0x4BaDFb501Ab304fF11217C44702bb9E9732E7CF4`](https://scan.initia.xyz/yominet-1/address/0x4BaDFb501Ab304fF11217C44702bb9E9732E7CF4) |

### $ONYX Uses

- `onyx.revive(kamiIndex)` — Revive a dead Kami (costs 33 ONYX) *(active)*
- `onyx.rename(kamiID, name)` — Rename a Kami (costs 5000 ONYX) *(currently disabled on production)*
- `onyx.respec(kamiID)` — Respec a Kami's skills (costs 10000 ONYX) *(currently disabled on production)*

> **Note:** Most $ONYX operations require the **Owner wallet** — except `onyx.revive()`, which uses the **Operator wallet**.

### Acquiring $ONYX

- **Trading on Baseline Markets** — $ONYX can be bought and sold on [Baseline Markets](https://legacy.baseline.markets). Search for the ONYX token on Yominet.
- **Player-to-player trading** — Use the in-game [Trading](player-api/trading.md) system to exchange items or $MUSU for $ONYX with other players.

---

## Infrastructure

| Layer | Technology |
|-------|-----------|
| Execution | OP Stack (Optimistic Rollup) |
| Data Availability | Celestia |
| Settlement | Initia L1 |
| Smart Contracts | Solidity (MUD ECS framework) |

---

## Related Pages

- [Architecture Overview](architecture.md) — How the MUD ECS model works
- [Live Addresses](contracts/live-addresses.md) — All deployed contract addresses
- [Integration Guide](integration-guide.md) — Getting started for developers
