# Overnight Handoff — AgentOrg

## Meta
- Goal: get this to v1
- Iteration: 2
- Status: CONTINUE
- Timestamp: 2026-03-28T06:00:00Z
- Branch: overnight/AgentOrg/2026-03-28

## App State
- Stack: OpenClaw gateway (Node.js Docker container) + JSON config/vault files + bash scripts + Python dashboard generator + Python onboarding simulator. No frontend app — this is a configuration-driven agent framework.
- Run command: `docker compose up -d` (requires `openclaw:local` image pre-built)
- Test command: `bash tests/run-all.sh`
- Dashboard: `bash scripts/generate-dashboard.sh` → opens `dashboards/index.html`
- Simulate onboarding: `bash scripts/simulate-onboarding.sh` → populates vault + evaluates L0 gate
- Port: 18791 (gateway API), 18792 (bridge)

## What Exists
### Routes
This is NOT a web app with routes. It's an OpenClaw gateway with:
- Gateway health endpoint: `GET :18791/health`
- Gateway control UI: `http://localhost:18791`
- Two registered agents: `orchestrator` (default, receives all inbound), `core-assistant`
- Agent-to-agent messaging via `sessions_send` with target `agent:<id>:main`
- Channel templates (Discord, Telegram) commented out in config
- **Founder Dashboard**: Static HTML generated from vault data via `scripts/generate-dashboard.sh`, output to `dashboards/index.html`
- **Onboarding Simulator**: Python script that populates vault with realistic onboarding data and evaluates L0 gate criteria programmatically

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
3. **Dashboard flow**: Founder runs `bash scripts/generate-dashboard.sh` → reads all vault JSON → generates `dashboards/index.html` → opens in browser. Shows phase status, gate progress, onboarding progress, budget, treasury, human tasks, knowledge entries, briefing status. Handles both empty state (fresh install) and populated state (mid-onboarding).
4. **Onboarding simulation flow**: `bash scripts/simulate-onboarding.sh [mode] [vault_dir]` — 5 modes:
   - `--simulate` (default): Populates vault with completed onboarding data, then evaluates L0 gate (exit 0 = all pass, exit 1 = some fail)
   - `--populate`: Writes realistic completed-founder data to vault files
   - `--partial`: Writes partially-completed data (5/9 sections, 3/6 gate criteria pass)
   - `--evaluate`: Evaluates L0 gate criteria against current vault state without modifying data
   - `--reset`: Resets vault to fresh-install empty state
   - `--no-save` flag: Skip writing evaluation results to phase-state.json
   - Outputs formatted gate report showing each criterion's PASS/FAIL with actual values
   - Saves evaluation results + history to phase-state.json (unless --no-save)
5. **Onboarding flow** (L0, designed but not yet exercised live): Founder messages gateway → orchestrator routes to core-assistant → core-assistant guides through 9 sections (welcome, personal, skills, availability, financial, goals, preferences, vision, review) → vault files populated → orchestrator evaluates L0 gate → transition to L1
6. **Daily briefing flow**: Cron triggers → orchestrator compiles from vault → sends to core-assistant → core-assistant formats for founder
7. **Budget enforcement flow**: Cost logged → daily-budget updated → thresholds checked → warn at 80%, pause at 100%, kill-switch at 200%
8. **Backup flow**: `scripts/backup.sh` creates timestamped tar.gz of knowledge + config + workspaces

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
scripts/generate-dashboard.sh  — Dashboard generator (bash wrapper → calls generate-dashboard.py)
scripts/generate-dashboard.py  — Python script that reads vault JSON and outputs dashboards/index.html
scripts/simulate-onboarding.sh — Onboarding simulation (bash wrapper → calls simulate-onboarding.py)
scripts/simulate-onboarding.py — Python script: populate vault with onboarding data + evaluate L0 gate criteria
dashboards/index.html          — Generated founder status dashboard (static HTML, regenerate with scripts/generate-dashboard.sh)
smoke/1-founder-dashboard.test.sh — Smoke test: dashboard generation (31 checks)
smoke/2-onboarding-simulation.test.sh — Smoke test: onboarding simulation & gate evaluation (40 checks across 7 phases)
tests/run-all.sh               — Test runner (4 validation suites + smoke tests)
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
- **Dashboard ↔ Vault**: `scripts/generate-dashboard.py` reads all vault JSON files + `config/progression.json` → evaluates gate criteria in Python → generates self-contained HTML. No server needed; static file opened in browser.
- **Simulation ↔ Vault**: `scripts/simulate-onboarding.py` writes realistic onboarding data to vault JSON files and evaluates L0 gate criteria using the same logic as the dashboard generator. Gate evaluation results are persisted to `phase-state.json` with history tracking. This proves the data flow from onboarding → vault → gate evaluation works without needing the live gateway.

## Iteration Log
### Iteration 0
- Assessment completed
- Sprint 3 complete: full L0 infrastructure operational (2 agents, 4 skills, vault, config, tests)
- All 4 test suites pass (structure: 56/56, config: 16/16, schemas: 22/22, scripts: 24/24)
- Version 0.3.0, phase L0 (Onboarding), onboarding not yet started
- No frontend/dashboard exists — the project is a configuration-driven agent framework
- All vault files are initialized with empty/null values (fresh install state)

