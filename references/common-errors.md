# Common Revert Reasons

Quick reference for common Solidity revert messages across Kamigotchi systems. These are the exact error strings returned on-chain — use them for error handling in your integration.

---

## Account Registration (`system.account.register`)

| Revert Message | Cause |
|----------------|-------|
| `"Account: exists for Owner"` | The owner wallet already has a registered account |
| `"Account: exists for Operator"` | The operator address is already assigned to another account |
| `"Account: name cannot be empty"` | Empty string passed as name |
| `"Account: name must be < 16chars"` | Name exceeds 16 bytes |
| `"Account: name taken"` | Another account already uses this name |

---

## Kami Naming (`system.kami.name`)

| Revert Message | Cause |
|----------------|-------|
| `"PetName: must be in room 11"` | The Kami is not in room 11 (required location for naming) |
| `"PetName: You need Holy Dust for this"` | Account has no Holy Dust (item index 11011) |
| `"PetName: name cannot be empty"` | Empty string passed as name |
| `"PetName: name can be at most 16 characters"` | Name exceeds 16 bytes |
| `"PetName: name taken"` | Another Kami already uses this name |

> **Note:** `PetName` is the on-chain contract name for the Kami naming system. These revert strings are immutable on-chain values.

---

## Harvest Liquidation (`system.harvest.liquidate`)

| Revert Message | Cause |
|----------------|-------|
| `"harvest inactive"` | The target harvest is not currently active |
| `"target too far"` | The attacker's Kami is not at the same node as the target harvest |
| `"node too far"` | The attacker's account is not in the same room as the node |
| `"kami lacks violence (weak)"` | The attacking Kami does not have enough violence stat to liquidate |

---

## Gacha Ticket Purchase (`system.buy.gacha.ticket` — Deprecated)

> **Note:** The `buyPublic()` / `buyWL()` ticket sale system is no longer active. Gacha tickets are now purchased via `system.auction.buy` (Dutch auction, paid in $MUSU). The errors below are from the legacy system.

| Revert Message | Cause |
|----------------|-------|
| `"max mints reached"` | Global mint cap has been reached |
| `"cannot mint 0 tickets"` | Zero amount passed |
| `"public mint has not yet started"` | Public minting period has not begun |
| `"max public mint per account reached"` | Account has hit its per-account public mint limit |
| `"not whitelisted"` | Account is not on the whitelist (for `buyWL()`) |
| `"whitelist mint has not yet started"` | Whitelist minting period has not begun |
| `"max whitelist mint per account reached"` | Account has hit its per-account whitelist mint limit |

---

## Friend Request (`system.friend.request`)

| Revert Message | Cause |
|----------------|-------|
| `"FriendRequest: cannot fren self"` | Attempted to send a friend request to your own account |
| `"Max friend requests reached"` | Target account has reached the maximum number of pending friend requests |
| `"FriendRequest: already exists"` | An outbound friend request to this target already exists |
| `"FriendRequest: inbound request exists"` | The target has already sent you a friend request (accept it instead) |
| `"FriendRequest: already friends"` | You are already friends with this account |
| `"FriendRequest: blocked"` | The target has blocked your account |

---

## Newbie Vendor (`system.newbievendor.buy`)

| Revert Message | Cause |
|----------------|-------|
| `"NewbieVendor: disabled"` | The Newbie Vendor is currently disabled by admin config |
| `"NewbieVendor: already purchased"` | This account has already bought from the Newbie Vendor |
| `"NewbieVendor: account too old"` | Account was created more than 24 hours ago |
| `"NewbieVendor: insufficient ETH"` | `msg.value` is less than the current vendor price |
| `"NewbieVendor: pool empty"` | No Kamis are currently available in the vendor pool |
| `"NewbieVendor: kami not on display"` | The requested Kami index is not in the current display pool |

---

## Kami Send (`system.kami.send`)

| Revert Message | Cause |
|----------------|-------|
| `"KamiSend: empty batch"` | Empty array passed as `kamiIndices` |
| `"KamiSend: cannot send to self"` | Sender and recipient are the same account |

---

## Chat (`system.chat`)

| Revert Message | Cause |
|----------------|-------|
| `"can't send messages"` | Account does not meet configurable prerequisites checked via `LibConditional` (may include room requirements or item ownership) |

---

## General Errors

These can appear across multiple systems:

| Revert Message | Cause |
|----------------|-------|
| `"Account: no account detected"` | No account registered for the owner wallet (`LibAccount.getByOwner`) |
| `"Account: Operator not found"` | No account registered for the operator wallet (`LibAccount.getByOperator`) |
| `"kami not urs"` | Kami is not owned by the caller's account (`LibKami.verifyAccount`) |
| `"kami not RESTING"` | Kami is not in `RESTING` state (e.g., already harvesting or dead) (`LibKami.verifyState`) |
| `"kami on cooldown"` | Kami's action cooldown has not expired (`LibKami.verifyCooldown`) |
| `"kami starving.."` | Kami's health is 0 — must be healed or revived (`LibKami.verifyHealthy`) |
| `"kami too far"` | Kami is not in the same room as the account (`LibKami.verifyRoom`) |
| `"PetLevel: need more experience"` | Kami doesn't have enough XP to level up (`KamiLevelSystem`) |
| `"Account: insufficient stamina"` | Account doesn't have enough stamina for the action (`LibAccount.depleteStamina`) |

---

## Troubleshooting FAQ

### "My transaction is pending forever"

Yominet uses flat gas pricing. If a transaction is stuck, check the nonce — you may have a nonce gap. You can replace a stuck transaction by submitting a new one with the same nonce and a higher priority fee.

### "I get 'execution reverted' with no message"

This usually means the system address was not resolved correctly, or you are using the wrong ABI. Double-check your system resolution logic (see [Resolving System Addresses](../contracts/ids-and-abis.md#resolving-system-addresses)) and verify the `executeTyped` signature matches the system you are calling.

### "My Kami died during harvesting"

Your Kami's health reached 0. You have two options to revive it:

1. **ONYX revive:** Call `system.kami.onyx.revive` — costs 33 ONYX, restores health to 33.
2. **Revive item:** Use a revive consumable (Red Ribbon Gummy, Djed Pillar, or Pale Potion) via `system.kami.use.item`.

If you have neither ONYX nor a revive item, you need to acquire ONYX (via harvesting on another Kami, trading, or the ERC20 portal) or craft/buy a revive item.

### "Newbie Vendor says 'account too old'"

The Newbie Vendor has a **24-hour window** from account registration. You must buy within 24 hours of calling `system.account.register`. If you missed the window, use gacha minting instead — see [Minting](../player-api/minting.md).

### "Which room should my Kami harvest in?"

Room 1 (Misty Riverside) has a harvest node at index 1, and most rooms have nodes. Higher-level nodes may have better yields. Check [Game Data — Harvest Nodes](game-data.md) for the full list of rooms and node indices.

### "How do I know when to collect my harvest?"

You can query the harvest entity's on-chain components to check accumulated rewards, or simply collect periodically with `system.harvest.collect`. Uncollected rewards accumulate — there is no expiration or penalty for waiting.

---

## See Also

- [Overview — Error Handling](../player-api/overview.md#error-handling) — How to catch and parse revert reasons
- [System IDs & ABIs](../contracts/ids-and-abis.md) — Complete system reference
