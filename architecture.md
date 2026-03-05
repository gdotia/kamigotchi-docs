# Architecture Overview

Kamigotchi is built on the **MUD Entity Component System (ECS)** framework — a fully on-chain game architecture where all state lives in smart contracts on Yominet, an Initia L2 rollup.

---

## MUD ECS Model

```
┌─────────────────────────────────────────────┐
│                   World                      │
│  (Root contract — system registry)            │
├─────────────────────────────────────────────┤
│                                             │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐     │
│  │ System A │  │ System B │  │ System C │    │
│  │ (Logic)  │  │ (Logic)  │  │ (Logic)  │    │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘   │
│       │              │              │         │
│  ┌────▼──────────────▼──────────────▼──────┐ │
│  │            Component Store              │ │
│  │  (On-chain state keyed by entity ID)    │ │
│  └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

### World

The **World** contract is the root of the entire game. It:

- Maintains a registry of all **Systems** (logic contracts)
- Exposes the `systems()` registry component, which maps `systemAddress -> systemId`
- Resolves system addresses by querying `SystemsComponent.getEntitiesWithValue(keccak256(systemId))` and casting the entity ID to `address`
- Manages access control and ownership
- Address: [`0x2729174c265dbBd8416C6449E0E813E88f43D0E7`](https://scan.initia.xyz/yominet-1/address/0x2729174c265dbBd8416C6449E0E813E88f43D0E7)

### Systems

Systems are stateless smart contracts that contain **game logic**. Each system:

- Extends `solecs/System.sol`
- Implements `execute(bytes)` and `executeTyped(...)` entry points
- Is identified by a human-readable **System ID** (e.g., `system.kami.level`)
- Has its address resolved dynamically via the `systems()` component

Kamigotchi has **67 documented player-facing systems** — see [System IDs & ABIs](contracts/ids-and-abis.md) for the complete list. The World contract contains additional internal and admin systems not covered here.

### Components

Components are on-chain key-value stores, keyed by **entity ID** (`uint256`). They hold all game state:

| Component | Description |
|-----------|-------------|
| `HealthComponent` | Kami health stats (base, shift, boost, sync) |
| `PowerComponent` | Kami power stats |
| `HarmonyComponent` | Kami harmony stats |
| `ViolenceComponent` | Kami violence stats |
| `IDOwnsInventoryComponent` | Inventory ownership mapping (holder entity ID) |
| `ValueComponent` | Inventory quantity / generic value storage |
| `IndexRoomComponent` | Account room index |
| ... | Many more |

### Entities

Every game object is an **entity** — a `uint256` identifier. Entities have no inherent meaning; their type is defined by which components are attached:

- A **Kami** entity has `HealthComponent`, `PowerComponent`, `HarmonyComponent`, `ViolenceComponent`, etc.
- An **Account** entity has `IDOwnsInventoryComponent`, `IndexRoomComponent`, etc.
- A **Trade** entity has trade-specific components

---

## Wallet Architecture

Kamigotchi uses a **dual-wallet model** to balance security with usability:

```
┌──────────────────┐          ┌──────────────────┐
│   Owner Wallet   │  ──────▶ │ Operator Wallet  │
│  (Main wallet)   │ delegates│  (Session key)   │
│                  │          │                  │
│ • Holds NFTs     │          │ • In-game txns   │
│ • Registers acct │          │ • Move, chat     │
│ • ONYX spending  │          │ • Harvest, trade  │
│ • Set operator   │          │ • Privy-managed   │
└──────────────────┘          └──────────────────┘
```

### Owner Wallet

The player's primary wallet (MetaMask, Rabby, etc.). Used for:

- `register()` — Creating a new account
- `set.operator()` — Delegating to an operator wallet
- `set.name()` — Renaming account
- `onyx.rename` and `onyx.respec` (via $ONYX, currently disabled on production)
- ERC721 staking/unstaking
- Trading (create, execute, complete, cancel)
- Gacha ticket purchase and minting
- `kamimarket.buy` — Buying Kami listings on the marketplace (sends ETH)
- `newbievendor.buy` — Buying first Kami from the Newbie Vendor (sends ETH)

### Operator Wallet

A delegated wallet (typically managed by [Privy](https://privy.io)) for frequent, low-risk transactions:

- Moving between rooms
- Sending chat messages
- Starting/stopping harvests
- Crafting, questing
- Setting profile picture (`set.pfp`)
- Reviving Kami via ONYX (`onyx.revive`)
- `kamimarket.list` — Listing a Kami for sale on the marketplace
- `kamimarket.offer` — Making specific or collection offers (WETH)
- `kamimarket.acceptoffer` — Accepting incoming offers
- `kamimarket.cancel` — Cancelling listings or offers
- All routine gameplay actions

> **Note:** The operator wallet is set during registration and can be updated by the owner wallet via `set.operator()`. This separation means the owner's private key is rarely exposed to transaction signing.

### How the Official Client Creates Wallets

The Kamigotchi game client uses [Privy](https://privy.io) to manage the wallet flow:

1. **Player connects** their external wallet (MetaMask, Rabby, etc.) via Privy → this becomes the **Owner wallet**
2. **Privy auto-creates** an embedded wallet on login (`createOnLogin: 'all-users'`) → this becomes the **Operator wallet**
3. **Registration** calls `register(embeddedWalletAddress, name)` — the player just enters a username

The embedded wallet acts as a session key: it signs routine gameplay transactions without explicit approval popups, while the owner wallet stays secure for privileged operations.

### Programmatic / Bot Integrations

For API integrations and bots, you can bypass Privy and use two private keys directly:

```javascript
function mustEnv(name) {
  const value = process.env[name];
  if (!value || !value.startsWith("0x")) {
    throw new Error(`Missing ${name}. Set it before running this script.`);
  }
  return value;
}

