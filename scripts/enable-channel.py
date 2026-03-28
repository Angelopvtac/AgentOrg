#!/usr/bin/env python3
"""
AgentOrg — Channel Configuration Manager

Enables/disables messaging channels (Discord, Telegram) in the gateway config.
Validates environment variables, updates config/openclaw.json, and reports status.

Usage:
    python3 enable-channel.py --enable discord --project /path/to/project
    python3 enable-channel.py --enable telegram --project /path/to/project
    python3 enable-channel.py --disable discord --project /path/to/project
    python3 enable-channel.py --status --project /path/to/project
"""

import argparse
import json
import os
import re
import sys
from datetime import datetime, timezone

SUPPORTED_CHANNELS = ["discord", "telegram"]

# Channel config templates (JSON5-compatible strings)
CHANNEL_TEMPLATES = {
    "discord": {
        "enabled": True,
        "groupPolicy": "allowlist",
        "accounts": {
            "agentorg": {
                "token": "${DISCORD_BOT_TOKEN}",
                "groupPolicy": "allowlist",
                "guilds": {},
                "activity": "AgentOrg",
                "status": "online"
            }
        }
    },
    "telegram": {
        "enabled": True,
        "accounts": {
            "agentorg": {
                "token": "${TELEGRAM_BOT_TOKEN}",
                "dmPolicy": "pairing"
            }
        }
    }
}

ENV_VAR_MAP = {
    "discord": "DISCORD_BOT_TOKEN",
    "telegram": "TELEGRAM_BOT_TOKEN"
}

SETUP_URLS = {
    "discord": "https://discord.com/developers/applications",
    "telegram": "https://t.me/BotFather"
}


def load_config_text(config_path):
    """Read the raw config file text."""
    with open(config_path, "r") as f:
        return f.read()


def write_config_text(config_path, text):
    """Write config file text back."""
    with open(config_path, "w") as f:
        f.write(text)


def has_active_channels_block(text):
    """Check if there's an active (uncommented) channels block."""
    # Look for "channels": { that isn't commented out
    lines = text.split("\n")
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("//"):
            continue
        if '"channels"' in stripped and "{" in stripped:
            return True
    return False


def has_commented_channels_block(text):
    """Check if there's a commented-out channels block."""
    return bool(re.search(r'^\s*//\s*"channels"\s*:', text, re.MULTILINE))


def find_commented_channel_block(text):
    """Find the start and end of the commented channel block including header comment."""
    lines = text.split("\n")
    start = None
    end = None
    brace_depth = 0
    in_block = False

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Find the header comment line
        if start is None and "Channel Templates" in stripped and stripped.startswith("//"):
            start = i
            continue

        # Find the opening "channels": {
        if start is not None and not in_block:
            if '"channels"' in stripped and stripped.startswith("//"):
                # Count braces from this line
                uncommented = stripped.lstrip("/ ")
                brace_depth += uncommented.count("{") - uncommented.count("}")
                in_block = True
                continue

        # Track braces to find the end
        if in_block:
            uncommented = stripped.lstrip("/ ")
            brace_depth += uncommented.count("{") - uncommented.count("}")
            if brace_depth <= 0:
                end = i
                break

    return start, end


def find_active_channel_block(text):
    """Find the start and end of an active (uncommented) channels block."""
    lines = text.split("\n")
    start = None
    end = None
    brace_depth = 0
    in_block = False

    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("//"):
            continue

        if start is None and '"channels"' in stripped:
            # Check if this line also has the opening brace
            start = i
            brace_depth += stripped.count("{") - stripped.count("}")
            if brace_depth > 0:
                in_block = True
            continue

        if start is not None and not in_block:
            brace_depth += stripped.count("{") - stripped.count("}")
            if brace_depth > 0:
                in_block = True

        if in_block:
            brace_depth += stripped.count("{") - stripped.count("}")
            if brace_depth <= 0:
                end = i
                break

    return start, end


