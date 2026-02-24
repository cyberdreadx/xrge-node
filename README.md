<div align="center">

# ⚛️ XRGE Node

### Run Your Own Post-Quantum Blockchain Node

[![RougeChain](https://img.shields.io/badge/Network-RougeChain-ff0040)](https://rougechain.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Rust](https://img.shields.io/badge/Built%20with-Rust-orange.svg)](https://www.rust-lang.org/)

**RougeChain** is the first L1 blockchain built on NIST-approved post-quantum cryptography (ML-DSA-65 + ML-KEM-768), designed to survive the quantum computing era.

[Explorer](https://rougechain.io) · [API Docs](API.md) · [Troubleshooting](TROUBLESHOOTING.md)

</div>

---

## ⚡ Quick Start (One Command)

SSH into your VPS and run:

```bash
curl -sSfL https://raw.githubusercontent.com/cyberdreadx/xrge-node/main/setup.sh | bash
```

The script will:
1. Install Rust + build dependencies
2. Clone and compile the node (~10 min)
3. Set up systemd for auto-restart
4. Configure Nginx + free SSL (optional)
5. Open firewall ports
6. Start mining!

---

## 🔧 Manual Setup

### Prerequisites

- Ubuntu 22.04+ (or Debian-based)
- 2GB+ RAM (or add swap)
- Rust toolchain

### 1. Install Dependencies

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential pkg-config libssl-dev curl git

# Install Rust
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"
```

### 2. Clone & Build

```bash
git clone https://github.com/cyberdreadx/xrge-node.git
cd xrge-node/core
cargo build --release -p quantum-vault-daemon
```

> ⏱ Build takes 5-15 minutes depending on VPS specs.

### 3. Run the Node

```bash
./target/release/quantum-vault-daemon \
  --mine \
  --host 0.0.0.0 \
  --api-port 5100 \
  --peers "https://testnet.rougechain.io"
```

### 4. Verify

```bash
curl http://localhost:5100/api/health
# → {"status":"ok","chain_id":"rougechain-devnet-1","height":...}

curl http://localhost:5100/api/stats
# → {"connected_peers":...,"network_height":...,"is_mining":true,...}
```

---

## 🏗 Architecture

```
┌──────────────────────────────────────────────┐
│              RougeChain Network              │
│                                              │
│   ┌─────────┐  P2P   ┌─────────┐           │
│   │ Node 1  │◄──────►│ Node 2  │  ...       │
│   │ (mine)  │  gRPC  │ (mine)  │           │
│   └────┬────┘        └────┬────┘           │
│        │ :5100            │ :5100           │
│        ▼                  ▼                 │
│     HTTP API           HTTP API             │
└──────────────────────────────────────────────┘
```

Each node:
- Maintains a full copy of the blockchain
- Validates and signs transactions with **ML-DSA-65**
- Mines new blocks (optional)
- Syncs with peers via gRPC
- Exposes an HTTP API on port `5100`

---

## ⚙️ CLI Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--mine` | `false` | Enable block production |
| `--host` | `127.0.0.1` | Bind address |
| `--port` | `4100` | P2P gRPC port |
| `--api-port` | `5100` | HTTP API port |
| `--chain-id` | `rougechain-devnet-1` | Chain identifier |
| `--block-time-ms` | `1000` | Target block time |
| `--data-dir` | `~/.quantum-vault/` | Blockchain data directory |
| `--api-keys` | `None` | Comma-separated API keys for auth |
| `--peers` | `None` | Comma-separated peer node URLs |
| `--public-url` | `None` | This node's public URL (for peer discovery) |

---

## 🔒 Production Setup (systemd + Nginx + SSL)

### Create systemd Service

```bash
sudo tee /etc/systemd/system/rougechain.service > /dev/null <<'EOF'
[Unit]
Description=RougeChain XRGE Node
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/xrge-node/core
ExecStart=$HOME/xrge-node/core/target/release/quantum-vault-daemon \
  --mine --host 0.0.0.0 --api-port 5100 \
  --peers "https://testnet.rougechain.io" \
  --public-url "https://YOUR_DOMAIN"
Restart=always
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now rougechain
```

### Nginx Reverse Proxy + SSL

```bash
sudo apt install -y nginx certbot python3-certbot-nginx

sudo tee /etc/nginx/sites-available/rougechain > /dev/null <<'NGINX'
server {
    listen 80;
    server_name YOUR_DOMAIN;

    location /api/ {
        proxy_pass http://127.0.0.1:5100;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /api/ws {
        proxy_pass http://127.0.0.1:5100;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
NGINX

sudo ln -sf /etc/nginx/sites-available/rougechain /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d YOUR_DOMAIN
```

### Open Firewall

```bash
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 4100/tcp  # P2P
sudo ufw allow 5100/tcp  # API
sudo ufw --force enable
```

---

## 🔑 Features

- **Post-Quantum Crypto** — ML-DSA-65 signatures, ML-KEM-768 key exchange
- **AMM/DEX** — Uniswap V2-style liquidity pools and token swaps
- **Token Creation** — Launch custom tokens on-chain
- **Staking** — Stake XRGE to become a validator
- **Token Burning** — Permanent on-chain burn tracking
- **Encrypted Messaging** — Quantum-safe end-to-end encrypted chat
- **WebSocket** — Real-time block and transaction feeds

---

## 📊 API Reference

See [API.md](API.md) for complete documentation. Key endpoints:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/health` | GET | Health check |
| `/api/stats` | GET | Node statistics |
| `/api/balance/{pubkey}` | GET | Wallet balance |
| `/api/blocks` | GET | All blocks |
| `/api/txs` | GET | Recent transactions |
| `/api/peers` | GET | Connected peers |
| `/api/pools` | GET | Liquidity pools |
| `/api/v2/transfer` | POST | Secure signed transfer |

---

## 🛠 Quick Commands

```bash
sudo systemctl status rougechain     # Check status
sudo systemctl restart rougechain    # Restart
sudo systemctl stop rougechain       # Stop
sudo journalctl -u rougechain -f     # Live logs
sudo journalctl -u rougechain -n 100 # Last 100 lines
```

---

## 🌐 Join the Network

| Peer | URL |
|------|-----|
| Testnet (primary) | `https://testnet.rougechain.io` |
| XRGE Node 2 | `https://xrge-node.gltch.app` |

Add peers with `--peers "https://testnet.rougechain.io,https://xrge-node.gltch.app"`

---

## 📄 License

MIT — see [LICENSE](LICENSE) for details.
