#!/usr/bin/env bash
# Smoke test: Channel configuration manager
# Tests enable/disable Discord and Telegram channels in gateway config

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PASS=0
FAIL=0
TOTAL=0

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}[PASS]${NC} $1"; PASS=$((PASS + 1)); TOTAL=$((TOTAL + 1)); }
fail() { echo -e "  ${RED}[FAIL]${NC} $1"; FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); }

# --- Setup: create isolated test environment ---
TEST_DIR=$(mktemp -d)
TEST_CONFIG="$TEST_DIR/config/openclaw.json"
TEST_ENV="$TEST_DIR/.env"
mkdir -p "$TEST_DIR/config"
cp "$PROJECT_DIR/config/openclaw.json" "$TEST_CONFIG"

# Create a .env with no tokens set
cat > "$TEST_ENV" << 'EOF'
OPENCLAW_GATEWAY_TOKEN=test-token-123
DISCORD_BOT_TOKEN=
TELEGRAM_BOT_TOKEN=
EOF

cleanup() { rm -rf "$TEST_DIR"; }
trap cleanup EXIT

# Helper to run the script
run_channel() {
    python3 "$PROJECT_DIR/scripts/enable-channel.py" "$@" --project "$TEST_DIR" --config "$TEST_CONFIG" 2>&1
}

echo "=== Channel Configuration Smoke Test ==="
echo ""

# --- Phase 1: Script structure ---
echo "Phase 1: Script files exist"

if [ -f "$PROJECT_DIR/scripts/enable-channel.py" ]; then
    pass "enable-channel.py exists"
else
    fail "enable-channel.py missing"
fi

if [ -f "$PROJECT_DIR/scripts/enable-channel.sh" ]; then
    pass "enable-channel.sh exists"
else
    fail "enable-channel.sh missing"
fi

if head -1 "$PROJECT_DIR/scripts/enable-channel.py" | grep -q "python3"; then
    pass "Python script has shebang"
else
    fail "Python script missing shebang"
fi

if head -1 "$PROJECT_DIR/scripts/enable-channel.sh" | grep -q "bash"; then
    pass "Bash wrapper has shebang"
else
    fail "Bash wrapper missing shebang"
fi

if grep -q "enable-channel.py" "$PROJECT_DIR/scripts/enable-channel.sh"; then
    pass "Bash wrapper calls Python script"
else
    fail "Bash wrapper doesn't call Python script"
fi

# --- Phase 2: Status mode (initial — all disabled) ---
echo ""
echo "Phase 2: Status mode (initial state)"

STATUS_OUT=$(run_channel --status)

if echo "$STATUS_OUT" | grep -q "Channel Status"; then
    pass "Status shows header"
else
    fail "Status missing header"
fi

if echo "$STATUS_OUT" | grep -qi "discord.*DISABLED"; then
    pass "Discord initially disabled"
else
    fail "Discord not shown as disabled"
fi

if echo "$STATUS_OUT" | grep -qi "telegram.*DISABLED"; then
    pass "Telegram initially disabled"
else
    fail "Telegram not shown as disabled"
fi

if echo "$STATUS_OUT" | grep -q "DISCORD_BOT_TOKEN"; then
    pass "Status shows Discord env var name"
else
    fail "Status missing Discord env var"
fi

if echo "$STATUS_OUT" | grep -q "TELEGRAM_BOT_TOKEN"; then
    pass "Status shows Telegram env var name"
else
    fail "Status missing Telegram env var"
fi

if echo "$STATUS_OUT" | grep -q "NOT SET"; then
    pass "Status shows tokens as NOT SET"
else
    fail "Status doesn't show NOT SET for tokens"
fi

# --- Phase 3: Enable Discord ---
echo ""
echo "Phase 3: Enable Discord"

ENABLE_OUT=$(run_channel --enable discord)

if echo "$ENABLE_OUT" | grep -q "SUCCESS"; then
    pass "Enable discord reports SUCCESS"
else
    fail "Enable discord didn't report SUCCESS"
fi

if echo "$ENABLE_OUT" | grep -q "WARNING"; then
    pass "Enable warns about missing token"
else
    fail "Enable didn't warn about missing token"
