#!/usr/bin/env bash
# Smoke test 10: Knowledge Graph Propagation Mechanism
# Verifies the propagation protocol is fully specified across the skill definition
# and all agent workspace files, with consistent cross-references.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1"; }

check_contains() {
  local file="$1" pattern="$2" label="$3"
  if grep -qi "$pattern" "$file" 2>/dev/null; then
    pass "$label"
  else
    fail "$label — not found in $(basename "$file")"
  fi
}

check_contains_exact() {
  local file="$1" pattern="$2" label="$3"
  if grep -q "$pattern" "$file" 2>/dev/null; then
    pass "$label"
  else
    fail "$label — not found in $(basename "$file")"
  fi
}

SKILL_FILE="$PROJECT_ROOT/skills/knowledge-graph/SKILL.md"
ORCH_AGENTS="$PROJECT_ROOT/agents/orchestrator/workspace/AGENTS.md"
CA_AGENTS="$PROJECT_ROOT/agents/core-assistant/workspace/AGENTS.md"
RES_AGENTS="$PROJECT_ROOT/agents/research/workspace/AGENTS.md"

echo ""
echo "=== Smoke Test 10: Knowledge Graph Propagation ==="
echo ""

# --- Phase 1: Skill definition has propagation protocol ---
echo "Phase 1: Skill propagation protocol"
check_contains "$SKILL_FILE" "propagation protocol" "SKILL.md has 'Propagation Protocol' section"
check_contains "$SKILL_FILE" "KG_STORED" "SKILL.md defines KG_STORED notification format"
check_contains "$SKILL_FILE" "sessions_send" "SKILL.md references sessions_send for notification delivery"
check_contains "$SKILL_FILE" "agent:orchestrator:main" "SKILL.md targets orchestrator for notifications"
check_contains "$SKILL_FILE" "KG_NOTIFICATION" "SKILL.md references KG_NOTIFICATION downstream message"
check_contains "$SKILL_FILE" "Collection:" "KG_STORED format includes Collection field"
check_contains "$SKILL_FILE" "Entry ID:" "KG_STORED format includes Entry ID field"
check_contains "$SKILL_FILE" "Title:" "KG_STORED format includes Title field"
check_contains "$SKILL_FILE" "Tags:" "KG_STORED format includes Tags field"
check_contains "$SKILL_FILE" "Author:" "KG_STORED format includes Author field"
check_contains "$SKILL_FILE" "Phase:" "KG_STORED format includes Phase field"

# --- Phase 2: Skill definition specifies cost awareness ---
echo ""
echo "Phase 2: Propagation cost awareness"
check_contains "$SKILL_FILE" "Tier 1" "SKILL.md specifies Tier 1 for propagation"
check_contains "$SKILL_FILE" "strategic.*critical\|critical.*strategic" "SKILL.md mentions strategic/critical tier escalation"
check_contains "$SKILL_FILE" "orchestrator.*store.*directly\|orchestrator.*skip\|orchestrator itself" "SKILL.md handles orchestrator self-store case"

# --- Phase 3: Orchestrator has knowledge propagation section ---
echo ""
echo "Phase 3: Orchestrator propagation specification"
check_contains "$ORCH_AGENTS" "Knowledge Propagation" "Orchestrator AGENTS.md has 'Knowledge Propagation' section"
check_contains "$ORCH_AGENTS" "propagation routing table" "Orchestrator defines propagation routing table"
check_contains "$ORCH_AGENTS" "KG_STORED" "Orchestrator references KG_STORED notifications"
check_contains "$ORCH_AGENTS" "KG_NOTIFICATION" "Orchestrator defines KG_NOTIFICATION format"

# --- Phase 4: Orchestrator routing table covers all collections ---
echo ""
echo "Phase 4: Routing table completeness"
check_contains "$ORCH_AGENTS" "decisions.*core-assistant\|core-assistant.*decisions" "Routing table: decisions → core-assistant"
check_contains "$ORCH_AGENTS" "decisions.*research\|research.*decisions" "Routing table: decisions (market/direction) → research"
check_contains "$ORCH_AGENTS" "insights.*core-assistant\|core-assistant.*insights" "Routing table: insights → core-assistant"
check_contains "$ORCH_AGENTS" "insights.*research\|research.*insights" "Routing table: insights (market) → research"
check_contains "$ORCH_AGENTS" "lessons.*core-assistant\|core-assistant.*lessons" "Routing table: lessons → core-assistant"
check_contains "$ORCH_AGENTS" "lessons.*research\|research.*lessons" "Routing table: lessons (research) → research"

