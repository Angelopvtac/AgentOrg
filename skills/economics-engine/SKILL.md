# Economics Engine Skill

Financial nervous system for AgentOrg. Tracks every dollar in and out — API costs per agent, infrastructure costs, revenue, treasury balance, burn rate, and budget enforcement. Not optional.

## Data Sources

| File | Purpose |
|------|---------|
| `config/economics.json` | Budget rules, thresholds, allocation formula |
| `vault/economics/daily-budget.json` | Daily spend tracking and alert thresholds |
| `vault/economics/costs.json` | Cost event log (API + infrastructure) |
| `vault/economics/revenue.json` | Revenue event log |
| `vault/economics/treasury.json` | Derived summary: balance, burn rate, runway |

## Tools

### `econ_log_cost`

Record a cost event (API usage or infrastructure expense).

**Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| agent | string | yes | Agent ID that incurred the cost |
| type | string | yes | One of: `api`, `infrastructure`, `tool`, `payment-processing` |
| amount | number | yes | Cost in USD |
| description | string | yes | What the cost was for |
| modelTier | number | no | Model tier (1/2/3) — required if type is `api` |
| tokensIn | number | no | Input tokens — if type is `api` |
| tokensOut | number | no | Output tokens — if type is `api` |

**Behavior:**

1. Read `vault/economics/costs.json`
2. Create cost entry:

```json
{
  "id": "<uuid>",
  "timestamp": "<ISO 8601>",
  "agent": "<agent-id>",
  "type": "<cost-type>",
  "amount": "<usd>",
  "description": "<what>",
  "modelTier": "<tier or null>",
  "tokensIn": "<tokens or null>",
  "tokensOut": "<tokens or null>",
  "phase": "<current phase from phase-state.json>"
}
```

3. Append to `entries` array
4. Write updated file
5. Update daily budget tracking (see `_update_daily_spend`)
6. Check budget thresholds — if exceeded, trigger alert or pause
7. Recalculate treasury (see `_recalc_treasury`) to keep balance current

### `econ_log_revenue`

Record a revenue event.

**Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| amount | number | yes | Revenue amount in USD |
| source | string | yes | Payment source: `stripe`, `gumroad`, `manual`, `other` |
| description | string | yes | What was sold / revenue description |
| customerId | string | no | Customer identifier for attribution |
| channel | string | no | Acquisition channel: `twitter`, `email`, `direct`, `referral`, `other` |
| agent | string | no | Agent that sourced/closed the sale |
| contentId | string | no | Content piece that drove the conversion |

**Behavior:**

1. Read `vault/economics/revenue.json`
2. Create revenue entry:

```json
{
  "id": "<uuid>",
  "timestamp": "<ISO 8601>",
  "amount": "<usd>",
  "source": "<source>",
  "description": "<what>",
  "customerId": "<customer or null>",
  "channel": "<channel or null>",
  "agent": "<agent or null>",
  "contentId": "<content or null>",
  "phase": "<current phase>"
}
```

3. Append to `entries` array
4. Write updated file
5. Recalculate treasury (see `_recalc_treasury`)

### `econ_log_refund`

Record a refund or chargeback.

**Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| originalRevenueId | string | yes | ID of the original revenue entry being refunded |
| amount | number | yes | Refund amount in USD |
| reason | string | yes | Reason for refund |

**Behavior:**

1. Read `vault/economics/revenue.json`
2. Locate original entry by `originalRevenueId` — if not found, log warning
3. Create refund entry:

```json
{
  "id": "<uuid>",
  "timestamp": "<ISO 8601>",
  "type": "refund",
  "originalRevenueId": "<id>",
  "amount": "<negative usd>",
  "reason": "<reason>",
  "phase": "<current phase>"
}
```

4. Append to `entries` array (negative amount)
5. Recalculate treasury

### `econ_get_treasury`

Get the current treasury balance and financial summary.

**Parameters:** None

**Behavior:**

1. Read `vault/economics/treasury.json`
2. If stale (older than 1 hour), recalculate from raw data
3. Return:

```json
{
  "balance": "<total revenue - total costs>",
  "totalRevenue": "<sum of all revenue>",
  "totalCosts": "<sum of all costs>",
  "netMargin": "<(revenue - costs) / revenue * 100>%",
  "lastUpdated": "<timestamp>"
}
```

### `econ_get_burn_rate`

Calculate current burn rate and runway.

**Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| window | number | no | Rolling window in days (default: 7) |

**Behavior:**

1. Read `vault/economics/costs.json`
2. Filter entries within the rolling window
3. Calculate:
   - **Daily burn rate**: Total costs in window / number of days in window
   - **Monthly projected burn**: Daily burn rate * 30
   - **Runway** (days): `dailyLimit / dailyBurnRate` — days of budget remaining at current burn rate. If `dailyBurnRate` is 0, runway is effectively unlimited (return `null`).
4. Return:

```json
{
  "dailyBurn": "<usd/day>",
  "monthlyProjectedBurn": "<usd/month>",
  "runway": {
    "days": "<calculated>",
    "basis": "<budget-based or revenue-based>"
  },
  "window": "<days>",
  "trend": "<increasing | stable | decreasing>"
}
```

### `econ_get_agent_costs`

Get cost breakdown by agent.

**Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| period | string | no | `today`, `week`, `month`, `all` (default: `month`) |
| agent | string | no | Filter to specific agent (default: all agents) |

**Behavior:**

1. Read `vault/economics/costs.json`
2. Filter by period and optionally by agent
3. Aggregate by agent:

