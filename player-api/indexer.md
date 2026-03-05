# Kamiden Indexer (gRPC)

Kamiden is Kamigotchi's off-chain **gRPC indexer** service. It indexes on-chain events into queryable endpoints and provides a real-time event stream. Use it to enumerate marketplace listings, query trade history, look up battles, and subscribe to live game events.

> **Why this matters:** Many on-chain data structures (e.g., marketplace listings, offers) use non-deterministic entity IDs and cannot be enumerated on-chain. Kamiden solves this by indexing all relevant events and exposing them via gRPC.

---

## Connection

Kamiden uses **Protobuf over gRPC-Web**. The official client connects via the `VITE_KAMIGAZE_URL` environment variable. There is no publicly documented default URL — you must obtain the endpoint from the Asphodel team or run your own indexer.

```javascript
import { createChannel, createClient } from "nice-grpc-web";

const KAMIDEN_URL = process.env.KAMIDEN_URL; // Obtain from Asphodel team
const channel = createChannel(KAMIDEN_URL);
// Use the KamidenServiceDefinition from the generated proto types
```

> **Transport:** The official client uses a custom gRPC transport (`grpcTransport.ts`). For Node.js bots, the `nice-grpc` package (non-web variant) works directly with standard gRPC transport.

---

## Marketplace Methods

These are the key methods for bot developers working with the KamiSwap marketplace.

### GetKamiMarketListings

Fetch active marketplace listings. The client polls this every ~10 seconds to keep the UI in sync.

```
rpc GetKamiMarketListings(KamiMarketListingsRequest) returns (KamiMarketListingsResponse)
```

**Request:**

| Field | Type | Description |
|-------|------|-------------|
| `Timestamp` | `uint64` (optional) | Filter listings after this unix timestamp |
| `Size` | `uint32` (optional) | Max results to return (client uses 500) |

**Response:** `KamiMarketListingsResponse.Listings` — array of `KamiMarketListing`:

| Field | Type | Description |
|-------|------|-------------|
| `OrderID` | `string` | The listing entity ID (use this for `system.kamimarket.buy`) |
| `SellerAccountID` | `string` | Seller's account entity ID |
| `KamiIndex` | `uint32` | Token index of the listed Kami |
| `Price` | `string` | Listing price in wei (ETH) |
| `Expiry` | `string` | Expiration unix timestamp (`"0"` = no expiry) |
| `Timestamp` | `uint64` | When the listing was created |
| `BuyerAccountID` | `string` | Populated after purchase; empty while active |

