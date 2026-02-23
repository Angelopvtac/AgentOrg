# Core Assistant — Tool Access

## Permissions

| Tool | Access | Notes |
|------|--------|-------|
| exec | none | Cannot execute commands |
| read | full | Can read all files and vault data |
| write | limited | Can write to specific vault files only (see below) |
| sessions | read | Can view sessions, cannot manage |
| cron | none | Cannot schedule jobs |
| agent-to-agent | send | Can message orchestrator and other agents |

## Vault Paths — Read Access

All vault files are at `/home/node/.openclaw/vault/`.

| Path | Purpose |
|------|---------|
| `vault/phase-state.json` | Current phase, gate results |
| `vault/founder-profile.json` | Founder profile data |
| `vault/onboarding-state.json` | Onboarding progress |
| `vault/economics/daily-budget.json` | Budget status (read-only) |
| `vault/briefing-state.json` | Latest briefing content and history (read-only) |

## Vault Paths — Write Access

You can write to these files only:

| Path | Purpose | When |
|------|---------|------|
| `vault/founder-profile.json` | Populate during onboarding, update on founder request | Sections 2-8 of onboarding |
| `vault/onboarding-state.json` | Track onboarding progress | After completing each section |
| `vault/economics/daily-budget.json` | Update `dailyLimit` from founder's financial preferences | Section 5 of onboarding only |

### Write rules

- Always read the file first, then modify specific fields, then write the complete object back
- Never delete existing data — only update or append
- Use ISO 8601 timestamps for all date fields
- If a write fails, inform the founder and retry once

## Config Paths — Read Only

| Path | Purpose |
|------|---------|
| `config/progression.json` | Phase definitions (for explaining gates to founder) |
| `config/schemas/founder-profile.json` | Profile schema (for validation reference) |

## Agent-to-Agent Messaging

Use `sessions_send` with target `agent:orchestrator:main`.

Only send to the orchestrator. Messages you send:
- Onboarding complete notification
- Founder operational requests (budget changes, status requests, etc.)
- Profile update notifications

## Skills

All shared skills at `/home/node/.openclaw/skills/`.

### Knowledge Graph (`skills/knowledge-graph`)

Read all collections. Write access to `insights` only.

| Tool | Access | Collections |
|------|--------|-------------|
| `kg_store` | write | insights only |
| `kg_read` | read | decisions, insights, lessons |
| `kg_search` | read | decisions, insights, lessons |
| `kg_list` | read | decisions, insights, lessons |

**Vault paths:**

| Path | Access |
|------|--------|
| `vault/decisions.json` | read |
| `vault/insights.json` | read/write |
| `vault/lessons.json` | read |

### Human Task Queue (`skills/human-task-queue`)

Read access and create only. Cannot complete tasks (founder action).

| Tool | Access |
|------|--------|
| `htq_create` | Create tasks for the founder |
| `htq_list` | List and filter tasks |
| `htq_complete` | **no access** |
| `htq_digest` | Generate pending task summary |

**Vault paths:**

| Path | Access |
|------|--------|
| `vault/human-tasks.json` | read, append (create only) |

### Progression Engine (`skills/progression-engine`)

Read-only access. Use to explain phase status and gate progress to the founder.

| Tool | Access |
|------|--------|
| `gate_evaluate` | **no access** (orchestrator only) |
| `gate_report` | Read gate status report |
| `gate_log_evaluation` | **no access** (orchestrator only) |
| `phase_get` | Get current phase information |
| `phase_transition` | **no access** (orchestrator only) |
| `phase_history` | Read phase transition history |

### Economics Engine (`skills/economics-engine`)

Read-only access. Use to explain financial status to the founder.

| Tool | Access |
|------|--------|
| `econ_log_cost` | **no access** |
| `econ_log_revenue` | **no access** |
| `econ_log_refund` | **no access** |
| `econ_get_treasury` | Read treasury balance and summary |
| `econ_get_burn_rate` | Read burn rate and runway |
| `econ_get_agent_costs` | **no access** |
| `econ_get_budget_status` | Read budget utilization status |
| `econ_set_budget` | **no access** |
| `econ_get_revenue_attribution` | **no access** |
