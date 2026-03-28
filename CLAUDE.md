# AgentOrg — Project Rules

## What This Is

Progressive autonomous company framework built on OpenClaw. Agents run inside an OpenClaw gateway container; configuration lives in `config/openclaw.json` (JSON5 format).

## Directory Guide

| Path | Purpose |
|------|---------|
| `config/` | Gateway config, model tiers, schemas |
| `agents/<id>/workspace/` | Per-agent workspace files (AGENTS.md, SOUL.md, IDENTITY.md, USER.md, TOOLS.md, HEARTBEAT.md, memory/) |
| `knowledge/` | Shared vault — persistent data accessible to all agents |
| `skills/` | Shared skills (each has SKILL.md) |
| `workflows/` | Lobster pipeline definitions |
| `dashboards/` | HTML dashboards served to the founder |
| `templates/` | Business-type templates (content-agency, saas, etc.) |
| `scripts/` | Operational scripts (setup, health-check, backup) |

## OpenClaw Conventions

- Config file is `config/openclaw.json` (JSON5, not `gateway.json`)
- Agent workspaces mount into container at `/home/node/.openclaw/workspace-<agentId>`
- Shared knowledge mounts as the vault at `/home/node/.openclaw/vault`
- Gateway listens on internal port 18789; mapped to host port 18791
- Bridge listens on internal port 18790; mapped to host port 18792
- Gateway bind mode is `lan` (required for Docker port forwarding to work)
- All secrets go in `.env`, never in config files

## Model Tiers

| Tier | Model | Use Case |
|------|-------|----------|
| 1 (Triage) | `openrouter/anthropic/claude-haiku-4.5` | Routing, status checks, simple ops |
| 2 (Execution) | `openrouter/anthropic/claude-sonnet-4.6` | Content, conversations, analysis |
| 3 (Strategic) | `openrouter/anthropic/claude-opus-4.6` | Gates, audits, strategy decisions |

## File Naming

- Config: kebab-case JSON/JSON5 (`models.json`, `openclaw.json`)
- Agent workspace files: UPPERCASE.md (`AGENTS.md`, `SOUL.md`)
- Scripts: kebab-case bash (`health-check.sh`, `setup.sh`)
- Skills: kebab-case directory with `SKILL.md` inside

## Rules

- Never commit `.env` or any secrets
- Always use environment variables for API keys and tokens
- Agent workspace files are the source of truth for agent behavior
- `knowledge/` files are runtime state — back up regularly
- Test with `docker compose up` and `scripts/health-check.sh`
