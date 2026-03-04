#!/usr/bin/env bash
# Kamigotchi setup — check kami-api, wallet config, and connectivity
set -euo pipefail

API_BASE="http://localhost:3008"
KAMI_API_DIR="/root/.openclaw/workspace/kami-api"
ENV_FILE="$KAMI_API_DIR/.env"

echo "=== Kamigotchi Setup ==="
echo ""

# 1. Check if kami-api directory exists
if [ ! -d "$KAMI_API_DIR" ]; then
  echo "❌ kami-api not found at $KAMI_API_DIR"
  echo "   Clone or install kami-api first."
  exit 1
fi
echo "✅ kami-api directory found"

# 2. Check if kami-api is running
API_RUNNING=false
if curl -sf "$API_BASE/api/world/status" > /dev/null 2>&1; then
  API_RUNNING=true
  echo "✅ kami-api is running on port 3008"
else
  echo "⚠️  kami-api not running — starting it..."
  cd "$KAMI_API_DIR"
  nohup npm run dev > /tmp/kami-api.log 2>&1 &
  KAMI_PID=$!
  echo "   Started kami-api (PID $KAMI_PID), waiting for it to come up..."

  # Wait up to 15 seconds for the API to respond
  for i in $(seq 1 15); do
    if curl -sf "$API_BASE/api/world/status" > /dev/null 2>&1; then
      API_RUNNING=true
      echo "✅ kami-api is running on port 3008"
      break
    fi
    sleep 1
  done

  if [ "$API_RUNNING" = false ]; then
    echo "❌ kami-api failed to start. Check /tmp/kami-api.log"
    exit 1
  fi
fi

# 3. Check .env file and KAMI_PRIVATE_KEY
if [ ! -f "$ENV_FILE" ]; then
  echo "⚠️  No .env file found at $ENV_FILE"
  echo "   Create one with: KAMI_PRIVATE_KEY=0x..."
  echo "   Read-only operations will still work."
else
  if grep -q "KAMI_PRIVATE_KEY" "$ENV_FILE" 2>/dev/null; then
    echo "✅ KAMI_PRIVATE_KEY configured"
  else
    echo "⚠️  KAMI_PRIVATE_KEY not found in .env"
    echo "   Add it to $ENV_FILE for write operations."
    echo "   Read-only operations will still work."
  fi
fi

# 4. Test API with /api/world/status
echo ""
echo "--- World Status ---"
STATUS=$(curl -sf "$API_BASE/api/world/status" 2>/dev/null || echo '{"error": "unreachable"}')
echo "$STATUS" | python3 -m json.tool 2>/dev/null || echo "$STATUS"

# 5. Print summary
echo ""
echo "=== Setup Summary ==="
echo "  API:    $API_BASE"
echo "  Dir:    $KAMI_API_DIR"
echo "  Status: $([ "$API_RUNNING" = true ] && echo '🟢 Running' || echo '🔴 Down')"
echo ""
echo "Next steps:"
echo "  1. Check account: curl $API_BASE/api/account/{address}"
echo "  2. Register if needed: curl -X POST $API_BASE/api/account/register -H 'Content-Type: application/json' -d '{\"name\":\"myname\"}'"
echo "  3. Stake a Kami: curl -X POST $API_BASE/api/kami/{id}/stake"
echo "  4. Start harvesting!"
