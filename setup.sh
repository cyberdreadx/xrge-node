#!/bin/bash
# XRGE Node — One-Command Setup Script
# Installs deps, builds the node, configures systemd + Nginx + SSL
set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}"
echo "  ██╗  ██╗██████╗  ██████╗ ███████╗"
echo "  ╚██╗██╔╝██╔══██╗██╔════╝ ██╔════╝"
echo "   ╚███╔╝ ██████╔╝██║  ███╗█████╗  "
echo "   ██╔██╗ ██╔══██╗██║   ██║██╔══╝  "
echo "  ██╔╝ ██╗██║  ██║╚██████╔╝███████╗"
echo "  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝"
echo -e "${NC}"
echo -e "${GREEN}RougeChain Node Setup${NC}"
echo "========================================"
echo ""

# ── Detect user & paths ──────────────────────
INSTALL_DIR="$HOME/xrge-node"
USER_NAME=$(whoami)

# ── System deps ──────────────────────────────
echo -e "${CYAN}[1/7]${NC} Installing system dependencies..."
sudo apt update -qq && sudo apt upgrade -y -qq
sudo apt install -y -qq build-essential pkg-config libssl-dev curl git

# ── Rust ─────────────────────────────────────
if ! command -v cargo &> /dev/null; then
    echo -e "${CYAN}[2/7]${NC} Installing Rust..."
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo -e "${GREEN}[2/7]${NC} Rust already installed: $(cargo --version)"
fi

# ── Clone repo ───────────────────────────────
if [ -d "$INSTALL_DIR/core" ]; then
    echo -e "${GREEN}[3/7]${NC} Repo already cloned at $INSTALL_DIR"
    cd "$INSTALL_DIR"
    git pull --ff-only || true
else
    echo -e "${CYAN}[3/7]${NC} Cloning xrge-node..."
    git clone https://github.com/cyberdreadx/xrge-node.git "$INSTALL_DIR"
fi

# ── Build ────────────────────────────────────
echo -e "${CYAN}[4/7]${NC} Building node (this takes 5-15 minutes)..."
cd "$INSTALL_DIR/core"
cargo build --release -p quantum-vault-daemon

DAEMON_PATH="$INSTALL_DIR/core/target/release/quantum-vault-daemon"
if [ ! -f "$DAEMON_PATH" ]; then
    echo -e "${RED}Build failed — binary not found at $DAEMON_PATH${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Build complete${NC}"

# ── Configuration prompts ────────────────────
echo ""
echo -e "${YELLOW}Configuration${NC}"
echo "──────────────"

read -p "Domain name (leave blank for IP-only): " DOMAIN
read -p "Enable mining? [Y/n]: " ENABLE_MINING
ENABLE_MINING=${ENABLE_MINING:-Y}

MINE_FLAG=""
if [[ "$ENABLE_MINING" =~ ^[Yy] ]]; then
    MINE_FLAG="--mine"
fi

PEERS="https://testnet.rougechain.io"
read -p "Peer URLs [$PEERS]: " CUSTOM_PEERS
PEERS=${CUSTOM_PEERS:-$PEERS}

PUBLIC_URL=""
if [ -n "$DOMAIN" ]; then
    PUBLIC_URL="--public-url \"https://$DOMAIN\""
fi

# ── Firewall ─────────────────────────────────
echo -e "${CYAN}[5/7]${NC} Configuring firewall..."
sudo ufw allow 22/tcp  2>/dev/null || true
sudo ufw allow 80/tcp  2>/dev/null || true
sudo ufw allow 443/tcp 2>/dev/null || true
sudo ufw allow 4100/tcp 2>/dev/null || true
sudo ufw allow 5100/tcp 2>/dev/null || true
sudo ufw --force enable 2>/dev/null || true

# ── systemd ──────────────────────────────────
echo -e "${CYAN}[6/7]${NC} Creating systemd service..."
EXEC_LINE="$DAEMON_PATH $MINE_FLAG --host 0.0.0.0 --api-port 5100 --peers \"$PEERS\""
if [ -n "$DOMAIN" ]; then
    EXEC_LINE="$EXEC_LINE --public-url \"https://$DOMAIN\""
fi

sudo bash -c "cat > /etc/systemd/system/rougechain.service << SVCEOF
[Unit]
Description=RougeChain XRGE Node
After=network.target

[Service]
Type=simple
User=$USER_NAME
WorkingDirectory=$INSTALL_DIR/core
ExecStart=$EXEC_LINE
Restart=always
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
SVCEOF"

sudo systemctl daemon-reload
sudo systemctl enable rougechain
sudo systemctl restart rougechain

echo -e "${GREEN}✓ Node started via systemd${NC}"

# ── Nginx + SSL (optional) ───────────────────
if [ -n "$DOMAIN" ]; then
    echo -e "${CYAN}[7/7]${NC} Setting up Nginx + SSL for $DOMAIN..."
    sudo apt install -y -qq nginx certbot python3-certbot-nginx

    sudo bash -c "cat > /etc/nginx/sites-available/rougechain << NGXEOF
server {
    listen 80;
    server_name $DOMAIN;

    location /api/ {
        proxy_pass http://127.0.0.1:5100;
        proxy_set_header Host \\\$host;
        proxy_set_header X-Real-IP \\\$remote_addr;
        proxy_set_header X-Forwarded-For \\\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \\\$scheme;
    }

    location /api/ws {
        proxy_pass http://127.0.0.1:5100;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \\\$http_upgrade;
        proxy_set_header Connection \"upgrade\";
        proxy_set_header Host \\\$host;
    }
}
NGXEOF"

    sudo ln -sf /etc/nginx/sites-available/rougechain /etc/nginx/sites-enabled/
    sudo nginx -t && sudo systemctl reload nginx
    sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email || {
        echo -e "${YELLOW}SSL setup needs manual completion: sudo certbot --nginx -d $DOMAIN${NC}"
    }
    echo -e "${GREEN}✓ Nginx + SSL configured${NC}"
else
    echo -e "${YELLOW}[7/7]${NC} Skipping Nginx (no domain provided)"
fi

# ── Verify ───────────────────────────────────
echo ""
sleep 2
echo -e "${CYAN}Verifying...${NC}"
HEALTH=$(curl -sf http://localhost:5100/api/health 2>/dev/null || echo "FAIL")

if echo "$HEALTH" | grep -q '"status"'; then
    echo -e "${GREEN}✓ Node is online!${NC}"
    echo "$HEALTH" | python3 -m json.tool 2>/dev/null || echo "$HEALTH"
else
    echo -e "${YELLOW}Node may still be starting — check logs:${NC}"
    echo "  sudo journalctl -u rougechain -f"
fi

echo ""
echo "════════════════════════════════════════"
echo -e "${GREEN}  XRGE Node deployed successfully! 🚀${NC}"
echo "════════════════════════════════════════"
echo ""
echo "  Status:   sudo systemctl status rougechain"
echo "  Logs:     sudo journalctl -u rougechain -f"
echo "  Restart:  sudo systemctl restart rougechain"
if [ -n "$DOMAIN" ]; then
    echo "  API:      https://$DOMAIN/api/stats"
else
    echo "  API:      http://$(hostname -I | awk '{print $1}'):5100/api/stats"
fi
echo ""
