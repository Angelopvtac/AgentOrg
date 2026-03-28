# Daily Briefing Pipeline
#
# Trigger: Cron — daily at founder's preferred time (default 09:00 UTC)
# Owner: orchestrator
# Delivery: core-assistant
# Phase: All phases (adapts content based on currentPhase)

---
pipeline: daily-briefing
version: 1.0.0
trigger:
  type: cron
  schedule: "0 9 * * *"
  adjust_to: vault/founder-profile.json → personalInfo.timezone
  fallback: UTC

---

## Step 1: Gather Phase Status

agent: orchestrator
tier: 1
input:
  - vault/phase-state.json
output:
  - phase_block

actions:
  - Read vault/phase-state.json
  - Extract: currentPhase, phaseName, phaseStartDate, gateResults
  - Count passing criteria vs total for current phase
  - Identify next unmet gate criterion (first false in gateResults)
  - If no gateResults exist, report "No evaluation yet"

format:
  ```
  PHASE: {currentPhase} — {phaseName} (since {phaseStartDate})
  GATE: {passing}/{total} criteria met. Next: {next_unmet_criterion}
  ```

---

## Step 2: Gather Budget Status

agent: orchestrator
tier: 1
input:
  - vault/economics/daily-budget.json
output:
  - budget_block

actions:
  - Read vault/economics/daily-budget.json
  - If currentDate != today: reset spent/breakdown to 0, set currentDate to today, archive to history
  - Calculate percentage: (spent / dailyLimit) * 100
  - Extract tier breakdown from breakdown object

format:
  ```
  BUDGET: ${spent} / ${dailyLimit} ({percent}%)
    Tier 1: ${tier1} | Tier 2: ${tier2} | Tier 3: ${tier3}
  ```

alert_thresholds:
  - 80%: Flag as warning in briefing
  - 100%: Flag as paused in briefing
  - 200%: Flag as emergency in briefing

---

## Step 3: Gather Pending Tasks

agent: orchestrator
tier: 1
input:
  - vault/human-tasks.json
output:
  - tasks_block

actions:
  - Read vault/human-tasks.json
  - Count tasks by status (pending, in-progress, completed)
  - Count by priority (critical, high, medium, low)
  - Identify overdue tasks (dueDate < today AND status != completed)
  - Sum estimatedMinutes for pending tasks

format:
  ```
  TASKS: {pending_count} pending ({critical_count} critical, {overdue_count} overdue)
    Est. time: ~{total_minutes} min
    {list critical task titles if any}
  ```

empty_state: "TASKS: No pending tasks"

---

## Step 4: Gather Recent Knowledge

agent: orchestrator
tier: 1
input:
  - vault/decisions.json
  - vault/insights.json
  - vault/lessons.json
output:
  - knowledge_block

actions:
  - Read all three knowledge graph files
  - Filter entries created in the last 24 hours (createdAt >= yesterday)
  - Count by type

format:
  ```
  KNOWLEDGE (last 24h):
    {decisions_count} new decisions, {insights_count} new insights, {lessons_count} new lessons
  ```

empty_state: "KNOWLEDGE (last 24h): No new entries"

---

## Step 5: Gather Phase-Specific Context

agent: orchestrator
tier: 1
input:
  - vault/phase-state.json (for currentPhase)
  - vault/onboarding-state.json (L0 only)
  - vault/business/direction.json (L1 only)
  - vault/metrics/social.json (L2 only)
  - vault/economics/revenue.json (L3+ only)
output:
  - phase_context_block

conditions:
  L0:
    actions:
      - Read vault/onboarding-state.json
      - Count completed vs total sections
      - Identify current section
    format:
      ```
      ONBOARDING: {completed}/{total} sections complete. Current: {current_section}
      ```

  L1:
    actions:
      - Read vault/business/direction.json
      - Read vault/research/ for report count
      - Read vault/business/brand-brief.json
    format:
      ```
      DISCOVERY: Direction {selected|pending}. {report_count} research reports. Brand brief {complete|in-progress|pending}.
      ```

  L2:
    actions:
      - Read vault/metrics/social.json
    format:
      ```
      PRESENCE: {totalFollowers} followers, {engagementRate}% engagement, {postsPublished} posts
      ```

  L3+:
    actions:
      - Read vault/economics/revenue.json
      - Read vault/economics/treasury.json
    format:
      ```
      REVENUE: ${totalRevenue} total, {customer_count} customers, ${treasury_balance} treasury
      ```

---

## Step 6: Compile Briefing

agent: orchestrator
tier: 1
input:
  - phase_block (from Step 1)
  - budget_block (from Step 2)
  - tasks_block (from Step 3)
  - knowledge_block (from Step 4)
  - phase_context_block (from Step 5)
output:
  - compiled_briefing

actions:
  - Combine all blocks into a single briefing message
  - Prepend header: "[DAILY BRIEFING]\nDate: {today}"
  - Append phase-specific context block at the end

format:
  ```
  [DAILY BRIEFING]
  Date: {today}

  {phase_block}

  {budget_block}

  {tasks_block}

  {knowledge_block}

  {phase_context_block}
  ```

---

## Step 7: Deliver to Core Assistant

agent: orchestrator
tier: 1
input:
  - compiled_briefing
output:
  - delivery_confirmation

actions:
  - Send compiled_briefing to core-assistant via sessions_send target agent:core-assistant:main
  - Include instruction: "Format this briefing for the founder using their communication style from vault/founder-profile.json"
  - Core-assistant formats based on personalInfo.communicationStyle:
    - concise: Bullet points, numbers only
    - detailed: Full paragraphs with context
    - casual: Relaxed conversational tone
    - formal: Structured, professional
  - Core-assistant checks quiet hours before delivering to founder
  - Core-assistant delivers formatted briefing to founder

---

## Step 8: Update Briefing State

agent: orchestrator
tier: 1
input:
  - compiled_briefing
  - delivery_confirmation
output:
  - vault/briefing-state.json (updated)

actions:
  - Read vault/briefing-state.json
  - Set lastBriefingSent to current ISO 8601 timestamp
  - Set lastBriefingContent to a summary of what was included (phase, budget %, task count, knowledge count)
  - Append to briefingHistory: { timestamp, summary, phase, delivered: true/false }
  - Write updated file back

---

## Error Handling

- If any vault file is missing or malformed: skip that section, note "(data unavailable)" in the briefing
- If core-assistant is unreachable: log error, retry once after 60 seconds, then store briefing for next delivery attempt
- If budget data shows anomaly (spent > 2x dailyLimit): prepend URGENT flag to briefing
- If gate evaluation shows regression (fewer passing criteria than last briefing): flag in phase block

## Success Criteria

The pipeline succeeds when:
1. All available vault data is gathered (missing files are gracefully handled)
2. Briefing is compiled with all non-empty blocks
3. Briefing is delivered to core-assistant
4. briefing-state.json is updated with current timestamp and summary