def get_active_channels(text):
    """Parse which channels are currently active in the config."""
    active = []
    if not has_active_channels_block(text):
        return active

    # Extract the channels block and parse it
    start, end = find_active_channel_block(text)
    if start is None or end is None:
        return active

    lines = text.split("\n")
    block_lines = lines[start:end + 1]
    block_text = "\n".join(block_lines)

    # Strip comments from the block for parsing
    cleaned = re.sub(r'//.*$', '', block_text, flags=re.MULTILINE)
    # Remove trailing commas before } or ]
    cleaned = re.sub(r',\s*([}\]])', r'\1', cleaned)

    try:
        parsed = json.loads("{" + cleaned.split("{", 1)[1] if "{" in cleaned else cleaned)
        for channel in SUPPORTED_CHANNELS:
            if channel in parsed and parsed[channel].get("enabled", False):
                active.append(channel)
    except (json.JSONDecodeError, IndexError):
        # Fallback: check for channel names in uncommented lines
        for channel in SUPPORTED_CHANNELS:
            pattern = rf'^\s*"{channel}"\s*:'
            for line in block_lines:
                stripped = line.strip()
                if not stripped.startswith("//") and re.match(pattern, stripped):
                    active.append(channel)
                    break

    return active


def find_channels_region(text):
    """Find the full region containing all channel-related lines (active block + disabled comments).
    Returns (start_line, end_line) or (None, None).

    Strategy: find the start (header comment or "channels" key), then use brace-depth tracking
    to find the end of the active JSON block, then continue past any trailing comment block.
    """
    lines = text.split("\n")
    start = None
    end = None

    # Phase 1: Find the start line
    for i, line in enumerate(lines):
        stripped = line.strip()
        if ("Channel Templates" in stripped or "Active Channels" in stripped or
                "Disabled Channel" in stripped) and stripped.startswith("//"):
            start = i
            break
        if not stripped.startswith("//") and '"channels"' in stripped:
            start = i
            break

    if start is None:
        return None, None

    # Phase 2: Find the end of any active channels JSON block (brace-depth tracking)
    brace_depth = 0
    in_json_block = False
    json_block_end = None

    for i in range(start, len(lines)):
        stripped = lines[i].strip()
        if stripped.startswith("//"):
            continue

        # Count braces in non-comment lines
        for ch in stripped:
            if ch == '{':
                if not in_json_block and '"channels"' in stripped:
                    in_json_block = True
                brace_depth += 1
            elif ch == '}':
                brace_depth -= 1

        if in_json_block and brace_depth <= 0:
            json_block_end = i
            break

    # Phase 3: Continue past any trailing comment block (disabled channel templates)
    scan_from = (json_block_end + 1) if json_block_end is not None else start + 1
    end = json_block_end if json_block_end is not None else start

    for i in range(scan_from, len(lines)):
        stripped = lines[i].strip()
        if stripped.startswith("//"):
            end = i
            continue
        if stripped == "":
            # Blank lines between comment blocks — peek ahead
            continue
        # Hit real content — stop
        break

    return start, end


