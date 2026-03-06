> **Doc Class:** Core Resource
> **Canonical Source:** This repository's documentation contract and navigation, plus canonical protocol data in Core Resources.
> **Freshness Rule:** Keep section boundaries and links current; when canonical values change, update Core pages and `resources/references/data-provenance.md`.

# Kamigotchi Technical Documentation

Kamigotchi is a fully on-chain game built on the MUD/solecs ECS framework, deployed on Yominet (Initia L2 rollup). This documentation covers the complete protocol reference and implementation guide for players, bot developers, and contract integrators.

Kamigotchi docs are organized into two explicit sections:

1. **Core Resources**: canonical protocol/game reference.
2. **Agent Guidance**: optional implementation workflows and tooling.

## Documentation Contract

- **Core Resources** contain source-of-truth material: addresses, IDs, ABIs, API behavior, mechanics, and source pointers.
- **Agent Guidance** contains optional setup flows, bot loops, examples, and helper tooling.
- Guidance can reference Core, but must not duplicate canonical tables, addresses, or IDs.

## Start Here

- **Playing in the browser?** [Player Quick Start](resources/player-quick-start.md)
- **Building a bot or agent?** [Agent Bootstrap](guidance/agent-bootstrap.md)
- **Integrating with contracts?** [Architecture Overview](resources/architecture.md) then [System IDs & ABIs](resources/contracts/ids-and-abis.md)
- **Full reference map:** [Core Resources](resources/README.md) | [Agent Guidance](guidance/README.md)

## Global References

- [Data Provenance & Freshness](resources/references/data-provenance.md)
- [Contributing Guide](CONTRIBUTING.md)

## Quick Links

| Resource | URL |
|----------|-----|
| Game | [kamigotchi.io](https://kamigotchi.io) |
| Block Explorer | [scan.initia.xyz/yominet-1](https://scan.initia.xyz/yominet-1) |
| World Contract | [`0x2729174c265dbBd8416C6449E0E813E88f43D0E7`](https://scan.initia.xyz/yominet-1/address/0x2729174c265dbBd8416C6449E0E813E88f43D0E7) |
