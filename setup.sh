#!/usr/bin/env bash
#
# ⚠️  xrge-node is DEPRECATED and archived.
#
# A node built from this repo cannot join the current network (stale genesis-sync
# and block-verification code). This script now redirects to the maintained
# installer in `rougechain-node`, which builds a node that actually syncs.
#
# Canonical repo:  https://github.com/cyberdreadx/rougechain-node
#
set -euo pipefail

INSTALLER="https://raw.githubusercontent.com/cyberdreadx/rougechain-node/main/scripts/install-validator.sh"

cat <<'BANNER'
============================================================================
  ⚠️  xrge-node is deprecated and archived.

  This repo's daemon can no longer join the network. Redirecting you to the
  maintained node installer (cyberdreadx/rougechain-node)...
============================================================================
BANNER

# Give the reader a moment to Ctrl-C if they piped this straight into a shell.
sleep 3

if command -v curl >/dev/null 2>&1; then
  exec bash -c "curl -sSL '$INSTALLER' | bash"
elif command -v wget >/dev/null 2>&1; then
  exec bash -c "wget -qO- '$INSTALLER' | bash"
else
  echo "Please install curl or wget, then run:" >&2
  echo "  curl -sSL $INSTALLER | bash" >&2
  exit 1
fi