def build_channels_region(enabled_channels):
    """Build the complete channels region text given a set of enabled channels."""
    lines = []

    if enabled_channels:
        lines.append('  // --- Active Channels ---')
        lines.append('  "channels": {')

        enabled_list = [ch for ch in SUPPORTED_CHANNELS if ch in enabled_channels]
        for idx, ch in enumerate(enabled_list):
            template = CHANNEL_TEMPLATES[ch]
            ch_json = json.dumps(template, indent=2)
            ch_lines = ch_json.split("\n")
            lines.append(f'    "{ch}": {{')
            for cl in ch_lines[1:-1]:
                lines.append(f'    {cl}')
            if idx < len(enabled_list) - 1:
                lines.append('    },')
            else:
                lines.append('    }')
        lines.append('  },')

        # Add commented templates for disabled channels
        disabled = [ch for ch in SUPPORTED_CHANNELS if ch not in enabled_channels]
        if disabled:
            lines.append('  // --- Disabled Channel Templates (enable with scripts/enable-channel.sh) ---')
            for ch in disabled:
                template = CHANNEL_TEMPLATES[ch]
                ch_json = json.dumps(template, indent=2)
                ch_lines = ch_json.split("\n")
                lines.append(f'  // "{ch}": {{')
                for cl in ch_lines[1:-1]:
                    lines.append(f'  // {cl}')
                lines.append(f'  // }}')
    else:
        # All disabled — restore the original commented template block
        lines.append('  // --- Channel Templates (uncomment and configure during channel setup) ---')
        lines.append('  // "channels": {')
        for idx, ch in enumerate(SUPPORTED_CHANNELS):
            template = CHANNEL_TEMPLATES[ch]
            ch_json = json.dumps(template, indent=2)
            ch_lines = ch_json.split("\n")
            lines.append(f'  //   "{ch}": {{')
            for cl in ch_lines[1:-1]:
                lines.append(f'  //   {cl}')
            if idx < len(SUPPORTED_CHANNELS) - 1:
                lines.append(f'  //   }},')
            else:
                lines.append(f'  //   }}')
        lines.append('  // },')

    return lines


def enable_channel(text, channel):
    """Enable a channel in the config. Returns (updated_text, changed)."""
    current_active = get_active_channels(text)
    if channel in current_active:
        return text, False  # Already enabled

    new_active = set(current_active) | {channel}
    return _rebuild_channels(text, new_active)


def disable_channel(text, channel):
    """Disable a channel in the config. Returns (updated_text, changed)."""
    current_active = get_active_channels(text)
    if channel not in current_active:
        return text, False  # Already disabled

    new_active = set(current_active) - {channel}
    return _rebuild_channels(text, new_active)


def _rebuild_channels(text, enabled_channels):
    """Replace the entire channels region with a rebuilt version."""
    lines = text.split("\n")

    # Find existing region
    start, end = find_channels_region(text)

    if start is not None and end is not None:
        # Replace existing region
        new_block = build_channels_region(enabled_channels)
        new_lines = lines[:start] + new_block + lines[end + 1:]
        return "\n".join(new_lines), True

    # No channels region found — insert before "messages" key
    insert_at = None
    for i, line in enumerate(lines):
        if '"messages"' in line and not line.strip().startswith("//"):
            insert_at = i
            break

    if insert_at is None:
        print("ERROR: Could not find insertion point for channels block", file=sys.stderr)
        return text, False

    new_block = build_channels_region(enabled_channels)
    new_block.append('')  # blank line separator
    new_lines = lines[:insert_at] + new_block + lines[insert_at:]
    return "\n".join(new_lines), True


def check_env_var(channel, project_root):
    """Check if the required env var is set in .env file."""
    env_var = ENV_VAR_MAP[channel]
    env_path = os.path.join(project_root, ".env")

    # Check actual environment first
    val = os.environ.get(env_var, "")
    if val:
        return True, val[:8] + "..." if len(val) > 8 else val

    # Check .env file
    if os.path.exists(env_path):
        with open(env_path, "r") as f:
            for line in f:
                line = line.strip()
                if line.startswith("#") or "=" not in line:
                    continue
                key, _, value = line.partition("=")
                # Strip inline comments and whitespace
                value = value.split("#")[0].strip()
                if key.strip() == env_var and value:
                    masked = value[:8] + "..." if len(value) > 8 else value
                    return True, masked

    return False, None


