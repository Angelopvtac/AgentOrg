#!/usr/bin/env bash
set -euo pipefail

# Smoke test: Founder Dashboard generation
# Tests both empty state (fresh install) and populated state (mid-onboarding)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0
TOTAL=0

pass() { PASS=$((PASS + 1)); TOTAL=$((TOTAL + 1)); echo "  [PASS] $1"; }
fail() { FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  [FAIL] $1"; }
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi; }

echo "=== Smoke Test: Founder Dashboard ==="
echo ""

# --- Test 1: Generate from real vault (empty/fresh state) ---
echo "Phase 1: Empty state dashboard"

OUTPUT_EMPTY="$SCRIPT_DIR/.test-output-empty.html"
trap 'rm -rf "$SCRIPT_DIR/.test-output-"* "$SCRIPT_DIR/.test-vault-"*' EXIT

bash "$PROJECT_ROOT/scripts/generate-dashboard.sh" \
  "$PROJECT_ROOT/knowledge" \
  "$OUTPUT_EMPTY" > /dev/null 2>&1

check "Dashboard file generated" "[[ -f '$OUTPUT_EMPTY' ]]"
check "File is non-empty" "[[ -s '$OUTPUT_EMPTY' ]]"
check "Valid HTML structure" "grep -q '<!DOCTYPE html>' '$OUTPUT_EMPTY'"
check "Contains phase L0" "grep -q 'Phase L0' '$OUTPUT_EMPTY'"
check "Shows Onboarding phase name" "grep -q 'Onboarding' '$OUTPUT_EMPTY'"
check "Shows gate progress (0/6)" "grep -q '0/6 criteria met' '$OUTPUT_EMPTY'"
check "Shows onboarding progress (0/9)" "grep -q '0/9 sections complete' '$OUTPUT_EMPTY'"
check "Shows budget section" "grep -q 'Daily Budget' '$OUTPUT_EMPTY'"
check "Shows treasury section" "grep -q 'Treasury' '$OUTPUT_EMPTY'"
check "Shows empty tasks state" "grep -q 'No pending tasks' '$OUTPUT_EMPTY'"
check "Shows knowledge sections" "grep -q 'Decisions' '$OUTPUT_EMPTY' && grep -q 'Insights' '$OUTPUT_EMPTY' && grep -q 'Lessons' '$OUTPUT_EMPTY'"
check "Shows empty knowledge state" "grep -q 'No decisions recorded yet' '$OUTPUT_EMPTY'"
check "Shows briefing section" "grep -q 'Daily Briefing' '$OUTPUT_EMPTY'"
check "Shows footer with version" "grep -q 'AgentOrg v0.3.0' '$OUTPUT_EMPTY'"
check "Responsive meta viewport" "grep -q 'viewport' '$OUTPUT_EMPTY'"

echo ""

# --- Test 2: Generate from simulated populated vault ---
echo "Phase 2: Populated state dashboard"

VAULT_DIR="$SCRIPT_DIR/.test-vault-populated"
mkdir -p "$VAULT_DIR/economics" "$VAULT_DIR/business" "$VAULT_DIR/metrics"

# Simulated phase state — still L0 but partially progressed
cat > "$VAULT_DIR/phase-state.json" << 'EOF'
{
  "currentPhase": "L0",
  "phaseName": "Onboarding",
  "phaseStartDate": "2026-03-15T00:00:00Z",
  "lastGateEvaluation": "2026-03-27T12:00:00Z",
  "gateResults": {},
  "history": []
}
EOF

# Founder with partial data filled in
cat > "$VAULT_DIR/founder-profile.json" << 'EOF'
{
  "personalInfo": {
    "name": "Elena Marchetti",
    "timezone": "Europe/Rome",
    "communicationStyle": "concise"
  },
  "skills": ["product strategy", "data analysis", "content writing", "UX research"],
  "availability": {
    "weeklyHours": 15,
    "quietHours": {"start": "22:00", "end": "08:00"}
  },
  "financial": {
    "riskTolerance": "moderate",
    "monthlyBudget": 150
  },
  "goals": ["Launch a micro-SaaS for freelance writers"],
  "preferences": {},
  "vision": {
    "statement": "Build an AI-powered writing assistant that helps freelance writers pitch to publications more effectively, starting with automated pitch letter generation and market research."
  }
}
EOF

# Onboarding: 7 of 9 complete
cat > "$VAULT_DIR/onboarding-state.json" << 'EOF'
{
  "status": "in-progress",
  "startedAt": "2026-03-15T10:00:00Z",
  "completedAt": null,
  "lastUpdated": "2026-03-27T16:30:00Z",
  "sections": {
    "welcome": {"status": "complete", "completedAt": "2026-03-15T10:05:00Z"},
    "personal": {"status": "complete", "completedAt": "2026-03-15T10:20:00Z"},
    "skills": {"status": "complete", "completedAt": "2026-03-15T10:35:00Z"},
    "availability": {"status": "complete", "completedAt": "2026-03-16T09:00:00Z"},
    "financial": {"status": "complete", "completedAt": "2026-03-16T09:15:00Z"},
    "goals": {"status": "complete", "completedAt": "2026-03-20T14:00:00Z"},
    "preferences": {"status": "complete", "completedAt": "2026-03-20T14:30:00Z"},
    "vision": {"status": "in-progress", "completedAt": null},
    "review": {"status": "pending", "completedAt": null}
  },
  "currentSection": "vision"
}
EOF

