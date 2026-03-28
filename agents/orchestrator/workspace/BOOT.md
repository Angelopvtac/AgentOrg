# Orchestrator — First Boot Initialization

This file runs on gateway start. If `vault/.boot-complete` exists, skip all tasks — initialization already ran.

## Tasks

### 1. Set Phase Start Date

Read `vault/phase-state.json`. If `phaseStartDate` is null:
- Set `phaseStartDate` to the current ISO 8601 timestamp
- Write the updated file back

If `phaseStartDate` is already set, skip this step.

### 2. Verify Vault Structure

Confirm these files exist and are valid JSON:

- `vault/phase-state.json`
- `vault/founder-profile.json`
- `vault/onboarding-state.json`
- `vault/economics/daily-budget.json`
- `vault/economics/costs.json`
- `vault/economics/revenue.json`
- `vault/economics/treasury.json`

If any file is missing or malformed, log an error. Do NOT attempt to recreate — this indicates a deployment issue.

### 3. Initialize Daily Budget

Read `vault/economics/daily-budget.json`. If `currentDate` is null:
- Set `currentDate` to today's date (YYYY-MM-DD)
- Ensure `spent` is 0.00
- Write the updated file back

### 4. Set Up Cron Jobs

Check if cron jobs already exist (use `cron_list`). If not, create:

**Daily Gate Check:**
```
cron_create:
  name: "daily-gate-check"
  schedule: "0 9 * * *"
  action: "Evaluate current phase gate criteria per config/progression.json. Read vault files, check all criteria, update vault/phase-state.json gateResults."
```

**Daily Budget Reset:**
```
cron_create:
  name: "daily-budget-reset"
  schedule: "0 0 * * *"
  action: "Archive current day budget to history in vault/economics/daily-budget.json. Reset spent to 0, breakdown to zeros, update currentDate to today."
```

**Daily Briefing:**
```
cron_create:
  name: "daily-briefing"
  schedule: "0 9 * * *"
  action: "Compile daily briefing from vault files (phase-state, daily-budget, human-tasks, decisions, insights, onboarding-state). Send compiled briefing to core-assistant for founder delivery. Update vault/briefing-state.json."
```

If cron jobs already exist with these names, skip creation.

### 5. Check Onboarding State

Read `vault/onboarding-state.json`:

- If `status` is `"not-started"`: The system is fresh. When the first founder message arrives, route it to `agent:core-assistant:main` to begin onboarding.
- If `status` is `"in-progress"`: Onboarding was interrupted. Route next founder message to core-assistant to resume.
- If `status` is `"complete"`: Run a gate evaluation to check if L0→L1 transition is ready.

### 6. Mark Boot Complete

After all tasks above are complete, create a sentinel file at `vault/.boot-complete` containing the current ISO 8601 timestamp. This prevents re-running initialization on gateway restarts.

**Check first**: If `vault/.boot-complete` already exists, SKIP ALL tasks above — boot has already run. Only proceed if the sentinel file is missing.
