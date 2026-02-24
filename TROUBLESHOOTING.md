# Troubleshooting

## Build Failures

### Out of memory during compilation
Add swap space:
```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```
Then retry the build.

### Missing `libssl-dev` or `pkg-config`
```bash
sudo apt install -y build-essential pkg-config libssl-dev
```

### Rust not found after install
```bash
source "$HOME/.cargo/env"
```

---

## Node Won't Start

### Check logs
```bash
sudo journalctl -u rougechain -n 50 --no-pager
```

### Port already in use
```bash
sudo lsof -i :5100
# Kill the conflicting process, then restart
sudo systemctl restart rougechain
```

### Permission denied on data directory
```bash
# Make sure the service User matches who owns the files
sudo chown -R $USER:$USER ~/.quantum-vault/
```

---

## Can't Connect to API

### Firewall blocking ports
```bash
sudo ufw status
sudo ufw allow 5100/tcp
sudo ufw allow 4100/tcp
```

### Node bound to localhost only
Make sure you're using `--host 0.0.0.0` (not `127.0.0.1`).

### CORS errors from frontend
The node allows any origin by default. If you're behind Nginx, make sure the proxy headers are set correctly.

---

## Peer Not Connecting

### Check peer URL is reachable
```bash
curl https://testnet.rougechain.io/api/health
```

### Verify your node is accessible from outside
```bash
# From another machine:
curl http://YOUR_IP:5100/api/health
```

### Check if your node advertises a public URL
Use `--public-url "https://YOUR_DOMAIN"` so peers can find you.

---

## SSL Issues

### Certbot fails
Make sure:
1. Your DNS A record points to this server's IP
2. Port 80 is open (`sudo ufw allow 80/tcp`)
3. Nginx is running (`sudo systemctl status nginx`)

Then retry:
```bash
sudo certbot --nginx -d YOUR_DOMAIN
```

### Certificate renewal
Certbot auto-renews via systemd timer. Check:
```bash
sudo certbot renew --dry-run
```

---

## Nginx Issues

### Test config
```bash
sudo nginx -t
```

### 502 Bad Gateway
The node isn't running or isn't on port 5100:
```bash
sudo systemctl status rougechain
curl http://localhost:5100/api/health
```

---

## Data & Storage

### Where is blockchain data stored?
Default: `~/.quantum-vault/`

### Reset chain data
```bash
sudo systemctl stop rougechain
rm -rf ~/.quantum-vault/
sudo systemctl start rougechain
```
> ⚠️ This deletes all local chain data. The node will re-sync from peers.
