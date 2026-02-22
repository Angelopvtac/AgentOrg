# AgentOrg

Progressive autonomous company framework built on [OpenClaw](https://github.com/nicepkg/openclaw). Start with two AI agents and a conversation. Scale to a full autonomous organization as your business grows.

## Architecture

```
                    ┌─────────────────────────────────┐
                    │        Inbound Channels          │
                    │   Discord · Telegram · Slack     │
                    └──────────────┬──────────────────┘
                                   │
                    ┌──────────────▼──────────────────┐
                    │      OpenClaw Gateway            │
                    │   :18791 (API) · :18792 (Bridge) │
                    └──────────────┬──────────────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              │                    │                     │
    ┌─────────▼────────┐ ┌────────▼─────────┐          │
    │   Orchestrator    │ │  Core Assistant   │    Future agents
    │   (CEO/Router)    │ │  (Founder UI)     │    unlock with
    │   Tier 1 default  │ │  Tier 2 default   │    each phase
    └──────────────────┘ └──────────────────┘          │
              │                    │                     │
    ┌─────────▼────────────────────▼─────────────────────▼──┐
    │                   Shared Knowledge (Vault)             │
    │   decisions · insights · lessons · economics · tasks   │
    └───────────────────────────────────────────────────────┘
```

## Quickstart

```bash
# 1. Clone / navigate to the project
cd /home/angelo/agentic/development/projects/AgentOrg

# 2. Run first-time setup (checks prereqs, creates .env, generates token)
./scripts/setup.sh

# 3. Add your OpenRouter API key to .env
#    OPENROUTER_API_KEY=sk-or-...

# 4. Start the gateway
docker compose up -d

# 5. Verify
./scripts/health-check.sh
curl http://localhost:18791/health
```

The gateway control UI is accessible at `http://localhost:18791`.

## Directory Structure

| Path | Purpose |
|------|---------|
| `config/` | Gateway config (`openclaw.json`), model tiers, schemas |
| `config/models.json` | 3-tier model system (Triage/Execution/Strategic) |
| `agents/orchestrator/` | CEO agent — routing, decisions, phase management |
| `agents/core-assistant/` | Founder interface — conversations, onboarding |
| `knowledge/` | Shared vault — persistent data for all agents |
| `skills/` | Shared skill definitions |
| `workflows/` | Lobster pipeline definitions |
| `dashboards/` | Founder-facing HTML dashboards |
| `templates/` | Business-type starter templates |
| `scripts/` | Operational scripts (setup, health-check, backup) |

## Phase System

AgentOrg uses a progressive phase system. New agents and capabilities unlock as your business hits real milestones.

| Phase | Name | Gate | Agents Unlocked |
|-------|------|------|-----------------|
| L0 | Onboarding | Profile + vision complete | Orchestrator, Core Assistant |
| L1 | Discovery | Direction selected, brand brief | + Research |
| L2 | Presence | 100 followers, 5% engagement | + Content, Social |
| L3 | First Revenue | $1 revenue, 1 paying customer | + Sales, Compliance |
| L4 | Product-Market Fit | 3x revenue vs cost, 15% repeat | + Finance, Operations, Audit |
| L5 | Scale Decision | Scaling proposal approved | + Strategy |
| L6 | Autonomous Ops | Continuous health monitoring | All agents active |

## Model Tiers

| Tier | Model | Use Case | Approx Cost |
|------|-------|----------|-------------|
| 1 — Triage | Claude Haiku 4.5 | Routing, status, simple ops | $0.80/$4.00 per M tokens |
| 2 — Execution | Claude Sonnet 4.6 | Content, conversations | $3.00/$15.00 per M tokens |
| 3 — Strategic | Claude Opus 4.6 | Gates, audits, strategy | $15.00/$75.00 per M tokens |

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/setup.sh` | Interactive first-run configuration |
| `scripts/health-check.sh` | System health verification (exit code = failures) |
| `scripts/backup.sh` | Timestamped archive of knowledge + config + workspaces |

## Current Status

**Sprint 1 complete** — Project scaffolded, gateway deployable, two placeholder agents configured.

Next: Sprint 2 (Orchestrator & Core Assistant full system prompts, onboarding flow).
