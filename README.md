<div align="center">

# ⚠️ XRGE Node is deprecated — use [`rougechain-node`](https://github.com/cyberdreadx/rougechain-node)

</div>

> **This repository is archived and no longer maintained.**
>
> A node built from this repo **cannot join the current network.** The daemon
> snapshot here predates two changes that are required to sync and follow mainnet:
>
> 1. **Genesis sync** — this repo requests `/blocks?limit=1000` with no
>    `from_height`, so past ~100 blocks a fresh node never receives block 0 and
>    never syncs.
> 2. **Block verification** — the proposer-authorization / block serialization
>    changed since this snapshot, so even a sync-patched build rejects current
>    blocks with `Invalid proposer signature on imported block`.
>
> Both are fixed in **[`rougechain-node`](https://github.com/cyberdreadx/rougechain-node)**,
> which is the canonical, maintained node. Please use it instead.

---

## Run a node (the maintained way)

**One command** — installs deps, prefers a prebuilt binary (no 10–30 min build),
sets up systemd, and prints the fund/stake steps:

```bash
curl -sSL https://raw.githubusercontent.com/cyberdreadx/rougechain-node/main/scripts/install-validator.sh | bash
```

Or build from source:

```bash
git clone https://github.com/cyberdreadx/rougechain-node.git
cd rougechain-node/core
cargo build --release -p quantum-vault-daemon
```

> **Mainnet needs `--genesis` explicitly.** Without it the daemon generates its
> own genesis and then correctly refuses to sync (`incompatible chain, refusing
> reset`). The installer passes it for you.

See the [`rougechain-node` README](https://github.com/cyberdreadx/rougechain-node)
and [validator guide](https://github.com/cyberdreadx/rougechain-node/blob/main/docs/staking/adding-a-validator.md)
for full instructions.

---

RougeChain is the first L1 built on NIST post-quantum cryptography
(ML-DSA-65 + ML-KEM-768). Explorer: <https://rougechain.io>. License: MIT.
