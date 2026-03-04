---
name: kamigotchi
version: 0.1.0
description: Play Kamigotchi as an AI agent. Manage Kamis (pets), harvest resources, craft items, trade with players, complete quests, and earn $ONYX. Use when the user wants to play Kamigotchi, manage their Kamis, check game status, or interact with the Kamigotchi onchain game on Yominet.
---

# Kamigotchi

Play Kamigotchi — an onchain idle-MMORPG on Yominet (Initia L2). Manage Kamis (pets), harvest resources, craft items, trade, quest, and interact with other players via smart contract calls.

All game interactions go through a local REST API server (`kami-api` at `localhost:3008`) that wraps smart contract calls.

## Quick Start

1. Ensure kami-api is running on port 3008:
   ```bash
   curl http://localhost:3008/api/world/status
   ```
   If connection refused, start it:
   ```bash
   cd /root/.openclaw/workspace/kami-api && npm run dev &
   ```
   Or run the setup script:
   ```bash
   bash /root/.openclaw/workspace/kamigotchi-play/scripts/setup.sh
   ```
2. Check wallet setup — `KAMI_PRIVATE_KEY` must be set in `kami-api/.env`
3. Check account status: `GET /api/account/{address}`
4. If not registered, register: `POST /api/account/register` with `{ "name": "..." }`
5. Stake a Kami: `POST /api/kami/{id}/stake`
6. Start playing!

## Play Modes

See `CONFIG.md` for current settings.

- 🤖 **Autonomous** — Agent decides everything: harvesting, questing, trading
- 💬 **Interactive** — Agent asks before each action

## Core Gameplay Loop (Autonomous)

1. Check Kami status (HP, stats, room, state)
2. If idle → start harvesting at best available node
3. Periodically collect harvest rewards
4. Check for available quests → accept and complete
5. If items in inventory → check merchant listings for profitable trades
6. Level up Kamis when XP is sufficient
7. Equip better gear when available

## API Base URL

```
http://localhost:3008
```

## Key Endpoints

Summary — full reference in `references/api.md`.

### Read (no wallet needed)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/world/status` | Check chain connection |
| GET | `/api/world/rooms` | List all rooms |
| GET | `/api/kami/{id}` | Kami stats, level, XP, room, state |
| GET | `/api/account/{address}` | Account info |
| GET | `/api/account/{address}/kamis` | List owned Kamis |

### Write (wallet required)

| Method | Path | Body | Description |
|--------|------|------|-------------|
| POST | `/api/account/register` | `{ name }` | Register account |
| POST | `/api/kami/{id}/stake` | — | Stake Kami into world |
| POST | `/api/kami/{id}/unstake` | — | Unstake Kami from world |
| POST | `/api/kami/{id}/harvest/start` | `{ nodeId, toolId, duration }` | Start harvesting |
| POST | `/api/kami/{id}/harvest/collect` | — | Collect harvest rewards |
| POST | `/api/kami/{id}/equip` | `{ itemId }` | Equip item |
| POST | `/api/kami/{id}/unequip` | `{ slot }` | Unequip item |
| POST | `/api/kami/{id}/use-item` | `{ itemId }` | Use consumable item |
| POST | `/api/kami/{id}/scavenge` | — | Scavenge current room |
| POST | `/api/kami/{id}/skill` | `{ skillId }` | Upgrade skill |
| POST | `/api/move` | `{ roomId }` | Move to room |
| POST | `/api/market/sell` | `{ price, itemIds, amounts }` | List items for sale |
| POST | `/api/market/buy` | `{ listingId, itemIds, amounts }` | Buy from listing |

## Wallet Requirement

- **Read endpoints:** No wallet needed
- **Write endpoints:** Require `KAMI_PRIVATE_KEY` in `kami-api/.env`
- **Owner-only actions** (register, setOperator, onyx spending): Must use the NFT owner wallet
- **Operator actions** (move, harvest, quest, equip): Can use delegated operator wallet

## Error Handling

- **Connection refused** → kami-api not running. Start it:
  ```bash
  cd /root/.openclaw/workspace/kami-api && npm run dev &
  ```
- **Transaction reverts** → Check Kami state, permissions, sufficient resources
- **Stale state** → Always read Kami status before taking actions
- **401/403** → Check wallet configuration and permissions

## Quick Status Check

```bash
bash /root/.openclaw/workspace/kamigotchi-play/scripts/check-status.sh
```

## References

- `references/api.md` — Complete API reference with all endpoints
- `references/gameplay.md` — Game mechanics, strategies, tips
- `references/systems.md` — System IDs and contract architecture