fi

if echo "$ENABLE_OUT" | grep -q "discord.com/developers"; then
    pass "Enable shows Discord setup URL"
else
    fail "Enable missing Discord setup URL"
fi

if echo "$ENABLE_OUT" | grep -qi "restart"; then
    pass "Enable mentions container restart"
else
    fail "Enable doesn't mention restart"
fi

# Verify config was updated
if grep -q '"channels"' "$TEST_CONFIG" && ! grep -q '// *"channels"' "$TEST_CONFIG"; then
    pass "Config has active channels block"
else
    fail "Config missing active channels block"
fi

if grep -q '"discord"' "$TEST_CONFIG"; then
    pass "Config contains discord channel"
else
    fail "Config missing discord channel"
fi

if grep -q 'DISCORD_BOT_TOKEN' "$TEST_CONFIG"; then
    pass "Config references DISCORD_BOT_TOKEN"
else
    fail "Config missing DISCORD_BOT_TOKEN reference"
fi

if grep -q '"groupPolicy"' "$TEST_CONFIG"; then
    pass "Discord has groupPolicy setting"
else
    fail "Discord missing groupPolicy"
fi

if grep -q '"activity": "AgentOrg"' "$TEST_CONFIG"; then
    pass "Discord has AgentOrg activity"
else
    fail "Discord missing activity"
fi

# --- Phase 4: Status after Discord enabled ---
echo ""
echo "Phase 4: Status (Discord enabled)"

STATUS_OUT2=$(run_channel --status)

if echo "$STATUS_OUT2" | grep -qi "discord.*ENABLED"; then
    pass "Status shows Discord enabled"
else
    fail "Status doesn't show Discord enabled"
fi

if echo "$STATUS_OUT2" | grep -qi "telegram.*DISABLED"; then
    pass "Status shows Telegram still disabled"
else
    fail "Status doesn't show Telegram disabled"
fi

if echo "$STATUS_OUT2" | grep -q "Active channels.*discord"; then
    pass "Active channels lists discord"
else
    fail "Active channels missing discord"
fi

# --- Phase 5: Idempotency ---
echo ""
echo "Phase 5: Idempotency"

IDEM_OUT=$(run_channel --enable discord)

if echo "$IDEM_OUT" | grep -q "already enabled"; then
    pass "Re-enabling discord is idempotent"
else
    fail "Re-enabling discord didn't report idempotent"
fi

# Verify config unchanged
DISCORD_COUNT=$(grep -c '"discord"' "$TEST_CONFIG")
if [ "$DISCORD_COUNT" -le 2 ]; then
    pass "Config not duplicated on re-enable"
else
    fail "Config duplicated discord block"
fi

# --- Phase 6: Enable Telegram (second channel) ---
echo ""
echo "Phase 6: Enable Telegram (second channel)"

TELE_OUT=$(run_channel --enable telegram)

if echo "$TELE_OUT" | grep -q "SUCCESS"; then
    pass "Enable telegram reports SUCCESS"
else
    fail "Enable telegram didn't report SUCCESS"
fi

if echo "$TELE_OUT" | grep -q "t.me/BotFather"; then
    pass "Enable shows Telegram setup URL"
else
    fail "Enable missing Telegram setup URL"
fi

# Both channels should be in config
STATUS_BOTH=$(run_channel --status)

if echo "$STATUS_BOTH" | grep -qi "discord.*ENABLED"; then
    pass "Discord still enabled"
else
    fail "Discord lost after enabling telegram"
fi

if echo "$STATUS_BOTH" | grep -qi "telegram.*ENABLED"; then
    pass "Telegram now enabled"
else
    fail "Telegram not enabled"
fi

if echo "$STATUS_BOTH" | grep -q "Active channels.*discord.*telegram\|Active channels.*telegram.*discord"; then
    pass "Active channels lists both"
else
    fail "Active channels missing one"
fi

if grep -q '"dmPolicy": "pairing"' "$TEST_CONFIG"; then
    pass "Telegram has dmPolicy: pairing"
else
    fail "Telegram missing dmPolicy"
fi

# --- Phase 7: Disable Discord (one of two) ---
echo ""
echo "Phase 7: Disable Discord (telegram remains)"

