#!/usr/bin/env bash
set -euo pipefail

# Smoke test: Phase transition — L0→L1 gate evaluation and transition
# Tests check mode, transition execution, force mode, rejection, status, and state integrity

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TRANSITION="$PROJECT_ROOT/scripts/phase-transition.py"
SIM="$PROJECT_ROOT/scripts/simulate-onboarding.py"
CONFIG="$PROJECT_ROOT/config/progression.json"

PASS=0
FAIL=0
TOTAL=0

pass() { PASS=$((PASS + 1)); TOTAL=$((TOTAL + 1)); echo "  [PASS] $1"; }
fail() { FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  [FAIL] $1"; }
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi; }

echo "=== Smoke Test: Phase Transition ==="
echo ""

# Cleanup temp dirs on exit
TMPBASE="$SCRIPT_DIR/.test-transition"
trap 'rm -rf "$TMPBASE"-*' EXIT

# -----------------------------------------------------------------------
# Phase 1: Check mode with complete onboarding — gate should pass
# -----------------------------------------------------------------------
echo "Phase 1: Check mode (dry-run) with complete onboarding"

V1="$TMPBASE-check-pass"
mkdir -p "$V1/economics"
python3 "$SIM" --simulate "$V1" --no-save > /dev/null 2>&1

OUTPUT1=$(python3 "$TRANSITION" --check "$V1" --config "$CONFIG" 2>&1) || true

check "Check mode reports PASSED" "echo '$OUTPUT1' | grep -q 'PASSED'"
check "Check mode reports 6/6 criteria" "echo '$OUTPUT1' | grep -q '6/6 criteria met'"
check "Check mode suggests transition" "echo '$OUTPUT1' | grep -q 'Ready to transition'"
check "Check mode mentions L1" "echo '$OUTPUT1' | grep -q 'L1'"
check "Phase state NOT modified (still L0)" "python3 -c \"import json; d=json.load(open('$V1/phase-state.json')); assert d['currentPhase'] == 'L0'\""

echo ""

# -----------------------------------------------------------------------
# Phase 2: Check mode with empty vault — gate should fail
# -----------------------------------------------------------------------
echo "Phase 2: Check mode with empty vault (expect failure)"

V2="$TMPBASE-check-fail"
mkdir -p "$V2/economics"
python3 "$SIM" --reset "$V2" > /dev/null 2>&1

RC=0
OUTPUT2=$(python3 "$TRANSITION" --check "$V2" --config "$CONFIG" 2>&1) || RC=$?

check "Check mode returns exit 1 on failure" "[[ $RC -eq 1 ]]"
check "Check mode reports OPEN" "echo '$OUTPUT2' | grep -q 'OPEN'"
check "Check mode reports 0/6" "echo '$OUTPUT2' | grep -q '0/6 criteria met'"
check "Phase state NOT modified (still L0)" "python3 -c \"import json; d=json.load(open('$V2/phase-state.json')); assert d['currentPhase'] == 'L0'\""

echo ""

# -----------------------------------------------------------------------
# Phase 3: Transition with complete onboarding — should succeed
# -----------------------------------------------------------------------
echo "Phase 3: Transition execution (L0 -> L1)"

V3="$TMPBASE-transition"
mkdir -p "$V3/economics"
python3 "$SIM" --simulate "$V3" --no-save > /dev/null 2>&1

OUTPUT3=$(python3 "$TRANSITION" --transition "$V3" --config "$CONFIG" --project "$PROJECT_ROOT" 2>&1) || true

