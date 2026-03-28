# Research Agent — Tool Access

## Permissions

| Tool | Access | Notes |
|------|--------|-------|
| exec | none | Cannot execute commands |
| read | full | Can read all files and vault data |
| write | limited | Can write to specific vault files only (see below) |
| sessions | read | Can view sessions, cannot manage |
| cron | none | Cannot schedule jobs |
| agent-to-agent | send | Can message orchestrator only |
| web_search | full | Primary research tool — web searches |
| web_fetch | full | Fetch and read web pages for research |

## Vault Paths — Read Access

All vault paths below are relative and resolve to `/home/node/.openclaw/vault/` inside the container (mapped from `knowledge/` on the host).

| Path | Purpose |
|------|---------|
| `vault/phase-state.json` | Current phase — confirm L1+ activation |
| `vault/founder-profile.json` | Founder skills, goals, vision — research lens |
| `vault/onboarding-state.json` | Onboarding status (read-only) |
| `vault/business/direction.json` | Current business direction |
| `vault/business/brand-brief.json` | Brand brief progress |
| `vault/decisions.json` | Decision log (read-only) |
| `vault/insights.json` | Insight collection (read-only) |
| `vault/lessons.json` | Lessons learned (read-only) |

## Vault Paths — Write Access

You can write to these files only:

| Path | Purpose | When |
|------|---------|------|
| `vault/research/*.json` | Research reports | After completing any research task |
| `vault/business/direction.json` | Business direction data | After founder selects a direction from your analysis |
| `vault/insights.json` | Market insights | When research surfaces strategic insights |

### Write rules

- Always read the file first, then modify specific fields, then write the complete object back
- Never delete existing data — only update or append
- Use ISO 8601 timestamps for all date fields
- Research reports are append-only — create new files, never overwrite existing reports
- If a write fails, notify the orchestrator

## Config Paths — Read Only

| Path | Purpose |
|------|---------|
| `config/progression.json` | Phase definitions (for understanding L1 gate criteria) |
| `config/models.json` | Model tier costs (for budget-aware research planning) |

## Agent-to-Agent Messaging

Use `sessions_send` with target `agent:orchestrator:main`.

Only send to the orchestrator. Messages you send:
- Market scan results and direction recommendations
- Competitive analysis completion notifications
- Brand research findings
- L1 gate criterion updates (market-research-done status)

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

### Progression Engine (`skills/progression-engine`)

Read-only access. Use to check L1 gate progress.

| Tool | Access |
|------|--------|
| `gate_evaluate` | **no access** (orchestrator only) |
| `gate_report` | Read gate status report |
| `gate_log_evaluation` | **no access** (orchestrator only) |
| `phase_get` | Get current phase information |
| `phase_transition` | **no access** (orchestrator only) |
| `phase_history` | Read phase transition history |
