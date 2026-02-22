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
- Calculate `percent = spent / dailyLimit`
- If percent >= 0.80 → send warning to founder via core-assistant
- If percent >= 1.00 → pause non-critical operations, notify founder
- If percent >= 3.00 → emergency stop, urgent founder alert

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

### 6. Queued Agent Messages
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
