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

## Game Currency: $ONYX

$ONYX is the in-game ERC-20 token used for premium operations.

| Contract Address |
|-----------------|
| [`0x4BaDFb501Ab304fF11217C44702bb9E9732E7CF4`](https://scan.initia.xyz/yominet-1/address/0x4BaDFb501Ab304fF11217C44702bb9E9732E7CF4) |

### $ONYX Uses

- `onyx.rename(kamiID, name)` — Rename a Kami *(currently disabled on production)*
- `onyx.revive(kamiIndex)` — Revive a dead Kami *(active)*
- `onyx.respec(kamiID)` — Respec a Kami's skills *(currently disabled on production)*

> **Note:** Most $ONYX operations require the **Owner wallet** — except `onyx.revive()`, which uses the **Operator wallet**.

### Acquiring $ONYX

- **In-game earning** — Harvesting yields $MUSU, which can be traded for $ONYX via player-to-player trades. Completing quests and crafting also generate value that feeds into $ONYX acquisition.
- **Trading on Baseline Markets** — $ONYX can be bought and sold on [Baseline Markets](https://legacy.baseline.markets). Search for the ONYX token on Yominet.
- **Player-to-player trading** — Use the in-game [Trading](player-api/trading.md) system to exchange items or $MUSU for $ONYX with other players.

---

## Bridging

ETH on Yominet is **bridged via LayerZero** from Ethereum mainnet. The native gas token is a wrapped ETH (WETH) token at this address:

| Token | Contract Address |
|-------|-----------------|
| **Wrapped ETH (WETH)** | [`0xE1Ff7038eAAAF027031688E1535a055B2Bac2546`](https://scan.initia.xyz/yominet-1/address/0xE1Ff7038eAAAF027031688E1535a055B2Bac2546) |

> **Note:** All gas on Yominet is paid in this bridged ETH token. When the docs refer to "$ETH on Yominet", this is the token being referenced.

### Bridge Options

| Bridge | URL | Notes |
|--------|-----|-------|
| gas.zip | [gas.zip](https://gas.zip) | Multi-chain gas bridge — easiest way to get ETH on Yominet |

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
