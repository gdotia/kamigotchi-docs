> **Doc Class:** Agent Guidance
> **Canonical Source:** Derived from Core Resources in this repo and canonical sources listed in `resources/references/data-provenance.md`.
> **Freshness Rule:** Do not become source-of-truth for canonical values; link back to Core Resources for addresses, IDs, and tables.

# Yominet Bridge (Working Route)

This folder stores the working Base -> Initia L1 -> Yominet flow that unwraps to the local Yominet ETH-denom token contract.

## Files

- `bridge-live.mjs`: working sender script (no hardcoded private key)
- `last-success.json`: last known successful run metadata

## Install

```bash
cd guidance/tools/yominet-bridge   # relative to repo root
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

## Bootstrap inputs

For the end-to-end agent bootstrap, the user supplies:

- `PRIVATE_KEY` — the Base-funded owner wallet private key
- `BRIDGE_AMOUNT_ETH` — how much ETH to move from Base to Yominet

The script derives the destination `0x...` and `init1...` recipients from that key automatically.

## Optional env vars

- `RECIPIENT_EVM` default: derived from `PRIVATE_KEY` (0x address)
- `RECIPIENT_INITIA` default: derived from `PRIVATE_KEY` (`init1...` address)
- `BRIDGE_AMOUNT_ETH` default: `0.0001`
- `BASE_RPC` default: `https://mainnet.base.org`
- `PRINT_ADDRESSES` default: unset (`1` = print mapping and exit)
- `DRY_RUN` default: unset (`1` = quote without sending)

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

- This route lands on the Yominet ETH asset exposed through local contract `0xE1Ff7038eAAAF027031688E1535a055B2Bac2546`.
- After bridge completion, the funds are usable for gas and native-ETH KamiSwap buys. Use the contract interface only when you need ERC-20 approvals such as marketplace offers or portal flows.
- The old wrapped token (`l2/...`) is contract `0xFe4Bb04ED0906942a37DE4A1C2142219d9fC1150`.

## Troubleshooting

- **Insufficient balance:** The script checks your Base ETH balance before sending. Ensure you have enough to cover the bridge amount plus gas (~0.001 ETH buffer).
- **LayerZero delivery delays:** Bridge transactions typically confirm within 2-5 minutes. Track your transaction at `https://layerzeroscan.com/tx/YOUR_TX_HASH`.
- **"fee payer address does not exist":** Your destination address has never received funds on Yominet/Initia. This is normal for first-time bridges — the transaction will create the account.
- **Ran the script twice by accident:** Safe to do — each run is an independent bridge transaction. Check your balance on [scan.initia.xyz/yominet-1](https://scan.initia.xyz/yominet-1).