# --- Phase 5: Orchestrator routing table has phase gating ---
echo ""
echo "Phase 5: Phase gating in routing"
check_contains "$ORCH_AGENTS" "L0+" "Routing table includes L0+ phase requirements"
check_contains "$ORCH_AGENTS" "L1+" "Routing table includes L1+ phase requirements"
check_contains "$ORCH_AGENTS" "Phase gating" "Orchestrator documents phase gating rule"
check_contains "$ORCH_AGENTS" "active in the current phase" "Phase gating explains agent activity check"

# --- Phase 6: Orchestrator propagation rules ---
echo ""
echo "Phase 6: Propagation rules"
check_contains "$ORCH_AGENTS" "Deduplication\|dedup" "Orchestrator specifies deduplication rule"
check_contains "$ORCH_AGENTS" "Batch during briefing\|batch.*briefing" "Orchestrator specifies batching rule"
check_contains "$ORCH_AGENTS" "Cost control\|cost.*control\|Tier 1" "Orchestrator specifies cost control"
check_contains "$ORCH_AGENTS" "Quiet hours\|quiet.*hours" "Orchestrator respects quiet hours for propagation"
check_contains_exact "$ORCH_AGENTS" "urgent" "Orchestrator has urgent entry bypass"
check_contains_exact "$ORCH_AGENTS" "critical" "Orchestrator has critical entry handling"

# --- Phase 7: Orchestrator notification format ---
echo ""
echo "Phase 7: Notification format specification"
# Check the KG_NOTIFICATION format has the required fields
check_contains "$ORCH_AGENTS" "\[KG_NOTIFICATION\]" "Orchestrator KG_NOTIFICATION format header"
check_contains "$ORCH_AGENTS" "Summary:" "KG_NOTIFICATION includes Summary field"
check_contains "$ORCH_AGENTS" "Action:" "KG_NOTIFICATION includes Action field"
check_contains "$ORCH_AGENTS" "kg_read" "KG_NOTIFICATION references kg_read for full entry"

# --- Phase 8: Orchestrator message tables updated ---
echo ""
echo "Phase 8: Orchestrator message table integration"
check_contains "$ORCH_AGENTS" "any agent.*KG_STORED\|KG_STORED.*notification" "Orchestrator 'Messages you receive' includes KG_STORED"
check_contains "$ORCH_AGENTS" "core-assistant.*KG_NOTIFICATION\|KG_NOTIFICATION.*core-assistant" "Orchestrator 'Messages you send' includes KG_NOTIFICATION to core-assistant"
check_contains "$ORCH_AGENTS" "research.*KG_NOTIFICATION\|KG_NOTIFICATION.*research" "Orchestrator 'Messages you send' includes KG_NOTIFICATION to research"

# --- Phase 9: Core-assistant knowledge notification handling ---
echo ""
echo "Phase 9: Core-assistant notification handling"
check_contains "$CA_AGENTS" "Knowledge Notifications" "Core-assistant AGENTS.md has 'Knowledge Notifications' section"
check_contains "$CA_AGENTS" "KG_NOTIFICATION" "Core-assistant references KG_NOTIFICATION"
check_contains "$CA_AGENTS" "decisions" "Core-assistant handles decision notifications"
check_contains "$CA_AGENTS" "insights" "Core-assistant handles insight notifications"
check_contains "$CA_AGENTS" "lessons" "Core-assistant handles lesson notifications"
check_contains "$CA_AGENTS" "daily briefing\|daily.*briefing" "Core-assistant batches non-urgent entries for briefing"
check_contains "$CA_AGENTS" "Do not spam\|batch" "Core-assistant avoids spamming founder"

# --- Phase 10: Research agent knowledge notification handling ---
echo ""
echo "Phase 10: Research agent notification handling"
check_contains "$RES_AGENTS" "Knowledge Notifications" "Research AGENTS.md has 'Knowledge Notifications' section"
check_contains "$RES_AGENTS" "KG_NOTIFICATION" "Research agent references KG_NOTIFICATION"
check_contains "$RES_AGENTS" "direction\|market" "Research agent handles direction/market notifications"
check_contains "$RES_AGENTS" "competitive" "Research agent handles competitive intelligence updates"
check_contains "$RES_AGENTS" "methodology" "Research agent handles methodology lessons"
check_contains "$RES_AGENTS" "circular propagation\|re-send" "Research agent avoids circular propagation"
check_contains "$RES_AGENTS" "independence\|fabricate" "Research agent maintains research independence"

