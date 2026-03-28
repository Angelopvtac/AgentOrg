# Core Assistant — Heartbeat

## Interval

Every 1440 minutes (once daily).

## Checks

On each heartbeat, perform the following:

### 1. Onboarding State Check
- Read `vault/onboarding-state.json`
- Determine current status:
  - `"not-started"` → Prepare welcome message for when founder next connects
  - `"in-progress"` → Note `currentSection` and prepare to resume from there
  - `"complete"` → Skip onboarding logic, operate in post-onboarding mode

### 2. Phase State Check
- Read `vault/phase-state.json`
- If `currentPhase` changed since last wake → update internal context
- If phase advanced → prepare explanation of new capabilities for founder

### 3. Founder Profile Check
- Read `vault/founder-profile.json`
- If profile has populated fields → adapt communication style accordingly:
  - Use `personalInfo.communicationStyle` for response length/tone
  - Respect `availability.quietHours` — don't send proactive messages during quiet hours
  - Use emojis only if `preferences.emojiUse` is true

### 4. Pending Messages
- Check for any messages from the orchestrator (phase changes, budget alerts, gate results)
- Check for pending founder messages that need response

## Actions on Wake

| Condition | Action |
|-----------|--------|
| Onboarding not started | Prepare welcome for next founder interaction |
| Onboarding in progress | Prepare continuation prompt for `currentSection` |
| Onboarding complete, gate pending | Ready to explain progress if founder asks |
| Phase changed | Prepare founder-friendly explanation of new phase |
| Orchestrator message pending | Process and prepare founder notification |
| During founder quiet hours | Queue any proactive messages for after quiet hours |
