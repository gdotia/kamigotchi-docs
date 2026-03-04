# Kamigotchi API Reference

Base URL: `http://localhost:3008`

All write endpoints require `KAMI_PRIVATE_KEY` in `kami-api/.env`.
All request bodies use `Content-Type: application/json`.

---

## World

### GET /api/world/status

Check chain connection and world contract status.

**Parameters:** None

**Example:**
```bash
curl http://localhost:3008/api/world/status
```

**Response:**
```json
{
  "connected": true,
  "chainId": 428962654539583,
  "worldAddress": "0x2729174c265dbBd8416C6449E0E813E88f43D0E7",
  "blockNumber": 12345678
}
```

---

### GET /api/world/rooms

List all available rooms in the game world.

**Parameters:** None

**Example:**
```bash
curl http://localhost:3008/api/world/rooms
```

**Response:**
```json
[
  {
    "id": "room_001",
    "name": "Starting Meadow",
    "description": "A peaceful meadow",
    "harvestNodes": ["node_001", "node_002"],
    "npcs": ["npc_001"]
  }
]
```

---

## Kami

### GET /api/kami/:id

Get full Kami details — stats, level, XP, room, state, equipment, inventory.

**Parameters:**
| Param | In | Description |
|-------|----|-------------|
| `id` | path | Kami token ID |

**Example:**
```bash
curl http://localhost:3008/api/kami/42
```

**Response:**
```json
{
  "id": 42,
  "name": "Sparkle",
  "level": 5,
  "xp": 1250,
  "xpToNextLevel": 2000,
  "room": "room_001",
  "state": "idle",
  "stats": {
    "health": { "base": 10, "shift": 0, "boost": 2, "sync": 0, "effective": 12 },
    "power": { "base": 8, "shift": 1, "boost": 0, "sync": 0, "effective": 9 },
    "harmony": { "base": 6, "shift": 0, "boost": 1, "sync": 0, "effective": 7 },
    "violence": { "base": 4, "shift": 0, "boost": 0, "sync": 0, "effective": 4 }
  },
  "equipment": {},
  "inventory": []
}
```

---

### POST /api/kami/:id/stake

Stake a Kami NFT into the game world. Must be called before the Kami can perform any in-game actions.

**Parameters:**
| Param | In | Description |
|-------|----|-------------|
| `id` | path | Kami token ID |

**Example:**
```bash
curl -X POST http://localhost:3008/api/kami/42/stake
```

**Response:**
```json
{
  "success": true,
  "txHash": "0xabc123..."
}
```

---

### POST /api/kami/:id/unstake

Unstake a Kami from the game world back to wallet. Kami must be idle (not harvesting/questing).

**Parameters:**
| Param | In | Description |
|-------|----|-------------|
| `id` | path | Kami token ID |

**Example:**
```bash
curl -X POST http://localhost:3008/api/kami/42/unstake
```

**Response:**
```json
{
  "success": true,
  "txHash": "0xdef456..."
}
```

---

### POST /api/kami/:id/equip

Equip an item to a Kami. Item must be in inventory and compatible.

**Parameters:**
| Param | In | Description |
|-------|----|-------------|
| `id` | path | Kami token ID |
| `itemId` | body | Item ID to equip |

**Example:**
```bash
curl -X POST http://localhost:3008/api/kami/42/equip \
  -H 'Content-Type: application/json' \
  -d '{"itemId": "item_sword_01"}'
```

**Response:**
```json
{
  "success": true,
  "txHash": "0x..."
}
```

---

### POST /api/kami/:id/unequip

Unequip an item from a slot.

**Parameters:**
| Param | In | Description |
|-------|----|-------------|
| `id` | path | Kami token ID |
| `slot` | body | Equipment slot to clear |

**Example:**
```bash
curl -X POST http://localhost:3008/api/kami/42/unequip \
  -H 'Content-Type: application/json' \
  -d '{"slot": "weapon"}'
```

**Response:**
```json
{
  "success": true,
  "txHash": "0x..."
}
```

---

### POST /api/kami/:id/use-item

Use a consumable item on a Kami.

**Parameters:**
| Param | In | Description |
|-------|----|-------------|
| `id` | path | Kami token ID |
| `itemId` | body | Consumable item ID |

**Example:**
```bash
curl -X POST http://localhost:3008/api/kami/42/use-item \
  -H 'Content-Type: application/json' \
  -d '{"itemId": "item_potion_hp"}'
```

**Response:**
```json
{
  "success": true,
  "txHash": "0x..."
}
```

---

### POST /api/kami/:id/skill

Upgrade a Kami skill.

**Parameters:**
| Param | In | Description |
|-------|----|-------------|
| `id` | path | Kami token ID |
| `skillId` | body | Skill to upgrade |

**Example:**
```bash
curl -X POST http://localhost:3008/api/kami/42/skill \
  -H 'Content-Type: application/json' \
  -d '{"skillId": "mining"}'
```

