#!/usr/bin/env bash
set -euo pipefail

# Smoke test: Onboarding simulation & L0 gate evaluation
# Tests complete, partial, empty, and edge-case scenarios

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SIM="$PROJECT_ROOT/scripts/simulate-onboarding.py"

PASS=0
FAIL=0
TOTAL=0

pass() { PASS=$((PASS + 1)); TOTAL=$((TOTAL + 1)); echo "  [PASS] $1"; }
fail() { FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  [FAIL] $1"; }
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi; }

echo "=== Smoke Test: Onboarding Simulation ==="
echo ""

# Cleanup temp dirs on exit
TMPBASE="$SCRIPT_DIR/.test-sim"
trap 'rm -rf "$TMPBASE"-*' EXIT

# -----------------------------------------------------------------------
# Phase 1: Complete onboarding — all 6 gate criteria should pass
# -----------------------------------------------------------------------
echo "Phase 1: Complete onboarding simulation"

V1="$TMPBASE-complete"
mkdir -p "$V1/economics"

OUTPUT1=$(python3 "$SIM" --simulate "$V1" --no-save 2>&1) || true

check "Simulate completes without error" "echo '$OUTPUT1' | grep -q 'PASSED'"
check "All 6 criteria pass" "echo '$OUTPUT1' | grep -q '6/6 criteria met'"
check "Profile criterion passes" "echo '$OUTPUT1' | grep -q '\\[PASS\\] Founder profile'"
check "Skills criterion passes" "echo '$OUTPUT1' | grep -q '\\[PASS\\] At least 3'"
check "Availability criterion passes" "echo '$OUTPUT1' | grep -q '\\[PASS\\] Weekly hours'"
check "Financial criterion passes" "echo '$OUTPUT1' | grep -q '\\[PASS\\] Daily budget confirmed'"
check "Vision criterion passes" "echo '$OUTPUT1' | grep -q '\\[PASS\\] Vision statement'"
check "Onboarding criterion passes" "echo '$OUTPUT1' | grep -q '\\[PASS\\] All 9 onboarding'"
check "Ready for L1 message" "echo '$OUTPUT1' | grep -q 'Ready to transition to L1'"

# Verify vault files were populated
check "founder-profile.json exists" "[[ -f '$V1/founder-profile.json' ]]"
check "Founder name is Elena Marchetti" "grep -q 'Elena Marchetti' '$V1/founder-profile.json'"
check "onboarding-state.json exists" "[[ -f '$V1/onboarding-state.json' ]]"
check "Onboarding status is complete" "grep -q '\"complete\"' '$V1/onboarding-state.json'"
check "daily-budget.json exists" "[[ -f '$V1/economics/daily-budget.json' ]]"
check "phase-state.json exists" "[[ -f '$V1/phase-state.json' ]]"

echo ""

# -----------------------------------------------------------------------
# Phase 2: Partial onboarding — some criteria should fail
# -----------------------------------------------------------------------
echo "Phase 2: Partial onboarding (expect failures)"

V2="$TMPBASE-partial"
mkdir -p "$V2/economics"

python3 "$SIM" --partial "$V2" 2>&1 > /dev/null

# Now evaluate the partial state
OUTPUT2=$(python3 "$SIM" --evaluate "$V2" --no-save 2>&1) || true

check "Partial evaluation returns OPEN" "echo '$OUTPUT2' | grep -q 'OPEN'"
check "Profile criterion still passes" "echo '$OUTPUT2' | grep -q '\\[PASS\\] Founder profile'"
check "Skills criterion passes (3 skills)" "echo '$OUTPUT2' | grep -q '\\[PASS\\] At least 3'"
check "Availability fails (no hours)" "echo '$OUTPUT2' | grep -q '\\[FAIL\\] Weekly hours'"
check "Financial fails (no risk tolerance)" "echo '$OUTPUT2' | grep -q '\\[FAIL\\] Daily budget confirmed'"
check "Vision fails (no statement)" "echo '$OUTPUT2' | grep -q '\\[FAIL\\] Vision statement'"
check "Onboarding fails (in-progress)" "echo '$OUTPUT2' | grep -q '\\[FAIL\\] All 9 onboarding'"
check "Reports unmet criteria" "echo '$OUTPUT2' | grep -q 'criteria unmet'"

echo ""

# -----------------------------------------------------------------------
# Phase 3: Empty/reset state — all criteria should fail
# -----------------------------------------------------------------------
echo "Phase 3: Empty state (all criteria fail)"

V3="$TMPBASE-empty"
mkdir -p "$V3/economics"

python3 "$SIM" --reset "$V3" 2>&1 > /dev/null
OUTPUT3=$(python3 "$SIM" --evaluate "$V3" --no-save 2>&1) || true

check "Empty state returns OPEN" "echo '$OUTPUT3' | grep -q 'OPEN'"
check "Shows 0/6 criteria met" "echo '$OUTPUT3' | grep -q '0/6 criteria met'"
check "Profile fails" "echo '$OUTPUT3' | grep -q '\\[FAIL\\] Founder profile'"
check "Skills fails" "echo '$OUTPUT3' | grep -q '\\[FAIL\\] At least 3'"

echo ""

