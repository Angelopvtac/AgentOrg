# Overnight Handoff — AgentOrg

## Meta
- Goal: get this to v1
- Iteration: 0
- Status: CONTINUE
- Timestamp: 2026-03-28T04:30:00Z
- Branch: overnight/AgentOrg/2026-03-28

## App State
- Stack: OpenClaw gateway (Node.js Docker container) + JSON config/vault files + bash scripts. No frontend app — this is a configuration-driven agent framework.
- Run command: `docker compose up -d` (requires `openclaw:local` image pre-built)
- Test command: `bash tests/run-all.sh`
- Port: 18791 (gateway API), 18792 (bridge)

## What Exists
### Routes
This is NOT a web app with routes. It's an OpenClaw gateway with:
- Gateway health endpoint: `GET :18791/health`
- Gateway control UI: `http://localhost:18791`
- Two registered agents: `orchestrator` (default, receives all inbound), `core-assistant`
- Agent-to-agent messaging via `sessions_send` with target `agent:<id>:main`
- Channel templates (Discord, Telegram) commented out in config

### Data Models
All data is JSON files in `knowledge/` (vault):

- **phase-state.json** — currentPhase (L0), phaseName, phaseStartDate, lastGateEvaluation, gateResults, history[]
- **founder-profile.json** — personalInfo, skills[], availability, financial, goals, preferences, vision (all null/empty — onboarding not started)
- **onboarding-state.json** — status ("not-started"), 9 sections each with status/completedAt
- **economics/daily-budget.json** — dailyLimit ($5), spent, breakdown by tier, alerts thresholds, history
- **economics/costs.json** — collection with entries[] (empty)
- **economics/revenue.json** — collection with entries[] (empty)
- **economics/treasury.json** — balance, totalRevenue, totalCosts (all zero)
- **decisions.json** — knowledge graph collection (empty)
- **insights.json** — knowledge graph collection (empty)
- **lessons.json** — knowledge graph collection (empty)
- **human-tasks.json** — tasks[], stats (all zero)
- **briefing-state.json** — lastBriefingSent (null), briefingHistory[]
- **business/direction.json** — direction (null), L1 phase data
- **business/brand-brief.json** — brandName (null), L1 phase data
- **metrics/social.json** — L2 phase social metrics (empty)

### User Flows
1. **Setup flow**: Founder runs `scripts/setup.sh` → checks prereqs → creates .env → generates gateway token → validates API key → starts Docker container
2. **Health check flow**: `scripts/health-check.sh` validates container, gateway, API keys, config, agent workspaces, vault files, skills
3. **Onboarding flow** (L0, designed but not yet exercised): Founder messages gateway → orchestrator routes to core-assistant → core-assistant guides through 9 sections (welcome, personal, skills, availability, financial, goals, preferences, vision, review) → vault files populated → orchestrator evaluates L0 gate → transition to L1
4. **Daily briefing flow**: Cron triggers → orchestrator compiles from vault → sends to core-assistant → core-assistant formats for founder
5. **Budget enforcement flow**: Cost logged → daily-budget updated → thresholds checked → warn at 80%, pause at 100%, kill-switch at 200%
6. **Backup flow**: `scripts/backup.sh` creates timestamped tar.gz of knowledge + config + workspaces

## File Map
```
config/openclaw.json           — Gateway config (JSON5): agents, tools, channels, hooks, auth
config/models.json             — 3-tier model system: Haiku/Sonnet/Opus with costs
config/progression.json        — Phase definitions L0-L6 with gate criteria
config/economics.json          — Budget rules, thresholds, per-agent allocation
config/schemas/*.json          — JSON schemas for founder-profile, human-task, knowledge-collections
agents/orchestrator/workspace/ — CEO agent: AGENTS.md (routing/gates/budget), BOOT.md (init), SOUL.md, IDENTITY.md, TOOLS.md, HEARTBEAT.md, USER.md
agents/core-assistant/workspace/ — Founder interface: AGENTS.md (onboarding/briefing), SOUL.md, IDENTITY.md, TOOLS.md, HEARTBEAT.md, USER.md
skills/knowledge-graph/SKILL.md     — kg_store/read/search/list across decisions/insights/lessons
skills/human-task-queue/SKILL.md    — htq_create/list/complete/digest with priority + quiet hours
skills/progression-engine/SKILL.md  — gate_evaluate/report/log/phase_get/transition/history
skills/economics-engine/SKILL.md    — econ_log_cost/revenue/refund, get_treasury/burn_rate/budget_status
knowledge/*.json               — All vault runtime state (see Data Models above)
scripts/setup.sh               — Interactive first-run setup
scripts/health-check.sh        — System health verification
scripts/backup.sh              — Timestamped backup of knowledge/config/workspaces
tests/run-all.sh               — Test runner (4 suites: structure, config, schemas, scripts)
tests/validate-*.sh            — Individual validation scripts
docker-compose.yml             — Single gateway container with volume mounts, security hardening
BACKLOG.md                     — Full product backlog (Epics 1-11+, stories, tasks with status)
```

