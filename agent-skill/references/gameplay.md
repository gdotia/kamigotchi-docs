# Kamigotchi Gameplay Mechanics

## Kami Stats

Every Kami has four core stats, each composed of four modifiers:

| Stat | Description |
|------|-------------|
| **Health** | Durability, survival capacity |
| **Power** | Strength, harvesting efficiency |
| **Harmony** | Social skills, crafting quality |
| **Violence** | Combat ability, PvP strength |

Each stat has:
- **base** — Innate value from minting/genetics
- **shift** — Permanent changes from leveling or respec
- **boost** — Temporary buffs from items or effects
- **sync** — Bonuses from room/environment synergy
- **effective** = base + shift + boost + sync

## Rooms and Movement

- The game world is divided into rooms
- Each room contains harvest nodes, NPCs, merchants, and/or quest givers
- Move between rooms with `POST /api/move { roomId }`
- Kami must be idle (not harvesting or in combat) to move
- Some rooms may have level or stat requirements
- List all rooms: `GET /api/world/rooms`

## Harvesting

The primary resource-gathering mechanic:

1. Move Kami to a room with harvest nodes
2. Start harvesting: `POST /api/kami/{id}/harvest/start { nodeId, toolId, duration }`
3. Resources accumulate over time
4. Collect rewards: `POST /api/kami/{id}/harvest/collect`
5. Kami cannot perform other actions while harvesting

**Tips:**
- Use appropriate tools to boost harvest speed/quality
- Higher Power stat = better harvest yields
- Collect regularly — some nodes have max capacity
- Match tool type to node type for bonuses

## Scavenging

- Quick one-time action to find random items in current room
- `POST /api/kami/{id}/scavenge`
- Lower rewards than sustained harvesting but instant
- Good for new players or between harvest cycles

## Crafting

Combine items using recipes:

- Recipes require specific items in specific amounts
- Higher Harmony stat = better craft quality/chance
- Crafted items can be equipment, consumables, or trade goods
- Uses `system.craft` system call

## Quests

NPCs offer quests with requirements and rewards:

1. Find quest-giving NPC in a room
2. Accept quest: `system.quest.accept`
3. Complete objectives (gather items, visit locations, etc.)
4. Turn in quest: `system.quest.complete`
5. Receive rewards (XP, items, ONYX)

## Trading

Player-to-player trade system:

1. **Create trade:** `system.trade.create` — Propose a trade offer
2. **Execute trade:** `system.trade.execute` — Other player accepts
3. **Complete trade:** `system.trade.complete` — Finalize transfer
4. **Cancel trade:** `system.trade.cancel` — Cancel open trade

## Merchant Listings

Buy and sell from NPC merchants:

- **Sell items:** `POST /api/market/sell { price, itemIds, amounts }`
- **Buy items:** `POST /api/market/buy { listingId, itemIds, amounts }`
- Prices set by players (for player listings) or fixed (for NPC merchants)
- Check merchant inventory before buying

## Skills

Upgrade Kami abilities:

- Each Kami can learn and upgrade skills
- Skills improve specific activities (harvesting, crafting, combat)
- Upgrade: `POST /api/kami/{id}/skill { skillId }`
- Respec available via ONYX: `system.skill.respec`

## Leveling

- Kamis gain XP from harvesting, quests, and combat
- Level up: `system.kami.level`
- Each level grants stat points and unlocks new abilities
- Check XP progress: `GET /api/kami/{id}` → `xp` / `xpToNextLevel`

## Equipment

- Kamis have equipment slots (weapon, armor, accessory, tool, etc.)
- Equip: `POST /api/kami/{id}/equip { itemId }`
- Unequip: `POST /api/kami/{id}/unequip { slot }`
- Equipment provides stat boosts and special abilities
- Better gear = better performance in all activities

## ONYX (Premium Currency)

In-game currency for premium actions:

| Action | Cost |
|--------|------|
| Rename Kami | ONYX |
| Revive Kami | ONYX |
| Respec stats | ONYX |
| Gacha tickets | ONYX |

- Earned through gameplay, quests, and trading
- Contract: `0x4BaDFb501Ab304fF11217C44702bb9E9732E7CF4`

## Portal

Move assets between wallet and game world:

- **Stake Kami:** Transfer Kami NFT from wallet into game (`POST /api/kami/{id}/stake`)
- **Unstake Kami:** Transfer Kami NFT from game back to wallet (`POST /api/kami/{id}/unstake`)
- **ERC20 Portal:** Deposit/withdraw fungible tokens (`system.erc20.portal`)
- Kami721 contract: `0x5d4376b62fa8ac16dfabe6a9861e11c33a48c677`

## Gacha System

Mint new Kamis through the gacha:

1. Buy gacha ticket (`system.buy.gacha.ticket`)
2. Mint Kami (`system.kami.gacha.mint`)
3. Reveal stats (`system.kami.gacha.reveal`)
4. Optionally reroll stats (`system.kami.gacha.reroll`)

## Social

- **Friends:** Request, accept, cancel, block (`system.friend.*`)
- **Chat:** In-game messaging (`system.chat`)
- **Relationships:** Advance Kami-to-Kami relationships (`system.relationship.advance`)

## Strategy Tips

### Early Game
1. Register account and stake your first Kami
2. Start harvesting immediately — resources are essential
3. Complete beginner quests for easy XP and items
4. Equip any gear you find — even basic gear helps

### Mid Game
1. Focus on leveling one Kami to unlock better areas
2. Upgrade harvesting skills for better yields
3. Start trading surplus resources for profit
4. Craft intermediate equipment

### Late Game
1. Optimize harvest routes for maximum efficiency
2. Complete high-level quests for rare rewards
3. Trade strategically on the market
4. Specialize Kamis for different roles (harvester, crafter, trader)
