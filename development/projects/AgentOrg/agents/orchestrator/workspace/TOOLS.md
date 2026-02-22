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

All vault files are at `/home/node/.openclaw/vault/`.

| Path | Purpose | Access |
|------|---------|--------|
| `vault/phase-state.json` | Current phase, gate results, history | read/write |
| `vault/founder-profile.json` | Founder profile (populated by onboarding) | read |
| `vault/onboarding-state.json` | Onboarding progress tracker | read |
| `vault/economics/daily-budget.json` | Daily budget tracking and spend | read/write |

## Config Paths

| Path | Purpose | Access |
|------|---------|--------|
| `config/progression.json` | Phase definitions and gate criteria (L0-L6) | read |
| `config/models.json` | Model tiers and cost rates | read |
| `config/schemas/founder-profile.json` | JSON Schema for profile validation | read |

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

| Target | Agent ID |
|--------|----------|
| Core Assistant | `agent:core-assistant:main` |

## Skills

All shared skills at `/home/node/.openclaw/skills/`.