check "Transition reports PASSED gate" "echo '$OUTPUT3' | grep -q 'PASSED'"
check "Transition shows L0 -> L1" "echo '$OUTPUT3' | grep -q 'L0 -> L1'"
check "Shows Discovery phase name" "echo '$OUTPUT3' | grep -q 'Discovery'"
check "Shows research agent unlocked" "echo '$OUTPUT3' | grep -q 'research'"
check "Phase updated to L1" "python3 -c \"import json; d=json.load(open('$V3/phase-state.json')); assert d['currentPhase'] == 'L1'\""
check "Phase name is Discovery" "python3 -c \"import json; d=json.load(open('$V3/phase-state.json')); assert d['phaseName'] == 'Discovery'\""
check "Phase start date updated" "python3 -c \"import json; d=json.load(open('$V3/phase-state.json')); assert '2026' in d['phaseStartDate']\""
check "History has transition entry" "python3 -c \"import json; d=json.load(open('$V3/phase-state.json')); h=[e for e in d['history'] if e.get('type')=='transition']; assert len(h) >= 1\""
check "Transition from L0 to L1 in history" "python3 -c \"import json; d=json.load(open('$V3/phase-state.json')); h=[e for e in d['history'] if e.get('type')=='transition']; assert h[-1]['fromPhase']=='L0' and h[-1]['toPhase']=='L1'\""
check "Gate results stored" "python3 -c \"import json; d=json.load(open('$V3/phase-state.json')); assert len(d['gateResults']) == 6\""

echo ""

# -----------------------------------------------------------------------
# Phase 4: Transition rejection — incomplete onboarding should block
# -----------------------------------------------------------------------
echo "Phase 4: Transition rejection (partial onboarding)"

V4="$TMPBASE-reject"
mkdir -p "$V4/economics"
python3 "$SIM" --partial "$V4" > /dev/null 2>&1

RC=0
OUTPUT4=$(python3 "$TRANSITION" --transition "$V4" --config "$CONFIG" 2>&1) || RC=$?

check "Transition rejected with exit 1" "[[ $RC -eq 1 ]]"
check "Reports criteria unmet" "echo '$OUTPUT4' | grep -q 'criteria unmet'"
check "Phase still L0 after rejection" "python3 -c \"import json; d=json.load(open('$V4/phase-state.json')); assert d['currentPhase'] == 'L0'\""

echo ""

# -----------------------------------------------------------------------
# Phase 5: Force transition
# -----------------------------------------------------------------------
echo "Phase 5: Force transition (skip gate)"

V5="$TMPBASE-force"
mkdir -p "$V5/economics"
python3 "$SIM" --reset "$V5" > /dev/null 2>&1

OUTPUT5=$(python3 "$TRANSITION" --force "$V5" --config "$CONFIG" --project "$PROJECT_ROOT" 2>&1) || true

check "Force mode mentions skipping gate" "echo '$OUTPUT5' | grep -q 'FORCE'"
check "Phase forced to L1" "python3 -c \"import json; d=json.load(open('$V5/phase-state.json')); assert d['currentPhase'] == 'L1'\""
check "Phase name is Discovery" "python3 -c \"import json; d=json.load(open('$V5/phase-state.json')); assert d['phaseName'] == 'Discovery'\""
check "History records force transition" "python3 -c \"import json; d=json.load(open('$V5/phase-state.json')); h=d['history']; assert len(h) >= 1 and h[-1]['type'] == 'transition'\""

echo ""

# -----------------------------------------------------------------------
# Phase 6: Status command
# -----------------------------------------------------------------------
echo "Phase 6: Status command"

V6="$TMPBASE-status"
mkdir -p "$V6/economics"
python3 "$SIM" --simulate "$V6" --no-save > /dev/null 2>&1

OUTPUT6=$(python3 "$TRANSITION" --status "$V6" --config "$CONFIG" 2>&1) || true

check "Status shows current phase" "echo '$OUTPUT6' | grep -q 'L0'"
check "Status shows phase name" "echo '$OUTPUT6' | grep -q 'Onboarding'"
check "Status shows Phase Status header" "echo '$OUTPUT6' | grep -q 'Phase Status'"

# Transition then check status again
python3 "$TRANSITION" --transition "$V6" --config "$CONFIG" --project "$PROJECT_ROOT" > /dev/null 2>&1
OUTPUT6B=$(python3 "$TRANSITION" --status "$V6" --config "$CONFIG" 2>&1) || true

check "Status shows L1 after transition" "echo '$OUTPUT6B' | grep -q 'L1'"
check "Status shows Discovery" "echo '$OUTPUT6B' | grep -q 'Discovery'"
check "Status shows transition history" "echo '$OUTPUT6B' | grep -q 'Transition History'"

echo ""

# -----------------------------------------------------------------------
# Phase 7: Terminal phase handling
# -----------------------------------------------------------------------
echo "Phase 7: Terminal phase error handling"

