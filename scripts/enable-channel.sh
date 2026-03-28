#!/usr/bin/env bash
set -euo pipefail

# Enable or disable messaging channels (Discord, Telegram) in the gateway config
# Usage: bash scripts/enable-channel.sh [mode] [channel]
#
# Modes:
#   --enable <channel>    Enable a channel (discord, telegram)
#   --disable <channel>   Disable a channel
#   --status              Show current channel configuration
#
# Examples:
#   bash scripts/enable-channel.sh --status
#   bash scripts/enable-channel.sh --enable discord
#   bash scripts/enable-channel.sh --enable telegram
#   bash scripts/enable-channel.sh --disable discord

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

python3 "$SCRIPT_DIR/enable-channel.py" "$@" --project "$PROJECT_ROOT"