# Budget with some spend
cat > "$VAULT_DIR/economics/daily-budget.json" << 'EOF'
{
  "dailyLimit": 5.00,
  "currency": "USD",
  "currentDate": "2026-03-27",
  "spent": 2.34,
  "breakdown": {"tier1": 0.12, "tier2": 1.87, "tier3": 0.35},
  "alerts": {"warnAt": 0.80, "pauseAt": 1.00, "killSwitchAt": 2.00},
  "history": []
}
EOF

cat > "$VAULT_DIR/economics/treasury.json" << 'EOF'
{"balance": -12.50, "totalRevenue": 0.00, "totalCosts": 12.50, "revenueToExpenseRatio": 0, "netMargin": 0, "lastUpdated": "2026-03-27T23:59:00Z"}
EOF
cat > "$VAULT_DIR/economics/costs.json" << 'EOF'
{"collection": "costs", "entries": []}
EOF
cat > "$VAULT_DIR/economics/revenue.json" << 'EOF'
{"collection": "revenue", "entries": []}
EOF

# Human tasks with entries
cat > "$VAULT_DIR/human-tasks.json" << 'EOF'
{
  "tasks": [
    {"title": "Connect Discord server for team communication", "description": "Set up a Discord server and share the invite link with the system.", "priority": "high", "status": "pending"},
    {"title": "Review brand brief draft", "description": "The AI has prepared a preliminary brand brief based on your vision — review and approve it.", "priority": "medium", "status": "pending"}
  ],
  "stats": {"totalCreated": 3, "totalCompleted": 1, "totalCancelled": 0}
}
EOF

# Knowledge with entries
cat > "$VAULT_DIR/decisions.json" << 'EOF'
{
  "collection": "decisions",
  "entries": [
    {"id": "d-001", "title": "Target freelance writers as primary audience", "date": "2026-03-20", "tags": ["market", "audience"]},
    {"id": "d-002", "title": "Use subscription pricing model at $19/month", "date": "2026-03-22", "tags": ["pricing", "revenue"]}
  ]
}
EOF
cat > "$VAULT_DIR/insights.json" << 'EOF'
{
  "collection": "insights",
  "entries": [
    {"id": "i-001", "title": "Pitch letter market has 40K active freelancers in US alone", "date": "2026-03-21", "tags": ["market-size"]}
  ]
}
EOF
cat > "$VAULT_DIR/lessons.json" << 'EOF'
{"collection": "lessons", "entries": []}
EOF

cat > "$VAULT_DIR/briefing-state.json" << 'EOF'
{
  "lastBriefingSent": "2026-03-27T08:00:00Z",
  "lastBriefingContent": null,
  "briefingHistory": [{"date": "2026-03-26"}, {"date": "2026-03-27"}]
}
EOF

cat > "$VAULT_DIR/business/direction.json" << 'EOF'
{"direction": null}
EOF
cat > "$VAULT_DIR/business/brand-brief.json" << 'EOF'
{"brandName": null}
EOF
cat > "$VAULT_DIR/metrics/social.json" << 'EOF'
{}
EOF

OUTPUT_POP="$SCRIPT_DIR/.test-output-populated.html"

bash "$PROJECT_ROOT/scripts/generate-dashboard.sh" \
  "$VAULT_DIR" \
  "$OUTPUT_POP" > /dev/null 2>&1

check "Populated dashboard generated" "[[ -f '$OUTPUT_POP' ]]"
check "Shows 5/6 gate criteria passing" "grep -q '5/6 criteria met' '$OUTPUT_POP'"
check "Shows 7/9 onboarding progress" "grep -q '7/9 sections complete' '$OUTPUT_POP'"
check "Shows budget spent \$2.34" "grep -q '\$2.34' '$OUTPUT_POP'"
check "Shows tier breakdown" "grep -q '\$1.87' '$OUTPUT_POP'"
check "Shows negative treasury balance" "grep -q 'negative' '$OUTPUT_POP'"
check "Shows human tasks (not empty)" "! grep -q 'No pending tasks' '$OUTPUT_POP'"
check "Shows task title" "grep -q 'Connect Discord server' '$OUTPUT_POP'"
check "Shows task priority badge" "grep -q 'high' '$OUTPUT_POP'"
check "Shows decision entries" "grep -q 'Target freelance writers' '$OUTPUT_POP'"
check "Shows insight entries" "grep -q 'Pitch letter market' '$OUTPUT_POP'"
check "Shows empty lessons state" "grep -q 'No lessons recorded yet' '$OUTPUT_POP'"
check "Shows last briefing date" "grep -q '2026-03-27' '$OUTPUT_POP'"
check "Shows briefing count" "grep -q '2 total' '$OUTPUT_POP'"
check "Phase start date shown" "grep -q '2026-03-15' '$OUTPUT_POP'"

echo ""

# --- Test 3: Script exits on missing knowledge dir ---
echo "Phase 3: Error handling"

check "Fails on missing knowledge dir" "! bash '$PROJECT_ROOT/scripts/generate-dashboard.sh' /nonexistent/path /dev/null 2>/dev/null"

echo ""

# --- Summary ---
echo "==========================================="
echo "  Dashboard smoke test: $PASS/$TOTAL passed"
if [[ $FAIL -gt 0 ]]; then
  echo "  $FAIL FAILURES"
  echo "==========================================="
  exit 1
fi
echo "==========================================="
exit 0
