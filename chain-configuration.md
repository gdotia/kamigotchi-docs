# Chain Configuration

Kamigotchi is deployed on **Yominet**, an Initia L2 rollup built on the OP Stack with Celestia DA (Data Availability).

---

## Network Details

### Testnet

| Parameter | Value |
|-----------|-------|
| **Chain Name** | Yominet Testnet |
| **Chain ID (EVM)** | `428962654539583` |
| **RPC URL** | `https://jsonrpc-yominet-1.anvil.asia-southeast.initia.xyz` |
| **Block Explorer** | [scan.initia.xyz/yominet-1](https://scan.initia.xyz/yominet-1) |
| **Gas Price** | Flat `0.005 gwei` |
| **Native Token** | $ETH (bridged) |
| **Currency Symbol** | ETH |

### Mainnet

| Parameter | Value |
|-----------|-------|
| **Chain Name** | Yominet Mainnet |
| **Chain ID (EVM)** | `4471190363524365` ⚠️ TBD — verify with Asphodel team |
| **RPC URL** | ⚠️ TBD — verify with Asphodel team |
| **Block Explorer** | ⚠️ TBD — verify with Asphodel team |
| **Gas Price** | Flat `0.005 gwei` |
| **Native Token** | $ETH (bridged) |

---

## Adding Yominet to Your Wallet

### MetaMask (Manual)

1. Open MetaMask → Settings → Networks → Add Network
2. Fill in:
   - **Network Name:** Yominet Testnet
   - **RPC URL:** `https://jsonrpc-yominet-1.anvil.asia-southeast.initia.xyz`
   - **Chain ID:** `428962654539583`
   - **Currency Symbol:** ETH
   - **Block Explorer URL:** `https://scan.initia.xyz/yominet-1`
3. Click **Save**

### Programmatic (ethers.js v6)

```javascript
import { ethers } from "ethers";

const YOMINET_TESTNET = {
  chainId: 428962654539583n,
  name: "Yominet Testnet",
};

const provider = new ethers.JsonRpcProvider(
  "https://jsonrpc-yominet-1.anvil.asia-southeast.initia.xyz",
  YOMINET_TESTNET
);
```

### Supported Wallets

| Wallet | Supported |
|--------|-----------|
| MetaMask | ✅ |
| Rabby | ✅ |
| WalletConnect | ⚠️ TBD |

---

## Gas

Yominet uses a **flat gas price** of `0.005 gwei`. This is extremely low compared to Ethereum mainnet.

```javascript
// Gas is cheap — but some systems need hardcoded gas limits:
// - account.move():        1,200,000 gas (rooms with gates)
// - harvest.liquidate():   7,500,000 gas
// - pet.mint():            4,000,000 + 3,000,000 per pet
```

> **Note:** Always set appropriate gas limits for high-compute operations. The flat gas price means cost is minimal, but gas **limits** still matter for complex system calls.

---

## Game Currency: $ONYX

$ONYX is the in-game ERC-20 token used for premium operations.

| Network | Contract Address |
|---------|-----------------|
| Testnet | [`0x4BaDFb501Ab304fF11217C44702bb9E9732E7CF4`](https://scan.initia.xyz/yominet-1/address/0x4BaDFb501Ab304fF11217C44702bb9E9732E7CF4) |
| Mainnet | [`0x9D9c32921575Fd98e67E27C0189ED4b750Cb17C5`](https://scan.initia.xyz/yominet-1/address/0x9D9c32921575Fd98e67E27C0189ED4b750Cb17C5) |

### $ONYX Uses

- `onyx.rename(kamiID, name)` — Rename a Kami
- `onyx.revive(kamiIndex)` — Revive a dead Kami
- `onyx.respec(kamiID)` — Respec a Kami's skills

> **Note:** All $ONYX operations require the **Owner wallet** (not operator).

---

## Bridging

To get $ETH on Yominet for gas, use one of these bridges:

| Bridge | URL | Notes |
|--------|-----|-------|
| Initia Bridge | ⚠️ TBD — verify URL with Asphodel team | Official Initia bridge |
| gas.zip | [gas.zip](https://gas.zip) | Multi-chain gas bridge |

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
