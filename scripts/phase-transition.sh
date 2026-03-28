#!/usr/bin/env bash
set -euo pipefail

# Evaluate phase gate and transition to next phase if criteria are met
# Usage: bash scripts/phase-transition.sh [mode] [vault_dir] [options]
#
# Modes:
#   --check       Dry-run: evaluate gate, report pass/fail (default)
#   --transition  Evaluate gate and transition if all pass
#   --force       Force transition without gate evaluation
#   --status      Show current phase status
#
# Examples:
#   bash scripts/phase-transition.sh --check                   # check against knowledge/
#   bash scripts/phase-transition.sh --transition              # transition knowledge/
#   bash scripts/phase-transition.sh --status knowledge/       # show status
#   bash scripts/phase-transition.sh --check /tmp/test-vault   # check temp vault

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

MODE="${1:---check}"
VAULT_DIR="${2:-$PROJECT_ROOT/knowledge}"

# Pass remaining args through
shift 2 2>/dev/null || true
EXTRA_ARGS="$*"

python3 "$SCRIPT_DIR/phase-transition.py" "$MODE" "$VAULT_DIR" --project "$PROJECT_ROOT" $EXTRA_ARGS
