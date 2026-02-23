# Progression Engine Skill

Evaluates phase gates, tracks evaluation history, and manages phase transitions across the L0–L6 lifecycle. The orchestrator uses this skill during daily evaluations and on-demand when agents report significant changes.

## Data Sources

| File | Purpose |
|------|---------|
| `config/progression.json` | Phase definitions, gate criteria, transition actions |
| `vault/phase-state.json` | Runtime state: current phase, history, last evaluation |
| `vault/founder-profile.json` | Onboarding data for L0 gate checks |
| `vault/onboarding-state.json` | Onboarding completion status |
| `vault/economics/daily-budget.json` | Budget data for L0 financial baseline check |
| `vault/economics/revenue.json` | Revenue data for L3+ gate checks |
| `vault/economics/costs.json` | Cost data for L4 revenue ratio check |
| `vault/economics/treasury.json` | Treasury summary for derived metrics |
| `vault/metrics/social.json` | Social metrics for L2 gate checks |
| `vault/business/direction.json` | Business direction for L1 gate |
| `vault/business/brand-brief.json` | Brand brief for L1 gate |
| `vault/research/` | Research reports for L1 gate |
| `vault/strategy/scaling-proposal.json` | Scaling proposal for L5 gate |

## Tools

### `gate_evaluate`

Evaluate all criteria for the current phase's gate.

**Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| phase | string | no | Phase to evaluate (default: current phase from phase-state.json) |

**Behavior:**

1. Read `vault/phase-state.json` to determine current phase (or use provided phase)
2. Read `config/progression.json` to get the gate criteria for that phase
3. For each criterion, evaluate based on gate type:

#### Checklist Gates (L0, L1)

For each criterion, read the file specified in `check` and verify the condition:

**L0 criteria evaluation:**
- `profile-complete`: Read `vault/founder-profile.json` → check `personalInfo.name`, `personalInfo.timezone`, `personalInfo.communicationStyle` are all non-null and non-empty
- `skills-identified`: Read `vault/founder-profile.json` → check `skills` array has `length >= 3`
- `availability-set`: Read `vault/founder-profile.json` → check `availability.weeklyHours > 0` and `availability.quietHours` is non-null
- `financial-baseline`: Read `vault/economics/daily-budget.json` → check `dailyLimit > 0`; read `vault/founder-profile.json` → check `financial.riskTolerance` is non-null
- `vision-defined`: Read `vault/founder-profile.json` → check `vision.statement` is non-null and `length > 50`
- `onboarding-complete`: Read `vault/onboarding-state.json` → check `status == "complete"`

**L1 criteria evaluation:**
- `direction-selected`: Check `vault/business/direction.json` exists and has non-null `targetMarket` and `description` fields
- `brand-brief-complete`: Check `vault/business/brand-brief.json` exists with non-null `name`, `positioning`, `tone` fields
- `market-research-done`: Check `vault/research/` directory contains at least one `.json` report file

#### Metric Gates (L2, L3, L4)

Fetch real metric values from data sources and compare against thresholds:

**L2 criteria evaluation:**
- `follower-count`: Read `vault/metrics/social.json` → check `totalFollowers >= 100`
- `engagement-rate`: Read `vault/metrics/social.json` → check `engagementRate >= 0.05` sustained for 7+ consecutive daily entries

**L3 criteria evaluation:**
- `first-revenue`: Read `vault/economics/revenue.json` → sum all `entries[].amount` → check `total >= 1.00`
- `paying-customer`: Read `vault/economics/revenue.json` → count distinct `entries[].customerId` → check `count >= 1`

**L4 criteria evaluation:**
- `revenue-ratio`: Read `vault/economics/treasury.json` → check `revenueToExpenseRatio >= 3.0`
- `repeat-rate`: Read `vault/economics/revenue.json` → calculate repeat customer rate → check `>= 0.15`

#### Approval Gates (L5)

- `scaling-proposal`: Read `vault/strategy/scaling-proposal.json` → check `status == "approved"`

#### Continuous Gates (L6)

No gate criteria — terminal phase. Monitor health metrics:
- Revenue covers operational costs (treasury positive)
- No vertical degradation for 30+ consecutive days
- Founder satisfaction above threshold

4. For each criterion, produce a result:

```json
{
  "id": "<criterion-id>",
  "status": "PASS | FAIL | ERROR",
  "target": "<what the criterion requires>",
  "actual": "<current measured value>",
  "detail": "<explanation if FAIL or ERROR>"
}
```

5. Determine overall gate status:
   - **PASSED**: All criteria have status `PASS`
   - **READY**: All criteria pass except one or two that are close (>80% of threshold) — flag as nearly ready
   - **OPEN**: One or more criteria are `FAIL`
   - **ERROR**: One or more criteria have `ERROR` (data source unavailable, parse failure)

6. Store the evaluation result (see `gate_log_evaluation`)
7. Return the gate report (see `gate_report` format)

### `gate_report`

Generate a formatted gate report for the current or specified phase.

**Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| phase | string | no | Phase to report on (default: current phase) |
| includeHistory | boolean | no | Include past evaluations (default: false) |

**Behavior:**

1. Run `gate_evaluate` if no recent evaluation exists (within last hour)
2. Format the report:

```
## Gate Report: <phase_name> (<phase_id>)

**Status**: <PASSED | READY | OPEN | ERROR>
**Days in phase**: <calculated from phaseStartDate>
**Last evaluated**: <timestamp>

### Criteria
| # | Criterion | Status | Target | Actual |
|---|-----------|--------|--------|--------|
| 1 | <description> | PASS/FAIL | <target> | <actual> |
| 2 | <description> | PASS/FAIL | <target> | <actual> |

### Recommendation
<If PASSED: "All criteria met. Ready to transition to <next_phase>.">
<If READY: "Nearly ready. <specific items> need attention.">
<If OPEN: "X of Y criteria unmet. Focus on: <list of failing criteria>.">
<If ERROR: "Evaluation errors encountered. Check data sources: <list>.">
```

3. If `includeHistory` is true, append trend data showing how criteria have progressed over recent evaluations.

### `gate_log_evaluation`

Store a gate evaluation result in the history.

**Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| phase | string | yes | Phase that was evaluated |
| results | object[] | yes | Array of per-criterion results |
| overallStatus | string | yes | One of: PASSED, READY, OPEN, ERROR |

**Behavior:**

1. Read `vault/phase-state.json`
2. Update `lastGateEvaluation` timestamp
3. Update `gateResults` with latest per-criterion results
4. Append to `history` array:

```json
{
  "timestamp": "<ISO 8601>",
  "phase": "<phase_id>",
  "status": "<overall_status>",
  "criteria": [
    { "id": "<criterion-id>", "status": "PASS|FAIL", "actual": "<value>" }
  ]
}
```

5. Write updated `vault/phase-state.json`

### `phase_get`

Get the current phase information.

**Parameters:** None

**Behavior:**

1. Read `vault/phase-state.json`
2. Read `config/progression.json` for phase definition
3. Return:

```json
{
  "currentPhase": "<id>",
  "phaseName": "<name>",
  "description": "<description>",
  "daysInPhase": "<calculated>",
  "activeAgents": ["<agent list>"],
  "gateCriteria": ["<criteria summaries>"],
  "lastGateStatus": "<from last evaluation>"
}
```

### `phase_transition`

Transition from the current phase to the next.

**Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| confirm | boolean | yes | Must be true — safety gate to prevent accidental transitions |

**Behavior:**

1. Read `vault/phase-state.json` for current phase
2. Read `config/progression.json` for transition definition
3. **Pre-check**: Run `gate_evaluate` — transition ONLY if status is `PASSED`
4. If gate is not PASSED, refuse transition and return the gate report showing what's unmet
5. If gate is PASSED and `confirm` is true:
   a. Record the current phase in history with end date
   b. Update `currentPhase` to the target phase
   c. Update `phaseName` to the target phase name
   d. Set `phaseStartDate` to current ISO 8601 timestamp
   e. Reset `gateResults` to empty (new phase, new gate)
   f. Write updated `vault/phase-state.json`
   g. Execute transition actions defined in `config/progression.json`:
      - Notify founder via core-assistant
      - Log transition event
   h. Return confirmation with new phase details and newly unlocked agents

### `phase_history`

Get the full phase transition history.

**Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| limit | number | no | Max history entries to return (default: all) |

**Behavior:**

1. Read `vault/phase-state.json`
2. Return `history` array sorted by timestamp descending
3. For each entry, include: phase entered, date entered, date exited (if applicable), gate evaluation count, days spent

## Failure Protocol

When a gate has been `OPEN` for an extended period (configurable, default: 14 days for L0-L1, 30 days for L2+), the progression engine triggers the failure protocol:

1. **Detection**: During daily gate evaluation, check `daysInPhase` against the phase's time limit
2. **Alert**: If approaching the limit (80% of time elapsed), warn the orchestrator
3. **Trigger**: If limit exceeded:
   a. Notify the orchestrator that pivot evaluation should begin
   b. Log the trigger event in `vault/phase-state.json` history
   c. Do NOT automatically transition — the pivot protocol skill handles the evaluation
4. **Pivot count**: Track total pivots in `vault/phase-state.json`. If count reaches 3, recommend full restart from L1

## Cron Schedule

The orchestrator should evaluate gates on this schedule:
- **L0**: On core-assistant notification that onboarding may be complete
- **L1**: Daily at briefing time
- **L2-L4**: Daily at briefing time (metric gates need fresh data)
- **L5**: On strategy agent notification
- **L6**: Weekly health check

## Access Control

| Agent | Permissions |
|-------|-------------|
| orchestrator | Full access: evaluate, transition, read history |
| core-assistant | Read only: phase_get, gate_report, phase_history |
| Future agents | Read access to phase_get for adapting behavior per phase |
