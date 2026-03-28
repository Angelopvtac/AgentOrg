#!/usr/bin/env bash
set -euo pipefail

# Smoke test: Business type templates and apply-template script
# Tests template structure, listing, preview, apply, reset, and L1 gate coherence

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0
TOTAL=0

check() {
    TOTAL=$((TOTAL + 1))
    local desc="$1"
    shift
    if "$@" > /dev/null 2>&1; then
        echo "  \033[0;32m[PASS]\033[0m $desc"
        PASS=$((PASS + 1))
    else
        echo "  \033[0;31m[FAIL]\033[0m $desc"
        FAIL=$((FAIL + 1))
    fi
}

check_output() {
    TOTAL=$((TOTAL + 1))
    local desc="$1"
    local pattern="$2"
    shift 2
    local output
    output=$("$@" 2>&1 || true)
    if echo "$output" | grep -q "$pattern"; then
        echo "  \033[0;32m[PASS]\033[0m $desc"
        PASS=$((PASS + 1))
    else
        echo "  \033[0;31m[FAIL]\033[0m $desc"
        FAIL=$((FAIL + 1))
    fi
}

check_file_contains() {
    TOTAL=$((TOTAL + 1))
    local desc="$1"
    local file="$2"
    local pattern="$3"
    if [ -f "$file" ] && grep -q "$pattern" "$file"; then
        echo "  \033[0;32m[PASS]\033[0m $desc"
        PASS=$((PASS + 1))
    else
        echo "  \033[0;31m[FAIL]\033[0m $desc"
        FAIL=$((FAIL + 1))
    fi
}

check_json_field() {
    TOTAL=$((TOTAL + 1))
    local desc="$1"
    local file="$2"
    local expr="$3"
    if [ -f "$file" ] && python3 -c "import json; d=json.load(open('$file')); assert $expr" 2>/dev/null; then
        echo "  \033[0;32m[PASS]\033[0m $desc"
        PASS=$((PASS + 1))
    else
        echo "  \033[0;31m[FAIL]\033[0m $desc"
        FAIL=$((FAIL + 1))
    fi
}

echo ""
echo "Phase 1: Template directory structure"

TEMPLATES=("content-agency" "saas-micro" "consulting")
for t in "${TEMPLATES[@]}"; do
    check "Template directory exists: $t" test -d "$PROJECT_ROOT/templates/$t"
    check "Template manifest exists: $t" test -f "$PROJECT_ROOT/templates/$t/template.json"
    check "Direction file exists: $t" test -f "$PROJECT_ROOT/templates/$t/direction.json"
    check "Brand brief file exists: $t" test -f "$PROJECT_ROOT/templates/$t/brand-brief.json"
    check "Market research file exists: $t" test -f "$PROJECT_ROOT/templates/$t/market-research.json"
done

echo ""
echo "Phase 2: Template manifest validation"

for t in "${TEMPLATES[@]}"; do
    check_json_field "Manifest has id: $t" "$PROJECT_ROOT/templates/$t/template.json" "d['id'] == '$t'"
    check_json_field "Manifest has name: $t" "$PROJECT_ROOT/templates/$t/template.json" "len(d['name']) > 5"
    check_json_field "Manifest has description: $t" "$PROJECT_ROOT/templates/$t/template.json" "len(d['description']) > 20"
    check_json_field "Manifest targets L1: $t" "$PROJECT_ROOT/templates/$t/template.json" "d['targetPhase'] == 'L1'"
    check_json_field "Manifest has suggestedSkills: $t" "$PROJECT_ROOT/templates/$t/template.json" "len(d['suggestedSkills']) >= 3"
    check_json_field "Manifest has suggestedGoal: $t" "$PROJECT_ROOT/templates/$t/template.json" "len(d['suggestedGoal']) > 10"
    check_json_field "Manifest lists files: $t" "$PROJECT_ROOT/templates/$t/template.json" "len(d['files']) == 3"
done

echo ""
echo "Phase 3: Direction file validation"

for t in "${TEMPLATES[@]}"; do
    check_json_field "Direction has collection: $t" "$PROJECT_ROOT/templates/$t/direction.json" "d['collection'] == 'business-direction'"
    check_json_field "Direction has direction object: $t" "$PROJECT_ROOT/templates/$t/direction.json" "d['direction'] is not None"
    check_json_field "Direction has market: $t" "$PROJECT_ROOT/templates/$t/direction.json" "len(d['direction']['market']) > 10"
    check_json_field "Direction has revenueModel: $t" "$PROJECT_ROOT/templates/$t/direction.json" "len(d['direction']['revenueModel']) > 10"
    check_json_field "Direction has risks: $t" "$PROJECT_ROOT/templates/$t/direction.json" "len(d['direction']['risks']) >= 2"
    check_json_field "Direction has alternatives: $t" "$PROJECT_ROOT/templates/$t/direction.json" "len(d['alternatives']) >= 2"
