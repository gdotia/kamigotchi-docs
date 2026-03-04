#!/usr/bin/env bash
# Quick status check — API health + account/kami info
set -euo pipefail

API_BASE="http://localhost:3008"
KAMI_API_DIR="/root/.openclaw/workspace/kami-api"
ENV_FILE="$KAMI_API_DIR/.env"

echo "=== Kamigotchi Status ==="
echo ""

# 1. Check API health
echo "--- API Health ---"
if STATUS=$(curl -sf "$API_BASE/api/world/status" 2>/dev/null); then
  echo "🟢 API is up"
  echo "$STATUS" | python3 -m json.tool 2>/dev/null || echo "$STATUS"
else
  echo "🔴 API unreachable at $API_BASE"
  echo "   Start it: cd $KAMI_API_DIR && npm run dev"
  exit 1
fi

# 2. Try to get wallet address from .env
WALLET_ADDR=""
if [ -f "$ENV_FILE" ]; then
  # Extract private key, derive address if possible
  PRIVKEY=$(grep -oP 'KAMI_PRIVATE_KEY=\K.*' "$ENV_FILE" 2>/dev/null || true)
  # Try to get address from API or env
  WALLET_ADDR=$(grep -oP 'KAMI_WALLET_ADDRESS=\K.*' "$ENV_FILE" 2>/dev/null || true)
fi

# If address provided as arg, use that
if [ -n "${1:-}" ]; then
  WALLET_ADDR="$1"
fi

if [ -z "$WALLET_ADDR" ]; then
  echo ""
  echo "ℹ️  No wallet address found."
  echo "   Pass address as argument: check-status.sh 0x..."
  echo "   Or set KAMI_WALLET_ADDRESS in $ENV_FILE"
  exit 0
fi

# 3. Account info
echo ""
echo "--- Account: $WALLET_ADDR ---"
ACCOUNT=$(curl -sf "$API_BASE/api/account/$WALLET_ADDR" 2>/dev/null || echo '{"error": "not found"}')
echo "$ACCOUNT" | python3 -m json.tool 2>/dev/null || echo "$ACCOUNT"

# 4. List Kamis
echo ""
echo "--- Kamis ---"
KAMIS=$(curl -sf "$API_BASE/api/account/$WALLET_ADDR/kamis" 2>/dev/null || echo '{"error": "not found"}')
echo "$KAMIS" | python3 -m json.tool 2>/dev/null || echo "$KAMIS"

echo ""
echo "=== End Status ==="
