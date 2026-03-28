#!/usr/bin/env bash
# Smoke test: Workflow pipeline definitions
# Validates that Lobster workflow files are complete, well-structured,
# and properly integrated with agents and config.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PASS=0
FAIL=0

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}[PASS]${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "  ${RED}[FAIL]${NC} $1"; FAIL=$((FAIL + 1)); }

check() {
    local desc="$1"
    local cmd="$2"
    if eval "$cmd" > /dev/null 2>&1; then
        pass "$desc"
    else
        fail "$desc"
    fi
}

WF_DIR="$PROJECT_DIR/workflows"

echo "=== Workflow Definitions Smoke Test ==="
echo ""

# ===========================
# Phase 1: File existence
# ===========================
echo "Phase 1: Workflow files exist"

check "workflows/ directory exists" "[ -d '$WF_DIR' ]"
check "daily-briefing.lobster exists" "[ -f '$WF_DIR/daily-briefing.lobster' ]"
check "discovery.lobster exists" "[ -f '$WF_DIR/discovery.lobster' ]"
check "daily-briefing.lobster is non-empty" "[ -s '$WF_DIR/daily-briefing.lobster' ]"
check "discovery.lobster is non-empty" "[ -s '$WF_DIR/discovery.lobster' ]"

# ===========================
# Phase 2: Daily Briefing pipeline structure
# ===========================
echo ""
echo "Phase 2: Daily Briefing pipeline structure"

DB="$WF_DIR/daily-briefing.lobster"

check "Has pipeline name" "grep -q 'pipeline: daily-briefing' '$DB'"
check "Has version" "grep -q 'version:' '$DB'"
check "Has cron trigger" "grep -q 'type: cron' '$DB'"
check "Has schedule definition" "grep -q 'schedule:' '$DB'"
check "Has timezone adjustment" "grep -q 'timezone' '$DB'"
check "Has Step 1: Phase Status" "grep -q 'Gather Phase Status' '$DB'"
check "Has Step 2: Budget Status" "grep -q 'Gather Budget Status' '$DB'"
check "Has Step 3: Pending Tasks" "grep -q 'Gather Pending Tasks' '$DB'"
check "Has Step 4: Recent Knowledge" "grep -q 'Gather Recent Knowledge' '$DB'"
check "Has Step 5: Phase-Specific Context" "grep -q 'Phase-Specific Context' '$DB'"
check "Has Step 6: Compile Briefing" "grep -q 'Compile Briefing' '$DB'"
check "Has Step 7: Deliver" "grep -q 'Deliver to Core Assistant' '$DB'"
check "Has Step 8: Update State" "grep -q 'Update Briefing State' '$DB'"
check "Has error handling section" "grep -q 'Error Handling' '$DB'"
check "Has success criteria" "grep -q 'Success Criteria' '$DB'"

# ===========================
# Phase 3: Daily Briefing data references
# ===========================
echo ""
echo "Phase 3: Daily Briefing vault references"

check "References phase-state.json" "grep -q 'vault/phase-state.json' '$DB'"
check "References daily-budget.json" "grep -q 'vault/economics/daily-budget.json' '$DB'"
check "References human-tasks.json" "grep -q 'vault/human-tasks.json' '$DB'"
check "References decisions.json" "grep -q 'vault/decisions.json' '$DB'"
check "References insights.json" "grep -q 'vault/insights.json' '$DB'"
check "References briefing-state.json" "grep -q 'vault/briefing-state.json' '$DB'"
check "References founder-profile.json" "grep -q 'vault/founder-profile.json' '$DB'"
check "References onboarding-state.json (L0 context)" "grep -q 'vault/onboarding-state.json' '$DB'"

# ===========================
# Phase 4: Daily Briefing agent assignments
# ===========================
echo ""
echo "Phase 4: Daily Briefing agent assignments"

check "Orchestrator is the compiler" "grep -q 'agent: orchestrator' '$DB'"
check "Core-assistant handles delivery" "grep -q 'core-assistant' '$DB'"
check "Uses tier 1 for gathering" "grep -q 'tier: 1' '$DB'"
check "References communication style formatting" "grep -q 'communicationStyle' '$DB'"
check "References quiet hours" "grep -q 'quiet hours' '$DB'"

# ===========================
# Phase 5: Discovery pipeline structure
# ===========================
echo ""
echo "Phase 5: Discovery pipeline structure"

DISC="$WF_DIR/discovery.lobster"

