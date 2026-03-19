<div align="center">

# RougeChain Whitepaper

### A Post-Quantum Layer 1 Blockchain

**v1.0 — February 2026**

[![RougeChain](https://img.shields.io/badge/Network-RougeChain-ff0040)](https://rougechain.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

*"Survive the quantum era."*

</div>

---

## Abstract

RougeChain is a Layer 1 blockchain built from the ground up with NIST-approved post-quantum cryptography. While existing blockchains rely on elliptic curve cryptography (ECC) that will be broken by sufficiently powerful quantum computers, RougeChain uses **ML-DSA-65** (CRYSTALS-Dilithium) for digital signatures and **ML-KEM-768** for key encapsulation — both standardized by NIST in 2024 as part of FIPS 204 and FIPS 203.

The network features a Delegated Proof-of-Stake (DPoS) consensus mechanism with stake-weighted block proposer selection, an integrated Uniswap V2-style Automated Market Maker (AMM), native token creation, an encrypted quantum-safe messenger, and a deflationary burn mechanism. The core node daemon is implemented in Rust for performance and memory safety, with a React/TypeScript web interface for wallet management and DeFi operations.

**Native Token**: XRGE  
**Chain ID**: `rougechain-devnet-1`  
**Block Time**: ~1 second  
**Source**: [github.com/cyberdreadx/xrge-node](https://github.com/cyberdreadx/xrge-node)

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [The Quantum Threat](#2-the-quantum-threat)
3. [Cryptographic Foundation](#3-cryptographic-foundation)
4. [Network Architecture](#4-network-architecture)
5. [Consensus Mechanism](#5-consensus-mechanism)
6. [Transaction Model](#6-transaction-model)
7. [Tokenomics & Fee Structure](#7-tokenomics--fee-structure)
8. [Decentralized Exchange (AMM/DEX)](#8-decentralized-exchange-ammdex)
9. [Token Creation Platform](#9-token-creation-platform)
10. [Secure Messaging](#10-secure-messaging)
11. [Deflationary Burn Mechanism](#11-deflationary-burn-mechanism)
12. [Validator Economics](#12-validator-economics)
13. [Security Model](#13-security-model)
14. [Implementation](#14-implementation)
15. [Roadmap](#15-roadmap)
16. [References](#16-references)

---

## 1. Introduction

The emergence of quantum computing poses an existential threat to the cryptographic foundations of modern blockchains. Bitcoin, Ethereum, and virtually all existing Layer 1 networks rely on ECDSA or EdDSA signatures — both of which are vulnerable to Shor's algorithm running on a cryptographically-relevant quantum computer (CRQC).

RougeChain was designed to address this inevitability, not retroactively, but from genesis. Every transaction signature, every block proposal, and every key pair in the system uses post-quantum cryptographic primitives that resist both classical and quantum attacks.

Beyond quantum resistance, RougeChain provides a complete DeFi ecosystem:

- **Stake-weighted consensus** with validator rewards and slashing
- **Constant product AMM** with multi-hop swap routing
- **Permissionless token creation** with on-chain metadata
- **Quantum-encrypted messaging** between wallets
- **Client-side transaction signing** — private keys never leave the user's device

---

## 2. The Quantum Threat

### 2.1 Current Vulnerability

Classical blockchains depend on the hardness of the Elliptic Curve Discrete Logarithm Problem (ECDLP). A 256-bit ECDSA key requires approximately 2¹²⁸ operations to break classically — infeasible with today's hardware.

However, Shor's algorithm (1994) solves the ECDLP in polynomial time on a quantum computer. A sufficiently powerful quantum machine could:

1. **Derive private keys from public keys** — exposing all funds in reused-address wallets
2. **Forge transaction signatures** — enabling arbitrary asset theft
3. **Impersonate validators** — compromising network consensus

### 2.2 Timeline

While current quantum computers lack the qubit count and coherence times for a CRQC, progress is accelerating. NIST initiated its Post-Quantum Cryptography (PQC) standardization project in 2016 and finalized its first standards in 2024, signaling that the threat horizon is measured in years, not decades.

### 2.3 The Migration Problem

Migrating an existing blockchain to post-quantum cryptography is extraordinarily difficult:

- Key sizes increase by 10–50×, inflating block sizes and storage
- Signature sizes grow correspondingly, increasing bandwidth requirements
- All existing wallets must re-register with new key types
- Smart contract ecosystems require comprehensive audits

RougeChain avoids these challenges entirely by being quantum-safe from its first block.

---

## 3. Cryptographic Foundation

### 3.1 Digital Signatures: ML-DSA-65

RougeChain uses **ML-DSA-65** (Module-Lattice Digital Signature Algorithm, FIPS 204) — the standardized version of CRYSTALS-Dilithium — for all transaction and block signatures.

| Parameter | Value |
|-----------|-------|
| **Algorithm** | ML-DSA-65 (CRYSTALS-Dilithium) |
| **NIST Standard** | FIPS 204 (2024) |
| **Security Level** | NIST Level 3 (~128-bit post-quantum) |
| **Public Key Size** | 1,952 bytes |
| **Secret Key Size** | 4,032 bytes |
| **Signature Size** | 3,309 bytes |
| **Hardness Assumption** | Module Learning With Errors (MLWE) |

ML-DSA-65 provides strong unforgeability under chosen-message attacks (EUF-CMA) and is resistant to both classical and quantum adversaries. The scheme operates over structured lattices in the module setting, which provides a balance between security, key size, and computational efficiency.

### 3.2 Hash Function: SHA-256

All block hashing, transaction hashing, and Merkle root computation uses **SHA-256**. While SHA-256 is not a post-quantum signature scheme, it benefits from Grover's algorithm reducing its effective security to 128 bits — still well above any feasible attack threshold.

### 3.3 Key Encapsulation: ML-KEM-768

For the encrypted messaging subsystem, RougeChain employs **ML-KEM-768** (FIPS 203) — the standardized version of CRYSTALS-Kyber — for quantum-safe key exchange and session establishment.

### 3.4 Implementation

The cryptographic layer is implemented in a dedicated Rust crate (`quantum-vault-crypto`) using the `fips204` library, which provides a pure-Rust, auditable implementation of the FIPS 204 standard. Key generation uses `rand::thread_rng()` for cryptographically secure randomness.

```rust
// Key sizes as implemented
const SK_LEN: usize = 4032;  // Secret key: 4,032 bytes
const PK_LEN: usize = 1952;  // Public key: 1,952 bytes
const SIG_LEN: usize = 3309; // Signature: 3,309 bytes
```

---

## 4. Network Architecture

### 4.1 Node Structure

Each RougeChain node is a self-contained Rust binary (`quantum-vault-daemon`) that operates independently while maintaining connectivity with the peer network.

```
┌──────────────────────────────────────────────────────┐
│                   RougeChain Node                    │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌───────────────────┐  │
│  │  Crypto   │  │Consensus │  │   Storage Layer   │  │
│  │ ML-DSA-65 │  │  DPoS    │  │ Chain (JSONL)     │  │
│  │ SHA-256   │  │ Proposer │  │ Validators (Sled) │  │
│  └──────────┘  │ Selection│  │ Pools (Sled)      │  │
│                └──────────┘  │ Messenger (Sled)   │  │
│  ┌──────────┐  ┌──────────┐  └───────────────────┘  │
│  │  AMM/DEX │  │   P2P    │                          │
│  │ Pools    │  │ Sync     │  ┌───────────────────┐  │
│  │ Routing  │  │ Gossip   │  │    HTTP API (:5100)│  │
│  │ Swaps    │  │ Discover │  │    gRPC P2P (:4100)│  │
│  └──────────┘  └──────────┘  └───────────────────┘  │
└──────────────────────────────────────────────────────┘
```

### 4.2 Crate Architecture

The node is organized as a Rust workspace with six specialized crates:

| Crate | Purpose |
|-------|---------|
| `daemon` | Node binary, HTTP/gRPC servers, block production, AMM execution |
| `types` | Shared data structures: `BlockV1`, `TxV1`, `VoteMessage`, `SlashPayload` |
| `crypto` | ML-DSA-65 signing/verification, SHA-256 hashing, key generation |
| `consensus` | Stake-weighted proposer selection with entropy seeding |
| `storage` | Chain persistence (JSONL), validator/pool/messenger state (Sled DB) |
| `p2p` | Peer discovery, TCP message protocol, gossip scaffolding |

### 4.3 Peer-to-Peer Network

Nodes communicate via two channels:

1. **HTTP API (port 5100)** — Block sync, transaction broadcast, peer discovery, and all client-facing operations
2. **gRPC (port 4100)** — Structured P2P messaging for block proposals, votes, and chain synchronization

Peer discovery is automatic: each node registers with known peers via `POST /api/peers/register` and periodically queries `GET /api/peers` to discover new participants. Peers broadcast new blocks and transactions to all connected nodes.

---

## 5. Consensus Mechanism

### 5.1 Delegated Proof-of-Stake (DPoS)

RougeChain uses a Delegated Proof-of-Stake model where block proposers are selected probabilistically based on their staked XRGE weight.

### 5.2 Proposer Selection

Block proposers are selected using a verifiable random function seeded by three inputs:

1. **Entropy** — Locally generated cryptographic randomness (32 bytes)
2. **Previous block hash** — Ensures chain-dependent randomness
3. **Block height** — Prevents replay of selection outcomes

```
seed = SHA-256(entropy ‖ prev_hash ‖ height)
selection_weight = u128(seed[0..16]) mod total_stake
proposer = first validator where cumulative_stake > selection_weight
```

Validators are iterated in deterministic order (`BTreeMap`), and the first validator whose cumulative stake exceeds the selection weight is chosen as the block proposer. This ensures that the probability of being selected is directly proportional to stake.

### 5.3 Block Production

Mining nodes produce blocks at a configurable interval (default: 1 second):

1. Collect pending transactions from the mempool (max 2,000)
2. Construct a `BlockHeaderV1` with chain metadata and Merkle root
3. Sign the block header with the proposer's ML-DSA-65 private key
4. Compute the block hash: `SHA-256(header_bytes ‖ proposer_signature)`
5. Append the block to the chain and broadcast to peers

### 5.4 Finality

RougeChain implements a vote-based finality model:

- Validators submit **prevote** and **precommit** messages for each height
- A block is finalized when votes representing **≥ 2/3 of total stake** are collected
- Quorum threshold: `(total_stake × 2 ÷ 3) + 1`

### 5.5 Validator Lifecycle

| Action | Effect |
|--------|--------|
| **Stake** | Lock XRGE to become an active validator |
| **Unstake** | Unlock XRGE and exit the validator set |
| **Slash** | Penalty for misbehavior: lose `stake / 10` (10%) |
| **Jail** | After slashing, validator is jailed for 20 blocks |

Validator state is tracked on-chain with four fields: `stake`, `slash_count`, `jailed_until`, and `entropy_contributions`.

---

## 6. Transaction Model

### 6.1 Transaction Structure

Every transaction in RougeChain is a versioned, typed structure:

```
TxV1 {
    version:      u32       // Protocol version (1)
    tx_type:      String    // "transfer", "stake", "create_token", "swap", ...
    from_pub_key: String    // Sender's ML-DSA-65 public key (hex)
    nonce:        u64       // Timestamp-based for replay protection
    payload:      TxPayload // Type-specific fields
    fee:          f64       // Transaction fee in XRGE
    sig:          String    // ML-DSA-65 signature (hex)
}
```

### 6.2 Transaction Types

| Type | Description | Fee (XRGE) |
|------|-------------|------------|
| `transfer` | Send XRGE or tokens to another address | 0.1 |
| `stake` | Lock XRGE as validator collateral | 0.1 |
| `unstake` | Unlock staked XRGE | 0.1 |
| `create_token` | Launch a new token on-chain | 100 |
| `create_pool` | Create an AMM liquidity pool | 10 |
| `add_liquidity` | Deposit tokens into a pool | 0.1 |
| `remove_liquidity` | Withdraw tokens from a pool | 0.1 |
| `swap` | Exchange tokens via the AMM | 0.1 |
| `slash` | Penalize a misbehaving validator | 0.1 |
| `update_token_metadata` | Update token image/description/socials | 0.1 |

### 6.3 Secure v2 API (Client-Side Signing)

RougeChain's v2 API guarantees that **private keys never leave the client**. The signing flow:

1. Client constructs a typed payload with `timestamp` and `nonce`
2. Client signs the serialized payload with their ML-DSA-65 private key
3. Client submits the `{payload, signature, public_key}` bundle to the node
4. Node verifies the signature and processes the transaction

Timestamp validation enforces a **5-minute window** to prevent replay attacks while tolerating clock skew.

---

## 7. Tokenomics & Fee Structure

### 7.1 Native Token: XRGE

XRGE is the native gas token of RougeChain. It is required for:

- Paying transaction fees
- Staking as validator collateral
- Creating tokens and liquidity pools
- Pairing against custom tokens in the AMM

### 7.2 Fee Distribution

All transaction fees are distributed to network participants in each block:

| Recipient | Share | Rationale |
|-----------|-------|-----------|
| **Block Proposer** | 25% | Incentivize block production and infrastructure costs |
| **Validator Set** | 75% | Distributed pro-rata by stake weight among all active validators |

This model ensures that all stakers earn passive income proportional to their stake, while block proposers receive a premium for the computational work of assembling and signing blocks.

### 7.3 Fee Schedule

| Operation | Fee |
|-----------|-----|
| Transfer (XRGE or token) | 0.1 XRGE |
| Stake / Unstake | 0.1 XRGE |
| Swap | 0.1 XRGE (+ 0.3% AMM fee) |
| Add / Remove Liquidity | 0.1 XRGE |
| Token Creation | 100 XRGE |
| Pool Creation | 10 XRGE |
| Token Metadata Update | 0.1 XRGE |

### 7.4 Faucet

A testnet faucet allows new users to request XRGE for experimentation. Faucet transactions are issued by the node's own key pair with zero fee.

---

## 8. Decentralized Exchange (AMM/DEX)

### 8.1 Constant Product Market Maker

RougeChain includes a native AMM implementing the **constant product formula**:

$$x \cdot y = k$$

Where `x` and `y` are the reserves of two tokens in a liquidity pool, and `k` is the invariant that must be maintained (or increased) after every trade.

### 8.2 Swap Mechanics

The output amount for a swap is calculated with a **0.3% fee**:

$$\text{amount\_out} = \frac{\text{amount\_in} \times 997 \times \text{reserve\_out}}{\text{reserve\_in} \times 1000 + \text{amount\_in} \times 997}$$

This is equivalent to the Uniswap V2 formula with `FEE_NUMERATOR = 997` and `FEE_DENOMINATOR = 1000`.

### 8.3 Multi-Hop Routing

When no direct pool exists between two tokens, the AMM uses **BFS-based pathfinding** to discover multi-hop routes (up to 3 hops). This enables trading between any pair of tokens connected through intermediate pools.

```
Example: TOKEN_A → XRGE → TOKEN_B (2-hop route)
```

The router calculates the optimal path and returns:
- Output amount after all hops and fees
- Price impact percentage
- Complete path with pool IDs

### 8.4 Liquidity Provision

Liquidity providers deposit token pairs into pools and receive **LP tokens** in return:

- **First provider**: LP tokens = `√(amount_a × amount_b) - MINIMUM_LIQUIDITY` (1,000 tokens burned for minimum liquidity)
- **Subsequent providers**: LP tokens proportional to the smaller ratio of deposits to reserves

LP tokens can be redeemed to withdraw a proportional share of pool reserves at any time.

### 8.5 Price Impact Protection

Every swap quote includes a **price impact** calculation that measures the deviation from the instantaneous price caused by the trade:

$$\text{price\_impact} = 1 - \frac{\text{amount\_out} \times \text{reserve\_in}}{\text{amount\_in} \times \text{reserve\_out}}$$

Clients can set a `min_amount_out` parameter for slippage protection. If the actual output falls below this threshold, the swap is rejected.

---

## 9. Token Creation Platform

### 9.1 Permissionless Token Launch

Any user can launch a custom token on RougeChain by submitting a `create_token` transaction with:

- Token name, symbol, and decimal precision
- Total supply (entirely allocated to the creator's address)
- 100 XRGE creation fee

### 9.2 Token Metadata

Token creators can enrich their tokens with on-chain metadata:

| Field | Description |
|-------|-------------|
| `image` | Token logo (IPFS, HTTP, or data URI) |
| `description` | Token description |
| `website` | Project website URL |
| `twitter` | X (formerly Twitter) handle |
| `discord` | Discord server invite |

Only the original token creator can update metadata, verified by scanning the blockchain for the original `create_token` transaction.

---

## 10. Secure Messaging

RougeChain includes a built-in **end-to-end encrypted messaging system**:

- Messages are encrypted using **ML-KEM-768** key encapsulation
- Conversations are wallet-to-wallet, identified by public keys
- Message history is persisted per-node in Sled database
- Messages are deduplicated to prevent replay

This provides quantum-safe private communication between any two RougeChain addresses without requiring an external messaging service.

---

## 11. Deflationary Burn Mechanism

### 11.1 Burn Address

RougeChain defines a permanent, deterministic burn address:

```
XRGE_BURN_0x000000000000000000000000000000000000000000000000000000000000DEAD
```

This address has no corresponding private key — tokens sent to it are **permanently and irreversibly destroyed**.

### 11.2 Burn Tracking

The chain tracks burned amounts per token symbol in real-time. Users and applications can query:

- `GET /api/burn-address` — The official burn address
- `GET /api/burned` — Total burned amounts for all tokens

Any token (XRGE or custom) can be burned by sending it to the burn address via a standard transfer. Burns are tracked separately from normal transfers and excluded from circulating supply calculations.

---

## 12. Validator Economics

### 12.1 Staking

Users stake XRGE to become validators and participate in consensus. Staking locks tokens in the validator's account and adds them to the stake-weighted proposer selection pool.

### 12.2 Rewards

Validators earn rewards from two sources:

1. **Fee share**: 75% of all transaction fees are distributed to validators proportional to their stake
2. **Proposer bonus**: When selected as block proposer, the validator receives an additional 25% of block fees

### 12.3 Slashing

Validators can be slashed for misbehavior:

- **Penalty**: 10% of staked tokens (`stake / 10`)
- **Jailing**: The validator is temporarily jailed for 20 blocks
- **Tracking**: Slash count is permanently recorded on-chain

### 12.4 Rate Limiting Tiers

The API implements three-tier rate limiting:

| Tier | Identity | Rate Limit |
|------|----------|------------|
| 1 (Highest) | Active staked validators | Highest (via `X-Validator-Key` header) |
| 2 (Medium) | Registered peers | Medium |
| 3 (Default) | Unknown clients | Standard read/write limits |

---

## 13. Security Model

### 13.1 Quantum Resistance

All signature operations use ML-DSA-65 at NIST Security Level 3, providing ≥128 bits of post-quantum security. Hash operations use SHA-256, providing 128 bits of security against quantum adversaries (via Grover's algorithm).

### 13.2 Client-Side Signing

The v2 API ensures that private keys exist only on the user's device. The node never receives, stores, or processes private key material.

### 13.3 Replay Protection

Transactions include:
- **Timestamp**: Must be within 5 minutes of server time
- **Nonce**: Unique per transaction, used for mempool deduplication

### 13.4 API Security

- Optional API key authentication (`X-API-Key` or `Bearer` token)
- Tiered rate limiting based on caller identity
- CORS headers for browser-based wallet access

---

## 14. Implementation

### 14.1 Technology Stack

| Layer | Technology |
|-------|-----------|
| **Core Node** | Rust (axum HTTP, tonic gRPC) |
| **Storage** | JSONL (chain data), Sled (validators, pools, messenger) |
| **Cryptography** | `fips204` (ML-DSA-65), `sha2` (SHA-256), `@noble/post-quantum` (client-side) |
| **Frontend** | React, TypeScript, Vite, Tailwind CSS, shadcn-ui |
| **Deployment** | systemd, Nginx, Let's Encrypt SSL |

### 14.2 Client Library

The browser-based wallet uses `@noble/post-quantum` for client-side ML-DSA-65 signing and ML-KEM-768 key encapsulation, ensuring that post-quantum operations run natively in the user's browser without server-side dependencies.

### 14.3 Node Requirements

| Specification | Minimum |
|---------------|---------|
| **OS** | Ubuntu 22.04+ (or Debian-based) |
| **RAM** | 2 GB (or add swap) |
| **Storage** | 10 GB |
| **Ports** | 4100 (P2P), 5100 (API) |
| **Build** | Rust toolchain |

---

## 15. Roadmap

| Phase | Milestone | Status |
|-------|-----------|--------|
| **Phase 1** | Core L1 with ML-DSA-65, DPoS consensus, and block production | ✅ Complete |
| **Phase 2** | Web wallet with client-side signing | ✅ Complete |
| **Phase 3** | AMM/DEX with multi-hop routing | ✅ Complete |
| **Phase 4** | Token creation platform and metadata | ✅ Complete |
| **Phase 5** | Encrypted messaging (ML-KEM-768) | ✅ Complete |
| **Phase 6** | Deflationary burn mechanism | ✅ Complete |
| **Phase 7** | Multi-node testnet with peer discovery | ✅ Complete |
| **Phase 8** | WebSocket real-time block/tx feeds | ✅ Complete |
| **Phase 9** | Validator slashing and jailing | ✅ Complete |
| **Phase 10** | Public node operator program | 🔄 In Progress |
| **Phase 11** | Smart contract runtime (WASM) | 📋 Planned |
| **Phase 12** | Cross-chain bridge (IBC-style) | 📋 Planned |
| **Phase 13** | Mobile wallet (React Native) | 📋 Planned |
| **Phase 14** | Mainnet launch | 📋 Planned |

---

## 16. References

1. **FIPS 204** — Module-Lattice-Based Digital Signature Standard (ML-DSA), NIST, 2024. https://csrc.nist.gov/pubs/fips/204/final
2. **FIPS 203** — Module-Lattice-Based Key-Encapsulation Mechanism Standard (ML-KEM), NIST, 2024. https://csrc.nist.gov/pubs/fips/203/final
3. **CRYSTALS-Dilithium** — Ducas, L., et al. "CRYSTALS-Dilithium: A Lattice-Based Digital Signature Scheme." IACR ePrint Archive, 2017.
4. **CRYSTALS-Kyber** — Bos, J., et al. "CRYSTALS-Kyber: A CCA-Secure Module-Lattice-Based KEM." IEEE Euro S&P, 2018.
5. **Uniswap V2** — Adams, H., et al. "Uniswap v2 Core." Uniswap Protocol, 2020. https://uniswap.org/whitepaper.pdf
6. **Shor's Algorithm** — Shor, P. "Polynomial-Time Algorithms for Prime Factorization and Discrete Logarithms on a Quantum Computer." SIAM J. Computing, 1997.
7. **Grover's Algorithm** — Grover, L. "A Fast Quantum Mechanical Algorithm for Database Search." STOC, 1996.

---

<div align="center">

**RougeChain** — Quantum-safe by design, not by patch.

[Website](https://rougechain.io) · [GitHub](https://github.com/cyberdreadx/xrge-node) · [API Docs](API.md)

*MIT License — © 2026 CyberDreadX*

</div>
