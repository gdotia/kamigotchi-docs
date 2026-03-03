# Gacha / Minting

The gacha system lets players mint new Kamis using gacha tickets. Minting follows a commit-reveal pattern for fair randomness.

---

## pet.mint()

Mint new Kamis using gacha tickets.

| Property | Value |
|----------|-------|
| **System ID** | `system.kami.gacha.mint` |
| **Wallet** | 🎮 Operator |
| **Gas** | **4,000,000 + 3,000,000 per pet** |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `amount` | `uint256` | Number of Kamis to mint |

### Description

Commits a mint request for one or more Kamis. Consumes gacha tickets from the player's inventory. This is the **commit** phase of the commit-reveal pattern — the Kami's traits are not determined yet.

After minting, use `pet.reveal()` to reveal the Kamis.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256 amount) returns (bytes)"];
const system = await getSystem("system.kami.gacha.mint", ABI, operatorSigner);

const mintAmount = 3;
const gasLimit = 4_000_000 + 3_000_000 * mintAmount; // Scale with amount

const tx = await system.executeTyped(mintAmount, { gasLimit });
await tx.wait();
console.log("Mint committed! Use pet.reveal() to reveal your Kamis.");
```

### Notes

- **Gas scales with mint amount**: base 4M + 3M per Kami.
- Requires sufficient gacha tickets — buy with `tickets.buy.public()` or `tickets.buy.whitelist()`.
- Returns commit IDs needed for `pet.reveal()`.

---

## pet.reveal()

Reveal minted Kamis.

| Property | Value |
|----------|-------|
| **System ID** | `system.kami.gacha.reveal` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `commitIDs` | `uint256[]` | Array of commit IDs from `pet.mint()` |

### Description

Reveals the traits (species, stats, rarity) of Kamis from previous mint commits. This is the **reveal** phase — on-chain randomness determines each Kami's attributes.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256[] commitIDs) returns (bytes)"];
const system = await getSystem("system.kami.gacha.reveal", ABI, operatorSigner);

const commitIds = [commitId1, commitId2, commitId3];
const tx = await system.executeTyped(commitIds);
await tx.wait();
console.log("Kamis revealed!");
```

### Notes

- There may be a minimum block delay between `mint()` and `reveal()` for randomness security.
- Batch reveals are more gas-efficient.
- After revealing, use [echo.kamis()](echo.md) if the UI doesn't update.

---

## pet.reroll()

Reroll Kamis.

| Property | Value |
|----------|-------|
| **System ID** | `system.kami.gacha.reroll` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `kamiIDs` | `uint256[]` | Array of Kami entity IDs to reroll |

### Description

Rerolls one or more Kamis, re-randomizing their traits. The original Kami is replaced with a new random result. This is a second chance mechanic for players unhappy with their initial mint results.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256[] kamiIDs) returns (bytes)"];
const system = await getSystem("system.kami.gacha.reroll", ABI, operatorSigner);

const kamiIds = [kamiId1, kamiId2];
const tx = await system.executeTyped(kamiIds);
await tx.wait();
console.log("Kamis rerolled!");
```

### Notes

- Rerolling may consume additional resources (tickets, items, or ONYX) — ⚠️ TBD.
- **Destructive** — the original Kami's traits are replaced permanently.
- May require a subsequent `pet.reveal()` call — ⚠️ TBD.

---

## tickets.buy.public()

Buy gacha tickets (public sale).

| Property | Value |
|----------|-------|
| **System ID** | `system.buy.gacha.ticket` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| `amount` | `uint256` | Number of tickets to buy |

### Description

Purchases gacha tickets from the public sale. Tickets are required for `pet.mint()`. Cost per ticket is ⚠️ TBD — may require $ETH or $ONYX.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

const ABI = ["function executeTyped(uint256 amount) returns (bytes)"];
const system = await getSystem("system.buy.gacha.ticket", ABI, operatorSigner);

const tx = await system.executeTyped(5); // Buy 5 tickets
await tx.wait();
console.log("Gacha tickets purchased!");
```

### Notes

- Ticket price and currency are ⚠️ TBD — verify with Asphodel team.
- Public sale may have per-wallet limits or total supply caps.
- May require token approval (if paying with ERC-20).

---

## tickets.buy.whitelist()

Buy gacha tickets (whitelist sale).

| Property | Value |
|----------|-------|
| **System ID** | `system.buy.gacha.ticket` |
| **Wallet** | 🎮 Operator |
| **Gas** | Default |

### Parameters

| Name | Type | Description |
|------|------|-------------|
| ⚠️ TBD | — | Likely includes a Merkle proof or signature for whitelist verification |

### Description

Purchases gacha tickets during a whitelist/presale phase. Only eligible wallets can call this function. May offer discounted pricing or guaranteed allocation.

### Code Example

```javascript
import { getSystem } from "./kamigotchi.js";

// ⚠️ TBD — exact ABI and parameters depend on whitelist implementation
const ABI = ["function executeTyped() returns (bytes)"];
const system = await getSystem("system.buy.gacha.ticket", ABI, operatorSigner);

const tx = await system.executeTyped();
await tx.wait();
console.log("Whitelist gacha tickets purchased!");
```

### Notes

- ⚠️ The whitelist mechanism (Merkle proof, signature, etc.) needs verification from the Asphodel team.
- Whitelist sales typically have limited availability windows.

---

## Minting Lifecycle

```
  tickets.buy.public()              pet.mint(amount)
  tickets.buy.whitelist()                │
         │                               ▼
         ▼                         Commit IDs generated
  Gacha Tickets                          │
  in Inventory                           ▼
         │                         pet.reveal(commitIDs)
         │                               │
         └──────────────────▶             ▼
                                   Kamis Revealed!
                                         │
                                         ├── Keep → Play!
                                         │
                                         └── pet.reroll(kamiIDs)
                                                  │
                                                  ▼
                                             New traits!
```

---

## Related Pages

- [Kami](kami.md) — Managing minted Kamis
- [Portal](portal.md) — Staking/unstaking Kami NFTs
- [Echo](echo.md) — Force-emit Kami data after minting