DIS_OUT=$(run_channel --disable discord)

if echo "$DIS_OUT" | grep -q "SUCCESS"; then
    pass "Disable discord reports SUCCESS"
else
    fail "Disable discord didn't report SUCCESS"
fi

if echo "$DIS_OUT" | grep -qi "restart"; then
    pass "Disable mentions restart"
else
    fail "Disable doesn't mention restart"
fi

STATUS_ONE=$(run_channel --status)

if echo "$STATUS_ONE" | grep -qi "discord.*DISABLED"; then
    pass "Discord now disabled"
else
    fail "Discord still shown as enabled"
fi

if echo "$STATUS_ONE" | grep -qi "telegram.*ENABLED"; then
    pass "Telegram still enabled"
else
    fail "Telegram lost when disabling discord"
fi

# --- Phase 8: Disable Telegram (last channel) ---
echo ""
echo "Phase 8: Disable Telegram (last channel)"

DIS_TELE=$(run_channel --disable telegram)

if echo "$DIS_TELE" | grep -q "SUCCESS"; then
    pass "Disable telegram reports SUCCESS"
else
    fail "Disable telegram didn't report SUCCESS"
fi

STATUS_NONE=$(run_channel --status)

if echo "$STATUS_NONE" | grep -qi "discord.*DISABLED"; then
    pass "Discord disabled"
else
    fail "Discord not disabled"
fi

if echo "$STATUS_NONE" | grep -qi "telegram.*DISABLED"; then
    pass "Telegram disabled"
else
    fail "Telegram not disabled"
fi

if echo "$STATUS_NONE" | grep -q "commented out"; then
    pass "Status shows all channels commented out"
else
    fail "Status doesn't show commented out message"
fi

# Config should have commented channel block
if grep -q '// .*"channels"' "$TEST_CONFIG"; then
    pass "Config has commented channels block"
else
    fail "Config missing commented channels block"
fi

# --- Phase 9: Disable already-disabled (idempotent) ---
echo ""
echo "Phase 9: Disable idempotency"

IDEM_DIS=$(run_channel --disable discord)

if echo "$IDEM_DIS" | grep -q "already disabled"; then
    pass "Disabling already-disabled is idempotent"
else
    fail "Disabling already-disabled didn't report idempotent"
fi

# --- Phase 10: Enable with token set in .env ---
echo ""
echo "Phase 10: Token detection"

# Write a real-looking token to .env
cat > "$TEST_ENV" << 'EOF'
DISCORD_BOT_TOKEN=MTIzNDU2Nzg5.AbCdEf.GhIjKlMnOpQrStUvWxYz1234
TELEGRAM_BOT_TOKEN=
EOF

TOKEN_STATUS=$(run_channel --status)

if echo "$TOKEN_STATUS" | grep -q "MTIzNDU2"; then
    pass "Status shows masked Discord token"
else
    fail "Status doesn't show masked token"
fi

TOKEN_ENABLE=$(run_channel --enable discord)

if echo "$TOKEN_ENABLE" | grep -q "SUCCESS"; then
    pass "Enable with token works"
else
    fail "Enable with token failed"
fi

if ! echo "$TOKEN_ENABLE" | grep -q "WARNING"; then
    pass "No warning when token is set"
else
    fail "Unnecessary warning when token is set"
fi

# --- Phase 11: Error handling ---
echo ""
echo "Phase 11: Error handling"

ERR_OUT=$(python3 "$PROJECT_DIR/scripts/enable-channel.py" --enable discord --project "$TEST_DIR" --config "/tmp/nonexistent/config.json" 2>&1)
ERR_CODE=$?

if [ "$ERR_CODE" -ne 0 ]; then
    pass "Missing config returns non-zero exit"
else
    fail "Missing config returns zero exit"
fi

if echo "$ERR_OUT" | grep -qi "not found\|error"; then
    pass "Missing config shows error message"
else
    fail "Missing config no error message"
fi

# --- Phase 12: Config integrity after full cycle ---
echo ""
echo "Phase 12: Config integrity"