**Response:**
```json
{
  "success": true,
  "txHash": "0x..."
}
```

---

### POST /api/kami/:id/scavenge

Scavenge the current room for random items.

**Parameters:**
| Param | In | Description |
|-------|----|-------------|
| `id` | path | Kami token ID |

**Example:**
```bash
curl -X POST http://localhost:3008/api/kami/42/scavenge
```

**Response:**
```json
{
  "success": true,
  "txHash": "0x..."
}
```

---

## Harvesting

### POST /api/kami/:id/harvest/start

Start harvesting at a resource node. Kami must be in the same room as the node.

**Parameters:**
| Param | In | Description |
|-------|----|-------------|
| `id` | path | Kami token ID |
| `nodeId` | body | Harvest node ID |
| `toolId` | body | Tool item ID to use (optional) |
| `duration` | body | Harvest duration in seconds (optional) |

**Example:**
```bash
curl -X POST http://localhost:3008/api/kami/42/harvest/start \
  -H 'Content-Type: application/json' \
  -d '{"nodeId": "node_001", "toolId": "item_pickaxe_01", "duration": 3600}'
```

**Response:**
```json
{
  "success": true,
  "txHash": "0x..."
}
```

---

### POST /api/kami/:id/harvest/collect

Collect accumulated harvest rewards from an active harvest.

**Parameters:**
| Param | In | Description |
|-------|----|-------------|
| `id` | path | Kami token ID |

**Example:**
```bash
curl -X POST http://localhost:3008/api/kami/42/harvest/collect
```

**Response:**
```json
{
  "success": true,
  "txHash": "0x...",
  "rewards": [
    { "itemId": "item_ore_iron", "amount": 5 }
  ]
}
```

---

## Account

### GET /api/account/:address

Get account information.

**Parameters:**
| Param | In | Description |
|-------|----|-------------|
| `address` | path | Wallet address (0x...) |

**Example:**
```bash
curl http://localhost:3008/api/account/0x1234...abcd
```

**Response:**
```json
{
  "address": "0x1234...abcd",
  "name": "PlayerOne",
  "registered": true,
  "room": "room_001",
  "onyxBalance": 500
}
```

---

### GET /api/account/:address/kamis

List all Kamis owned by an account.

**Parameters:**
| Param | In | Description |
|-------|----|-------------|
| `address` | path | Wallet address (0x...) |

**Example:**
```bash
curl http://localhost:3008/api/account/0x1234...abcd/kamis
```

**Response:**
```json
[
  {
    "id": 42,
    "name": "Sparkle",
    "level": 5,
    "state": "harvesting",
    "staked": true
  },
  {
    "id": 99,
    "name": "Shadow",
    "level": 3,
    "state": "idle",
    "staked": false
  }
]
```

---

### POST /api/account/register

Register a new account in the game world. Owner wallet required.

**Parameters:**
| Param | In | Description |
|-------|----|-------------|
| `name` | body | Display name for the account |

**Example:**
```bash
curl -X POST http://localhost:3008/api/account/register \
  -H 'Content-Type: application/json' \
  -d '{"name": "PlayerOne"}'
```

**Response:**
```json
{
  "success": true,
  "txHash": "0x..."
}
```

---

## Movement

### POST /api/move

Move the account (and active Kami) to a different room. Kami must be idle.

**Parameters:**
| Param | In | Description |
|-------|----|-------------|
| `roomId` | body | Target room ID |

**Example:**
```bash
curl -X POST http://localhost:3008/api/move \
  -H 'Content-Type: application/json' \
  -d '{"roomId": "room_002"}'
```

**Response:**
```json
{
  "success": true,
  "txHash": "0x..."
}
```

---

## Market

### POST /api/market/sell

Create a merchant listing to sell items.

**Parameters:**
| Param | In | Description |
|-------|----|-------------|
| `price` | body | Price in ONYX or game currency |
| `itemIds` | body | Array of item IDs to sell |
| `amounts` | body | Array of amounts for each item |

**Example:**
```bash
curl -X POST http://localhost:3008/api/market/sell \
  -H 'Content-Type: application/json' \
  -d '{"price": 100, "itemIds": ["item_ore_iron"], "amounts": [10]}'
```

**Response:**
```json
{
  "success": true,
  "txHash": "0x...",
  "listingId": "listing_001"
}
```

---

### POST /api/market/buy

Buy items from a merchant listing.

**Parameters:**
| Param | In | Description |
|-------|----|-------------|
| `listingId` | body | Listing ID to buy from |
| `itemIds` | body | Array of item IDs to buy |
| `amounts` | body | Array of amounts for each item |

**Example:**
```bash
curl -X POST http://localhost:3008/api/market/buy \
  -H 'Content-Type: application/json' \
  -d '{"listingId": "listing_001", "itemIds": ["item_ore_iron"], "amounts": [5]}'
```

**Response:**
```json
{
  "success": true,
  "txHash": "0x..."
}
```