### Iteration 1
- Built **Founder Dashboard** — the #1 V1 priority
- Created `scripts/generate-dashboard.sh` (bash wrapper) + `scripts/generate-dashboard.py` (Python generator)
- Dashboard reads all vault JSON files and generates a self-contained `dashboards/index.html`
- Displays: phase status with L0-L6 timeline, gate progress (evaluates 6 criteria in Python), onboarding section grid (9 sections), daily budget with bar chart and tier breakdown, treasury overview, human tasks list with priority badges, knowledge graph entries (decisions/insights/lessons), daily briefing status
- Handles both empty state (fresh install — all sections show appropriate "no data" messages) and populated state (realistic mid-onboarding data renders correctly)
- Dark theme, responsive design (mobile 375px to desktop 1440px), proper visual hierarchy
- Smoke test: `smoke/1-founder-dashboard.test.sh` — 31 checks across 3 phases (empty state, populated state, error handling)
- Updated `tests/run-all.sh` to auto-discover and run smoke tests from `smoke/` directory
- All 5 test suites pass (structure: 56/56, config: 16/16, schemas: 22/22, scripts: 24/24, smoke: 31/31)

### Iteration 2
- Built **Onboarding Simulation & L0 Gate Evaluation** — proves the core data flow works end-to-end
- Created `scripts/simulate-onboarding.py` — Python script with 5 modes: simulate (populate + evaluate), populate, partial, evaluate, reset
- Created `scripts/simulate-onboarding.sh` — bash wrapper matching existing script patterns
- Gate evaluator checks all 6 L0 criteria (profile-complete, skills-identified, availability-set, financial-baseline, vision-defined, onboarding-complete) with detailed actual-vs-target reporting
- Realistic founder data: Elena Marchetti, freelance writing SaaS founder, 5 skills, 15 hrs/week, moderate risk tolerance, 250+ char vision statement
- Three data states: complete (6/6 pass), partial (3/6 pass — profile + skills pass, availability/financial/vision/onboarding fail), empty (0/6 pass)
- Evaluation results persist to `phase-state.json`: updates lastGateEvaluation timestamp, stores per-criterion gateResults, appends to history array
- Dashboard coherence verified: simulated vault data produces correct 6/6 and 9/9 in the dashboard
- Smoke test: `smoke/2-onboarding-simulation.test.sh` — 40 checks across 7 phases (complete simulation, partial evaluation, empty state, persistence, dashboard coherence, exit codes, bash wrapper)
- All 6 test suites pass (structure: 56/56, config: 13/13, schemas: 22/22, scripts: 36/36, dashboard smoke: 31/31, onboarding smoke: 40/40)

## Remaining Opportunities (ranked)

### Feature Completeness (V1 Critical Path)

1. **L0→L1 transition implementation** — The gate evaluation now works (iteration 2 proved it). Next: implement the actual phase transition script that updates phase-state.json from L0→L1 when all criteria pass (update currentPhase, phaseName, phaseStartDate, log transition in history). Could extend simulate-onboarding.py with a `--transition` mode or create a separate `scripts/phase-transition.py`.

2. **Research agent workspace (L1)** — Backlog Epic 8 is entirely "planned". V1 should include at least the research agent workspace files (AGENTS.md, SOUL.md, IDENTITY.md, TOOLS.md, HEARTBEAT.md) so L1 has something to unlock to when the gate passes.

3. **Workflow definitions** — `workflows/` dir is empty with only `.gitkeep`. The daily-briefing, discovery, and content-pipeline workflows referenced in BACKLOG are unimplemented. At minimum, a `workflows/daily-briefing.lobster` template.

4. **Channel configuration templates** — Discord/Telegram configs are commented out in openclaw.json. V1 should have a `scripts/enable-channel.sh` helper that uncomments and configures a channel with guided prompts.

5. **Template business types** — `templates/` dir is empty. V1 should include at least 2-3 starter templates (e.g., content-agency, saas-micro, consulting) that pre-seed business direction and brand brief for faster L1 completion.

6. **Knowledge graph propagation** — Backlog F4.1-S2: "insights propagate to relevant agents automatically" is planned. V1 needs at least the notification mechanism spec'd out.

7. **Documentation completeness** — CONTRIBUTING.md exists but could use expansion. No architecture decision records exist.

### Quality & Polish

8. **Dashboard auto-refresh** — Currently requires manual re-run of the generator script. Could add a cron hook or a watch mode.

9. **Vault backup before phase transitions** — Automatic backup trigger when phase changes (safety net).

10. **Schema validation on vault writes** — Currently schemas exist in `config/schemas/` but there's no validation enforced when agents write to vault files.

11. **SECURITY.md improvements** — Exists but could document the actual threat model (agent-to-agent trust, vault integrity, prompt injection defenses).

## Known Issues

1. **No workflows defined** — `workflows/` directory is empty. Lobster pipelines referenced in backlog don't exist.
2. **No templates** — `templates/` directory is empty. Business-type templates not created.
3. **Channel configuration commented out** — Discord/Telegram configs exist as comments in openclaw.json but no automation to enable them.
4. **Phase start date is hardcoded** — `phase-state.json` has `phaseStartDate: "2026-02-23T00:00:00Z"` which should be set dynamically by BOOT.md on first run.
5. **shellcheck not installed** — Test suite skips shell linting.
6. **Dashboard is static** — Must be manually regenerated to see current state. No live-refresh mechanism.
7. **No L0→L1 transition script** — Gate evaluation works but the actual phase transition (updating phase-state.json) is not yet scripted.