```json
{
  "period": "<period>",
  "agents": {
    "<agent-id>": {
      "totalCost": "<usd>",
      "apiCost": "<usd>",
      "requestCount": "<number>",
      "avgCostPerRequest": "<usd>",
      "tierBreakdown": {
        "tier1": "<usd>",
        "tier2": "<usd>",
        "tier3": "<usd>"
      }
    }
  },
  "totalAllAgents": "<usd>"
}
```

### `econ_get_budget_status`

Check current daily budget utilization and alert status.

**Parameters:** None

**Behavior:**

1. Read `vault/economics/daily-budget.json`
2. Calculate utilization: `spent / dailyLimit`
3. Return:

```json
{
  "dailyLimit": "<usd>",
  "spent": "<usd>",
  "remaining": "<usd>",
  "utilization": "<percentage>",
  "status": "<ok | warning | paused | kill-switch>",
  "breakdown": {
    "tier1": "<usd>",
    "tier2": "<usd>",
    "tier3": "<usd>"
  }
}
```

Status thresholds (from `daily-budget.json` alerts):
- `ok`: utilization < 80%
- `warning`: utilization >= 80% and < 100%
- `paused`: utilization >= 100% and < 200% — non-critical agents should pause
- `kill-switch`: utilization >= 200% — ALL non-essential agents must stop immediately

### `econ_set_budget`

Update the daily budget limit.

**Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| dailyLimit | number | yes | New daily budget in USD |
| reason | string | yes | Why the budget is being changed |

**Behavior:**

1. Read `vault/economics/daily-budget.json`
2. Log the change in history:

```json
{
  "timestamp": "<ISO 8601>",
  "previousLimit": "<old>",
  "newLimit": "<new>",
  "reason": "<reason>",
  "changedBy": "<agent-id>"
}
```

3. Update `dailyLimit`
4. Write updated file
5. Only the orchestrator and founder may change the budget

### `econ_get_revenue_attribution`

Trace revenue back to channel, agent, and content.

**Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| period | string | no | `week`, `month`, `all` (default: `month`) |
| groupBy | string | no | `channel`, `agent`, `content` (default: `channel`) |

**Behavior:**

1. Read `vault/economics/revenue.json`
2. Filter by period
3. Group by the specified dimension
4. Return:

```json
{
  "period": "<period>",
  "groupBy": "<dimension>",
  "groups": {
    "<group-key>": {
      "revenue": "<usd>",
      "transactions": "<count>",
      "avgTransaction": "<usd>"
    }
  },
  "total": "<usd>"
}
```

## Internal Operations

### `_update_daily_spend`

Called after every `econ_log_cost`. Not a public tool.

1. Read `vault/economics/daily-budget.json`
2. Check if `currentDate` matches today's date
   - If not: archive today's entry to `history`, reset `spent` and `breakdown` to 0, set `currentDate` to today
3. Add the new cost amount to `spent`
4. Add to the appropriate tier in `breakdown`
5. Write updated file
6. Evaluate thresholds and return alert status

### `_recalc_treasury`

Called after revenue or cost changes. Not a public tool.

1. Read `vault/economics/costs.json` — sum all `entries[].amount`
2. Read `vault/economics/revenue.json` — sum all `entries[].amount` (including negative refunds)
3. Calculate:
   - `balance = totalRevenue - totalCosts`
   - `revenueToExpenseRatio = totalRevenue / totalCosts` (use 0 if totalCosts == 0 to avoid division by zero)
   - `netMargin = (totalRevenue - totalCosts) / totalRevenue * 100` (use 0 if totalRevenue == 0 to avoid division by zero)
4. Write to `vault/economics/treasury.json`:

```json
{
  "balance": "<usd>",
  "totalRevenue": "<usd>",
  "totalCosts": "<usd>",
  "revenueToExpenseRatio": "<ratio>",
  "netMargin": "<percentage>",
  "lastUpdated": "<ISO 8601>"
}
```

## Budget Enforcement

The orchestrator uses `econ_get_budget_status` during its routing loop to enforce spending limits:

### Alert Escalation

| Threshold | Action |
|-----------|--------|
| **80% (warning)** | Orchestrator logs warning. Agents prefer lower model tiers where possible. |
| **100% (pause)** | Non-critical agents pause operations. Only orchestrator + core-assistant remain active. Critical human task queue items still delivered. |
| **200% (kill-switch)** | ALL agents except orchestrator stop immediately. Orchestrator sends emergency alert to founder. No new API calls except the alert itself. |

### Post-Kill-Switch Recovery

1. Orchestrator sends founder a message: "Daily budget exceeded 2x. All agents paused. Current spend: $X / $Y limit."
2. Founder must acknowledge and either increase budget or wait for next day reset
3. On acknowledgement or new day: reset daily spend, resume normal operations
4. Log the kill-switch event in `vault/economics/costs.json` history for audit

## Access Control

| Agent | Permissions |
|-------|-------------|
| orchestrator | Full access: all tools |
| core-assistant | Read only: get_treasury, get_budget_status, get_burn_rate |
| finance (future) | Full read + log_cost, log_revenue, log_refund |
| audit (future) | Full read access for verification |
| sales (future) | log_revenue only |
| All other agents | get_budget_status only (to self-regulate) |

## Storage File Formats

### `vault/economics/costs.json`

```json
{
  "collection": "costs",
  "description": "All cost events — API usage and infrastructure",
  "entries": []
}
```

### `vault/economics/revenue.json`

```json
{
  "collection": "revenue",
  "description": "All revenue events including refunds",
  "entries": []
}
```

### `vault/economics/treasury.json`

```json
{
  "balance": 0.00,
  "totalRevenue": 0.00,
  "totalCosts": 0.00,
  "revenueToExpenseRatio": 0,
  "netMargin": 0,
  "lastUpdated": null
}
```