const ownerSigner = new ethers.Wallet(mustEnv("OWNER_PRIVATE_KEY"), provider);
const operatorSigner = new ethers.Wallet(mustEnv("OPERATOR_PRIVATE_KEY"), provider);

// Register: pass the operator address during account creation
const registerSystem = await getSystem("system.account.register", registerABI, ownerSigner);
await registerSystem.executeTyped(operatorSigner.address, "MyBotAccount");
```

This is the approach used throughout the [Integration Guide](integration-guide.md) and Player API documentation.

---

## Reading State

The **GetterSystem** provides view functions for reading game state without gas costs:

```javascript
// Read Kami data
const kamiData = await getterSystem.getKami(kamiEntityId);

// Read Account data
const accountData = await getterSystem.getAccount(accountEntityId);
```

> **Note:** For real-time data, Kamigotchi uses an off-chain indexer. If the indexer lags behind, use the [Echo functions](player-api/echo.md) to force-emit current state.

---

## System Call Flow

Every player action follows this pattern:

```
1. Client resolves system address from World.systems() component using keccak256(systemId)
2. Player signs tx with Owner or Operator wallet
3. Tx calls the system contract directly at its resolved address
4. System.executeTyped(...) (or execute(bytes)) runs game logic
5. System reads/writes Component state
6. Events emitted → Indexer picks up changes → Client updates
```

> **Note:** The World is a **registry**, not a proxy. It does not route or relay calls — clients resolve system addresses from the World and call them directly.

### Resolving System Addresses

System contract addresses are **not hardcoded** — they are dynamically resolved from the World contract:

```javascript
import { ethers } from "ethers";

const worldAddress = "0x2729174c265dbBd8416C6449E0E813E88f43D0E7";
const worldAbi = ["function systems() view returns (address)"];
const systemsComponentAbi = [
  "function getEntitiesWithValue(uint256) view returns (uint256[])",
];
const world = new ethers.Contract(worldAddress, worldAbi, provider);
const systemsComponentAddress = await world.systems();
const systemsComponent = new ethers.Contract(
  systemsComponentAddress,
  systemsComponentAbi,
  provider
);

// Resolve a system address
const systemId = ethers.keccak256(ethers.toUtf8Bytes("system.kami.level"));
const entities = await systemsComponent.getEntitiesWithValue(systemId);
if (entities.length === 0) throw new Error("System not found");
const systemAddress = ethers.getAddress(ethers.toBeHex(entities[0], 20));
```

---

## Kami Stat Model

Each Kami entity has four core stat categories, each with four sub-values:

| Stat | Description |
|------|-------------|
| **Health** | Durability and survival |
| **Power** | Attack strength |
| **Harmony** | Support and healing |
| **Violence** | Aggressive capabilities |

Each stat has:

| Sub-value | Description |
|-----------|-------------|
| `base` | Innate stat from Kami species/rarity |
| `shift` | Permanent modifications (leveling, items) |
| `boost` | Temporary buffs/debuffs |
| `sync` | Synchronization bonus |

---

## Related Pages

- [Chain Configuration](chain-configuration.md) — Network details
- [Live Addresses](contracts/live-addresses.md) — Contract addresses
- [System IDs & ABIs](contracts/ids-and-abis.md) — All 67 system identifiers
- [Player API Overview](player-api/overview.md) — How to call systems