done

echo ""
echo "Phase 4: Brand brief validation"

for t in "${TEMPLATES[@]}"; do
    check_json_field "Brand has name: $t" "$PROJECT_ROOT/templates/$t/brand-brief.json" "d['brandName'] is not None and len(d['brandName']) > 2"
    check_json_field "Brand has tagline: $t" "$PROJECT_ROOT/templates/$t/brand-brief.json" "d['tagline'] is not None and len(d['tagline']) > 5"
    check_json_field "Brand has voice: $t" "$PROJECT_ROOT/templates/$t/brand-brief.json" "d['voice'] is not None and len(d['voice']) > 20"
    check_json_field "Brand has audience: $t" "$PROJECT_ROOT/templates/$t/brand-brief.json" "d['audience'] is not None and len(d['audience']) > 20"
done

echo ""
echo "Phase 5: Market research validation"

for t in "${TEMPLATES[@]}"; do
    check_json_field "Research has reportType: $t" "$PROJECT_ROOT/templates/$t/market-research.json" "d['reportType'] == 'market-scan'"
    check_json_field "Research has title: $t" "$PROJECT_ROOT/templates/$t/market-research.json" "len(d['title']) > 10"
    check_json_field "Research has findings: $t" "$PROJECT_ROOT/templates/$t/market-research.json" "len(d['findings']) >= 3"
    check_json_field "Research findings have confidence: $t" "$PROJECT_ROOT/templates/$t/market-research.json" "all('confidence' in f for f in d['findings'])"
    check_json_field "Research findings have sources: $t" "$PROJECT_ROOT/templates/$t/market-research.json" "all(len(f['sources']) > 0 for f in d['findings'])"
    check_json_field "Research has recommendations: $t" "$PROJECT_ROOT/templates/$t/market-research.json" "len(d['recommendations']) >= 3"
done

echo ""
echo "Phase 6: Script existence and structure"

check "apply-template.py exists" test -f "$PROJECT_ROOT/scripts/apply-template.py"
check "apply-template.sh exists" test -f "$PROJECT_ROOT/scripts/apply-template.sh"
check "apply-template.sh is executable" test -x "$PROJECT_ROOT/scripts/apply-template.sh"
check_file_contains "Script has --list mode" "$PROJECT_ROOT/scripts/apply-template.py" "def list_templates"
check_file_contains "Script has --preview mode" "$PROJECT_ROOT/scripts/apply-template.py" "def preview_template"
check_file_contains "Script has --apply mode" "$PROJECT_ROOT/scripts/apply-template.py" "def apply_template"
check_file_contains "Script has --reset mode" "$PROJECT_ROOT/scripts/apply-template.py" "def reset_business_data"

echo ""
echo "Phase 7: --list mode"

check_output "List shows all 3 templates" "Available business templates (3)" python3 "$PROJECT_ROOT/scripts/apply-template.py" --list --project "$PROJECT_ROOT"
check_output "List shows content-agency" "content-agency" python3 "$PROJECT_ROOT/scripts/apply-template.py" --list --project "$PROJECT_ROOT"
check_output "List shows saas-micro" "saas-micro" python3 "$PROJECT_ROOT/scripts/apply-template.py" --list --project "$PROJECT_ROOT"
check_output "List shows consulting" "consulting" python3 "$PROJECT_ROOT/scripts/apply-template.py" --list --project "$PROJECT_ROOT"

echo ""
echo "Phase 8: --preview mode"

check_output "Preview shows template name" "Content & Marketing Agency" python3 "$PROJECT_ROOT/scripts/apply-template.py" --preview content-agency --project "$PROJECT_ROOT"
check_output "Preview shows brand name" "Inkwell Studio" python3 "$PROJECT_ROOT/scripts/apply-template.py" --preview content-agency --project "$PROJECT_ROOT"
check_output "Preview shows target phase" "Target Phase: L1" python3 "$PROJECT_ROOT/scripts/apply-template.py" --preview content-agency --project "$PROJECT_ROOT"
check_output "Preview shows suggested skills" "copywriting" python3 "$PROJECT_ROOT/scripts/apply-template.py" --preview content-agency --project "$PROJECT_ROOT"

echo ""
echo "Phase 9: --apply mode (isolated vault)"

TMPVAULT=$(mktemp -d)
mkdir -p "$TMPVAULT/business" "$TMPVAULT/research"

# Apply content-agency template
check_output "Apply writes direction" "business/direction.json" python3 "$PROJECT_ROOT/scripts/apply-template.py" --apply content-agency "$TMPVAULT" --project "$PROJECT_ROOT"

# Verify files were written
check "Direction file created" test -f "$TMPVAULT/business/direction.json"
check "Brand brief file created" test -f "$TMPVAULT/business/brand-brief.json"
check "Research report created" test -f "$TMPVAULT/research/market-scan-content-agency.json"

