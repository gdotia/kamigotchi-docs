> **Doc Class:** Agent Guidance
> **Canonical Source:** Derived from `../../../guidance/agent-bootstrap.md`, `../../../guidance/integration-guide.md`, and Core pages linked below.
> **Freshness Rule:** Treat this page as a routing summary; verify mutable values in the linked Core Resources before relying on them.

# Bootstrap & Wallets Reference

Key facts for setting up the owner/operator wallet model and bridging to Yominet. No code templates — use these facts to build your bootstrap, then follow [Agent Bootstrap](../../../guidance/agent-bootstrap.md) for the full walkthrough.

## Owner / Operator Model

| Wallet | Role | Typical Operations |
|--------|------|--------------------|
| **Owner** | Primary, holds NFTs | `register`, `set.operator`, ERC721 ops, `kamimarket.buy`, gacha mint |
| **Operator** | Delegated session key | move, harvest, quest, craft, `kamimarket.list/offer/cancel`, `kami.send` |

- Owner sets the operator during `system.account.register` and can change it later via `system.account.set.operator`.
- Operator must be a **distinct address** from Owner — never reuse the owner key as operator.
- Deterministic derivation: `keccak256(solidityPacked(["string","address"], ["kamigotchi.operator", ownerAddress]))` gives a stable operator private key from the owner key.

## Bridge Path

There is **no faucet on Yominet**. You must bridge real ETH.

1. Start with ETH on **Base**.
2. Use the Yominet bridge script ([guidance/tools/yominet-bridge/](../../../guidance/tools/yominet-bridge/README.md)) to transfer ETH from Base to Yominet.
3. Bridge to both the owner address **and** the derived operator address (operator needs small ETH for gas).

## Runtime Environment Variables

| Variable | Required By | Notes |
|----------|-------------|-------|
| `OWNER_PRIVATE_KEY` | All scripts | Must start with `0x` |
| `OPERATOR_PRIVATE_KEY` | Gameplay scripts | Must start with `0x`; must be distinct from owner |
| `BRIDGE_AMOUNT_ETH` | Bootstrap only | Amount to bridge from Base |
| `KAMI_ACCOUNT_NAME` | Bootstrap only | 1–15 bytes, used for `system.account.register` |

## Smoke-Test Order

Run these checks after bridging and registering, before building your bot loop:

1. `provider.getBalance(ownerAddress)` → non-zero ETH on Yominet
2. `provider.getBalance(operatorAddress)` → small ETH for gas
3. `getter.getAccount(accountId)` → account exists (non-empty name)
4. `getter.getKami(kamiId)` → Kami exists and state is `"RESTING"`
5. `valueComponent.getValue(inventoryEntityId)` → item balance readable (returns 0 if none held)

## Chain Config Quick Reference

| Parameter | Value |
|-----------|-------|
| Chain ID | `428962654539583` |
| RPC URL | `https://jsonrpc-yominet-1.anvil.asia-southeast.initia.xyz` |
| World contract | `0x2729174c265dbBd8416C6449E0E813E88f43D0E7` |
| Library | ethers.js v6, ESM |

Full chain config: [resources/chain-configuration.md](../../../resources/chain-configuration.md)
Full address list: [resources/contracts/live-addresses.md](../../../resources/contracts/live-addresses.md)
