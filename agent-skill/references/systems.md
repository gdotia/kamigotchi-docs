# Kamigotchi Systems Reference

## Architecture

Kamigotchi uses the MUD Entity Component System (ECS) framework on Yominet.

- **Chain:** Yominet
- **Chain ID:** 428962654539583
- **RPC:** `https://jsonrpc-yominet-1.anvil.asia-southeast.initia.xyz`
- **World Contract:** `0x2729174c265dbBd8416C6449E0E813E88f43D0E7`
- **Kami721 (NFT):** `0x5d4376b62fa8ac16dfabe6a9861e11c33a48c677`
- **ONYX (ERC20):** `0x4BaDFb501Ab304fF11217C44702bb9E9732E7CF4`

All game actions are system calls to the World contract. The kami-api wraps these into REST endpoints.

## System IDs (56 total)

### Account (7)
| System ID | Description |
|-----------|-------------|
| `system.account.move` | Move account to a room |
| `system.account.register` | Register new account |
| `system.account.set.bio` | Set account bio |
| `system.account.set.name` | Set account display name |
| `system.account.set.operator` | Delegate operator wallet |
| `system.account.set.pfp` | Set profile picture |
| `system.account.use.item` | Use item at account level |

### Kami (11)
| System ID | Description |
|-----------|-------------|
| `system.kami.level` | Level up a Kami |
| `system.kami.name` | Set Kami name |
| `system.kami.equip` | Equip item to Kami |
| `system.kami.unequip` | Unequip item from Kami |
| `system.kami.use.item` | Use consumable on Kami |
| `system.kami.cast.item` | Cast item in combat |
| `system.kami.sacrifice.commit` | Commit to sacrifice ritual |
| `system.kami.sacrifice.reveal` | Reveal sacrifice result |
| `system.kami.onyx.rename` | Rename Kami (costs ONYX) |
| `system.kami.onyx.respec` | Respec Kami stats (costs ONYX) |
| `system.kami.onyx.revive` | Revive Kami (costs ONYX) |

### Gacha (4)
| System ID | Description |
|-----------|-------------|
| `system.kami.gacha.mint` | Mint new Kami from gacha |
| `system.kami.gacha.reroll` | Reroll gacha result |
| `system.kami.gacha.reveal` | Reveal gacha Kami stats |
| `system.buy.gacha.ticket` | Purchase gacha ticket |

### Portal (4)
| System ID | Description |
|-----------|-------------|
| `system.kami721.stake` | Stake Kami NFT into world |
| `system.kami721.unstake` | Unstake Kami NFT from world |
| `system.kami721.transfer` | Transfer Kami within world |
| `system.erc20.portal` | Deposit/withdraw ERC20 tokens |

### Harvesting (4)
| System ID | Description |
|-----------|-------------|
| `system.harvest.start` | Start harvesting at node |
| `system.harvest.stop` | Stop active harvest |
| `system.harvest.collect` | Collect harvest rewards |
| `system.harvest.liquidate` | Liquidate another player's harvest (PvP attack) |

### Skills (2)
| System ID | Description |
|-----------|-------------|
| `system.skill.upgrade` | Upgrade a skill |
| `system.skill.respec` | Respec skill points |

### Social (5)
| System ID | Description |
|-----------|-------------|
| `system.friend.request` | Send friend request |
| `system.friend.accept` | Accept friend request |
| `system.friend.cancel` | Cancel friend request |
| `system.friend.block` | Block a player |
| `system.chat` | Send chat message |

### Trading (4)
| System ID | Description |
|-----------|-------------|
| `system.trade.create` | Create trade offer |
| `system.trade.execute` | Execute/accept trade |
| `system.trade.complete` | Complete trade |
| `system.trade.cancel` | Cancel trade |

### Quests (2)
| System ID | Description |
|-----------|-------------|
| `system.quest.accept` | Accept quest from NPC |
| `system.quest.complete` | Complete and turn in quest |

### Merchants (2)
| System ID | Description |
|-----------|-------------|
| `system.listing.buy` | Buy from merchant listing |
| `system.listing.sell` | Sell to merchant listing |

### Crafting (1)
| System ID | Description |
|-----------|-------------|
| `system.craft` | Craft item from recipe |

### Items (3)
| System ID | Description |
|-----------|-------------|
| `system.item.burn` | Burn/destroy item |
| `system.item.transfer` | Transfer item to another player |
| `system.droptable.item.reveal` | Reveal pending droptable items |

### Goals (2)
| System ID | Description |
|-----------|-------------|
| `system.goal.contribute` | Contribute to community goal |
| `system.goal.claim` | Claim goal reward |

### Scavenge (1)
| System ID | Description |
|-----------|-------------|
| `system.scavenge.claim` | Claim accumulated scavenge points |

### Relationships (1)
| System ID | Description |
|-----------|-------------|
| `system.relationship.advance` | Advance NPC relationship |

### Auctions (1)
| System ID | Description |
|-----------|-------------|
| `system.auction.buy` | Buy from auction |

### Echo (2)
| System ID | Description |
|-----------|-------------|
| `system.echo.kamis` | Echo/broadcast Kami info |
| `system.echo.room` | Echo/broadcast room info |