# Re-enable both channels, then verify the rest of the config is intact
run_channel --enable discord > /dev/null 2>&1
run_channel --enable telegram > /dev/null 2>&1

# Check that non-channel parts of config are preserved
if grep -q '"orchestrator"' "$TEST_CONFIG"; then
    pass "Orchestrator agent preserved"
else
    fail "Orchestrator agent lost"
fi

if grep -q '"core-assistant"' "$TEST_CONFIG"; then
    pass "Core-assistant agent preserved"
else
    fail "Core-assistant agent lost"
fi

if grep -q '"research"' "$TEST_CONFIG"; then
    pass "Research agent preserved"
else
    fail "Research agent preserved check — may be in channels section"
fi

if grep -q '"gateway"' "$TEST_CONFIG"; then
    pass "Gateway section preserved"
else
    fail "Gateway section lost"
fi

if grep -q '"hooks"' "$TEST_CONFIG"; then
    pass "Hooks section preserved"
else
    fail "Hooks section lost"
fi

if grep -q '"messages"' "$TEST_CONFIG"; then
    pass "Messages section preserved"
else
    fail "Messages section lost"
fi

if grep -q '"commands"' "$TEST_CONFIG"; then
    pass "Commands section preserved"
else
    fail "Commands section preserved"
fi

if grep -q '"tools"' "$TEST_CONFIG"; then
    pass "Tools section preserved"
else
    fail "Tools section lost"
fi

# --- Phase 13: Gateway config coherence ---
echo ""
echo "Phase 13: Gateway config coherence"

# The channels block should be between tools and messages
CHANNELS_LINE=$(grep -n '"channels"' "$TEST_CONFIG" | grep -v '//' | head -1 | cut -d: -f1)
MESSAGES_LINE=$(grep -n '"messages"' "$TEST_CONFIG" | grep -v '//' | head -1 | cut -d: -f1)
TOOLS_LINE=$(grep -n '"tools"' "$TEST_CONFIG" | grep -v '//' | head -1 | cut -d: -f1)

if [ -n "$CHANNELS_LINE" ] && [ -n "$MESSAGES_LINE" ] && [ "$CHANNELS_LINE" -lt "$MESSAGES_LINE" ]; then
    pass "Channels block is before messages block"
else
    fail "Channels block ordering wrong"
fi

# Channel tokens use env var substitution (${VAR} syntax)
if grep -q '${DISCORD_BOT_TOKEN}' "$TEST_CONFIG"; then
    pass "Discord token uses env var substitution"
else
    fail "Discord token not using env var substitution"
fi

if grep -q '${TELEGRAM_BOT_TOKEN}' "$TEST_CONFIG"; then
    pass "Telegram token uses env var substitution"
else
    fail "Telegram token not using env var substitution"
fi

# Docker-compose passes these env vars to the container
if grep -q 'DISCORD_BOT_TOKEN' "$PROJECT_DIR/docker-compose.yml"; then
    pass "Docker compose forwards DISCORD_BOT_TOKEN"
else
    fail "Docker compose missing DISCORD_BOT_TOKEN"
fi

if grep -q 'TELEGRAM_BOT_TOKEN' "$PROJECT_DIR/docker-compose.yml"; then
    pass "Docker compose forwards TELEGRAM_BOT_TOKEN"
else
    fail "Docker compose missing TELEGRAM_BOT_TOKEN"
fi

# .env.example documents the token vars
if grep -q 'DISCORD_BOT_TOKEN' "$PROJECT_DIR/.env.example"; then
    pass ".env.example documents DISCORD_BOT_TOKEN"
else
    fail ".env.example missing DISCORD_BOT_TOKEN"
fi

if grep -q 'TELEGRAM_BOT_TOKEN' "$PROJECT_DIR/.env.example"; then
    pass ".env.example documents TELEGRAM_BOT_TOKEN"
else
    fail ".env.example missing TELEGRAM_BOT_TOKEN"
fi

# --- Summary ---
echo ""
if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}Channel configuration smoke test: ${PASS}/${TOTAL} passed${NC}"
else
    echo -e "${RED}Channel configuration smoke test: ${PASS}/${TOTAL} passed (${FAIL} failed)${NC}"
fi

exit "$FAIL"
