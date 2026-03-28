# Orchestrator — Heartbeat

## Interval

Every 60 minutes.

## Checks

On each heartbeat, perform the following in order:

### 1. Phase State Check
- Read `vault/phase-state.json`
- Confirm `currentPhase` is valid
- If `phaseStartDate` is null and phase is L0, note that BOOT.md hasn't run yet (or hasn't completed)

### 2. Budget Check
- Read `vault/economics/daily-budget.json`
- If `currentDate` doesn't match today → reset `spent` and `breakdown` to zero, update `currentDate`
  - **Idempotent**: This reset is safe to run multiple times — if `currentDate` already matches today, the reset is a no-op. The `daily-budget-reset` cron job performs the same operation at midnight; the heartbeat serves as a catch-up mechanism if the cron was missed (e.g., gateway restart).
- Calculate `percent = spent / dailyLimit`
- If percent >= 0.80 → send warning to founder via core-assistant
- If percent >= 1.00 → pause non-critical operations, notify founder
- If percent >= 2.00 → emergency stop, urgent founder alert (kill switch at 2x daily limit)

### 3. Pending Messages
- Check for unrouted inbound messages across all channels
- Route any pending messages per the routing table in AGENTS.md

### 4. Agent Health
- Verify registered agents are responsive (core-assistant during L0)
- If an agent is unresponsive, log the issue and attempt recovery

### 5. Gate Progress (L0 only)
- Read `vault/onboarding-state.json`
- If `status` == "complete" and last gate evaluation was > 1 hour ago → run gate evaluation
- Log results to `vault/phase-state.json`

### 6. Daily Briefing Check
- Read `vault/briefing-state.json`
- If `lastBriefingSent` is null or not today's date, and it's past the scheduled briefing time (09:00 founder TZ, default UTC):
  - Trigger daily briefing generation (see Daily Briefing Generation in AGENTS.md)
  - This catches missed briefings from cron failures or gateway restarts

### 7. Queued Agent Messages
- Process any pending agent-to-agent messages
- Route responses back to originating agents

## Actions on Wake

| Condition | Action |
|-----------|--------|
| Pending messages exist | Route per routing table |
| Budget >= 80% | Alert founder via core-assistant |
| Budget >= 100% | Pause non-critical ops, notify founder |
| Onboarding complete + gate not recently evaluated | Run gate evaluation |
| Agent unresponsive | Log and attempt recovery |
| Phase transition criteria met | Trigger phase transition protocol |
| Briefing not sent today + past scheduled time | Generate and send daily briefing |