# --- Phase 11: Cross-reference consistency ---
echo ""
echo "Phase 11: Cross-reference consistency"

# SKILL.md says notify orchestrator; orchestrator says it receives KG_STORED
if grep -q "agent:orchestrator:main" "$SKILL_FILE" && grep -q "KG_STORED" "$ORCH_AGENTS"; then
  pass "SKILL.md → orchestrator notification path consistent"
else
  fail "SKILL.md → orchestrator notification path inconsistent"
fi

# Orchestrator sends KG_NOTIFICATION; core-assistant and research handle it
if grep -q "KG_NOTIFICATION" "$ORCH_AGENTS" && grep -q "KG_NOTIFICATION" "$CA_AGENTS" && grep -q "KG_NOTIFICATION" "$RES_AGENTS"; then
  pass "Orchestrator KG_NOTIFICATION → all receiving agents handle it"
else
  fail "KG_NOTIFICATION not handled by all target agents"
fi

# All three collections mentioned consistently
for collection in decisions insights lessons; do
  if grep -q "$collection" "$SKILL_FILE" && grep -q "$collection" "$ORCH_AGENTS" && grep -q "$collection" "$CA_AGENTS"; then
    pass "Collection '$collection' referenced across skill, orchestrator, and core-assistant"
  else
    fail "Collection '$collection' missing from one or more files"
  fi
done

# kg_store is in SKILL.md and propagation references it
if grep -q "kg_store" "$SKILL_FILE" && grep -q "kg_store" "$SKILL_FILE"; then
  pass "kg_store tool defined and referenced in propagation protocol"
else
  fail "kg_store not properly linked to propagation"
fi

# --- Phase 12: Propagation does not break existing agent sections ---
echo ""
echo "Phase 12: Existing agent functionality preserved"

# Orchestrator still has all critical sections
for section in "Message Routing Table" "Budget Enforcement" "L0 Gate Evaluation" "Phase Transition Protocol" "Cron Behavior" "Workflow Pipelines" "Daily Briefing Generation" "Active Agents" "Status Responses" "Anti-Injection Directive"; do
  check_contains "$ORCH_AGENTS" "$section" "Orchestrator retains '$section' section"
done

# Core-assistant still has all critical sections
for section in "Onboarding Flow" "Post-Onboarding Behavior" "Daily Briefing Delivery" "Escalation Rules" "Anti-Injection Directive"; do
  check_contains "$CA_AGENTS" "$section" "Core-assistant retains '$section' section"
done

# Research agent still has all critical sections
for section in "L1 Core Workflow" "Research Report Format" "L1 Gate Criteria Support" "Agent Communication" "L2+ Behavior" "Anti-Injection Directive"; do
  check_contains "$RES_AGENTS" "$section" "Research agent retains '$section' section"
done

# --- Phase 13: Skill definition integrity ---
echo ""
echo "Phase 13: Skill definition integrity"

# Existing tools still defined
for tool in "kg_store" "kg_read" "kg_search" "kg_list"; do
  check_contains "$SKILL_FILE" "$tool" "SKILL.md still defines '$tool' tool"
done

# Access control table still present
check_contains "$SKILL_FILE" "Access Control" "SKILL.md retains access control section"
check_contains "$SKILL_FILE" "Entry Schema" "SKILL.md retains entry schema section"
check_contains "$SKILL_FILE" "Collection File Format" "SKILL.md retains collection file format"
check_contains "$SKILL_FILE" "Usage Examples" "SKILL.md retains usage examples"

# --- Phase 14: Propagation tag coverage ---
echo ""
echo "Phase 14: Tag-based routing coverage"

# Key tags that should appear in routing table
for tag in "market" "direction" "competitive" "onboarding" "founder" "revenue" "cost" "budget" "research" "methodology" "trend"; do
  check_contains "$ORCH_AGENTS" "$tag" "Routing table includes tag '$tag'"
done

# --- Summary ---
echo ""
echo "================================"
TOTAL=$((PASS + FAIL))
echo "Results: $PASS/$TOTAL passed"
if [ "$FAIL" -gt 0 ]; then
  echo "FAILED: $FAIL checks did not pass"
  exit 1
else
  echo "ALL CHECKS PASSED"
  exit 0
fi