# -----------------------------------------------------------------------
# Phase 4: Gate evaluation saves to phase-state.json
# -----------------------------------------------------------------------
echo "Phase 4: Gate evaluation persistence"

V4="$TMPBASE-persist"
mkdir -p "$V4/economics"

python3 "$SIM" --simulate "$V4" 2>&1 > /dev/null

check "phase-state has lastGateEvaluation" "python3 -c \"import json; d=json.load(open('$V4/phase-state.json')); assert d['lastGateEvaluation'] is not None\""
check "phase-state has gateResults" "python3 -c \"import json; d=json.load(open('$V4/phase-state.json')); assert len(d['gateResults']) == 6\""
check "phase-state has history entry" "python3 -c \"import json; d=json.load(open('$V4/phase-state.json')); assert len(d['history']) >= 1\""
check "History entry shows PASSED" "python3 -c \"import json; d=json.load(open('$V4/phase-state.json')); assert d['history'][-1]['status'] == 'PASSED'\""
check "All 6 criteria in gateResults" "python3 -c \"import json; d=json.load(open('$V4/phase-state.json')); ids=set(d['gateResults'].keys()); assert ids == {'profile-complete','skills-identified','availability-set','financial-baseline','vision-defined','onboarding-complete'}\""

echo ""

# -----------------------------------------------------------------------
# Phase 5: Dashboard coherence — populated vault generates correct dashboard
# -----------------------------------------------------------------------
echo "Phase 5: Dashboard coherence with simulated data"

V5="$TMPBASE-dashboard"
mkdir -p "$V5/economics" "$V5/business" "$V5/metrics"

python3 "$SIM" --populate "$V5" 2>&1 > /dev/null

# Add minimum files the dashboard expects
cat > "$V5/human-tasks.json" << 'EOF'
{"tasks": [], "stats": {"totalCreated": 0, "totalCompleted": 0}}
EOF
cat > "$V5/decisions.json" << 'EOF'
{"collection": "decisions", "entries": []}
EOF
cat > "$V5/insights.json" << 'EOF'
{"collection": "insights", "entries": []}
EOF
cat > "$V5/lessons.json" << 'EOF'
{"collection": "lessons", "entries": []}
EOF
cat > "$V5/briefing-state.json" << 'EOF'
{"lastBriefingSent": null, "briefingHistory": []}
EOF
cat > "$V5/business/direction.json" << 'EOF'
{"direction": null}
EOF
cat > "$V5/business/brand-brief.json" << 'EOF'
{"brandName": null}
EOF
cat > "$V5/metrics/social.json" << 'EOF'
{}
EOF
cat > "$V5/economics/treasury.json" << 'EOF'
{"balance": 0, "totalRevenue": 0, "totalCosts": 0, "revenueToExpenseRatio": 0}
EOF
cat > "$V5/economics/costs.json" << 'EOF'
{"collection": "costs", "entries": []}
EOF
cat > "$V5/economics/revenue.json" << 'EOF'
{"collection": "revenue", "entries": []}
EOF

DASH_OUT="$TMPBASE-dashboard.html"
bash "$PROJECT_ROOT/scripts/generate-dashboard.sh" "$V5" "$DASH_OUT" > /dev/null 2>&1

check "Dashboard generates from simulated vault" "[[ -f '$DASH_OUT' ]]"
check "Dashboard shows 6/6 gate criteria" "grep -q '6/6 criteria met' '$DASH_OUT'"
check "Dashboard shows 9/9 onboarding" "grep -q '9/9 sections complete' '$DASH_OUT'"
check "Dashboard shows founder name in no-error state" "[[ -s '$DASH_OUT' ]]"

echo ""

# -----------------------------------------------------------------------
# Phase 6: Exit codes
# -----------------------------------------------------------------------
echo "Phase 6: Exit codes"

V6="$TMPBASE-exitcodes"
mkdir -p "$V6/economics"

python3 "$SIM" --simulate "$V6" --no-save > /dev/null 2>&1
check "Exit 0 on all-pass simulation" "[[ $? -eq 0 ]]"

python3 "$SIM" --reset "$V6" > /dev/null 2>&1
RC=0; python3 "$SIM" --evaluate "$V6" --no-save > /dev/null 2>&1 || RC=$?
check "Exit 1 on failed evaluation" "[[ $RC -eq 1 ]]"

RC=0; python3 "$SIM" --badmode /tmp > /dev/null 2>&1 || RC=$?
check "Exit 2 on bad arguments" "[[ $RC -eq 2 ]]"

echo ""

# -----------------------------------------------------------------------
# Phase 7: Bash wrapper works
# -----------------------------------------------------------------------
echo "Phase 7: Bash wrapper"

V7="$TMPBASE-wrapper"
mkdir -p "$V7/economics"

WRAPPER_OUT=$(bash "$PROJECT_ROOT/scripts/simulate-onboarding.sh" --simulate "$V7" --no-save 2>&1) || true
check "Wrapper script runs successfully" "echo '$WRAPPER_OUT' | grep -q 'PASSED'"

echo ""

# -----------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------
echo "==========================================="
echo "  Onboarding simulation smoke test: $PASS/$TOTAL passed"
if [[ $FAIL -gt 0 ]]; then
  echo "  $FAIL FAILURES"
  echo "==========================================="
  exit 1
fi
echo "==========================================="
exit 0
