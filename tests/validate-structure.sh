#!/usr/bin/env bash
# Verify all required directories and files exist.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PASS=0
FAIL=0

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}[PASS]${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "  ${RED}[FAIL]${NC} $1"; FAIL=$((FAIL + 1)); }

echo "=== Structure Validation ==="
echo ""

# --- Required directories ---
echo "Required directories:"
REQUIRED_DIRS=(
    config
    config/schemas
    knowledge
    knowledge/economics
    skills
    skills/knowledge-graph
    skills/human-task-queue
    workflows
    dashboards
    templates
    agents
    agents/orchestrator
    agents/orchestrator/workspace
    agents/core-assistant
    agents/core-assistant/workspace
    scripts
)
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$PROJECT_DIR/$dir" ]; then
        pass "$dir/"
    else
        fail "$dir/ — directory missing"
    fi
done

# --- Required root files ---
echo ""
echo "Required root files:"
ROOT_FILES=(
    docker-compose.yml
    .env.example
    CLAUDE.md
    README.md
)
for f in "${ROOT_FILES[@]}"; do
    if [ -f "$PROJECT_DIR/$f" ]; then
        pass "$f"
    else
        fail "$f — missing"
    fi
done

# --- Agent workspace files ---
echo ""
echo "Agent workspace files:"
REQUIRED_WS_FILES=(AGENTS.md IDENTITY.md SOUL.md TOOLS.md)
for agent in orchestrator core-assistant; do
    for file in "${REQUIRED_WS_FILES[@]}"; do
        if [ -f "$PROJECT_DIR/agents/$agent/workspace/$file" ]; then
            pass "agents/$agent/workspace/$file"
        else
            fail "agents/$agent/workspace/$file — missing"
        fi
    done
done

# --- Skill directories have SKILL.md ---
echo ""
echo "Skill definitions:"
for skill_dir in "$PROJECT_DIR"/skills/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    if [ -f "$skill_dir/SKILL.md" ]; then
        pass "skills/$skill_name/SKILL.md"
    else
        fail "skills/$skill_name/SKILL.md — missing"
    fi
done

# --- Config files ---
echo ""
echo "Config files:"
CONFIG_FILES=(
    config/openclaw.json
    config/models.json
    config/progression.json
)
for f in "${CONFIG_FILES[@]}"; do
    if [ -f "$PROJECT_DIR/$f" ]; then
        pass "$f"
    else
        fail "$f — missing"
    fi
done

# --- Schema files ---
echo ""
echo "Schema files:"
SCHEMA_FILES=(
    config/schemas/founder-profile.json
    config/schemas/human-task.json
    config/schemas/knowledge-collections.json
)
for f in "${SCHEMA_FILES[@]}"; do
    if [ -f "$PROJECT_DIR/$f" ]; then
        pass "$f"
    else
        fail "$f — missing"
    fi
done

# --- Knowledge files ---
echo ""
echo "Knowledge files:"
KNOWLEDGE_FILES=(
    knowledge/phase-state.json
    knowledge/founder-profile.json
    knowledge/onboarding-state.json
    knowledge/decisions.json
    knowledge/insights.json
    knowledge/lessons.json
    knowledge/human-tasks.json
    knowledge/briefing-state.json
    knowledge/economics/daily-budget.json
)
for f in "${KNOWLEDGE_FILES[@]}"; do
    if [ -f "$PROJECT_DIR/$f" ]; then
        pass "$f"
    else
        fail "$f — missing"
    fi
done

# --- Summary ---
echo ""
TOTAL=$((PASS + FAIL))
echo "Structure validation: $PASS/$TOTAL passed"
exit "$FAIL"
