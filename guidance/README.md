> **Doc Class:** Agent Guidance
> **Canonical Source:** Derived from Core Resources in this repo and canonical sources listed in `resources/references/data-provenance.md`.
> **Freshness Rule:** Do not become source-of-truth for canonical values; link to Core pages for addresses, IDs, and tables.

# Agent Guidance

This section is optional implementation guidance and tooling for bot and agent developers.

## Recommended Reading Order

1. **[Agent Bootstrap](agent-bootstrap.md)** — Shortest path: fund on Base -> bridge -> register account -> acquire first Kami. Start here if you have a single owner key funded on Base.
2. **[Integration Guide](integration-guide.md)** — Complete low-level reference: wallet setup, account registration, Kami acquisition (4 methods), basic gameplay actions, and full example scripts.
3. **[Yominet Bridge Tooling](tools/yominet-bridge/README.md)** — Working Base -> Yominet bridge script with dry-run preview and address derivation. Used by Agent Bootstrap.

## Tools & Scripts

- **[Yominet Bridge](tools/yominet-bridge/README.md)** — Base -> Yominet bridge sender with dry-run and address preview modes.
- **[validate-docs.sh](tools/validate-docs.sh)** — Documentation quality validator: checks Doc Class metadata, relative link integrity, and Core boundary language.

## What's Next

Once you've completed the bootstrap and integration guide:

- [Player API Overview](../resources/player-api/overview.md) — System-by-system API documentation
- [Game Data Reference](../resources/references/game-data.md) — Items, skills, rooms, quests, and traits
- [Architecture Overview](../resources/architecture.md) — ECS patterns and entity ID derivation

## Scope Boundary

- Guidance can explain **how** to use Core Resources.
- Guidance cannot duplicate canonical tables, address lists, or ID registries.
- If canonical values are needed, link back to Core Resources.
