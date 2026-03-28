#!/usr/bin/env bash
set -euo pipefail

# Apply a business-type template to pre-seed L1 discovery data
# Usage: bash scripts/apply-template.sh [mode] [args...]
#
# Modes:
#   --list                          List available templates
#   --preview <template_id>         Show template details
#   --apply <template_id> [vault]   Apply template to vault
#   --reset [vault]                 Reset L1 business data
#
# Examples:
#   bash scripts/apply-template.sh --list
#   bash scripts/apply-template.sh --preview content-agency
#   bash scripts/apply-template.sh --apply saas-micro
#   bash scripts/apply-template.sh --apply consulting /tmp/test-vault
#   bash scripts/apply-template.sh --reset

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

python3 "$SCRIPT_DIR/apply-template.py" "$@" --project "$PROJECT_ROOT"
