# Getting Started with Kamigotchi

Two ways in: **play the game**, or **build a bot**. Pick your track.

---

# Track 1 — Player Quick Start

Get from zero to playing in five minutes.

## 1) Go to [kamigotchi.io](https://kamigotchi.io)

## 2) Connect Your Wallet

Use **MetaMask** or **Rabby**. Add the Yominet network:

| Field    | Value |
|----------|-------|
| Network  | Yominet |
| Chain ID | `428962654539583` |
| RPC URL  | `https://jsonrpc-yominet-1.anvil.asia-southeast.initia.xyz` |

## 3) Bridge ETH to Yominet

**There is no faucet.** You need to bridge real ETH (0.01 ETH is enough to start).

- **In-game bridge** — Settings → Bridge inside the Kamigotchi client
- **Initia Bridge** — [app.initia.xyz](https://app.initia.xyz/?openBridge=true)

Supported source chains: **Arbitrum**, **Base**, or **Ethereum**.

## 4) Register Your Account

Click Register in-game. **Privy** automatically creates and assigns an Operator wallet — you don't need to set one up yourself.

## 5) Buy Your First Kami

Head to **KamiSwap** in the marketplace and pick up a Kami.

## 6) You're Playing 🎮

Explore, battle, trade. See the [KamiSwap Marketplace docs](player-api/marketplace.md) for trading details.

---

# Track 2 — Bot Developer Setup

Everything below is for developers who want to run agent scripts against the Kamigotchi contracts.

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

## 2) Generate & Fund Your Wallets

**There is no faucet on Yominet.** You must bridge real ETH to get started.

> **Privy is only for the web UI client.** The official Kamigotchi web app uses [Privy](https://privy.io) to auto-create an embedded Operator wallet for browser players. **Bots do not use Privy.** Instead, you generate two wallets yourself (Owner + Operator) and pass the Operator address as a parameter when registering.

### Generate Two Wallets

Bots need **two wallets**: an Owner wallet (holds NFTs, registers, pays ETH) and an Operator wallet (signs routine gameplay transactions).

```javascript
import { ethers } from "ethers";

// Generate Owner wallet
const owner = ethers.Wallet.createRandom();
console.log("Owner address:", owner.address);
console.log("Owner private key:", owner.privateKey);

// Generate Operator wallet
const operator = ethers.Wallet.createRandom();
console.log("Operator address:", operator.address);
console.log("Operator private key:", operator.privateKey);
// ⚠️ Save both keys securely
```

### Fund the Owner Wallet

Bridge real ETH to **your Owner wallet address**. The Operator wallet also needs a small amount of ETH for gas (routine gameplay transactions are sent from the Operator).

Two options to bridge ETH:

1. **In-game bridge** — Open the Kamigotchi client, go to Settings > Bridge. This uses the Initia bridge to move ETH from mainnet/L1 to Yominet.
2. **Initia Bridge** — Use the [Initia Bridge](https://app.initia.xyz/?openBridge=true) to bridge ETH from Arbitrum, Base, or Ethereum to Yominet.

**Recommended amounts:**
- Owner: 0.01 ETH for gas + registration + Kami acquisition
- Operator: 0.001 ETH for gameplay gas
- Additional budget for Kami acquisition: purchase a Kami on KamiSwap marketplace (variable ETH cost), or earn $MUSU for gacha tickets (purchased via auction)

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
  ["function systems() view returns (address)"],
  provider
);
const SYSTEMS_COMPONENT_ABI = [
  "function getEntitiesWithValue(uint256) view returns (uint256[])",
];

async function getSystemAddress(systemId) {
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
4. Gacha reveal commit mismatch:
Resolve commit IDs from confirmed tx events/indexer output (do not trust preflight `staticCall` alone).
5. Marketplace listing ID mismatch:
Use `LISTING_ID` from confirmed tx events/indexer output; listing IDs are non-deterministic.

---

## Typical Bot Gameplay Loop

Once registered with a Kami, a bot's core loop looks like this:

1. **Harvest & scavenge** — Send your Kami to a node (`system.harvest.start`) to earn $MUSU. Certain nodes also have scavenge bars where you can claim items (`system.scavenge.claim`). Harvesting drains HP over time — when it gets dangerous, feed items to your Kami (`system.kami.use.item`) to heal and reset the danger, or stop (`system.harvest.stop`) and rest until full HP. If HP drops below a certain threshold, other players at the same node can kill your Kami. If HP hits 0, your Kami is *starving* — you cannot stop or collect, only feed to heal first, then stop. Never leave a Kami unattended.
2. **Level up** — Spend earned XP to level (`system.kami.level`), then allocate skill points (`system.skill.upgrade`) to strengthen your Kami's stats.
3. **Equip & craft** — Craft items from materials (`system.craft`) and equip gear for stat bonuses (`system.kami.equip`).
4. **Quests** — Accept quests (`system.quest.accept`) and complete them for rewards (`system.quest.complete`).
5. **Trade** — Trade items with players (`system.trade.create`) or buy/sell Kamis on KamiSwap (`system.kamimarket.buy` / `system.kamimarket.list`).
6. **Expand** — Mint new Kamis via gacha (`system.kami.gacha.mint` → `reveal()`), build NPC relationships (`system.relationship.advance`), and contribute to community goals (`system.goal.contribute`).

> ⚠️ **Death is punishing but not permanent.** A dead Kami can be revived with Onyx Shards or a Red Gakki Ribbon. Always monitor your Kami's health while harvesting.

---

## Choosing Your First Kami

After registering, you need a Kami to play. The primary way to acquire one is **KamiSwap** (`system.kamimarket.buy`) — the in-game marketplace where players list Kamis for ETH. The **Owner wallet** pays for the purchase, and the Kami is assigned to your shared account entity (accessible by both Owner and Operator).

When choosing a Kami, look at:

- **Body trait** — determines affinity (Normal, Eerie, Insect, Scrap) and base stat bonuses
- **Hand trait** — also carries an affinity, affects harvest efficacy alongside body
- **Base stats** — every Kami starts with 50 HP / 10 Power / 10 Violence / 10 Harmony, modified by traits

### Recommended: Normal-Affinity Harvester

For a safe, efficient farming bot, pick a **Normal-affinity body with high base Harmony**. Normal affinity gets a half-bonus at *all* node types (jack-of-all-trades), and Harmony reduces harvest strain (HP drain).

**Best body pick: Plant** (index 20, Normal, Uncommon) — +5 Harmony, giving **15 base Harmony at level 1**. This is the highest Harmony bonus among Normal-affinity bodies.

Other Normal bodies for reference:

| Body | Rarity | HP | Pow | Vio | **Harm** | Slots |
|------|--------|-----|-----|-----|----------|-------|
| Plant | Uncommon | 0 | 0 | 0 | **+5** | 0 |
| Orb | Common | 0 | 0 | 0 | **+4** | 0 |
| Suit | Legendary | 0 | 0 | 6 | **+3** | 0 |
| Ghost | Common | 10 | 1 | 1 | +1 | 0 |
| Magatama | Rare | 30 | 3 | 0 | 0 | 0 |

> See [Game Data Reference — Body Traits](references/game-data.md#body-traits) for the full trait table.

---

## Starter Build: Guardian Tree (Levels 1–30)

This build maximizes harvest survivability — high Harmony (reduces strain), high HP (buffer before danger), and Intensity bonuses (more time before strain ramps up).

### Skill Point Allocation

| Phase | Tier | Skills (points each) | Total Pts | Cumulative | Gains |
|-------|------|----------------------|-----------|------------|-------|
| 1 | T1 | 5× Defensiveness, 5× Toughness, 5× Patience | 15 | 15 | +5 Harmony, +50 HP, +25 Intensity/hr |
| 2 | T2 | 5× Vigor, 4× Armor | 9 | 24 | +50 HP, +8% Defense Type Shift |
| 3 | T3 | Anxiety (pick 1 of 3) | 1 | 25 | +3 Harmony |
| 4 | T4 | 5× Dedication | 5 | 30 | +25 Intensity/hr |

**Level 30 totals from skills:** +8 Harmony, +100 HP, +50 Intensity/hr, +8% DTS

Combined with a Plant body, your Kami reaches **23 effective Harmony** (10 base + 5 body + 8 skills) before equipment — making it very resilient to harvest strain and hard for predators to kill profitably.

### Why Guardian over Harvester/Predator?

| Tree | Playstyle | Early-Game Risk |
|------|-----------|-----------------|
| **Guardian** | Survive longer, harvest safely | Low — hard to kill, forgiving for AFK |
| Harvester | Higher MUSU yield per hour | Medium — less tanky, relies on Power for bounty |
| Predator | Kill other Kamis for spoils | High — needs Violence investment, risky PvP |
| Enlightened | Rest faster, fertility bonuses | Medium — good yield but less durable |

For a first bot, Guardian is the safest path. You can always respec later with a Respec Potion (item 11403) or ONYX.

> **Skill reference:** See [Game Data Reference — Skills](references/game-data.md#skills) for all 72 skills across 4 trees.

---

## Next Docs

1. [Integration Guide](integration-guide.md) for full account + first-Kami setup.
2. [Entity Discovery](player-api/entity-discovery.md) for deriving and locating IDs.
3. [KamiSwap Marketplace](player-api/marketplace.md) for listing, buying, and offers.
