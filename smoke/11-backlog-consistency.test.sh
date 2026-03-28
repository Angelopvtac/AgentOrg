#!/usr/bin/env bash
# Smoke test 11: Backlog consistency — verifies BACKLOG.md status reflects actual project state
set -euo pipefail

PASS=0
FAIL=0
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKLOG="$PROJECT_DIR/BACKLOG.md"

pass() { PASS=$((PASS + 1)); echo "  [PASS] $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  [FAIL] $1"; }

check_status() {
    local id="$1" expected="$2" desc="$3"
    if grep -q "| $id |.*| $expected |" "$BACKLOG"; then
        pass "$id shows '$expected' — $desc"
    else
        fail "$id should show '$expected' — $desc"
    fi
}

check_contains() {
    local pattern="$1" desc="$2"
    if grep -qi "$pattern" "$BACKLOG"; then
        pass "$desc"
    else
        fail "$desc"
    fi
}

check_not_contains() {
    local pattern="$1" desc="$2"
    if grep -qi "$pattern" "$BACKLOG"; then
        fail "$desc"
    else
        pass "$desc"
    fi
}

echo ""
echo "=== Smoke Test 11: Backlog Consistency ==="
echo ""

# Phase 1: Epic 1 — Foundation (all done)
echo "Phase 1: Epic 1 — Foundation stories are done"
check_status "F1.1-S1" "done" "project scaffold"
check_status "F1.1-S2" "done" "docker compose"
check_status "F1.2-S1" "done" "message routing"
check_status "F1.2-S2" "done" "primary channel"
check_status "F1.3-S1" "done" "model tier routing"
check_status "F1.3-S2" "done" "cost attribution per tier"
check_status "F1.4-S1" "done" "setup script"
check_status "F1.4-S2" "done" "health check"

# Phase 2: Epic 2 — Orchestrator & Core Assistant (all done)
echo ""
echo "Phase 2: Epic 2 — Orchestrator & Core Assistant stories are done"
check_status "F2.1-S1" "done" "orchestrator routing"
check_status "F2.1-S2" "done" "gate evaluation"
check_status "F2.1-S3" "done" "budget enforcement"
check_status "F2.1-S4" "done" "daily briefings"
check_status "F2.2-S1" "done" "founder conversations"
check_status "F2.2-S2" "done" "translate system state"
check_status "F2.2-S3" "done" "onboarding questionnaire"

# Phase 3: Epic 3 — Onboarding (all done, including transition)
echo ""
echo "Phase 3: Epic 3 — Onboarding stories are done"
check_status "F3.1-S1" "done" "guided onboarding"
check_status "F3.1-S2" "done" "founder profile generation"
check_status "F3.1-S3" "done" "phase transition on criteria"
check_status "F3.2-S1" "done" "phase state persistence"
check_status "F3.2-S2" "done" "phase context reading"

# Phase 4: Epic 4 — Knowledge Graph
echo ""
echo "Phase 4: Epic 4 — Knowledge Graph stories"
check_status "F4.1-S1" "done" "store and retrieve"
check_status "F4.1-S2" "done" "insight propagation"

# Phase 5: Epics 5-7 — Core skills (all done)
echo ""
echo "Phase 5: Epics 5-7 — Core skills all done"
check_status "F5.1-S1" "done" "create tasks"
check_status "F5.1-S2" "done" "daily digest"
check_status "F5.1-S3" "done" "mark complete"
check_status "F5.1-S4" "done" "quiet hours"
check_status "F6.1-S1" "done" "gate evaluation"
check_status "F6.1-S2" "done" "gate reports"
check_status "F6.1-S3" "done" "phase transitions"
check_status "F6.1-S4" "done" "failure protocol"
check_status "F7.1-S1" "done" "API cost tracking"
check_status "F7.1-S2" "done" "infra cost tracking"
check_status "F7.1-S3" "done" "derived metrics"
check_status "F7.1-S4" "done" "treasury balance"
check_status "F7.1-S5" "done" "budget enforcement"

# Phase 6: Epic 8 — Research & Discovery (done by iterations 4-5)
echo ""
echo "Phase 6: Epic 8 — Research & Discovery stories are done"
check_status "F8.1-S1" "done" "market scans"
check_status "F8.1-S2" "done" "viable directions"
check_status "F8.1-S3" "done" "market monitoring"
check_status "F8.2-S1" "done" "discovery workflow"

# Phase 7: Epic 9 — Presence (only daily briefing done)
echo ""
echo "Phase 7: Epic 9 — Daily briefing done, content/social planned"
check_status "F9.5-S1" "done" "daily briefing workflow"
check_status "F9.1-S1" "planned" "content agent (L2+)"
check_status "F9.2-S1" "planned" "social posting (L2+)"

# Phase 8: Epic 14 — Dashboards (done by iteration 1)
echo ""
echo "Phase 8: Epic 14 — Dashboard stories are done"
check_status "F14.1-S1" "done" "founder dashboard"
check_status "F14.1-S2" "done" "browser dashboard"

# Phase 9: Epic 15 — Templates (done by iteration 6)
echo ""
echo "Phase 9: Epic 15 — Template story is done"
check_status "F15.1-S1" "done" "business templates"

# Phase 10: Epic 16 — Security (V1 items done)
echo ""
echo "Phase 10: Epic 16 — Security V1 items done"
check_status "F16.1-S1" "done" "untrusted input"
check_status "F16.2-S1" "done" "kill switch"
check_status "F16.2-S2" "done" "no autonomous spend"
check_status "F16.3-S1" "done" "local data + env secrets"

