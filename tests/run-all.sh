#!/usr/bin/env bash
# Run all AgentOrg validation tests and report results.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOTAL_PASS=0
TOTAL_FAIL=0

RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

run_test() {
    local name="$1"
    local script="$2"
    echo ""
    echo -e "${BOLD}--- $name ---${NC}"
    if "$script"; then
        TOTAL_PASS=$((TOTAL_PASS + 1))
    else
        TOTAL_FAIL=$((TOTAL_FAIL + 1))
    fi
}

echo -e "${BOLD}========================================="
echo "  AgentOrg — Validation Suite"
echo -e "=========================================${NC}"

run_test "Structure" "$SCRIPT_DIR/validate-structure.sh"
run_test "Config" "$SCRIPT_DIR/validate-config.sh"
run_test "Schemas" "$SCRIPT_DIR/validate-schemas.sh"
run_test "Scripts" "$SCRIPT_DIR/validate-scripts.sh"

# Smoke tests (if directory exists)
SMOKE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)/smoke"
if [[ -d "$SMOKE_DIR" ]]; then
    for smoke_test in "$SMOKE_DIR"/*.test.sh; do
        [[ -f "$smoke_test" ]] || continue
        test_name="Smoke: $(basename "$smoke_test" .test.sh)"
        run_test "$test_name" "$smoke_test"
    done
fi

TOTAL=$((TOTAL_PASS + TOTAL_FAIL))
echo ""
echo -e "${BOLD}========================================="
if [ "$TOTAL_FAIL" -eq 0 ]; then
    echo -e "  ${GREEN}ALL $TOTAL TEST SUITES PASSED${NC}"
else
    echo -e "  ${RED}$TOTAL_FAIL/$TOTAL TEST SUITES HAD FAILURES${NC}"
fi
echo -e "${BOLD}=========================================${NC}"

exit "$TOTAL_FAIL"
