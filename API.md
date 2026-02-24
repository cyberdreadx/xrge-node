# XRGE Node API Reference

Base URL: `http://YOUR_SERVER:5100/api` or `https://YOUR_DOMAIN/api`

## Authentication

When API keys are enabled, send one of:
- `X-API-Key: YOUR_KEY`
- `Authorization: Bearer YOUR_KEY`

`/api/health` is always public.

---

## Core Endpoints

### Health Check
`GET /api/health`
```json
{ "status": "ok", "chain_id": "rougechain-devnet-1", "height": 42 }
```

### Node Stats
`GET /api/stats`
```json
{
  "connected_peers": 2,
  "network_height": 42,
  "is_mining": true,
  "node_id": "uuid",
  "total_fees_collected": 50.5,
  "fees_in_last_block": 0.1,
  "chain_id": "rougechain-devnet-1",
  "finalized_height": 40
}
```

### Connected Peers
`GET /api/peers`
```json
{ "peers": ["https://testnet.rougechain.io", "https://xrge-node.gltch.app"], "count": 2 }
```

---

## Wallet & Balances

### Create Wallet
`POST /api/wallet/create`
```json
{ "success": true, "publicKey": "a1b2...", "privateKey": "e5f6...", "algorithm": "ML-DSA-65" }
```
> ⚠️ In production, generate keys client-side.

### Get Balance
`GET /api/balance/{publicKey}`
```json
{ "success": true, "balance": 1000.5 }
```

---

## Blocks & Transactions

### Get Blocks
`GET /api/blocks`

### Get Transactions
`GET /api/txs?limit=200&offset=0`

### Submit Transaction
`POST /api/tx/submit`
```json
{
  "fromPrivateKey": "...",
  "fromPublicKey": "...",
  "toPublicKey": "...",
  "amount": 100,
  "fee": 0.1
}
```

---

## Secure v2 API (Client-Side Signing)

All v2 endpoints accept pre-signed transactions — **private keys never leave your browser**.

### Payload Format
```json
{
  "payload": {
    "type": "transfer",
    "from": "sender-pubkey",
    "to": "recipient-pubkey",
    "amount": 100,
    "fee": 1,
    "token": "XRGE",
    "timestamp": 1234567890123,
    "nonce": "random-hex"
  },
  "signature": "ml-dsa-65-signature-hex",
  "public_key": "sender-pubkey"
}
```

| Endpoint | Type | Description |
|----------|------|-------------|
| `POST /api/v2/transfer` | `transfer` | Send tokens |
| `POST /api/v2/token/create` | `create_token` | Launch a token |
| `POST /api/v2/swap/execute` | `swap` | Swap tokens |
| `POST /api/v2/pool/create` | `create_pool` | Create LP pool |
| `POST /api/v2/pool/add-liquidity` | `add_liquidity` | Add LP |
| `POST /api/v2/pool/remove-liquidity` | `remove_liquidity` | Remove LP |
| `POST /api/v2/stake` | `stake` | Stake XRGE |
| `POST /api/v2/unstake` | `unstake` | Unstake XRGE |
| `POST /api/v2/faucet` | `faucet` | Request testnet tokens |

---

## AMM / DEX

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/pools` | GET | List all pools |
| `/api/pool/{pool_id}` | GET | Pool details |
| `/api/pool/{pool_id}/prices` | GET | Price history |
| `/api/pool/{pool_id}/events` | GET | Pool events |
| `/api/pool/{pool_id}/stats` | GET | Pool analytics |
| `/api/swap/quote` | POST | Get swap quote |

### Swap Quote
`POST /api/swap/quote`
```json
{ "token_in": "XRGE", "token_out": "QSHIB", "amount_in": 100 }
```
Response:
```json
{ "success": true, "amount_out": 495, "price_impact": 0.5, "path": ["XRGE", "QSHIB"], "pools": ["XRGE-QSHIB"] }
```

---

## Validators & Consensus

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/validators` | GET | Validator set |
| `/api/validators/stats` | GET | Vote participation |
| `/api/selection` | GET | Current proposer |
| `/api/finality` | GET | Finality status |
| `/api/votes?height=N` | GET | Vote quorum |

---

## Token Burning

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/burn-address` | GET | Official burn address |
| `/api/burned` | GET | Total burned per token |

---

## Error Format

```json
{ "success": false, "error": "Error message" }
```

| Status | Meaning |
|--------|---------|
| 200 | Success |
| 400 | Bad request |
| 404 | Not found |
| 429 | Rate limited |
| 500 | Server error |
