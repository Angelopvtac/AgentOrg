#!/usr/bin/env bash
set -euo pipefail

# Simulate the onboarding flow and evaluate L0 gate criteria
# Usage: bash scripts/simulate-onboarding.sh [mode] [vault_dir] [--no-save]
#
# Modes:
#   --simulate   Populate completed data + evaluate (default)
#   --populate   Write completed onboarding data to vault
#   --partial    Write partial onboarding data
#   --evaluate   Evaluate L0 gate against current vault state
#   --reset      Reset vault to fresh-install state
#
# Examples:
#   bash scripts/simulate-onboarding.sh                    # simulate against knowledge/
#   bash scripts/simulate-onboarding.sh --evaluate         # evaluate current state
#   bash scripts/simulate-onboarding.sh --partial /tmp/tv  # partial data to temp vault

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

MODE="${1:---simulate}"
VAULT_DIR="${2:-$PROJECT_ROOT/knowledge}"
EXTRA_ARGS="${3:-}"

python3 "$SCRIPT_DIR/simulate-onboarding.py" "$MODE" "$VAULT_DIR" $EXTRA_ARGS
