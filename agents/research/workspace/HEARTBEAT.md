# Research Agent — Heartbeat

## Interval

Every 360 minutes (6 hours).

## Checks

On each heartbeat, perform the following:

### 1. Phase Verification
- Read `vault/phase-state.json`
- Confirm `currentPhase` is L1 or higher — if still L0, this agent should not be active
- If phase regressed (unexpected), notify orchestrator

### 2. Research State Check
- List files in `vault/research/`
- If L1 and no research reports exist → the market-research-done gate criterion is unmet
- If a market scan was started but not completed, note the gap

### 3. Direction State Check
- Read `vault/business/direction.json`
- If direction is still null and research reports exist → the founder hasn't selected a direction yet
- Consider queuing a reminder via orchestrator to core-assistant

### 4. Brand Brief State Check
- Read `vault/business/brand-brief.json`
- If direction is selected but brand brief is empty → brand research may be needed
- If brand research reports exist but brief is incomplete → note for orchestrator

### 5. L1 Gate Progress
- Check all three L1 criteria:
  - direction-selected: `vault/business/direction.json` has non-null fields?
  - brand-brief-complete: `vault/business/brand-brief.json` has required fields?
  - market-research-done: `vault/research/` contains at least one report?
- If all three pass, notify orchestrator that L1 gate may be ready for evaluation

### 6. Pending Research Requests
- Check for unprocessed messages from the orchestrator
- Process any queued research tasks

## Actions on Wake

| Condition | Action |
|-----------|--------|
| No research reports in L1 | Begin market scan from founder profile |
| Direction selected, no competitive analysis | Start competitive analysis |
| Direction confirmed, no brand research | Start brand research |
| All L1 gate criteria appear met | Notify orchestrator for gate evaluation |
| Orchestrator message pending | Process research request |
| Phase is L2+ | Shift to monitoring mode — check competitors, trends |
