#!/usr/bin/env bash
# Check all .sh files are executable and pass shellcheck if available.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PASS=0
FAIL=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}[PASS]${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "  ${RED}[FAIL]${NC} $1"; FAIL=$((FAIL + 1)); }
skip() { echo -e "  ${YELLOW}[SKIP]${NC} $1"; }

echo "=== Script Validation ==="
echo ""

# Collect all .sh files
mapfile -t SCRIPTS < <(find "$PROJECT_DIR" -name "*.sh" -type f ! -path "*/backups/*" ! -path "*/.git/*" | sort)

if [ ${#SCRIPTS[@]} -eq 0 ]; then
    echo "No .sh files found."
    exit 0
fi

# --- Check executable bit ---
echo "Executable permissions:"
for script in "${SCRIPTS[@]}"; do
    rel="${script#"$PROJECT_DIR"/}"
    if [ -x "$script" ]; then
        pass "$rel — executable"
    else
        fail "$rel — not executable (fix: chmod +x $rel)"
    fi
done

# --- Check shebang ---
echo ""
echo "Shebang lines:"
for script in "${SCRIPTS[@]}"; do
    rel="${script#"$PROJECT_DIR"/}"
    first_line=$(head -1 "$script")
    if [[ "$first_line" == "#!/"* ]]; then
        pass "$rel — has shebang"
    else
        fail "$rel — missing shebang line"
    fi
done

# --- Check set -euo pipefail or set -uo pipefail ---
echo ""
echo "Strict mode (set -euo pipefail):"
for script in "${SCRIPTS[@]}"; do
    rel="${script#"$PROJECT_DIR"/}"
    if grep -q 'set -euo pipefail\|set -uo pipefail' "$script"; then
        pass "$rel — strict mode enabled"
    else
        fail "$rel — missing 'set -euo pipefail'"
    fi
done

# --- Shellcheck ---
echo ""
echo "Shellcheck:"
if command -v shellcheck &>/dev/null; then
    for script in "${SCRIPTS[@]}"; do
        rel="${script#"$PROJECT_DIR"/}"
        if shellcheck -S warning "$script" >/dev/null 2>&1; then
            pass "$rel — no warnings"
        else
            fail "$rel — shellcheck warnings found"
            shellcheck -S warning "$script" 2>&1 | head -20 | sed 's/^/         /'
        fi
    done
else
    skip "shellcheck not installed — skipping lint checks"
fi

# --- Summary ---
echo ""
TOTAL=$((PASS + FAIL))
echo "Script validation: $PASS/$TOTAL passed"
exit "$FAIL"