# Phase 11: Verify items that SHOULD still be planned (L2+ features)
echo ""
echo "Phase 11: L2+ features correctly remain planned"
check_status "F9.1-S2" "planned" "content strategy adaptation"
check_status "F9.2-S2" "planned" "engagement monitoring"
check_status "F9.2-S3" "planned" "analytics tracking"
check_status "F9.3-S1" "planned" "social analytics skill"
check_status "F9.4-S1" "planned" "content pipeline"
check_status "F10.1-S1" "planned" "sales agent"
check_status "F10.2-S1" "planned" "compliance agent"
check_status "F10.3-S1" "planned" "revenue tracker"
check_status "F11.1-S1" "planned" "finance agent"
check_status "F11.2-S1" "planned" "operations agent"
check_status "F11.3-S1" "planned" "audit agent"
check_status "F12.1-S1" "planned" "strategy agent"

# Phase 12: Summary table accuracy
echo ""
echo "Phase 12: Summary table accuracy"
check_contains "V1 DONE" "Summary table contains V1 DONE entries"
check_contains "V1 complete" "Summary has V1 complete totals line"
check_not_contains "42% complete" "No stale 42% completion percentage"
check_not_contains "MVP DONE.*budget/gates need" "No stale MVP caveat about budget/gates"
check_not_contains "MVP DONE.*transition needs" "No stale MVP caveat about transition"
check_not_contains "propagation/ACL deferred" "No stale propagation deferred note"

# Phase 13: Sprint descriptions accuracy
echo ""
echo "Phase 13: Sprint descriptions reflect V1 completion"
check_contains "overnight iterations" "Sprint descriptions reference overnight iterations"
check_contains "14 test suites" "Sprint descriptions reference 14 test suites"
check_contains "700" "Sprint descriptions reference 700+ checks"
check_not_contains "Sprint 4: Discovery" "No stale Sprint 4 Discovery (done)"

# Phase 14: Cross-reference with disk — done items have corresponding files
echo ""
echo "Phase 14: Done items have corresponding artifacts on disk"

# Research agent (F8.1) has workspace
if [ -d "$PROJECT_DIR/agents/research/workspace" ]; then
    pass "Research agent workspace exists (F8.1 done)"
else
    fail "Research agent workspace missing (F8.1 marked done)"
fi

# Discovery workflow (F8.2) exists
if [ -f "$PROJECT_DIR/workflows/discovery.lobster" ]; then
    pass "Discovery workflow exists (F8.2 done)"
else
    fail "Discovery workflow missing (F8.2 marked done)"
fi

# Daily briefing workflow (F9.5) exists
if [ -f "$PROJECT_DIR/workflows/daily-briefing.lobster" ]; then
    pass "Daily briefing workflow exists (F9.5 done)"
else
    fail "Daily briefing workflow missing (F9.5 marked done)"
fi

# Dashboard (F14.1) generator exists
if [ -f "$PROJECT_DIR/scripts/generate-dashboard.py" ]; then
    pass "Dashboard generator exists (F14.1 done)"
else
    fail "Dashboard generator missing (F14.1 marked done)"
fi

# Templates (F15.1) exist
if [ -d "$PROJECT_DIR/templates/content-agency" ] && [ -d "$PROJECT_DIR/templates/saas-micro" ] && [ -d "$PROJECT_DIR/templates/consulting" ]; then
    pass "All 3 templates exist (F15.1 done)"
else
    fail "Templates missing (F15.1 marked done)"
fi

# Phase transition (F3.1-S3) engine exists
if [ -f "$PROJECT_DIR/scripts/phase-transition.py" ]; then
    pass "Phase transition engine exists (F3.1-S3 done)"
else
    fail "Phase transition engine missing (F3.1-S3 marked done)"
fi

# Knowledge propagation (F4.1-S2) protocol in skill
if grep -q "Propagation" "$PROJECT_DIR/skills/knowledge-graph/SKILL.md"; then
    pass "Knowledge propagation protocol in skill (F4.1-S2 done)"
else
    fail "Knowledge propagation missing from skill (F4.1-S2 marked done)"
fi

# Anti-injection (F16.1-S1) directive in agents
if grep -q -i "injection" "$PROJECT_DIR/agents/research/workspace/AGENTS.md"; then
    pass "Anti-injection directive in research agent (F16.1-S1 done)"
else
    fail "Anti-injection directive missing (F16.1-S1 marked done)"
fi

# Kill switch (F16.2-S1) in orchestrator
if grep -q "kill" "$PROJECT_DIR/agents/orchestrator/workspace/AGENTS.md"; then
    pass "Kill switch in orchestrator instructions (F16.2-S1 done)"
else
    fail "Kill switch missing from orchestrator (F16.2-S1 marked done)"
fi

# Channel config (related to F1.2) exists
if [ -f "$PROJECT_DIR/scripts/enable-channel.py" ]; then
    pass "Channel config script exists"
else
    fail "Channel config script missing"
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo -e "\033[0;32mBacklog consistency smoke test: $PASS/$((PASS + FAIL)) passed\033[0m"
else
    echo -e "\033[0;31mBacklog consistency smoke test: $PASS/$((PASS + FAIL)) passed, $FAIL failed\033[0m"
    exit 1
fi
