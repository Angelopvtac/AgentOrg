#!/usr/bin/env bash
# AgentOrg Health Check
# Exit code = number of failed checks (0 = all healthy)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18791}"
FAILURES=0

check() {
    local name="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        echo "  [PASS] $name"
    else
        echo "  [FAIL] $name"
        FAILURES=$((FAILURES + 1))
    fi
}

check_shell() {
    local name="$1"
    local cmd="$2"
    if bash -c "$cmd" >/dev/null 2>&1; then
        echo "  [PASS] $name"
    else
        echo "  [FAIL] $name"
        FAILURES=$((FAILURES + 1))
    fi
}

echo "=== AgentOrg Health Check ==="
echo ""

# --- Container ---
echo "Container:"
check "Docker running" docker info
check_shell "agentorg-gateway container up" "docker compose -f '$PROJECT_DIR/docker-compose.yml' ps --status running --format '{{.Name}}' 2>/dev/null | grep -q agentorg-gateway"

# --- Gateway ---
echo ""
echo "Gateway:"
check "Gateway HTTP response" curl -sf --max-time 5 "http://localhost:${GATEWAY_PORT}/health"

# --- API Keys ---
echo ""
echo "API Keys:"
if [ -f "$PROJECT_DIR/.env" ]; then
    # shellcheck source=/dev/null
    source "$PROJECT_DIR/.env"
fi
check "OPENROUTER_API_KEY set" test -n "${OPENROUTER_API_KEY:-}"

# --- Config Files ---
echo ""
echo "Config:"
check "openclaw.json exists" test -f "$PROJECT_DIR/config/openclaw.json"
check "models.json exists" test -f "$PROJECT_DIR/config/models.json"
check "docker-compose.yml exists" test -f "$PROJECT_DIR/docker-compose.yml"

# --- Agent Workspaces ---
echo ""
echo "Agent Workspaces:"
for agent in orchestrator core-assistant; do
    for file in AGENTS.md SOUL.md IDENTITY.md USER.md TOOLS.md HEARTBEAT.md; do
        check "$agent/$file" test -f "$PROJECT_DIR/agents/$agent/workspace/$file"
    done
done

# --- Disk Usage ---
echo ""
echo "Disk:"
USAGE=$(du -sh "$PROJECT_DIR" 2>/dev/null | cut -f1)
echo "  [INFO] Project size: $USAGE"

# --- Summary ---
echo ""
if [ "$FAILURES" -eq 0 ]; then
    echo "=== HEALTHY (all checks passed) ==="
else
    echo "=== UNHEALTHY ($FAILURES check(s) failed) ==="
fi

exit "$FAILURES"