V7="$TMPBASE-terminal"
mkdir -p "$V7/economics"

# Set phase to L6 (terminal)
python3 -c "
import json
from pathlib import Path
d = {'currentPhase': 'L6', 'phaseName': 'Autonomous Operations',
     'phaseStartDate': '2026-03-28T00:00:00Z', 'lastGateEvaluation': None,
     'gateResults': {}, 'history': []}
Path('$V7/phase-state.json').write_text(json.dumps(d, indent=2) + '\n')
"

RC=0
OUTPUT7=$(python3 "$TRANSITION" --transition "$V7" --config "$CONFIG" 2>&1) || RC=$?

check "Terminal phase returns exit 2" "[[ $RC -eq 2 ]]"
check "Reports terminal phase" "echo '$OUTPUT7' | grep -q 'terminal phase'"

echo ""

# -----------------------------------------------------------------------
# Phase 8: Bash wrapper
# -----------------------------------------------------------------------
echo "Phase 8: Bash wrapper"

V8="$TMPBASE-wrapper"
mkdir -p "$V8/economics"
python3 "$SIM" --simulate "$V8" --no-save > /dev/null 2>&1

WRAPPER_OUT=$(bash "$PROJECT_ROOT/scripts/phase-transition.sh" --check "$V8" 2>&1) || true
check "Wrapper script runs successfully" "echo '$WRAPPER_OUT' | grep -q 'PASSED'"
check "Wrapper reports gate results" "echo '$WRAPPER_OUT' | grep -q '6/6'"

echo ""

# -----------------------------------------------------------------------
# Phase 9: Dashboard coherence after transition
# -----------------------------------------------------------------------
echo "Phase 9: Dashboard coherence after transition"

V9="$TMPBASE-dashboard"
mkdir -p "$V9/economics" "$V9/business" "$V9/metrics"

# Populate and transition
python3 "$SIM" --simulate "$V9" --no-save > /dev/null 2>&1
python3 "$TRANSITION" --transition "$V9" --config "$CONFIG" --project "$PROJECT_ROOT" > /dev/null 2>&1

# Add minimum files the dashboard expects
cat > "$V9/human-tasks.json" << 'EOF'
{"tasks": [], "stats": {"totalCreated": 0, "totalCompleted": 0}}
EOF
cat > "$V9/decisions.json" << 'EOF'
{"collection": "decisions", "entries": []}
EOF
cat > "$V9/insights.json" << 'EOF'
{"collection": "insights", "entries": []}
EOF
cat > "$V9/lessons.json" << 'EOF'
{"collection": "lessons", "entries": []}
EOF
cat > "$V9/briefing-state.json" << 'EOF'
{"lastBriefingSent": null, "briefingHistory": []}
EOF
cat > "$V9/business/direction.json" << 'EOF'
{"direction": null}
EOF
cat > "$V9/business/brand-brief.json" << 'EOF'
{"brandName": null}
EOF
cat > "$V9/metrics/social.json" << 'EOF'
{}
EOF
cat > "$V9/economics/treasury.json" << 'EOF'
{"balance": 0, "totalRevenue": 0, "totalCosts": 0, "revenueToExpenseRatio": 0}
EOF
cat > "$V9/economics/costs.json" << 'EOF'
{"collection": "costs", "entries": []}
EOF
cat > "$V9/economics/revenue.json" << 'EOF'
{"collection": "revenue", "entries": []}
EOF

DASH_OUT="$TMPBASE-dashboard.html"
bash "$PROJECT_ROOT/scripts/generate-dashboard.sh" "$V9" "$DASH_OUT" > /dev/null 2>&1

check "Dashboard generates after transition" "[[ -f '$DASH_OUT' ]]"
check "Dashboard shows L1 phase" "grep -q 'L1' '$DASH_OUT'"
check "Dashboard shows Discovery" "grep -q 'Discovery' '$DASH_OUT'"

echo ""

# -----------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------
echo "==========================================="
echo "  Phase transition smoke test: $PASS/$TOTAL passed"
if [[ $FAIL -gt 0 ]]; then
  echo "  $FAIL FAILURES"
  echo "==========================================="
  exit 1
fi
echo "==========================================="
exit 0
