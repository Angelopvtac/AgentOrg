#!/usr/bin/env bash
# AgentOrg First-Run Setup
# Interactive script to configure and start AgentOrg.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "========================================="
echo "  AgentOrg — First-Run Setup"
echo "========================================="
echo ""

# --- Step 1: Check prerequisites ---
echo "[1/6] Checking prerequisites..."

if ! command -v docker &>/dev/null; then
    echo "  ERROR: Docker is not installed. Install Docker first."
    exit 1
fi
echo "  Docker: $(docker --version | head -1)"

if ! docker compose version &>/dev/null; then
    echo "  ERROR: Docker Compose v2 is required."
    exit 1
fi
echo "  Docker Compose: $(docker compose version --short)"

if ! docker image inspect openclaw:local &>/dev/null; then
    echo "  ERROR: Docker image 'openclaw:local' not found."
    echo "  Build it first: cd /home/angelo/openclaw-workspace/openclaw-src && docker build -t openclaw:local ."
    exit 1
fi
echo "  Image openclaw:local: found"
echo ""

# --- Step 2: Create .env ---
echo "[2/6] Configuring environment..."

if [ -f "$PROJECT_DIR/.env" ]; then
    echo "  .env already exists. Skipping copy."
else
    cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/.env"
    echo "  Created .env from .env.example"
fi

# --- Step 3: Generate gateway token ---
echo ""
echo "[3/6] Setting gateway token..."

# Check if token already set
if grep -q "^OPENCLAW_GATEWAY_TOKEN=.\+" "$PROJECT_DIR/.env" 2>/dev/null; then
    echo "  Gateway token already configured."
else
    TOKEN=$(openssl rand -hex 24)
    sed -i "s/^OPENCLAW_GATEWAY_TOKEN=.*/OPENCLAW_GATEWAY_TOKEN=$TOKEN/" "$PROJECT_DIR/.env"
    echo "  Generated gateway token."
fi

# --- Step 4: Validate API keys ---
echo ""
echo "[4/6] Checking API keys..."

# shellcheck source=/dev/null
source "$PROJECT_DIR/.env"

if [ -n "${OPENROUTER_API_KEY:-}" ]; then
    echo "  OPENROUTER_API_KEY: set"
else
    echo "  OPENROUTER_API_KEY: NOT SET"
    echo "  >> Get your key at https://openrouter.ai/keys"
    echo "  >> Add it to $PROJECT_DIR/.env"
    echo ""
    read -rp "  Continue without API key? (y/N): " CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        echo "  Setup paused. Add your API key and re-run."
        exit 0
    fi
fi

if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    echo "  ANTHROPIC_API_KEY: set (optional)"
else
    echo "  ANTHROPIC_API_KEY: not set (optional — OpenRouter is primary)"
fi

# --- Step 5: Ensure directories ---
echo ""
echo "[5/6] Verifying directories..."

for dir in knowledge skills workflows config/schemas dashboards templates \
    agents/orchestrator/workspace/memory agents/core-assistant/workspace/memory; do
    mkdir -p "$PROJECT_DIR/$dir"
done
echo "  All directories verified."

# --- Step 6: Start gateway ---
echo ""
echo "[6/6] Starting AgentOrg gateway..."

cd "$PROJECT_DIR"
docker compose up -d

echo ""
echo "Waiting for gateway to become healthy..."
sleep 3

GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18791}"
RETRIES=10
while [ $RETRIES -gt 0 ]; do
    if curl -sf --max-time 2 "http://localhost:${GATEWAY_PORT}/health" >/dev/null 2>&1; then
        echo ""
        echo "========================================="
        echo "  AgentOrg is running!"
        echo "========================================="
        echo ""
        echo "  Gateway:    http://localhost:${GATEWAY_PORT}"
        echo "  Control UI: http://localhost:${GATEWAY_PORT}"
        echo "  Health:     http://localhost:${GATEWAY_PORT}/health"
        echo ""
        echo "  Run health check:  ./scripts/health-check.sh"
        echo "  Create backup:     ./scripts/backup.sh"
        echo "  View logs:         docker compose logs -f"
        echo ""

        # Run health check
        "$SCRIPT_DIR/health-check.sh" || true
        exit 0
    fi
    RETRIES=$((RETRIES - 1))
    sleep 2
done

echo ""
echo "  WARNING: Gateway did not respond within timeout."
echo "  Check logs: docker compose logs agentorg-gateway"
exit 1
