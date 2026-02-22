# Core Assistant — Tool Access

## Permissions
| Tool | Access | Notes |
|------|--------|-------|
| exec | none | Cannot execute commands |
| read | full | Can read all files and vault data |
| write | none | Cannot modify files or config |
| sessions | read | Can view sessions, cannot manage |
| cron | none | Cannot schedule jobs |
| agent-to-agent | send | Can message orchestrator and other agents |

## Vault Paths (Read Only)
- `/home/node/.openclaw/vault/` — Shared knowledge base
- `/home/node/.openclaw/vault/phase-state.json` — Current phase (Sprint 2)

## Skills (Read Only)
- Knowledge graph read access (Sprint 3)
- Human task queue read access (Sprint 3)
