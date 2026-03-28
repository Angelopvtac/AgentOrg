# Orchestrator — Tool Access

## Permissions

| Tool | Access | Notes |
|------|--------|-------|
| exec | full | Can execute commands and scripts |
| read | full | Can read all files and vault data |
| write | full | Can write to knowledge, config, workspaces |
| sessions | full | Can view and manage all agent sessions |
| cron | full | Can schedule and manage cron jobs |
| agent-to-agent | full | Can message any registered agent |

## Vault Paths

All vault paths below are relative and resolve to `/home/node/.openclaw/vault/` inside the container (mapped from `knowledge/` on the host).

| Path | Purpose | Access |
|------|---------|--------|
| `vault/phase-state.json` | Current phase, gate results, history | read/write |
| `vault/founder-profile.json` | Founder profile (populated by onboarding) | read |
| `vault/onboarding-state.json` | Onboarding progress tracker | read |
| `vault/economics/daily-budget.json` | Daily budget tracking and spend | read/write |
| `vault/economics/costs.json` | Cost event log | read/write |
| `vault/economics/revenue.json` | Revenue event log | read/write |
| `vault/economics/treasury.json` | Derived financial summary | read/write |
| `vault/briefing-state.json` | Daily briefing tracking and history | read/write |
| `vault/decisions.json` | Decision log | read/write |
| `vault/insights.json` | Insight collection | read/write |
| `vault/lessons.json` | Lessons learned | read/write |
| `vault/human-tasks.json` | Human task queue | read/write |
| `vault/research/*.json` | Research reports (L1+) | read |
| `vault/business/direction.json` | Business direction (L1+) | read/write |
| `vault/business/brand-brief.json` | Brand brief (L1+) | read/write |

## Cron Tools

| Tool | Purpose |
|------|---------|
| `cron_create` | Create a new cron job with schedule and action |
| `cron_list` | List all active cron jobs |
| `cron_delete` | Remove a cron job by ID |
| `cron_update` | Modify an existing cron job's schedule or action |

Cron jobs are stored at runtime in `/cron/jobs.json`. Create them during BOOT.md execution.

### Required cron jobs

| Job | Schedule | Action |
|-----|----------|--------|
| daily-gate-check | `0 9 * * *` (adjust to founder TZ) | Evaluate current phase gate criteria |
| daily-budget-reset | `0 0 * * *` UTC | Reset daily spend, archive to history |

## Agent-to-Agent Messaging

Use `sessions_send` with target format `agent:<id>:main`.

| Target | Agent ID | Available |
|--------|----------|-----------|
| Core Assistant | `agent:core-assistant:main` | L0+ |
| Research Agent | `agent:research:main` | L1+ |

## Skills

All shared skills at `/home/node/.openclaw/skills/`.

### Knowledge Graph (`skills/knowledge-graph`)

Full read/write access to all collections.

| Tool | Access | Collections |
|------|--------|-------------|
| `kg_store` | write | decisions, insights, lessons |
| `kg_read` | read | decisions, insights, lessons |
| `kg_search` | read | decisions, insights, lessons |
| `kg_list` | read | decisions, insights, lessons |

**Vault paths:**

| Path | Access |
|------|--------|
| `vault/decisions.json` | read/write |
| `vault/insights.json` | read/write |
| `vault/lessons.json` | read/write |

### Human Task Queue (`skills/human-task-queue`)

Full access to task management.

| Tool | Access |
|------|--------|
| `htq_create` | Create tasks for the founder |
| `htq_list` | List and filter tasks |
| `htq_complete` | Mark tasks as done |
| `htq_digest` | Generate pending task summary |

**Vault paths:**

| Path | Access |
|------|--------|
| `vault/human-tasks.json` | read/write |

### Progression Engine (`skills/progression-engine`)

Full access. Used for daily gate evaluation, phase transitions, and history tracking.

| Tool | Access |
|------|--------|
| `gate_evaluate` | Evaluate all criteria for current phase gate |
| `gate_report` | Generate formatted gate status report |
| `gate_log_evaluation` | Store evaluation results in history |
| `phase_get` | Get current phase information |
| `phase_transition` | Transition to next phase (requires gate PASSED) |
| `phase_history` | Get full phase transition history |

**Vault paths:**

| Path | Access |
|------|--------|
| `vault/phase-state.json` | read/write |
| `vault/founder-profile.json` | read (for L0 gate checks) |
| `vault/onboarding-state.json` | read (for L0 gate checks) |
| `vault/economics/daily-budget.json` | read (for L0 financial baseline check) |

**Config paths:**

| Path | Access |
|------|--------|
| `config/progression.json` | read (phase definitions and gate criteria) |

### Economics Engine (`skills/economics-engine`)

Full access. Used for cost tracking, budget enforcement, and financial reporting.

| Tool | Access |
|------|--------|
| `econ_log_cost` | Record API or infrastructure cost event |
| `econ_log_revenue` | Record revenue event |
| `econ_log_refund` | Record refund or chargeback |
| `econ_get_treasury` | Get treasury balance and summary |
| `econ_get_burn_rate` | Calculate burn rate and runway |
| `econ_get_agent_costs` | Get cost breakdown by agent |
| `econ_get_budget_status` | Check daily budget utilization |
| `econ_set_budget` | Update daily budget limit |
| `econ_get_revenue_attribution` | Revenue attribution by channel/agent/content |

**Vault paths:**

| Path | Access |
|------|--------|
| `vault/economics/daily-budget.json` | read/write |
| `vault/economics/costs.json` | read/write |
| `vault/economics/revenue.json` | read/write |
| `vault/economics/treasury.json` | read/write |

**Config paths:**

| Path | Access |
|------|--------|
| `config/economics.json` | read (budget rules and thresholds) |
