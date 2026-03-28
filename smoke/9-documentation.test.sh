#!/usr/bin/env bash
set -euo pipefail

# Smoke test: Documentation completeness
# Verifies README, CONTRIBUTING, and SECURITY docs are accurate and complete

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0

pass() { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

check_contains() {
    local file="$1" pattern="$2" desc="$3"
    if grep -qi "$pattern" "$file" 2>/dev/null; then
        pass "$desc"
    else
        fail "$desc — pattern '$pattern' not found in $(basename "$file")"
    fi
}

check_not_contains() {
    local file="$1" pattern="$2" desc="$3"
    if grep -qi "$pattern" "$file" 2>/dev/null; then
        fail "$desc — stale pattern '$pattern' found in $(basename "$file")"
    else
        pass "$desc"
    fi
}

README="$PROJECT_DIR/README.md"
CONTRIB="$PROJECT_DIR/CONTRIBUTING.md"
SECURITY="$PROJECT_DIR/SECURITY.md"

# ─── Phase 1: Documentation files exist ───
echo ""
echo "Phase 1: Documentation files exist"

[[ -f "$README" ]] && pass "README.md exists" || fail "README.md missing"
[[ -f "$CONTRIB" ]] && pass "CONTRIBUTING.md exists" || fail "CONTRIBUTING.md missing"
[[ -f "$SECURITY" ]] && pass "SECURITY.md exists" || fail "SECURITY.md missing"
[[ -f "$PROJECT_DIR/LICENSE" ]] && pass "LICENSE exists" || fail "LICENSE missing"
[[ -f "$PROJECT_DIR/CLAUDE.md" ]] && pass "CLAUDE.md exists" || fail "CLAUDE.md missing"
[[ -f "$PROJECT_DIR/BACKLOG.md" ]] && pass "BACKLOG.md exists" || fail "BACKLOG.md missing"

# ─── Phase 2: README covers all agents ───
echo ""
echo "Phase 2: README covers all agents"

check_contains "$README" "orchestrator" "README mentions orchestrator"
check_contains "$README" "core.assistant" "README mentions core-assistant"
check_contains "$README" "research" "README mentions research agent"
check_contains "$README" "L1" "README mentions L1 activation"

# ─── Phase 3: README covers all scripts ───
echo ""
echo "Phase 3: README covers all scripts"

for script in setup health-check backup generate-dashboard simulate-onboarding phase-transition apply-template enable-channel; do
    check_contains "$README" "$script" "README documents $script script"
done

# ─── Phase 4: README covers all skills ───
echo ""
echo "Phase 4: README covers all skills"

check_contains "$README" "knowledge.graph" "README documents knowledge-graph skill"
check_contains "$README" "human.task.queue" "README documents human-task-queue skill"
check_contains "$README" "progression.engine" "README documents progression-engine skill"
check_contains "$README" "economics.engine" "README documents economics-engine skill"

# ─── Phase 5: README covers phase system ───
echo ""
echo "Phase 5: README covers phase system"

for phase in L0 L1 L2 L3 L4 L5 L6; do
    check_contains "$README" "$phase" "README mentions phase $phase"
done
check_contains "$README" "Onboarding" "README mentions Onboarding phase name"
check_contains "$README" "Discovery" "README mentions Discovery phase name"
check_contains "$README" "Presence" "README mentions Presence phase name"

# ─── Phase 6: README covers model tiers ───
echo ""
echo "Phase 6: README covers model tiers"

check_contains "$README" "Haiku" "README mentions Haiku (Tier 1)"
check_contains "$README" "Sonnet" "README mentions Sonnet (Tier 2)"
check_contains "$README" "Opus" "README mentions Opus (Tier 3)"
check_contains "$README" "Triage" "README mentions Triage tier"
check_contains "$README" "Execution" "README mentions Execution tier"
check_contains "$README" "Strategic" "README mentions Strategic tier"

# ─── Phase 7: README covers key features ───
echo ""
echo "Phase 7: README covers key features"

check_contains "$README" "dashboard" "README covers dashboard"
check_contains "$README" "onboarding.simul" "README covers onboarding simulation"
check_contains "$README" "phase.transition" "README covers phase transitions"
check_contains "$README" "template" "README covers business templates"
check_contains "$README" "channel" "README covers channel configuration"
check_contains "$README" "workflow" "README covers workflows"
check_contains "$README" "daily.briefing" "README covers daily briefing workflow"
check_contains "$README" "discovery" "README covers discovery workflow"
check_contains "$README" "lobster" "README mentions Lobster pipeline format"

# ─── Phase 8: README covers environment variables ───
echo ""
echo "Phase 8: README covers environment variables"

for var in OPENCLAW_GATEWAY_TOKEN OPENROUTER_API_KEY DISCORD_BOT_TOKEN TELEGRAM_BOT_TOKEN AGENTORG_TIMEZONE AGENTORG_DAILY_BUDGET; do
    check_contains "$README" "$var" "README documents $var"
done

# ─── Phase 9: README covers directory structure ───
echo ""
echo "Phase 9: README covers directory structure"

for dir in config agents skills workflows knowledge dashboards templates scripts smoke; do
    check_contains "$README" "$dir" "README documents $dir/ directory"
done

# ─── Phase 10: README covers testing ───
echo ""
echo "Phase 10: README covers testing"

check_contains "$README" "run-all" "README documents test runner"
check_contains "$README" "smoke" "README mentions smoke tests"
check_contains "$README" "structure.valid" "README mentions structure validation"

# ─── Phase 11: README has no stale content ───
echo ""
echo "Phase 11: README has no stale content"

check_not_contains "$README" "Sprint 3 complete" "README doesn't have stale sprint status"
check_not_contains "$README" "what.*working" "README doesn't have in-progress status section"

# ─── Phase 12: README covers quick start ───
echo ""
echo "Phase 12: README covers quick start"

check_contains "$README" "docker compose up" "README has docker compose command"
check_contains "$README" "setup.sh" "README references setup script"
check_contains "$README" "health-check" "README references health check"
check_contains "$README" "openclaw:local" "README mentions required Docker image"

# ─── Phase 13: README covers troubleshooting ───
echo ""
echo "Phase 13: README covers troubleshooting"

check_contains "$README" "troubleshoot" "README has troubleshooting section"
check_contains "$README" "docker compose logs" "README has log inspection tip"
check_contains "$README" "18791" "README references gateway port"

# ─── Phase 14: CONTRIBUTING covers all contribution types ───
echo ""
echo "Phase 14: CONTRIBUTING covers all contribution types"

check_contains "$CONTRIB" "adding a new agent" "CONTRIBUTING covers adding agents"
check_contains "$CONTRIB" "adding a new skill" "CONTRIBUTING covers adding skills"
check_contains "$CONTRIB" "adding a new workflow" "CONTRIBUTING covers adding workflows"
check_contains "$CONTRIB" "adding a new.*template" "CONTRIBUTING covers adding templates"
check_contains "$CONTRIB" "adding a new phase" "CONTRIBUTING covers adding phases"
check_contains "$CONTRIB" "adding a new script" "CONTRIBUTING covers adding scripts"
check_contains "$CONTRIB" "validate-structure" "CONTRIBUTING references structure validation"
check_contains "$CONTRIB" "run-all" "CONTRIBUTING references test runner"

# ─── Phase 15: CONTRIBUTING conventions are accurate ───
echo ""
echo "Phase 15: CONTRIBUTING conventions are accurate"

check_contains "$CONTRIB" "kebab-case" "CONTRIBUTING documents kebab-case convention"
check_contains "$CONTRIB" "UPPERCASE.md" "CONTRIBUTING documents workspace file convention"
check_contains "$CONTRIB" "set -euo pipefail" "CONTRIBUTING requires strict bash"
check_contains "$CONTRIB" "smoke" "CONTRIBUTING mentions smoke tests"
check_contains "$CONTRIB" "lobster" "CONTRIBUTING mentions Lobster format"
check_contains "$CONTRIB" "template.json" "CONTRIBUTING documents template manifest"

# ─── Phase 16: SECURITY covers key areas ───
echo ""
echo "Phase 16: SECURITY covers key areas"

check_contains "$SECURITY" "cap_drop" "SECURITY documents capability restriction"
check_contains "$SECURITY" "no-new-privileges" "SECURITY documents privilege escalation block"
check_contains "$SECURITY" "read-only" "SECURITY documents read-only filesystem"
check_contains "$SECURITY" "environment variable" "SECURITY documents secret handling"

# ─── Phase 17: Cross-document consistency ───
echo ""
echo "Phase 17: Cross-document consistency"

# README template list should match actual templates
for tmpl in content-agency saas-micro consulting; do
    if [[ -d "$PROJECT_DIR/templates/$tmpl" ]]; then
        check_contains "$README" "$tmpl" "README lists template $tmpl that exists on disk"
    else
        fail "Template directory $tmpl missing but may be referenced in README"
    fi
done

# README agent list should match actual agents
for agent in orchestrator core-assistant research; do
    if [[ -d "$PROJECT_DIR/agents/$agent" ]]; then
        check_contains "$README" "$agent" "README lists agent $agent that exists on disk"
    else
        fail "Agent directory $agent missing but referenced in README"
    fi
done

# README skill list should match actual skills
for skill in knowledge-graph human-task-queue progression-engine economics-engine; do
    if [[ -d "$PROJECT_DIR/skills/$skill" ]]; then
        pass "Skill $skill exists on disk and is documented"
    else
        fail "Skill directory $skill missing"
    fi
done

# README workflow list should match actual workflows
for wf in daily-briefing discovery; do
    if [[ -f "$PROJECT_DIR/workflows/$wf.lobster" ]]; then
        pass "Workflow $wf.lobster exists on disk and is documented"
    else
        fail "Workflow $wf.lobster missing"
    fi
done

# ─── Results ───
echo ""
TOTAL=$((PASS + FAIL))
if [[ $FAIL -eq 0 ]]; then
    echo -e "\033[0;32mDocumentation smoke test: $PASS/$TOTAL passed\033[0m"
else
    echo -e "\033[0;31mDocumentation smoke test: $PASS/$TOTAL passed ($FAIL failures)\033[0m"
fi

exit "$FAIL"