# Verify content
check_json_field "Applied direction has selectedAt timestamp" "$TMPVAULT/business/direction.json" "d['selectedAt'] is not None"
check_json_field "Applied brand has createdAt timestamp" "$TMPVAULT/business/brand-brief.json" "d['createdAt'] is not None"
check_json_field "Applied research has generatedAt timestamp" "$TMPVAULT/research/market-scan-content-agency.json" "d['generatedAt'] is not None"
check_json_field "Applied research has templateSource" "$TMPVAULT/research/market-scan-content-agency.json" "d['templateSource'] == 'content-agency'"

# Verify L1 gate report in output
check_output "Apply reports L1 gate status" "direction-selected" python3 "$PROJECT_ROOT/scripts/apply-template.py" --apply saas-micro "$TMPVAULT" --project "$PROJECT_ROOT"

echo ""
echo "Phase 10: --reset mode (isolated vault)"

python3 "$PROJECT_ROOT/scripts/apply-template.py" --reset "$TMPVAULT" --project "$PROJECT_ROOT" > /dev/null 2>&1

check_json_field "Reset clears direction" "$TMPVAULT/business/direction.json" "d['direction'] is None"
check_json_field "Reset clears brandName" "$TMPVAULT/business/brand-brief.json" "d['brandName'] is None"
check "Reset removes research reports" test ! -f "$TMPVAULT/research/market-scan-content-agency.json"

rm -rf "$TMPVAULT"

echo ""
echo "Phase 11: All templates apply cleanly"

for t in "${TEMPLATES[@]}"; do
    TMPVAULT2=$(mktemp -d)
    mkdir -p "$TMPVAULT2/business" "$TMPVAULT2/research"
    python3 "$PROJECT_ROOT/scripts/apply-template.py" --apply "$t" "$TMPVAULT2" --project "$PROJECT_ROOT" > /dev/null 2>&1
    EXIT_CODE=$?
    TOTAL=$((TOTAL + 1))
    if [ $EXIT_CODE -eq 0 ]; then
        echo "  \033[0;32m[PASS]\033[0m Template '$t' applies without error"
        PASS=$((PASS + 1))
    else
        echo "  \033[0;31m[FAIL]\033[0m Template '$t' applies without error"
        FAIL=$((FAIL + 1))
    fi
    rm -rf "$TMPVAULT2"
done

echo ""
echo "Phase 12: Error handling"

# Invalid template
TOTAL=$((TOTAL + 1))
ERR_OUTPUT=$(python3 "$PROJECT_ROOT/scripts/apply-template.py" --preview nonexistent --project "$PROJECT_ROOT" 2>&1 || true)
if echo "$ERR_OUTPUT" | grep -q "not found"; then
    echo "  \033[0;32m[PASS]\033[0m Invalid template shows error"
    PASS=$((PASS + 1))
else
    echo "  \033[0;31m[FAIL]\033[0m Invalid template shows error"
    FAIL=$((FAIL + 1))
fi

# Invalid vault
TOTAL=$((TOTAL + 1))
ERR_OUTPUT=$(python3 "$PROJECT_ROOT/scripts/apply-template.py" --apply content-agency /tmp/nonexistent-vault-dir --project "$PROJECT_ROOT" 2>&1 || true)
if echo "$ERR_OUTPUT" | grep -q "not found"; then
    echo "  \033[0;32m[PASS]\033[0m Invalid vault shows error"
    PASS=$((PASS + 1))
else
    echo "  \033[0;31m[FAIL]\033[0m Invalid vault shows error"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "Phase 13: Progression system coherence"

# Templates align with L1 gate criteria in progression.json
check_file_contains "Progression has direction-selected criterion" "$PROJECT_ROOT/config/progression.json" "direction-selected"
check_file_contains "Progression has brand-brief-complete criterion" "$PROJECT_ROOT/config/progression.json" "brand-brief-complete"
check_file_contains "Progression has market-research-done criterion" "$PROJECT_ROOT/config/progression.json" "market-research-done"

# Apply-template script checks these same criteria
check_file_contains "Script checks direction-selected" "$PROJECT_ROOT/scripts/apply-template.py" "direction-selected"
check_file_contains "Script checks brand-brief-complete" "$PROJECT_ROOT/scripts/apply-template.py" "brand-brief-complete"
check_file_contains "Script checks market-research-done" "$PROJECT_ROOT/scripts/apply-template.py" "market-research-done"

echo ""
if [ $FAIL -eq 0 ]; then
    echo "\033[0;32mBusiness templates smoke test: $PASS/$TOTAL passed\033[0m"
else
    echo "\033[0;31mBusiness templates smoke test: $PASS/$TOTAL passed ($FAIL failed)\033[0m"
fi
echo ""

exit $FAIL
