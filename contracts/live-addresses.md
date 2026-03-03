# Live Contract Addresses

All core Kamigotchi contracts deployed on Yominet.

---

## Core Contracts

### Testnet

| Contract | Address | Explorer |
|----------|---------|----------|
| **World** | `0x2729174c265dbBd8416C6449E0E813E88f43D0E7` | [View](https://scan.initia.xyz/yominet-1/address/0x2729174c265dbBd8416C6449E0E813E88f43D0E7) |
| **Kami721 (NFT)** | `0x5d4376b62fa8ac16dfabe6a9861e11c33a48c677` | [View](https://scan.initia.xyz/yominet-1/address/0x5d4376b62fa8ac16dfabe6a9861e11c33a48c677) |
| **ONYX Token** | `0x4BaDFb501Ab304fF11217C44702bb9E9732E7CF4` | [View](https://scan.initia.xyz/yominet-1/address/0x4BaDFb501Ab304fF11217C44702bb9E9732E7CF4) |

### Mainnet

| Contract | Address |
|----------|---------|
| **World** | ⚠️ TBD — verify with Asphodel team |
| **Kami721 (NFT)** | ⚠️ TBD — verify with Asphodel team |
| **ONYX Token** | `0x9D9c32921575Fd98e67E27C0189ED4b750Cb17C5` |

---

## System Contract Addresses

System contracts are **not deployed at fixed addresses**. They are registered in the World contract and resolved dynamically at runtime.

### How to Resolve a System Address

```javascript
import { ethers } from "ethers";

const WORLD_ADDRESS = "0x2729174c265dbBd8416C6449E0E813E88f43D0E7";
const WORLD_ABI = ["function systems(uint256) view returns (address)"];

const provider = new ethers.JsonRpcProvider(
  "https://jsonrpc-yominet-1.anvil.asia-southeast.initia.xyz"
);

const world = new ethers.Contract(WORLD_ADDRESS, WORLD_ABI, provider);

// Resolve any system by its string ID
async function getSystemAddress(systemId) {
  const hash = ethers.keccak256(ethers.toUtf8Bytes(systemId));
  return await world.systems(hash);
}

// Example: resolve the Kami level system
const levelSystemAddr = await getSystemAddress("system.kami.level");
console.log("KamiLevelSystem:", levelSystemAddr);
```

### Why Dynamic Resolution?

The MUD framework allows systems to be **upgraded** by deploying new contracts and updating the World registry. Hardcoding system addresses would break on upgrades. Always resolve from the World contract.

---

## Token Contracts

### ONYX (ERC-20)

The in-game currency token. Standard ERC-20 interface.

| Network | Address |
|---------|---------|
| Testnet | `0x4BaDFb501Ab304fF11217C44702bb9E9732E7CF4` |
| Mainnet | `0x9D9c32921575Fd98e67E27C0189ED4b750Cb17C5` |

```javascript
const ONYX_ABI = [
  "function balanceOf(address) view returns (uint256)",
  "function approve(address spender, uint256 amount) returns (bool)",
  "function transfer(address to, uint256 amount) returns (bool)",
  "function allowance(address owner, address spender) view returns (uint256)",
];

const onyx = new ethers.Contract(
  "0x4BaDFb501Ab304fF11217C44702bb9E9732E7CF4",
  ONYX_ABI,
  signer
);

const balance = await onyx.balanceOf(walletAddress);
```

### Kami721 (ERC-721)

The Kami NFT contract. Standard ERC-721 interface with game-specific extensions.

| Network | Address |
|---------|---------|
| Testnet | `0x5d4376b62fa8ac16dfabe6a9861e11c33a48c677` |
| Mainnet | ⚠️ TBD — verify with Asphodel team |

```javascript
const KAMI721_ABI = [
  "function balanceOf(address) view returns (uint256)",
  "function ownerOf(uint256 tokenId) view returns (address)",
  "function approve(address to, uint256 tokenId)",
  "function setApprovalForAll(address operator, bool approved)",
  "function transferFrom(address from, address to, uint256 tokenId)",
];

const kami721 = new ethers.Contract(
  "0x5d4376b62fa8ac16dfabe6a9861e11c33a48c677",
  KAMI721_ABI,
  signer
);
```

---

## Related Pages

- [System IDs & ABIs](ids-and-abis.md) — All 55 system identifiers
- [Chain Configuration](../chain-configuration.md) — Network details
- [Architecture Overview](../architecture.md) — How contracts interact
