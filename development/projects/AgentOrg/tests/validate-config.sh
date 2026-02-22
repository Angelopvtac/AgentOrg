#!/usr/bin/env bash
# Validate all JSON config files parse correctly and have required fields.

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
    local label="${2:-$file}"
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

check_field() {
    local file="$1"
    local field="$2"
    local label="$3"
    if python3 -c "import json,sys; d=json.load(open('$file')); assert $field" 2>/dev/null; then
        pass "$label"
    else
        fail "$label"
    fi
}

echo "=== Config Validation ==="
echo ""

# --- openclaw.json (JSON5 — validate with python3 manually) ---
echo "openclaw.json:"
OCFILE="$PROJECT_DIR/config/openclaw.json"
if [ ! -f "$OCFILE" ]; then
    fail "openclaw.json — file not found"
else
    # JSON5 has comments, strip them and validate
    if python3 -c "
import re, json, sys
with open('$OCFILE') as f:
    text = f.read()
# Strip single-line comments
text = re.sub(r'//.*', '', text)
# Strip trailing commas before } or ]
text = re.sub(r',\s*([}\]])', r'\1', text)
data = json.loads(text)
assert 'agents' in data, 'missing agents'
assert 'tools' in data, 'missing tools'
sys.exit(0)
" 2>/dev/null; then
        pass "openclaw.json — valid and has 'agents', 'tools'"
    else
        fail "openclaw.json — parse error or missing required fields (agents, tools)"
    fi
fi

# --- models.json ---
echo ""
echo "models.json:"
MFILE="$PROJECT_DIR/config/models.json"
check_json "$MFILE" "models.json"
if [ -f "$MFILE" ]; then
    check_field "$MFILE" "'tiers' in d and len(d['tiers']) > 0" "models.json has 'tiers'"
    check_field "$MFILE" "'providers' in d and len(d['providers']) > 0" "models.json has 'providers'"
fi

# --- progression.json ---
echo ""
echo "progression.json:"
PFILE="$PROJECT_DIR/config/progression.json"
check_json "$PFILE" "progression.json"
if [ -f "$PFILE" ]; then
    check_field "$PFILE" "'phases' in d and 'L0' in d['phases']" "progression.json has 'phases' with L0"
    check_field "$PFILE" "all(p in d['phases'] for p in ['L0','L1','L2','L3','L4','L5','L6'])" "progression.json has all phases L0-L6"
fi

# --- All other JSON files in config/ ---
echo ""
echo "Other config files:"
for f in "$PROJECT_DIR"/config/*.json; do
    [ -f "$f" ] || continue
    base="$(basename "$f")"
    # Skip openclaw.json (JSON5 — validated above) and files already checked
    [[ "$base" == "openclaw.json" || "$base" == "models.json" || "$base" == "progression.json" ]] && continue
    check_json "$f" "$base"
done

# --- Schema files ---
echo ""
echo "Schema files:"
for f in "$PROJECT_DIR"/config/schemas/*.json; do
    [ -f "$f" ] || continue
    check_json "$f" "schemas/$(basename "$f")"
done

# --- Summary ---
echo ""
TOTAL=$((PASS + FAIL))
echo "Config validation: $PASS/$TOTAL passed"
exit "$FAIL"