```javascript
// Example: fetch all active listings
const listings = await client.getKamiMarketListings({ Size: 500 });
for (const listing of listings.Listings) {
  console.log(
    `Kami #${listing.KamiIndex} listed for ${listing.Price} wei by ${listing.SellerAccountID}`
  );
}
```

### GetKamiMarketBids

Fetch active offers (specific and collection bids).

```
rpc GetKamiMarketBids(KamiMarketBidsRequest) returns (KamiMarketBidsResponse)
```

**Request:**

| Field | Type | Description |
|-------|------|-------------|
| `Timestamp` | `uint64` (optional) | Filter bids after this timestamp |
| `Size` | `uint32` (optional) | Max results |

**Response:** `KamiMarketBidsResponse.Bids` — array of `KamiMarketBid`:

| Field | Type | Description |
|-------|------|-------------|
| `OrderID` | `string` | The offer entity ID |
| `BuyerAccountID` | `string` | Buyer's account entity ID |
| `KamiIndex` | `uint32` | Target Kami index (0 for collection offers) |
| `Total` | `uint32` | Original quantity |
| `Price` | `string` | Offer price in wei (WETH) |
| `Expiry` | `string` | Expiration unix timestamp |
| `Timestamp` | `uint64` | When the offer was created |
| `BidType` | `enum` | `KAMI_MARKET_BID_TYPE_SPECIFIC` (2) or `KAMI_MARKET_BID_TYPE_ANY` (1) |
| `Quantity` | `uint32` | Remaining quantity |
| `BoughtKamiIndexes` | `uint32[]` | Kami indices already purchased by this bid |

### GetKamiMarketHistory

Fetch completed/cancelled marketplace orders for an account.

```
rpc GetKamiMarketHistory(KamiMarketHistoryRequest) returns (KamiMarketHistoryResponse)
```

**Request:**

| Field | Type | Description |
|-------|------|-------------|
| `AccountId` | `string` | Account entity ID to query history for |
| `Timestamp` | `uint64` (optional) | Filter after this timestamp |
| `Size` | `uint32` (optional) | Max results |

**Response:** `KamiMarketHistoryResponse.Orders` — array of `KamiMarketOrder`:

| Field | Type | Description |
|-------|------|-------------|
| `Timestamp` | `uint64` | Order timestamp |
| `OrderID` | `string` | Order entity ID |
| `IsCanceled` | `bool` | Whether the order was cancelled |
| `IsComplete` | `bool` | Whether the order was filled |
| `Listing` | `KamiMarketListing` (optional) | Listing details (if this was a listing) |
| `Bid` | `KamiMarketBid` (optional) | Bid details (if this was an offer) |

---

## Real-Time Event Stream

Subscribe to a persistent gRPC stream for real-time game events. The stream pushes `Feed` objects containing batched events.

```
rpc SubscribeToStream(StreamRequest) returns (stream StreamResponse)
```

**Request:**

| Field | Type | Description |
|-------|------|-------------|
| `topics` | `string[]` | Optional topic filter (empty = all events) |

**Marketplace events in the Feed:**

| Feed Field | Type | Description |
|------------|------|-------------|
| `KamiMarketLists` | `KamiMarketList[]` | New listings created |
| `KamiMarketBuys` | `KamiMarketBuy[]` | Listings purchased |
| `KamiMarketOffers` | `KamiMarketOffer[]` | New offers made |
| `KamiMarketAccepts` | `KamiMarketAccept[]` | Offers accepted |
| `KamiMarketCancels` | `KamiMarketCancel[]` | Orders cancelled |

The Feed also includes non-marketplace events: `Movements`, `HarvestEnds`, `Kills`, `Trades`, `KamiCasts`, `DroptableReveals`, `SacrificeReveals`.

```javascript
// Example: subscribe and react to marketplace events
const stream = client.subscribeToStream({ topics: [] });

for await (const response of stream) {
  if (!response.Feed) continue;

  for (const listing of response.Feed.KamiMarketLists) {
    console.log(`New listing: Kami #${listing.KamiIndex} for ${listing.Price} wei`);
  }
  for (const buy of response.Feed.KamiMarketBuys) {
    console.log(`Kami #${buy.KamiIndex} sold for ${buy.Price} wei`);
  }
  for (const offer of response.Feed.KamiMarketOffers) {
    console.log(`New offer on Kami #${offer.KamiIndex}: ${offer.Price} wei`);
  }
}
```

> **Reconnection:** The official client automatically reconnects after 5 seconds on stream error. Implement similar retry logic in your bot.

---

## Other Methods

Kamiden also indexes non-marketplace data:

| Method | Request | Response | Description |
|--------|---------|----------|-------------|
| `GetRoomMessages` | `RoomRequest` | `RoomResponse` | Chat messages for a room |
| `GetBattles` | `BattlesRequest` | `BattlesResponse` | PvP kill history |
| `GetBattleStats` | `BattleStatsRequest` | `BattleStatsResponse` | Kill/death/PNL stats for a Kami |
| `GetTradeHistory` | `TradesRequest` | `TradesResponse` | Item trade history |
| `GetOpenOffers` | `TradesRequest` | `TradesResponse` | Open item trade offers |
| `GetItemTransfers` | `ItemTransferRequest` | `ItemTransferResponse` | Item transfer history |
| `GetTokenWithdrawals` | `TokenPortalRequest` | `TokenPortalResponse` | ERC20 portal withdrawal history |
| `GetTokenDeposits` | `TokenPortalRequest` | `TokenPortalResponse` | ERC20 portal deposit history |
| `GetAuctionBuys` | `AuctionBuysRequest` | `AuctionBuysResponse` | Auction purchase history |
| `GetHarvestRanking` | `RankingRequest` | `LeaderboardResponse` | Harvest leaderboard |
| `GetKillerRanking` | `RankingRequest` | `LeaderboardResponse` | PvP kill leaderboard |
| Various leaderboards | `LeaderboardRequest` | `LeaderboardResponse` | Kills, deaths, musu, movements by account/kami |

---

## Related Pages

- [KamiSwap Marketplace](marketplace.md) — On-chain marketplace systems (list, buy, offer, cancel)
- [Entity Discovery](entity-discovery.md) — Deriving entity IDs referenced in indexer responses
- [Trading](trading.md) — Player-to-player item trades