def show_status(text, project_root):
    """Show the current channel configuration status."""
    print("=" * 60)
    print("  AgentOrg — Channel Status")
    print("=" * 60)
    print()

    has_active = has_active_channels_block(text)
    has_commented = has_commented_channels_block(text)
    active_channels = get_active_channels(text) if has_active else []

    for channel in SUPPORTED_CHANNELS:
        env_var = ENV_VAR_MAP[channel]
        has_token, masked = check_env_var(channel, project_root)

        if channel in active_channels:
            status = "\033[0;32mENABLED\033[0m"
        else:
            status = "\033[0;33mDISABLED\033[0m"

        token_status = f"\033[0;32m{masked}\033[0m" if has_token else f"\033[0;31mNOT SET\033[0m"

        print(f"  {channel.capitalize():12s}  Status: {status}")
        print(f"  {'':12s}  Token:  {env_var} = {token_status}")
        if not has_token:
            print(f"  {'':12s}  Setup:  {SETUP_URLS[channel]}")
        print()

    if not has_active and has_commented:
        print("  All channels are commented out in config/openclaw.json.")
        print("  Run: bash scripts/enable-channel.sh --enable <channel>")
    elif has_active:
        print(f"  Active channels: {', '.join(active_channels)}")
        print("  Note: Container restart required after config changes.")
    print()

    return 0


def main():
    parser = argparse.ArgumentParser(description="AgentOrg channel configuration manager")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--enable", choices=SUPPORTED_CHANNELS, help="Enable a messaging channel")
    group.add_argument("--disable", choices=SUPPORTED_CHANNELS, help="Disable a messaging channel")
    group.add_argument("--status", action="store_true", help="Show channel status")
    parser.add_argument("--project", required=True, help="Project root directory")
    parser.add_argument("--config", help="Config file path (default: config/openclaw.json)")

    args = parser.parse_args()
    project_root = os.path.abspath(args.project)
    config_path = args.config or os.path.join(project_root, "config", "openclaw.json")

    if not os.path.exists(config_path):
        print(f"ERROR: Config file not found: {config_path}", file=sys.stderr)
        sys.exit(2)

    text = load_config_text(config_path)

    # Status mode
    if args.status:
        sys.exit(show_status(text, project_root))

    # Enable mode
    if args.enable:
        channel = args.enable
        env_var = ENV_VAR_MAP[channel]

        print(f"\n  Enabling {channel.capitalize()} channel...")
        print()

        # Check env var
        has_token, masked = check_env_var(channel, project_root)
        if not has_token:
            print(f"  \033[0;33mWARNING\033[0m: {env_var} is not set in .env")
            print(f"  The channel will be configured but won't connect until the token is set.")
            print(f"  Get your token at: {SETUP_URLS[channel]}")
            print(f"  Then add it to .env: {env_var}=your_token_here")
            print()

        new_text, changed = enable_channel(text, channel)
        if not changed:
            active = get_active_channels(text) if has_active_channels_block(text) else []
            if channel in active:
                print(f"  {channel.capitalize()} is already enabled.")
            else:
                print(f"  ERROR: Failed to enable {channel}.", file=sys.stderr)
                sys.exit(1)
        else:
            write_config_text(config_path, new_text)
            print(f"  \033[0;32mSUCCESS\033[0m: {channel.capitalize()} channel enabled in {config_path}")
            if has_token:
                print(f"  Token: {env_var} = {masked}")
            print()
            print(f"  Next steps:")
            if not has_token:
                print(f"    1. Set {env_var} in .env")
                print(f"    2. Restart the gateway: docker compose restart")
            else:
                print(f"    1. Restart the gateway: docker compose restart")

            if channel == "discord":
                print(f"    {'2' if has_token else '3'}. Add the bot to your Discord server")
                print(f"    {'3' if has_token else '4'}. Configure guild allowlist if using groupPolicy: allowlist")
            elif channel == "telegram":
                print(f"    {'2' if has_token else '3'}. Start a conversation with your bot on Telegram")
            print()

        sys.exit(0)

    # Disable mode
    if args.disable:
        channel = args.disable
        print(f"\n  Disabling {channel.capitalize()} channel...")
        print()

        new_text, changed = disable_channel(text, channel)
        if not changed:
            print(f"  {channel.capitalize()} is already disabled.")
        else:
            write_config_text(config_path, new_text)
            print(f"  \033[0;32mSUCCESS\033[0m: {channel.capitalize()} channel disabled")
            print(f"  Restart the gateway to apply: docker compose restart")
            print()

        sys.exit(0)


if __name__ == "__main__":
    main()
