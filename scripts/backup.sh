#!/usr/bin/env bash
# AgentOrg Backup
# Creates a timestamped tar.gz of knowledge/, config/, and agent workspaces.
# Keeps the last 10 backups.

set -euo pipefail

usage() {
    echo "Usage: $(basename "$0") [-h]"
    echo "Creates a timestamped backup of AgentOrg knowledge, config, skills, and workspaces."
    echo "Keeps the last $MAX_BACKUPS backups."
    exit 0
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && MAX_BACKUPS=10 && usage

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_DIR/backups"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
BACKUP_FILE="$BACKUP_DIR/agentorg-backup-$TIMESTAMP.tar.gz"
MAX_BACKUPS=10

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

echo "=== AgentOrg Backup ==="
echo "Timestamp: $TIMESTAMP"
echo ""

# Build list of paths to back up
PATHS_TO_BACKUP=()
for path in knowledge config skills agents/orchestrator/workspace agents/core-assistant/workspace; do
    if [ -d "$PROJECT_DIR/$path" ]; then
        PATHS_TO_BACKUP+=("$path")
    fi
done

if [ ${#PATHS_TO_BACKUP[@]} -eq 0 ]; then
    echo "Nothing to back up."
    exit 0
fi

# Create archive
echo "Backing up: ${PATHS_TO_BACKUP[*]}"
tar -czf "$BACKUP_FILE" -C "$PROJECT_DIR" "${PATHS_TO_BACKUP[@]}"

SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo "Created: $BACKUP_FILE ($SIZE)"

# Prune old backups (keep last N)
BACKUP_COUNT=$(find "$BACKUP_DIR" -name "agentorg-backup-*.tar.gz" -type f | wc -l)
if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
    PRUNE_COUNT=$((BACKUP_COUNT - MAX_BACKUPS))
    echo "Pruning $PRUNE_COUNT old backup(s)..."
    find "$BACKUP_DIR" -name "agentorg-backup-*.tar.gz" -type f -print0 | sort -z | head -z -n "$PRUNE_COUNT" | xargs -0 rm -f
fi

echo ""
echo "=== Backup complete ==="
echo "Total backups: $(find "$BACKUP_DIR" -name "agentorg-backup-*.tar.gz" -type f | wc -l)/$MAX_BACKUPS"