## Integration Seams
- **Gateway ↔ Agents**: OpenClaw routes inbound messages to orchestrator (default agent). Orchestrator dispatches to core-assistant via `sessions_send`.
- **Agent ↔ Vault**: All agents read/write JSON files in `knowledge/` directory (mounted as `/home/node/.openclaw/vault/` in container).
- **Agent ↔ Skills**: Skills are markdown specifications (SKILL.md) defining tool interfaces. Agents follow the spec to read/write vault files — there is no code runtime; it's all prompt-driven behavior.
- **Config ↔ Gateway**: `config/openclaw.json` (JSON5) is mounted read-only into the container. Changes require container restart.
- **Cron ↔ Orchestrator**: Orchestrator creates runtime cron jobs during BOOT.md execution (stored in Docker volume, not in git).
- **Phase System**: `config/progression.json` defines gates → orchestrator evaluates via progression-engine skill → results stored in `knowledge/phase-state.json` → phase transitions unlock new agents.
- **Budget Enforcement**: Economics engine logs costs → updates daily-budget → orchestrator heartbeat checks thresholds → alerts/pauses via core-assistant.

## Iteration Log
### Iteration 0
- Assessment completed
- Sprint 3 complete: full L0 infrastructure operational (2 agents, 4 skills, vault, config, tests)
- All 4 test suites pass (structure: 56/56, config: 16/16, schemas: 22/22, scripts: 24/24)
- Version 0.3.0, phase L0 (Onboarding), onboarding not yet started
- No frontend/dashboard exists — the project is a configuration-driven agent framework
- All vault files are initialized with empty/null values (fresh install state)

## Remaining Opportunities (ranked)

### Feature Completeness (V1 Critical Path)

1. **Founder dashboard (HTML)** — `dashboards/` dir is empty. V1 needs at minimum a status dashboard showing: current phase, gate progress, budget status, pending tasks, recent knowledge entries. This is the founder's primary visibility into the system outside of chat.

2. **L0→L1 transition implementation** — Backlog F3.1-S3 is "planned". The gate evaluation logic is defined in agent prompts but there's no integration test proving the full flow works: onboarding completes → gate evaluates → phase transitions → new agents unlock. Need a simulation/test script.

3. **Research agent workspace (L1)** — Backlog Epic 8 is entirely "planned". V1 should include at least the research agent workspace files (AGENTS.md, SOUL.md, IDENTITY.md, TOOLS.md, HEARTBEAT.md) so L1 has something to unlock to when the gate passes.

4. **Workflow definitions** — `workflows/` dir is empty with only `.gitkeep`. The daily-briefing, discovery, and content-pipeline workflows referenced in BACKLOG are unimplemented. At minimum, a `workflows/daily-briefing.lobster` template.

5. **Dashboard: founder status page** — A single-page HTML dashboard (no framework needed) that reads vault JSON files and displays: phase status, gate progress bar, budget gauge, pending tasks count, onboarding progress, recent decisions/insights. Serve from `dashboards/index.html`.

6. **Onboarding simulation test** — A script that simulates the onboarding flow by writing valid data to all vault files and verifying the L0 gate would pass. Proves the data flow works end-to-end without needing the actual OpenClaw gateway running.

7. **Channel configuration templates** — Discord/Telegram configs are commented out in openclaw.json. V1 should have a `scripts/enable-channel.sh` helper that uncomments and configures a channel with guided prompts.

8. **Knowledge graph propagation** — Backlog F4.1-S2: "insights propagate to relevant agents automatically" is planned. V1 needs at least the notification mechanism spec'd out.

9. **Template business types** — `templates/` dir is empty. V1 should include at least 2-3 starter templates (e.g., content-agency, saas-micro, consulting) that pre-seed business direction and brand brief for faster L1 completion.

10. **Documentation completeness** — CONTRIBUTING.md exists but could use expansion. No architecture decision records exist.

### Quality & Polish

11. **Smoke test for gateway integration** — Test that `docker compose up` actually starts, health endpoint responds, and basic API calls work (requires openclaw:local image).

12. **Vault backup before phase transitions** — Automatic backup trigger when phase changes (safety net).

13. **Schema validation on vault writes** — Currently schemas exist in `config/schemas/` but there's no validation enforced when agents write to vault files.

14. **SECURITY.md improvements** — Exists but could document the actual threat model (agent-to-agent trust, vault integrity, prompt injection defenses).

## Known Issues

1. **No dashboard exists** — `dashboards/` directory contains only `.gitkeep`. Founder has no visual interface for system status outside of chat.
2. **No workflows defined** — `workflows/` directory is empty. Lobster pipelines referenced in backlog don't exist.
3. **No templates** — `templates/` directory is empty. Business-type templates not created.
4. **Onboarding never tested end-to-end** — The 9-section onboarding flow and L0 gate evaluation have never been exercised with real or simulated data.
5. **Channel configuration commented out** — Discord/Telegram configs exist as comments in openclaw.json but no automation to enable them.
6. **No smoke test infrastructure for integration tests** — The existing test suite validates file structure and JSON validity, but doesn't test actual gateway behavior or agent interactions.
7. **Phase start date is hardcoded** — `phase-state.json` has `phaseStartDate: "2026-02-23T00:00:00Z"` which should be set dynamically by BOOT.md on first run.
8. **shellcheck not installed** — Test suite skips shell linting.
