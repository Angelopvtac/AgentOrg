#!/usr/bin/env bash
set -euo pipefail

# Generate founder status dashboard from vault data
# Usage: bash scripts/generate-dashboard.sh [knowledge_dir] [output_file]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

KNOWLEDGE_DIR="${1:-$PROJECT_ROOT/knowledge}"
OUTPUT_FILE="${2:-$PROJECT_ROOT/dashboards/index.html}"

if [[ ! -d "$KNOWLEDGE_DIR" ]]; then
  echo "ERROR: Knowledge directory not found: $KNOWLEDGE_DIR"
  exit 1
fi

GENERATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
GENERATED_DISPLAY=$(date +"%B %d, %Y at %H:%M")

mkdir -p "$(dirname "$OUTPUT_FILE")"

# Use Python to do all JSON parsing and HTML generation in one shot
python3 "$SCRIPT_DIR/generate-dashboard.py" \
  "$KNOWLEDGE_DIR" \
  "$PROJECT_ROOT/config/progression.json" \
  "$OUTPUT_FILE" \
  "$GENERATED_AT" \
  "$GENERATED_DISPLAY"

echo "Dashboard generated: $OUTPUT_FILE"
echo "Open in browser: file://$(realpath "$OUTPUT_FILE")"
