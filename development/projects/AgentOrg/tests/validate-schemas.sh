#!/usr/bin/env bash
# Validate knowledge/*.json files are valid JSON and match expected structure.

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

check_json() {
    local file="$1"
    local label="$2"
    if [ ! -f "$file" ]; then
        fail "$label — file not found"
        return 1
    fi
    if python3 -m json.tool "$file" >/dev/null 2>&1; then
        pass "$label — valid JSON"
        return 0
    else
        fail "$label — invalid JSON"
        return 1
    fi
}

echo "=== Schema Validation (knowledge/) ==="
echo ""

# --- Validate all knowledge JSON files parse ---
echo "JSON validity:"
for f in "$PROJECT_DIR"/knowledge/*.json "$PROJECT_DIR"/knowledge/**/*.json; do
    [ -f "$f" ] || continue
    rel="${f#"$PROJECT_DIR"/}"
    check_json "$f" "$rel"
done

# --- Validate knowledge collections structure ---
echo ""
echo "Knowledge collection structure:"
for collection in decisions insights lessons; do
    FILE="$PROJECT_DIR/knowledge/$collection.json"
    if [ ! -f "$FILE" ]; then
        fail "$collection.json — not found"
        continue
    fi
    if python3 -c "
import json, sys
d = json.load(open('$FILE'))
assert 'collection' in d, 'missing collection field'
assert 'entries' in d, 'missing entries field'
assert isinstance(d['entries'], list), 'entries is not an array'
" 2>/dev/null; then
        pass "$collection.json — has 'collection' and 'entries' array"
    else
        fail "$collection.json — missing required structure (collection, entries)"
    fi
done

# --- Validate human-tasks.json structure ---
echo ""
echo "Human tasks structure:"
HT_FILE="$PROJECT_DIR/knowledge/human-tasks.json"
if [ ! -f "$HT_FILE" ]; then
    fail "human-tasks.json — not found"
else
    if python3 -c "
import json, sys
d = json.load(open('$HT_FILE'))
assert 'tasks' in d, 'missing tasks'
assert 'stats' in d, 'missing stats'
assert isinstance(d['tasks'], list), 'tasks is not an array'
for key in ['totalCreated', 'totalCompleted', 'totalCancelled']:
    assert key in d['stats'], f'missing stats.{key}'
" 2>/dev/null; then
        pass "human-tasks.json — has 'tasks' array and 'stats' with required counters"
    else
        fail "human-tasks.json — missing required structure"
    fi
fi

# --- Validate phase-state.json ---
echo ""
echo "Phase state structure:"
PS_FILE="$PROJECT_DIR/knowledge/phase-state.json"
if [ ! -f "$PS_FILE" ]; then
    fail "phase-state.json — not found"
else
    if python3 -c "
import json
d = json.load(open('$PS_FILE'))
assert 'currentPhase' in d, 'missing currentPhase'
" 2>/dev/null; then
        pass "phase-state.json — has 'currentPhase'"
    else
        fail "phase-state.json — missing 'currentPhase'"
    fi
fi

# --- Validate founder-profile.json ---
echo ""
echo "Founder profile structure:"
FP_FILE="$PROJECT_DIR/knowledge/founder-profile.json"
if [ ! -f "$FP_FILE" ]; then
    fail "founder-profile.json — not found"
else
    if python3 -c "
import json
d = json.load(open('$FP_FILE'))
# File may be a template with null values, just check it's a dict
assert isinstance(d, dict), 'not a JSON object'
" 2>/dev/null; then
        pass "founder-profile.json — valid object"
    else
        fail "founder-profile.json — not a valid JSON object"
    fi
fi

# --- Validate daily-budget.json ---
echo ""
echo "Economics structure:"
DB_FILE="$PROJECT_DIR/knowledge/economics/daily-budget.json"
if [ ! -f "$DB_FILE" ]; then
    fail "economics/daily-budget.json — not found"
else
    if python3 -c "
import json
d = json.load(open('$DB_FILE'))
assert 'dailyLimit' in d, 'missing dailyLimit'
" 2>/dev/null; then
        pass "economics/daily-budget.json — has 'dailyLimit'"
    else
        fail "economics/daily-budget.json — missing 'dailyLimit'"
    fi
fi

# --- Summary ---
echo ""
TOTAL=$((PASS + FAIL))
echo "Schema validation: $PASS/$TOTAL passed"
exit "$FAIL"
