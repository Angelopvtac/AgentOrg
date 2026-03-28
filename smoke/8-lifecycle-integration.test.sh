#!/usr/bin/env bash
set -euo pipefail

# Smoke test: End-to-end lifecycle integration
# Proves the entire progression pipeline works as a connected system:
#   Reset → Simulate onboarding → L0 gate passes → L0→L1 transition
#   → Apply template → L1 gate passes → L1→L2 transition
#   → Dashboard shows L2 state → Vault state consistent throughout

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SIM="$PROJECT_ROOT/scripts/simulate-onboarding.py"
TRANSITION="$PROJECT_ROOT/scripts/phase-transition.py"
TEMPLATE="$PROJECT_ROOT/scripts/apply-template.py"
DASHBOARD="$PROJECT_ROOT/scripts/generate-dashboard.py"
CONFIG="$PROJECT_ROOT/config/progression.json"

PASS=0
FAIL=0
TOTAL=0

pass_test() { PASS=$((PASS + 1)); TOTAL=$((TOTAL + 1)); echo "  [PASS] $1"; }
fail_test() { FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  [FAIL] $1"; }

echo "=== Smoke Test: End-to-End Lifecycle Integration ==="
echo ""

# Create isolated test vault
VAULT="$SCRIPT_DIR/.test-lifecycle"
DASH_OUT="$SCRIPT_DIR/.test-lifecycle-dashboard.html"
trap 'rm -rf "$VAULT" "$DASH_OUT"' EXIT

# -----------------------------------------------------------------------
# Phase 1: Fresh state — vault starts clean
# -----------------------------------------------------------------------
echo "Phase 1: Initialize fresh vault"

mkdir -p "$VAULT/economics" "$VAULT/business" "$VAULT/research" "$VAULT/metrics"
python3 "$SIM" --reset "$VAULT" > /dev/null 2>&1

if [[ -f "$VAULT/phase-state.json" ]]; then pass_test "Vault initialized"; else fail_test "Vault initialized"; fi

python3 -c "import json; d=json.load(open('$VAULT/phase-state.json')); exit(0 if d['currentPhase'] == 'L0' else 1)" 2>/dev/null \
  && pass_test "Phase is L0" || fail_test "Phase is L0"

python3 -c "import json; d=json.load(open('$VAULT/onboarding-state.json')); exit(0 if d['status'] == 'not-started' else 1)" 2>/dev/null \
  && pass_test "Onboarding not started" || fail_test "Onboarding not started"

python3 -c "import json; d=json.load(open('$VAULT/founder-profile.json')); exit(0 if d['personalInfo']['name'] is None else 1)" 2>/dev/null \
  && pass_test "Founder profile empty" || fail_test "Founder profile empty"

echo ""

# -----------------------------------------------------------------------
# Phase 2: L0 gate fails on empty vault
# -----------------------------------------------------------------------
echo "Phase 2: L0 gate rejects empty vault"

RC=0
OUTPUT=$(python3 "$TRANSITION" --check "$VAULT" --config "$CONFIG" 2>&1) || RC=$?

[[ $RC -eq 1 ]] && pass_test "L0 gate fails on empty vault" || fail_test "L0 gate fails on empty vault"
echo "$OUTPUT" | grep -q '0/6 criteria met' && pass_test "Reports 0/6 criteria" || fail_test "Reports 0/6 criteria"
echo "$OUTPUT" | grep -q 'OPEN' && pass_test "Status is OPEN" || fail_test "Status is OPEN"

echo ""

# -----------------------------------------------------------------------
# Phase 3: Simulate complete onboarding
# -----------------------------------------------------------------------
echo "Phase 3: Simulate complete onboarding"

python3 "$SIM" --simulate "$VAULT" --no-save > /dev/null 2>&1

python3 -c "import json; d=json.load(open('$VAULT/onboarding-state.json')); exit(0 if d['status'] == 'complete' else 1)" 2>/dev/null \
  && pass_test "Onboarding state is complete" || fail_test "Onboarding state is complete"

python3 -c "import json; d=json.load(open('$VAULT/founder-profile.json')); exit(0 if d['personalInfo']['name'] is not None else 1)" 2>/dev/null \
  && pass_test "Founder name populated" || fail_test "Founder name populated"

python3 -c "import json; d=json.load(open('$VAULT/founder-profile.json')); exit(0 if len(d['skills']) >= 3 else 1)" 2>/dev/null \
  && pass_test "Skills populated (>=3)" || fail_test "Skills populated (>=3)"

python3 -c "import json; d=json.load(open('$VAULT/founder-profile.json')); v=d['vision']['statement']; exit(0 if v and len(v) > 50 else 1)" 2>/dev/null \
  && pass_test "Vision defined" || fail_test "Vision defined"

python3 -c "import json; d=json.load(open('$VAULT/founder-profile.json')); exit(0 if d['availability']['weeklyHours'] > 0 else 1)" 2>/dev/null \
  && pass_test "Availability set" || fail_test "Availability set"

echo ""

# -----------------------------------------------------------------------
# Phase 4: L0 gate passes after onboarding
# -----------------------------------------------------------------------
echo "Phase 4: L0 gate passes after onboarding"

RC=0
OUTPUT=$(python3 "$TRANSITION" --check "$VAULT" --config "$CONFIG" 2>&1) || RC=$?

[[ $RC -eq 0 ]] && pass_test "L0 gate passes" || fail_test "L0 gate passes"
echo "$OUTPUT" | grep -q '6/6 criteria met' && pass_test "Reports 6/6 criteria" || fail_test "Reports 6/6 criteria"
echo "$OUTPUT" | grep -q 'PASSED' && pass_test "Status is PASSED" || fail_test "Status is PASSED"

python3 -c "import json; d=json.load(open('$VAULT/phase-state.json')); exit(0 if d['currentPhase'] == 'L0' else 1)" 2>/dev/null \
  && pass_test "Still on L0 (dry-run)" || fail_test "Still on L0 (dry-run)"

echo ""

# -----------------------------------------------------------------------
# Phase 5: Execute L0 → L1 transition
# -----------------------------------------------------------------------
echo "Phase 5: Execute L0 → L1 transition"

python3 "$TRANSITION" --transition "$VAULT" --config "$CONFIG" > /dev/null 2>&1

python3 -c "import json; d=json.load(open('$VAULT/phase-state.json')); exit(0 if d['currentPhase'] == 'L1' else 1)" 2>/dev/null \
  && pass_test "Phase is now L1" || fail_test "Phase is now L1"

python3 -c "import json; d=json.load(open('$VAULT/phase-state.json')); exit(0 if d['phaseName'] == 'Discovery' else 1)" 2>/dev/null \
  && pass_test "Phase name is Discovery" || fail_test "Phase name is Discovery"

python3 -c "import json; d=json.load(open('$VAULT/phase-state.json')); exit(0 if '2026' in d['phaseStartDate'] else 1)" 2>/dev/null \
  && pass_test "Phase start date updated" || fail_test "Phase start date updated"

python3 -c "
import json
d = json.load(open('$VAULT/phase-state.json'))
transitions = [h for h in d.get('history', []) if h.get('type') == 'transition']
assert len(transitions) >= 1
assert transitions[-1]['fromPhase'] == 'L0'
assert transitions[-1]['toPhase'] == 'L1'
" 2>/dev/null && pass_test "Transition logged in history" || fail_test "Transition logged in history"

echo ""

# -----------------------------------------------------------------------
# Phase 6: L1 gate fails before template
# -----------------------------------------------------------------------
echo "Phase 6: L1 gate fails without business data"

RC=0
python3 "$TRANSITION" --check "$VAULT" --config "$CONFIG" > /dev/null 2>&1 || RC=$?

[[ $RC -eq 1 ]] && pass_test "L1 gate fails without template" || fail_test "L1 gate fails without template"

echo ""

# -----------------------------------------------------------------------
# Phase 7: Apply business template to satisfy L1 gate
# -----------------------------------------------------------------------
echo "Phase 7: Apply business template (content-agency)"

python3 "$TEMPLATE" --apply content-agency "$VAULT" --project "$PROJECT_ROOT" > /dev/null 2>&1

python3 -c "import json; d=json.load(open('$VAULT/business/direction.json')); exit(0 if d.get('direction') is not None else 1)" 2>/dev/null \
  && pass_test "Direction file populated" || fail_test "Direction file populated"

python3 -c "import json; d=json.load(open('$VAULT/business/brand-brief.json')); exit(0 if d.get('brandName') is not None else 1)" 2>/dev/null \
  && pass_test "Brand brief populated" || fail_test "Brand brief populated"

python3 -c "
import os
reports = [f for f in os.listdir('$VAULT/research') if f.endswith('.json')]
exit(0 if len(reports) >= 1 else 1)
" 2>/dev/null && pass_test "Market research exists" || fail_test "Market research exists"

python3 -c "
import json
d = json.load(open('$VAULT/business/direction.json'))
direction = d.get('direction')
exit(0 if isinstance(direction, dict) and (direction.get('market') or direction.get('targetCustomer')) else 1)
" 2>/dev/null && pass_test "Direction has target market" || fail_test "Direction has target market"

python3 -c "import json; d=json.load(open('$VAULT/business/brand-brief.json')); exit(0 if d.get('positioning') is not None else 1)" 2>/dev/null \
  && pass_test "Brand brief has positioning" || fail_test "Brand brief has positioning"

python3 -c "import json; d=json.load(open('$VAULT/business/brand-brief.json')); exit(0 if d.get('voice') or d.get('tone') else 1)" 2>/dev/null \
  && pass_test "Brand brief has voice" || fail_test "Brand brief has voice"

echo ""

# -----------------------------------------------------------------------
# Phase 8: L1 gate passes after template
# -----------------------------------------------------------------------
echo "Phase 8: L1 gate passes after template"

RC=0
OUTPUT=$(python3 "$TRANSITION" --check "$VAULT" --config "$CONFIG" 2>&1) || RC=$?

[[ $RC -eq 0 ]] && pass_test "L1 gate passes" || fail_test "L1 gate passes"
echo "$OUTPUT" | grep -q '3/3 criteria met' && pass_test "Reports 3/3 criteria" || fail_test "Reports 3/3 criteria"
echo "$OUTPUT" | grep -q 'PASSED' && pass_test "Status is PASSED" || fail_test "Status is PASSED"

echo ""

# -----------------------------------------------------------------------
# Phase 9: Execute L1 → L2 transition
# -----------------------------------------------------------------------
echo "Phase 9: Execute L1 → L2 transition"

python3 "$TRANSITION" --transition "$VAULT" --config "$CONFIG" > /dev/null 2>&1

python3 -c "import json; d=json.load(open('$VAULT/phase-state.json')); exit(0 if d['currentPhase'] == 'L2' else 1)" 2>/dev/null \
  && pass_test "Phase is now L2" || fail_test "Phase is now L2"

python3 -c "import json; d=json.load(open('$VAULT/phase-state.json')); exit(0 if d['phaseName'] == 'Presence' else 1)" 2>/dev/null \
  && pass_test "Phase name is Presence" || fail_test "Phase name is Presence"

python3 -c "
import json
d = json.load(open('$VAULT/phase-state.json'))
transitions = [h for h in d.get('history', []) if h.get('type') == 'transition']
l1l2 = [t for t in transitions if t.get('fromPhase') == 'L1' and t.get('toPhase') == 'L2']
exit(0 if len(l1l2) >= 1 else 1)
" 2>/dev/null && pass_test "L1→L2 transition in history" || fail_test "L1→L2 transition in history"

python3 -c "
import json
d = json.load(open('$VAULT/phase-state.json'))
transitions = [h for h in d.get('history', []) if h.get('type') == 'transition']
exit(0 if len(transitions) >= 2 else 1)
" 2>/dev/null && pass_test "Two transitions total in history" || fail_test "Two transitions total in history"

echo ""

# -----------------------------------------------------------------------
# Phase 10: Status mode shows full history
# -----------------------------------------------------------------------
echo "Phase 10: Status shows complete journey"

OUTPUT=$(python3 "$TRANSITION" --status "$VAULT" --config "$CONFIG" 2>&1) || true

echo "$OUTPUT" | grep -q 'L2' && pass_test "Status shows L2" || fail_test "Status shows L2"
echo "$OUTPUT" | grep -q 'Presence' && pass_test "Status shows Presence" || fail_test "Status shows Presence"

echo ""

# -----------------------------------------------------------------------
# Phase 11: Dashboard renders L2 state
# -----------------------------------------------------------------------
echo "Phase 11: Dashboard renders L2 state"

python3 "$DASHBOARD" "$VAULT" "$CONFIG" "$DASH_OUT" "2026-03-28T12:00:00Z" "March 28, 2026 at 12:00" > /dev/null 2>&1

[[ -f "$DASH_OUT" ]] && pass_test "Dashboard generated" || fail_test "Dashboard generated"
grep -q 'L2' "$DASH_OUT" 2>/dev/null && pass_test "Dashboard shows L2" || fail_test "Dashboard shows L2"
grep -q 'Presence' "$DASH_OUT" 2>/dev/null && pass_test "Dashboard shows Presence" || fail_test "Dashboard shows Presence"
[[ $(wc -c < "$DASH_OUT") -gt 5000 ]] && pass_test "Dashboard is non-trivial HTML" || fail_test "Dashboard is non-trivial HTML"
grep -qi 'gate\|criteria\|progress' "$DASH_OUT" 2>/dev/null && pass_test "Dashboard contains gate section" || fail_test "Dashboard contains gate section"

echo ""

# -----------------------------------------------------------------------
# Phase 12: Vault state consistency
# -----------------------------------------------------------------------
echo "Phase 12: Vault state consistency"

python3 -c "
import json
d = json.load(open('$VAULT/phase-state.json'))
assert d.get('gateResults') is not None
assert len(d['gateResults']) > 0
" 2>/dev/null && pass_test "Phase-state has gateResults" || fail_test "Phase-state has gateResults"

python3 -c "
import json
d = json.load(open('$VAULT/phase-state.json'))
transitions = [h for h in d.get('history', []) if h.get('type') == 'transition']
phases = [(t['fromPhase'], t['toPhase']) for t in transitions]
assert phases == [('L0', 'L1'), ('L1', 'L2')]
" 2>/dev/null && pass_test "Phase-state history is ordered" || fail_test "Phase-state history is ordered"

python3 -c "import json; d=json.load(open('$VAULT/onboarding-state.json')); exit(0 if d['status'] == 'complete' else 1)" 2>/dev/null \
  && pass_test "Onboarding data survived transitions" || fail_test "Onboarding data survived transitions"

python3 -c "import json; d=json.load(open('$VAULT/founder-profile.json')); exit(0 if d['personalInfo']['name'] is not None else 1)" 2>/dev/null \
  && pass_test "Founder profile survived transitions" || fail_test "Founder profile survived transitions"

python3 -c "import json; d=json.load(open('$VAULT/business/direction.json')); exit(0 if d.get('direction') is not None else 1)" 2>/dev/null \
  && pass_test "Business direction survived transitions" || fail_test "Business direction survived transitions"

python3 -c "import json; d=json.load(open('$VAULT/business/brand-brief.json')); exit(0 if d.get('brandName') is not None else 1)" 2>/dev/null \
  && pass_test "Brand brief survived transitions" || fail_test "Brand brief survived transitions"

python3 -c "
import os
reports = [f for f in os.listdir('$VAULT/research') if f.endswith('.json')]
exit(0 if len(reports) >= 1 else 1)
" 2>/dev/null && pass_test "Research reports survived transitions" || fail_test "Research reports survived transitions"

echo ""

# -----------------------------------------------------------------------
# Phase 13: Reset capabilities
# -----------------------------------------------------------------------
echo "Phase 13: Reset capabilities"

python3 "$TEMPLATE" --reset "$VAULT" --project "$PROJECT_ROOT" > /dev/null 2>&1

python3 -c "import json; d=json.load(open('$VAULT/business/direction.json')); exit(0 if d.get('direction') is None else 1)" 2>/dev/null \
  && pass_test "Template reset clears direction" || fail_test "Template reset clears direction"

python3 -c "import json; d=json.load(open('$VAULT/business/brand-brief.json')); exit(0 if d.get('brandName') is None else 1)" 2>/dev/null \
  && pass_test "Template reset clears brand" || fail_test "Template reset clears brand"

python3 "$SIM" --reset "$VAULT" > /dev/null 2>&1

python3 -c "import json; d=json.load(open('$VAULT/founder-profile.json')); exit(0 if d['personalInfo']['name'] is None else 1)" 2>/dev/null \
  && pass_test "Onboarding reset clears profile" || fail_test "Onboarding reset clears profile"

python3 -c "import json; d=json.load(open('$VAULT/onboarding-state.json')); exit(0 if d['status'] == 'not-started' else 1)" 2>/dev/null \
  && pass_test "Onboarding reset clears status" || fail_test "Onboarding reset clears status"

echo ""

# -----------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------

if [[ $FAIL -eq 0 ]]; then
  echo -e "\033[0;32mLifecycle integration smoke test: $PASS/$TOTAL passed\033[0m"
else
  echo -e "\033[0;31mLifecycle integration smoke test: $PASS/$TOTAL passed, $FAIL FAILED\033[0m"
  exit 1
fi
