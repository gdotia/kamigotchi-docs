> **Doc Class:** Agent Guidance
> **Canonical Source:** Derived from Core Resources in this repo and canonical sources listed in `references/data-provenance.md`.
> **Freshness Rule:** Do not become source-of-truth for canonical values; link back to Core Resources for addresses, IDs, and tables.

# Yominet Bridge (Working Route)

This folder stores the working Base -> Initia L1 -> Yominet flow that unwraps to the local Yominet ETH-denom token contract.

## Files

- `bridge-live.mjs`: working sender script (no hardcoded private key)
- `last-success.json`: last known successful run metadata

## Install

```bash
cd /home/matrix/kamigotchi-docs/tools/yominet-bridge
npm init -y
npm i ethers @initia/initia.js
```

## Run (dry-run first)

```bash
export PRIVATE_KEY='YOUR_BASE_PRIVATE_KEY'
export DRY_RUN=1
node bridge-live.mjs
```

## Print derived address mapping only

```bash
export PRIVATE_KEY='YOUR_BASE_PRIVATE_KEY'
export PRINT_ADDRESSES=1
node bridge-live.mjs
```

## Run live send

```bash
export PRIVATE_KEY='YOUR_BASE_PRIVATE_KEY'
unset DRY_RUN
node bridge-live.mjs
```

## Optional env vars

- `RECIPIENT_EVM` default: derived from `PRIVATE_KEY` (0x address)
- `RECIPIENT_INITIA` default: derived from `PRIVATE_KEY` (`init1...` address)
- `BRIDGE_AMOUNT_ETH` default: `0.0001`
- `BASE_RPC` default: `https://mainnet.base.org`
- `PRINT_ADDRESSES` default: unset (`1` = print mapping and exit)

## Address mapping behavior

- With only `PRIVATE_KEY`, script deterministically maps:
  - `PRIVATE_KEY -> RECIPIENT_EVM` (0x)
  - `PRIVATE_KEY -> RECIPIENT_INITIA` (init1...)
- If you override recipients, set both `RECIPIENT_EVM` and `RECIPIENT_INITIA` together.
- You cannot derive an `init1...` address from an arbitrary `0x` address alone. The shared source of truth is the private key.

## Advanced recipient override

```bash
export PRIVATE_KEY='YOUR_BASE_PRIVATE_KEY'
export RECIPIENT_EVM='0xYourDestinationEvmAddress'
export RECIPIENT_INITIA='init1yourdestinationbech32'
export DRY_RUN=1
node bridge-live.mjs
```

## Notes

- This route deposits to Yominet token contract `0xE1Ff7038eAAAF027031688E1535a055B2Bac2546` (not native gas ETH).
- The old wrapped token (`l2/...`) is contract `0xFe4Bb04ED0906942a37DE4A1C2142219d9fC1150`.