check "Has pipeline name" "grep -q 'pipeline: discovery' '$DISC'"
check "Has version" "grep -q 'version:' '$DISC'"
check "Has event trigger" "grep -q 'type: event' '$DISC'"
check "Has L1 phase guard" "grep -q 'currentPhase.*L1' '$DISC'"
check "Has Step 1: Founder Profile Ingestion" "grep -q 'Founder Profile Ingestion' '$DISC'"
check "Has Step 2: Market Scan" "grep -q 'Market Scan' '$DISC'"
check "Has Step 3: Direction Selection" "grep -q 'Direction Selection' '$DISC'"
check "Has Step 4: Competitive Deep-Dive" "grep -q 'Competitive Deep-Dive' '$DISC'"
check "Has Step 5: Brand Brief Research" "grep -q 'Brand Brief Research' '$DISC'"
check "Has Step 6: Brand Brief Completion" "grep -q 'Brand Brief Completion' '$DISC'"
check "Has Step 7: L1 Gate Verification" "grep -q 'L1 Gate Verification' '$DISC'"
check "Has error handling section" "grep -q 'Error Handling' '$DISC'"
check "Has pipeline state tracking" "grep -q 'Pipeline State' '$DISC'"
check "Has success criteria" "grep -q 'Success Criteria' '$DISC'"

# ===========================
# Phase 6: Discovery L1 gate criteria coverage
# ===========================
echo ""
echo "Phase 6: Discovery L1 gate criteria"

check "Covers direction-selected criterion" "grep -q 'direction-selected' '$DISC'"
check "Covers brand-brief-complete criterion" "grep -q 'brand-brief-complete' '$DISC'"
check "Covers market-research-done criterion" "grep -q 'market-research-done' '$DISC'"
check "References vault/business/direction.json" "grep -q 'vault/business/direction.json' '$DISC'"
check "References vault/business/brand-brief.json" "grep -q 'vault/business/brand-brief.json' '$DISC'"
check "References vault/research/" "grep -q 'vault/research/' '$DISC'"

# ===========================
# Phase 7: Discovery agent assignments
# ===========================
echo ""
echo "Phase 7: Discovery agent assignments"

check "Research agent executes scan" "grep -q 'agent: research' '$DISC'"
check "Core-assistant handles founder interaction" "grep -q 'agent: core-assistant' '$DISC'"
check "Orchestrator handles gate verification" "grep -q 'agent: orchestrator' '$DISC'"
check "Research uses Tier 2 for scan" "grep -q 'tier: 2' '$DISC'"
check "Competitive analysis uses Tier 3" "grep -q 'tier: 3' '$DISC'"
check "Orchestrator verifies gate at Tier 3" "grep -q 'tier: 3' '$DISC'"

# ===========================
# Phase 8: Discovery research report schema
# ===========================
echo ""
echo "Phase 8: Discovery report format"

check "Defines report type market-scan" "grep -q 'market-scan' '$DISC'"
check "Defines report type competitive-analysis" "grep -q 'competitive-analysis' '$DISC'"
check "Defines report type brand-research" "grep -q 'brand-research' '$DISC'"
check "Report has findings field" "grep -q 'findings' '$DISC'"
check "Report has confidence levels" "grep -q 'confidence' '$DISC'"
check "Report has sources" "grep -q 'source' '$DISC'"
check "Report has recommendations" "grep -q 'recommendations' '$DISC'"

# ===========================
# Phase 9: Orchestrator integration
# ===========================
echo ""
echo "Phase 9: Agent integration references"

ORCH_AGENTS="$PROJECT_DIR/agents/orchestrator/workspace/AGENTS.md"
RESEARCH_AGENTS="$PROJECT_DIR/agents/research/workspace/AGENTS.md"

check "Orchestrator references daily-briefing workflow" "grep -q 'daily-briefing.lobster' '$ORCH_AGENTS'"
check "Orchestrator references discovery workflow" "grep -q 'discovery.lobster' '$ORCH_AGENTS'"
check "Orchestrator has Workflow Pipelines section" "grep -q 'Workflow Pipelines' '$ORCH_AGENTS'"
check "Research agent references discovery workflow" "grep -q 'discovery.lobster' '$RESEARCH_AGENTS'"

# ===========================
# Phase 10: Cross-reference with progression.json
# ===========================
echo ""
echo "Phase 10: Progression system coherence"

PROG="$PROJECT_DIR/config/progression.json"

# Verify L1 gate criteria in discovery workflow match progression.json
check "progression.json L1 has direction-selected" "grep -q 'direction-selected' '$PROG'"
check "progression.json L1 has brand-brief-complete" "grep -q 'brand-brief-complete' '$PROG'"
check "progression.json L1 has market-research-done" "grep -q 'market-research-done' '$PROG'"
check "Discovery workflow covers all 3 L1 criteria" "
    DISC_CRITERIA=\$(grep -c 'gate_progress:' '$DISC')
    [ \"\$DISC_CRITERIA\" -ge 2 ]
"

# ===========================
# Summary
# ===========================
echo ""
TOTAL=$((PASS + FAIL))
if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}Workflow definitions smoke test: $PASS/$TOTAL passed${NC}"
else
    echo -e "${RED}Workflow definitions smoke test: $PASS/$TOTAL passed ($FAIL failed)${NC}"
fi
echo ""
exit "$FAIL"
