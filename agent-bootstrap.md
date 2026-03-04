# Agent Bootstrap (First-Time Setup)

This page is a copy-paste path for a brand-new developer to run a Kamigotchi agent script without hitting common setup traps.

---

## 1) Initialize a Node Project

```bash
mkdir kamigotchi-agent
cd kamigotchi-agent
npm init -y
npm install ethers
npm pkg set type=module
```

Why this matters:
1. Docs use `import` syntax and top-level `await`.
2. `type=module` is required for those scripts to run.

---

## 2) Fund Your Wallets

**There is no faucet on Yominet.** You must bridge real ETH to get started.

Two options to fund your wallets:

1. **In-game bridge** — Open the Kamigotchi client, go to Settings > Bridge. This uses the Initia bridge to move ETH from mainnet/L1 to Yominet.
2. **gas.zip** — A third-party bridge aggregator that supports Yominet.

Fund **both** your Owner and Operator wallets with ETH for gas.

**Recommended amounts:**
- 0.01 ETH per wallet for gas
- Additional budget for Kami acquisition: 0.005+ ETH for the Newbie Vendor, or 0.1+ ETH for gacha minting

If you need to generate fresh wallets:

```javascript
import { ethers } from "ethers";
const owner = ethers.Wallet.createRandom();
const operator = ethers.Wallet.createRandom();
console.log("Owner address:", owner.address);
console.log("Owner private key:", owner.privateKey);
console.log("Operator address:", operator.address);
console.log("Operator private key:", operator.privateKey);
// ⚠️ Save these keys securely — they control your wallets
```

---

## 3) Set Required Environment Variables

```bash
# Linux/macOS
export OWNER_PRIVATE_KEY=0xYOUR_OWNER_PRIVATE_KEY
export OPERATOR_PRIVATE_KEY=0xYOUR_OPERATOR_PRIVATE_KEY
```

```powershell
# Windows PowerShell
$env:OWNER_PRIVATE_KEY="0xYOUR_OWNER_PRIVATE_KEY"
$env:OPERATOR_PRIVATE_KEY="0xYOUR_OPERATOR_PRIVATE_KEY"
```

---

## 4) Run a Connectivity + Resolver Smoke Test

Create `bootstrap-check.js`:

```javascript
import { ethers } from "ethers";

const RPC_URL = "https://jsonrpc-yominet-1.anvil.asia-southeast.initia.xyz";
const WORLD_ADDRESS = "0x2729174c265dbBd8416C6449E0E813E88f43D0E7";
const CHAIN = { chainId: 428962654539583, name: "Yominet" };

function mustEnv(name) {
  const value = process.env[name];
  if (!value || !value.startsWith("0x")) {
    throw new Error(`Missing ${name}.`);
  }
  return value;
}

const provider = new ethers.JsonRpcProvider(RPC_URL, CHAIN);
const ownerSigner = new ethers.Wallet(mustEnv("OWNER_PRIVATE_KEY"), provider);
const operatorSigner = new ethers.Wallet(mustEnv("OPERATOR_PRIVATE_KEY"), provider);

const world = new ethers.Contract(
  WORLD_ADDRESS,
  [
    "function systems() view returns (address)",
    "function systems(uint256) view returns (address)",
  ],
  provider
);
const SYSTEMS_COMPONENT_ABI = [
  "function getEntitiesWithValue(uint256) view returns (uint256[])",
];

async function getSystemAddress(systemId) {
  const hash = ethers.keccak256(ethers.toUtf8Bytes(systemId));

  try {
    const legacyAddr = await world["systems(uint256)"](hash);
    if (legacyAddr !== ethers.ZeroAddress) return legacyAddr;
  } catch (_) {}

  const systemsComponentAddr = await world["systems()"]();
  const systemsComponent = new ethers.Contract(
    systemsComponentAddr,
    SYSTEMS_COMPONENT_ABI,
    provider
  );
  const entities = await systemsComponent.getEntitiesWithValue(hash);
  if (entities.length === 0) throw new Error(`System not found: ${systemId}`);
  return ethers.getAddress(ethers.toBeHex(entities[0], 20));
}

const block = await provider.getBlockNumber();
const registerSystem = await getSystemAddress("system.account.register");
console.log("Block:", block);
console.log("Owner:", ownerSigner.address);
console.log("Operator:", operatorSigner.address);
console.log("system.account.register:", registerSystem);
```

Run it:

```bash
node bootstrap-check.js
```

If this succeeds, your environment is ready for the [Integration Guide](integration-guide.md).

---

## 5) First-Run Flow Pitfalls

1. `Cannot use import statement outside a module`:
Fix by running `npm pkg set type=module`.
2. `invalid network object name or chainId`:
Use `chainId: 428962654539583` as a number, not `428962654539583n`.
3. `invalid private key`:
Your env var is missing/invalid. Re-export `OWNER_PRIVATE_KEY` and `OPERATOR_PRIVATE_KEY`.
4. `NewbieVendor: kami not on display`:
Refresh current vendor display indices and retry with a displayed `kamiIndex`.
5. Gacha reveal commit mismatch:
Resolve commit IDs from confirmed tx events/indexer output (do not trust preflight `staticCall` alone).
6. Marketplace listing ID mismatch:
Use `LISTING_ID` from confirmed tx events/indexer output; listing IDs are non-deterministic.

---

## Next Docs

1. [Integration Guide](integration-guide.md) for full account + first-Kami setup.
2. [Entity Discovery](player-api/entity-discovery.md) for deriving and locating IDs.
3. [KamiSwap Marketplace](player-api/marketplace.md) for listing, buying, and offers.
