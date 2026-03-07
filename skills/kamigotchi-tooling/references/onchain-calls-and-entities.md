> **Doc Class:** Agent Guidance
> **Canonical Source:** Derived from `../../../guidance/integration-guide.md` and Core pages linked below.
> **Freshness Rule:** Treat this page as a routing summary; verify mutable values in the linked Core Resources before relying on them.

# On-Chain Calls & Entities Reference

Key facts for resolving systems, reading state, deriving entity IDs, selecting wallets, and handling non-standard entry points. Always refer to [System IDs & ABIs](../../../resources/contracts/ids-and-abis.md) for the full system registry.

## System Resolution

World is a **registry**, not a router — call system contracts directly.

```
systemId (string) → keccak256 → hash
hash → SystemsComponent.getEntitiesWithValue(hash) → [entityId]
entityId → address(uint160(entityId)) → system address
```

- `World.systems()` returns the **SystemsComponent** address (maps systemAddress → systemId).
- `World.components()` returns the **ComponentsRegistry** address (maps componentAddress → componentId).
- These are **separate registries** — do not mix them up.
- Component IDs use dot notation: `component.value`, `component.stat.health`, etc.

## Entity ID Derivation

| Entity | Formula |
|--------|---------|
| Account | `uint256(uint160(ownerAddress))` |
| Kami | `keccak256(solidityPacked(["string","uint32"], ["kami.id", kamiIndex]))` |
| Harvest | `keccak256(solidityPacked(["string","uint256"], ["harvest", kamiId]))` |
| Inventory slot | `keccak256(solidityPacked(["string","uint256","uint32"], ["inventory.instance", accountId, itemIndex]))` |
| Item registry | `keccak256(solidityPacked(["string","uint32"], ["registry.item", itemIndex]))` |

All derivations are client-side — no RPC calls needed.

Full reference: [resources/player-api/entity-discovery.md](../../../resources/player-api/entity-discovery.md)

## Getter System (Read-Only)

`system.getter` exposes `getKami(uint256)` and `getAccount(uint256)` as view calls — no gas cost. It does **not** cover inventory. To read inventory, use `ValueComponent.getValue(inventoryEntityId)` directly.

Key gotcha: `execute()` reverts with "not implemented" on GetterSystem — call named functions only.

## Value Component Pattern

```
componentName → keccak256 → hash
hash → ComponentsRegistry.getEntitiesWithValue(hash) → [entityId]
entityId → address(uint160(entityId)) → component address
component.getValue(entityId) → uint256
```

`getValue()` returns `0` for entities that have never been set — safe to call for any entity.

## Wallet Selection

| Operation | Wallet |
|-----------|--------|
| `register`, `set.operator`, ERC721, portal, `kamimarket.buy`, gacha mint | Owner |
| move, harvest, quest, craft, chat, `kamimarket.list/offer/cancel/acceptoffer`, `kami.send` | Operator |

When in doubt: if the operation is privileged or involves ETH/NFT custody, use Owner.

## Non-Standard Entry Points

Most systems use `execute(bytes)` or `executeTyped(...)`. Exceptions:

| System | Entry Point | Notes |
|--------|-------------|-------|
| `system.getter` | Named functions only | `execute()` reverts "not implemented" |
| `system.kami.gacha.reveal` | `reveal()` | Not `execute()` |
| `system.kami.gacha.reroll` | `reroll()` | Not `execute()` |
| `system.newbievendor.buy` | `calcPrice()` for reads | Named function, payable for buy |

## Gas Overrides

Yominet uses flat gas pricing — hardcode overrides instead of relying on estimation:

```
maxFeePerGas: 2500000n   // 0.0025 gwei
maxPriorityFeePerGas: 0n
```

Systems requiring explicit gas limits:

| System | Gas Limit |
|--------|-----------|
| `system.account.move` | 1,200,000 |
| `system.harvest.liquidate` | 7,500,000 |
| `system.kami.gacha.mint` | 4,000,000 + 3,000,000/kami |

## ethers.js Gotchas

- Pass `chainId` as a **number** (not BigInt) in the provider network object.
- `Stat.shift` collides with `Array.shift()` — access stat fields by index (`h[0]`, `h[1]`, `h[2]`, `h[3]`).
- `BareComponent._set()` reverts on zero-length values — zero-value protection is enforced on-chain.
