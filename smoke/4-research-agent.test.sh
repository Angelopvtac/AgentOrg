#!/usr/bin/env bash
set -euo pipefail

# Smoke test: Research agent workspace — validates L1 agent is fully configured,
# registered in gateway, wired into orchestrator routing, and vault structure ready.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0
TOTAL=0

pass() { PASS=$((PASS + 1)); TOTAL=$((TOTAL + 1)); echo "  [PASS] $1"; }
fail() { FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  [FAIL] $1"; }
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi; }

echo "=== Smoke Test: Research Agent Workspace ==="
echo ""

# -----------------------------------------------------------------------
# Phase 1: Workspace file existence and structure
# -----------------------------------------------------------------------
echo "Phase 1: Workspace files exist"

WS="$PROJECT_ROOT/agents/research/workspace"

check "AGENTS.md exists" "[[ -f '$WS/AGENTS.md' ]]"
check "SOUL.md exists" "[[ -f '$WS/SOUL.md' ]]"
check "IDENTITY.md exists" "[[ -f '$WS/IDENTITY.md' ]]"
check "TOOLS.md exists" "[[ -f '$WS/TOOLS.md' ]]"
check "HEARTBEAT.md exists" "[[ -f '$WS/HEARTBEAT.md' ]]"
check "USER.md exists" "[[ -f '$WS/USER.md' ]]"
check "memory/ directory exists" "[[ -d '$WS/memory' ]]"

echo ""

# -----------------------------------------------------------------------
# Phase 2: Workspace content — key sections present
# -----------------------------------------------------------------------
echo "Phase 2: AGENTS.md has required sections"

check "AGENTS.md defines role" "grep -q 'market research' '$WS/AGENTS.md'"
check "AGENTS.md references L1 phase" "grep -q 'L1' '$WS/AGENTS.md'"
check "AGENTS.md has market scan workflow" "grep -q 'Market Scan' '$WS/AGENTS.md'"
check "AGENTS.md has direction analysis" "grep -q 'Direction Deep-Dive' '$WS/AGENTS.md'"
check "AGENTS.md has brand brief support" "grep -q 'Brand Brief' '$WS/AGENTS.md'"
check "AGENTS.md has research report format" "grep -q 'vault/research/' '$WS/AGENTS.md'"
check "AGENTS.md references orchestrator messaging" "grep -q 'agent:orchestrator:main' '$WS/AGENTS.md'"
check "AGENTS.md has anti-injection directive" "grep -q 'Anti-Injection' '$WS/AGENTS.md'"
check "AGENTS.md references L1 gate criteria" "grep -q 'direction-selected' '$WS/AGENTS.md'"
check "AGENTS.md references market-research-done criterion" "grep -q 'market-research-done' '$WS/AGENTS.md'"

echo ""

# -----------------------------------------------------------------------
# Phase 3: SOUL.md and IDENTITY.md
# -----------------------------------------------------------------------
echo "Phase 3: Identity and personality"

check "IDENTITY.md has agent ID 'research'" "grep -q 'research' '$WS/IDENTITY.md'"
check "IDENTITY.md specifies L1 activation" "grep -q 'L1' '$WS/IDENTITY.md'"
check "SOUL.md defines rigorous trait" "grep -q 'Rigorous' '$WS/SOUL.md'"
check "SOUL.md defines skeptical trait" "grep -q 'Skeptical' '$WS/SOUL.md'"
check "SOUL.md defines founder-aware trait" "grep -q 'Founder-aware' '$WS/SOUL.md'"
check "SOUL.md has confidence levels" "grep -q 'confidence' '$WS/SOUL.md'"
check "SOUL.md has boundaries" "grep -q 'Boundaries' '$WS/SOUL.md'"

echo ""

# -----------------------------------------------------------------------
# Phase 4: TOOLS.md — permissions model
# -----------------------------------------------------------------------
echo "Phase 4: Tool permissions"

check "TOOLS.md grants web_search" "grep -q 'web_search' '$WS/TOOLS.md'"
check "TOOLS.md grants web_fetch" "grep -q 'web_fetch' '$WS/TOOLS.md'"
check "TOOLS.md write access to vault/research/" "grep -q 'vault/research/' '$WS/TOOLS.md'"
check "TOOLS.md write access to vault/business/direction.json" "grep -q 'vault/business/direction.json' '$WS/TOOLS.md'"
check "TOOLS.md read access to founder-profile" "grep -q 'vault/founder-profile.json' '$WS/TOOLS.md'"
check "TOOLS.md references knowledge graph skill" "grep -q 'knowledge-graph' '$WS/TOOLS.md'"
check "TOOLS.md references progression engine skill" "grep -q 'progression-engine' '$WS/TOOLS.md'"
check "TOOLS.md restricts exec to none" "grep -q 'exec.*none' '$WS/TOOLS.md'"

echo ""

# -----------------------------------------------------------------------
# Phase 5: Gateway registration (openclaw.json)
# -----------------------------------------------------------------------
echo "Phase 5: Gateway configuration"

OCFILE="$PROJECT_ROOT/config/openclaw.json"

