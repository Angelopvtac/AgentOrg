# Changelog

## Sprint 3 — Skills, Daily Briefing & Validation

- Knowledge Graph skill: `kg_store`, `kg_read`, `kg_search`, `kg_list` across decisions/insights/lessons collections
- Human Task Queue skill: `htq_create`, `htq_list`, `htq_complete`, `htq_digest` with priority levels and quiet hours
- Daily Briefing system: compiles status from all vault files, delivers via core-assistant
- Orchestrator cron jobs: daily gate evaluation, budget reset, briefing trigger
- JSON schemas for founder-profile, human-task, and knowledge-collections
- Knowledge vault files: `briefing-state.json`, `insights.json`, `lessons.json`
- End-to-end health check validation

## Sprint 2 — Orchestrator Brain & Onboarding

- Orchestrator agent: message routing, budget enforcement, L0 gate evaluation (6 criteria), phase transition logic
- Core-assistant agent: 9-section founder onboarding flow with vault persistence
- Phase management: L0 gate with profile, skills, availability, financial, vision, and onboarding criteria
- Model tier escalation: Tier 1 default with rules for escalating to Tier 2/3
- Agent-to-agent communication via orchestrator routing
- Onboarding state tracking in `knowledge/onboarding-state.json`

## Sprint 1 — Foundation & Infrastructure

- Project scaffold: directory structure for agents, config, knowledge, skills, workflows
- OpenClaw gateway configuration (`config/openclaw.json`, JSON5)
- Docker Compose setup with volume mounts, security hardening, resource limits, healthcheck
- 3-tier model system: Triage (Haiku), Execution (Sonnet), Strategic (Opus)
- Agent workspace structure: AGENTS.md, IDENTITY.md, SOUL.md, TOOLS.md, USER.md, HEARTBEAT.md
- Operational scripts: `setup.sh`, `health-check.sh`, `backup.sh`
- Environment configuration: `.env.example` with all variables
- Progressive phase system: L0-L6 defined in `config/progression.json`
- Shared knowledge vault: `phase-state.json`, `founder-profile.json`, `economics/daily-budget.json`
