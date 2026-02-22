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
- `/home/node/.openclaw/vault/` — Shared knowledge base
- `/home/node/.openclaw/vault/phase-state.json` — Current phase (Sprint 2)
- `/home/node/.openclaw/vault/economics/` — Cost and revenue tracking (Sprint 3)

## Skills
- All shared skills in `/home/node/.openclaw/skills/`
