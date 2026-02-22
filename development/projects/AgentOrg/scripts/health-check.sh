#!/usr/bin/env bash
# AgentOrg Health Check
# Exit code = number of failed checks (0 = all healthy)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18791}"
FAILURES=0

check() {
    local name="$1"
    local hint="${2:-}"
    shift 2 || shift 1
    if "$@" >/dev/null 2>&1; then
        echo "  [PASS] $name"
    else
        echo "  [FAIL] $name"
        [ -n "$hint" ] && echo "         -> $hint"
        FAILURES=$((FAILURES + 1))
    fi
}

check_shell() {
    local name="$1"
    local cmd="$2"
    local hint="${3:-}"
    if bash -c "$cmd" >/dev/null 2>&1; then
        echo "  [PASS] $name"
    else
        echo "  [FAIL] $name"
        [ -n "$hint" ] && echo "         -> $hint"
        FAILURES=$((FAILURES + 1))
    fi
}

echo "=== AgentOrg Health Check ==="
echo ""

# --- Container ---
echo "Container:"
check "Docker running" "Install Docker: https://docs.docker.com/get-docker/" docker info
check_shell "agentorg-gateway container up" "docker compose -f '$PROJECT_DIR/docker-compose.yml' ps --status running --format '{{.Name}}' 2>/dev/null | grep -q agentorg-gateway" "Start it: cd $PROJECT_DIR && docker compose up -d"

# --- Gateway ---
echo ""
echo "Gateway:"
check "Gateway HTTP response" "Gateway not responding on port $GATEWAY_PORT. Check: docker compose logs agentorg-gateway" curl -sf --max-time 5 "http://localhost:${GATEWAY_PORT}/health"

# --- API Keys ---
echo ""
echo "API Keys:"
if [ -f "$PROJECT_DIR/.env" ]; then
    # shellcheck source=/dev/null
    source "$PROJECT_DIR/.env"
fi
check "OPENROUTER_API_KEY set" "Add OPENROUTER_API_KEY to $PROJECT_DIR/.env (get one at https://openrouter.ai/keys)" test -n "${OPENROUTER_API_KEY:-}"

# --- Config Files ---
echo ""
echo "Config:"
check "openclaw.json exists" "Missing config/openclaw.json — run scripts/setup.sh" test -f "$PROJECT_DIR/config/openclaw.json"
check "models.json exists" "Missing config/models.json — copy from config/ templates" test -f "$PROJECT_DIR/config/models.json"
check "docker-compose.yml exists" "Missing docker-compose.yml — project may be incomplete" test -f "$PROJECT_DIR/docker-compose.yml"

# --- Agent Workspaces ---
echo ""
echo "Agent Workspaces:"
for agent in orchestrator core-assistant; do
    for file in AGENTS.md SOUL.md IDENTITY.md USER.md TOOLS.md HEARTBEAT.md; do
        check "$agent/$file" "Create agents/$agent/workspace/$file" test -f "$PROJECT_DIR/agents/$agent/workspace/$file"
    done
done

# --- Vault Files ---
echo ""
echo "Vault (knowledge/):"
VAULT_FILES=(
    "phase-state.json"
    "founder-profile.json"
    "onboarding-state.json"
    "economics/daily-budget.json"
    "decisions.json"
    "insights.json"
    "lessons.json"
    "human-tasks.json"
    "briefing-state.json"
)
for vfile in "${VAULT_FILES[@]}"; do
    check "$vfile exists" "Missing knowledge/$vfile — check project setup" test -f "$PROJECT_DIR/knowledge/$vfile"
    check_shell "$vfile valid JSON" "python3 -c \"import json; json.load(open('$PROJECT_DIR/knowledge/$vfile'))\"" "Fix JSON syntax in knowledge/$vfile"
done

# --- Config Schemas ---
echo ""
echo "Config Schemas:"
check "progression.json exists" "Missing config/progression.json" test -f "$PROJECT_DIR/config/progression.json"
check_shell "progression.json valid JSON" "python3 -c \"import json; json.load(open('$PROJECT_DIR/config/progression.json'))\"" "Fix JSON syntax in config/progression.json"

# --- Skills ---
echo ""
echo "Skills:"
check "knowledge-graph/SKILL.md" "Missing skills/knowledge-graph/SKILL.md" test -f "$PROJECT_DIR/skills/knowledge-graph/SKILL.md"
check "human-task-queue/SKILL.md" "Missing skills/human-task-queue/SKILL.md" test -f "$PROJECT_DIR/skills/human-task-queue/SKILL.md"

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