# Strip JSON5 comments and trailing commas, then validate
check "Research agent registered in openclaw.json" "python3 -c \"
import re, json, sys
with open(sys.argv[1]) as f:
    text = f.read()
text = re.sub(r'(?<![:\\\"\w])//.*', '', text)
text = re.sub(r',\s*([}\]])', r'\1', text)
data = json.loads(text)
agents = {a['id'] for a in data['agents']['list']}
assert 'research' in agents, 'research agent not in agent list'
\" '$OCFILE'"

check "Research agent has Sonnet as primary model" "python3 -c \"
import re, json, sys
with open(sys.argv[1]) as f:
    text = f.read()
text = re.sub(r'(?<![:\\\"\w])//.*', '', text)
text = re.sub(r',\s*([}\]])', r'\1', text)
data = json.loads(text)
agents = {a['id']: a for a in data['agents']['list']}
assert 'sonnet' in agents['research']['model']['primary'].lower()
\" '$OCFILE'"

check "Research agent has 360m heartbeat" "python3 -c \"
import re, json, sys
with open(sys.argv[1]) as f:
    text = f.read()
text = re.sub(r'(?<![:\\\"\w])//.*', '', text)
text = re.sub(r',\s*([}\]])', r'\1', text)
data = json.loads(text)
agents = {a['id']: a for a in data['agents']['list']}
assert agents['research']['heartbeat']['every'] == '360m'
\" '$OCFILE'"

check "Research agent in agentToAgent allow list" "python3 -c \"
import re, json, sys
with open(sys.argv[1]) as f:
    text = f.read()
text = re.sub(r'(?<![:\\\"\w])//.*', '', text)
text = re.sub(r',\s*([}\]])', r'\1', text)
data = json.loads(text)
assert 'research' in data['tools']['agentToAgent']['allow']
\" '$OCFILE'"

echo ""

# -----------------------------------------------------------------------
# Phase 6: Docker volume mount
# -----------------------------------------------------------------------
echo "Phase 6: Docker configuration"

DCFILE="$PROJECT_ROOT/docker-compose.yml"

check "Research workspace volume mounted in docker-compose.yml" "grep -q 'workspace-research' '$DCFILE'"
check "Research workspace mount maps to agents/research/workspace" "grep -q 'agents/research/workspace' '$DCFILE'"

echo ""

# -----------------------------------------------------------------------
# Phase 7: Orchestrator integration
# -----------------------------------------------------------------------
echo "Phase 7: Orchestrator awareness"

ORCH_AGENTS="$PROJECT_ROOT/agents/orchestrator/workspace/AGENTS.md"
ORCH_TOOLS="$PROJECT_ROOT/agents/orchestrator/workspace/TOOLS.md"

check "Orchestrator AGENTS.md has L1 routing for research" "grep -q 'agent:research:main' '$ORCH_AGENTS'"
check "Orchestrator AGENTS.md has L1 agent table" "grep -q 'L1 (Discovery)' '$ORCH_AGENTS'"
check "Orchestrator TOOLS.md has research agent target" "grep -q 'agent:research:main' '$ORCH_TOOLS'"
check "Orchestrator TOOLS.md has vault/research read access" "grep -q 'vault/research' '$ORCH_TOOLS'"

echo ""

# -----------------------------------------------------------------------
# Phase 8: Vault structure for L1
# -----------------------------------------------------------------------
echo "Phase 8: L1 vault structure"

check "knowledge/research/ directory exists" "[[ -d '$PROJECT_ROOT/knowledge/research' ]]"
check "knowledge/business/ directory exists" "[[ -d '$PROJECT_ROOT/knowledge/business' ]]"
check "knowledge/business/direction.json exists" "[[ -f '$PROJECT_ROOT/knowledge/business/direction.json' ]]"
check "knowledge/business/brand-brief.json exists" "[[ -f '$PROJECT_ROOT/knowledge/business/brand-brief.json' ]]"

echo ""

# -----------------------------------------------------------------------
# Phase 9: Progression.json coherence — L1 lists research agent
# -----------------------------------------------------------------------
echo "Phase 9: Progression system coherence"

check "progression.json L1 includes research agent" "python3 -c \"
import json, sys
d = json.load(open(sys.argv[1]))
assert 'research' in d['phases']['L1']['agents']
\" '$PROJECT_ROOT/config/progression.json'"

check "progression.json L1 has 3 gate criteria" "python3 -c \"
import json, sys
d = json.load(open(sys.argv[1]))
assert len(d['phases']['L1']['gate']['criteria']) == 3
\" '$PROJECT_ROOT/config/progression.json'"

check "L1 gate includes market-research-done" "python3 -c \"
import json, sys
d = json.load(open(sys.argv[1]))
ids = [c['id'] for c in d['phases']['L1']['gate']['criteria']]
assert 'market-research-done' in ids
\" '$PROJECT_ROOT/config/progression.json'"

echo ""

# -----------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------
echo "Research agent smoke test: $PASS/$TOTAL passed"
if [[ $FAIL -gt 0 ]]; then
    echo "FAILURES: $FAIL"
    exit 1
fi
exit 0
