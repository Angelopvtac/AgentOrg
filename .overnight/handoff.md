# Overnight Handoff — AgentOrg

## Meta
- Goal: get this to v1
- Iteration: 5
- Status: CONTINUE
- Timestamp: 2026-03-28T09:00:00Z
- Branch: overnight/AgentOrg/2026-03-28

## App State
- Stack: OpenClaw gateway (Node.js Docker container) + JSON config/vault files + bash scripts + Python dashboard generator + Python onboarding simulator + Python phase transition engine + Lobster workflow definitions. No frontend app — this is a configuration-driven agent framework.
- Run command: `docker compose up -d` (requires `openclaw:local` image pre-built)
- Test command: `bash tests/run-all.sh`
- Dashboard: `bash scripts/generate-dashboard.sh` → opens `dashboards/index.html`
- Simulate onboarding: `bash scripts/simulate-onboarding.sh` → populates vault + evaluates L0 gate
- Phase transition: `bash scripts/phase-transition.sh --transition` → evaluates gate + transitions phase
- Port: 18791 (gateway API), 18792 (bridge)

## What Exists
### Routes
This is NOT a web app with routes. It's an OpenClaw gateway with:
- Gateway health endpoint: `GET :18791/health`
- Gateway control UI: `http://localhost:18791`
- Three registered agents: `orchestrator` (default, receives all inbound), `core-assistant`, `research` (L1+)
- Agent-to-agent messaging via `sessions_send` with target `agent:<id>:main`
- Channel templates (Discord, Telegram) commented out in config
- **Founder Dashboard**: Static HTML generated from vault data via `scripts/generate-dashboard.sh`, output to `dashboards/index.html`
- **Onboarding Simulator**: Python script that populates vault with realistic onboarding data and evaluates L0 gate criteria programmatically
- **Phase Transition Engine**: Python script that evaluates gate criteria for the current phase and transitions to the next phase when all criteria pass, with backup, state persistence, and history tracking
- **Workflow Pipelines**: Lobster pipeline definitions in `workflows/` that codify multi-step agent workflows with triggers, steps, data flow, and success criteria

### Data Models
All data is JSON files in `knowledge/` (vault):

- **phase-state.json** — currentPhase (L0), phaseName, phaseStartDate, lastGateEvaluation, gateResults, history[] (includes transition entries with type, fromPhase, toPhase, criteria)
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
- **research/*.json** — Research reports directory (empty, ready for L1 use)

### User Flows
1. **Setup flow**: Founder runs `scripts/setup.sh` → checks prereqs → creates .env → generates gateway token → validates API key → starts Docker container
2. **Health check flow**: `scripts/health-check.sh` validates container, gateway, API keys, config, agent workspaces, vault files, skills
3. **Dashboard flow**: Founder runs `bash scripts/generate-dashboard.sh` → reads all vault JSON → generates `dashboards/index.html` → opens in browser. Shows phase status, gate progress, onboarding progress, budget, treasury, human tasks, knowledge entries, briefing status. Handles both empty state (fresh install) and populated state (mid-onboarding).
4. **Onboarding simulation flow**: `bash scripts/simulate-onboarding.sh [mode] [vault_dir] [--no-save]` — 5 modes:
   - `--simulate` (default): Populates vault with completed onboarding data, then evaluates L0 gate (exit 0 = all pass, exit 1 = some fail)
   - `--populate`: Writes realistic completed-founder data to vault files
   - `--partial`: Writes partially-completed data (5/9 sections, 3/6 gate criteria pass)
   - `--evaluate`: Evaluates L0 gate criteria against current vault state without modifying data
   - `--reset`: Resets vault to fresh-install empty state
   - `--no-save` flag: Skip writing evaluation results to phase-state.json
   - Outputs formatted gate report showing each criterion's PASS/FAIL with actual values
   - Saves evaluation results + history to phase-state.json (unless --no-save)
5. **Phase transition flow**: `bash scripts/phase-transition.sh [mode] [vault_dir]` — 4 modes:
   - `--check` (default): Dry-run — evaluates gate criteria for current phase, reports pass/fail without modifying state
   - `--transition`: Evaluates gate and transitions to next phase if all criteria pass. Creates backup, updates phase-state.json (currentPhase, phaseName, phaseStartDate), logs transition in history with criteria snapshot
   - `--force`: Skips gate evaluation and forces transition to next phase (for development/testing)
   - `--status`: Shows current phase, start date, gate progress, and transition history
   - Supports L0 and L1 gate evaluation (evaluators for L2-L5 can be added as system progresses)
   - Exit codes: 0 = success/gate passed, 1 = gate failed, 2 = error (terminal phase, missing config)
6. **Onboarding flow** (L0, designed but not yet exercised live): Founder messages gateway → orchestrator routes to core-assistant → core-assistant guides through 9 sections → vault files populated → orchestrator evaluates L0 gate → transition to L1
7. **L1 Discovery flow** (designed with full workflow definition): After L0→L1 transition → discovery pipeline activates per `workflows/discovery.lobster` → research agent performs market scan → presents 3-5 directions → founder selects → competitive analysis → brand brief support → L1 gate evaluation → L2 transition
8. **Daily briefing flow** (designed with full workflow definition): Cron triggers per `workflows/daily-briefing.lobster` → orchestrator gathers phase/budget/tasks/knowledge data from vault → compiles briefing → sends to core-assistant → core-assistant formats for founder's communication style → delivers respecting quiet hours → updates briefing-state.json
9. **Budget enforcement flow**: Cost logged → daily-budget updated → thresholds checked → warn at 80%, pause at 100%, kill-switch at 200%
10. **Backup flow**: `scripts/backup.sh` creates timestamped tar.gz of knowledge + config + workspaces

## File Map
```
config/openclaw.json           — Gateway config (JSON5): 3 agents, tools, channels, hooks, auth
config/models.json             — 3-tier model system: Haiku/Sonnet/Opus with costs
config/progression.json        — Phase definitions L0-L6 with gate criteria
config/economics.json          — Budget rules, thresholds, per-agent allocation
config/schemas/*.json          — JSON schemas for founder-profile, human-task, knowledge-collections
agents/orchestrator/workspace/ — CEO agent: AGENTS.md (routing/gates/budget/workflows), BOOT.md (init), SOUL.md, IDENTITY.md, TOOLS.md, HEARTBEAT.md, USER.md
agents/core-assistant/workspace/ — Founder interface: AGENTS.md (onboarding/briefing), SOUL.md, IDENTITY.md, TOOLS.md, HEARTBEAT.md, USER.md
agents/research/workspace/     — Market researcher (L1+): AGENTS.md (market scan/direction/brand, refs discovery.lobster), SOUL.md, IDENTITY.md, TOOLS.md, HEARTBEAT.md, USER.md
skills/knowledge-graph/SKILL.md     — kg_store/read/search/list across decisions/insights/lessons
skills/human-task-queue/SKILL.md    — htq_create/list/complete/digest with priority + quiet hours
skills/progression-engine/SKILL.md  — gate_evaluate/report/log/phase_get/transition/history
skills/economics-engine/SKILL.md    — econ_log_cost/revenue/refund, get_treasury/burn_rate/budget_status
workflows/daily-briefing.lobster    — 8-step pipeline: gather vault data → compile → deliver via core-assistant → update state
workflows/discovery.lobster         — 7-step pipeline: profile → market scan → direction selection → competitive analysis → brand brief → gate verification
knowledge/*.json               — All vault runtime state (see Data Models above)
knowledge/research/            — Research reports directory (empty, populated by research agent in L1)
scripts/setup.sh               — Interactive first-run setup
scripts/health-check.sh        — System health verification
scripts/backup.sh              — Timestamped backup of knowledge/config/workspaces
scripts/generate-dashboard.sh  — Dashboard generator (bash wrapper → calls generate-dashboard.py)
scripts/generate-dashboard.py  — Python script that reads vault JSON and outputs dashboards/index.html
scripts/simulate-onboarding.sh — Onboarding simulation (bash wrapper → calls simulate-onboarding.py)
scripts/simulate-onboarding.py — Python script: populate vault with onboarding data + evaluate L0 gate criteria
scripts/phase-transition.sh    — Phase transition (bash wrapper → calls phase-transition.py)
scripts/phase-transition.py    — Python script: evaluate gate criteria + execute phase transition with backup + history
dashboards/index.html          — Generated founder status dashboard (static HTML, regenerate with scripts/generate-dashboard.sh)
smoke/1-founder-dashboard.test.sh — Smoke test: dashboard generation (31 checks)
smoke/2-onboarding-simulation.test.sh — Smoke test: onboarding simulation & gate evaluation (40 checks)
smoke/3-phase-transition.test.sh — Smoke test: phase transition engine (39 checks)
smoke/4-research-agent.test.sh — Smoke test: research agent workspace & integration (49 checks)
smoke/5-workflow-definitions.test.sh — Smoke test: workflow pipeline definitions (74 checks)
tests/run-all.sh               — Test runner (4 validation suites + smoke tests)
tests/validate-*.sh            — Individual validation scripts
docker-compose.yml             — Single gateway container with volume mounts for 3 agents, security hardening
BACKLOG.md                     — Full product backlog (Epics 1-11+, stories, tasks with status)
```

## Integration Seams
- **Gateway ↔ Agents**: OpenClaw routes inbound messages to orchestrator (default agent). Orchestrator dispatches to core-assistant or research via `sessions_send`.
- **Agent ↔ Vault**: All agents read/write JSON files in `knowledge/` directory (mounted as `/home/node/.openclaw/vault/` in container).
- **Agent ↔ Skills**: Skills are markdown specifications (SKILL.md) defining tool interfaces. Agents follow the spec to read/write vault files — there is no code runtime; it's all prompt-driven behavior.
- **Agent ↔ Workflows**: Workflow definitions in `workflows/*.lobster` codify multi-step agent pipelines. Orchestrator references these when coordinating cross-agent operations. Each workflow defines: trigger conditions, step sequence with agent assignments, data inputs/outputs per step, gate progress tracking, error handling, and success criteria.
- **Config ↔ Gateway**: `config/openclaw.json` (JSON5) is mounted read-only into the container. Changes require container restart.
- **Cron ↔ Orchestrator**: Orchestrator creates runtime cron jobs during BOOT.md execution (stored in Docker volume, not in git).
- **Phase System**: `config/progression.json` defines gates → orchestrator evaluates via progression-engine skill → results stored in `knowledge/phase-state.json` → phase transitions unlock new agents. Now scriptable via `scripts/phase-transition.py` with gate evaluation + state update + history tracking.
- **Budget Enforcement**: Economics engine logs costs → updates daily-budget → orchestrator heartbeat checks thresholds → alerts/pauses via core-assistant.
- **Dashboard ↔ Vault**: `scripts/generate-dashboard.py` reads all vault JSON files + `config/progression.json` → evaluates gate criteria in Python → generates self-contained HTML. No server needed; static file opened in browser.
- **Simulation ↔ Vault**: `scripts/simulate-onboarding.py` writes realistic onboarding data to vault JSON files and evaluates L0 gate criteria using the same logic as the dashboard generator. Gate evaluation results are persisted to `phase-state.json` with history tracking.
- **Transition ↔ Vault**: `scripts/phase-transition.py` reads phase-state.json + progression.json → evaluates gate criteria for current phase → if all pass, creates backup (via backup.sh) → updates phase-state.json with new phase, start date, gate results → logs transition in history array with from/to phases and criteria snapshot. Supports L0 and L1 gate evaluators.
- **Orchestrator ↔ Research**: Orchestrator dispatches research requests to `agent:research:main` when phase >= L1. Research agent writes reports to `vault/research/`, updates `vault/business/direction.json`, and notifies orchestrator of gate criterion completion.
- **Research ↔ Vault**: Research agent reads `vault/founder-profile.json` for context, writes structured JSON reports to `vault/research/`, updates `vault/business/direction.json` with selected direction data. Reports follow a defined schema with findings, confidence levels, sources, and recommendations.
- **Daily Briefing Pipeline** (`workflows/daily-briefing.lobster`): Cron trigger → 8 steps: gather phase status, budget, tasks, knowledge, phase-specific context → compile → deliver to core-assistant → update briefing-state.json. Handles all phases (L0-L6) with phase-specific context blocks.
- **Discovery Pipeline** (`workflows/discovery.lobster`): Event trigger (L1 transition) → 7 steps: profile ingestion → market scan → founder direction selection → competitive deep-dive → brand brief research → brand brief completion → L1 gate verification. Tracks gate progress (3 criteria) through vault file state. Supports pipeline resumption after interruption.

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
- Created `scripts/simulate-onboarding.py` — Python script with 5 modes: simulate, populate, partial, evaluate, reset
- Created `scripts/simulate-onboarding.sh` — bash wrapper matching existing script patterns
- Gate evaluator checks all 6 L0 criteria with detailed actual-vs-target reporting
- Realistic founder data: Elena Marchetti, freelance writing SaaS founder
- Three data states: complete (6/6 pass), partial (3/6 pass), empty (0/6 pass)
- Evaluation results persist to phase-state.json with history tracking
- Smoke test: `smoke/2-onboarding-simulation.test.sh` — 40 checks across 7 phases
- All 6 test suites pass

### Iteration 3
- Built **Phase Transition Engine** — completes the progression loop (gate eval → phase transition)
- Created `scripts/phase-transition.py` — Python script with 4 modes: check (dry-run), transition, force, status
- Created `scripts/phase-transition.sh` — bash wrapper matching existing patterns
- Gate evaluation for L0 (6 criteria) and L1 (3 criteria: direction-selected, brand-brief-complete, market-research-done)
- Transition flow: evaluate gate → create backup (via backup.sh) → update phase-state.json (currentPhase, phaseName, phaseStartDate) → log transition in history with type, fromPhase, toPhase, gateStatus, criteria snapshot
- Check mode is a safe dry-run that reports gate status without modifying state
- Force mode skips gate evaluation for development/testing scenarios
- Status mode shows current phase, start date, gate progress, and transition history
- Terminal phase (L6) correctly rejects further transitions with exit code 2
- Dashboard coherence verified: after L0→L1 transition, dashboard correctly shows L1/Discovery
- Smoke test: `smoke/3-phase-transition.test.sh` — 39 checks across 9 phases
- All 7 test suites pass (structure: 56/56, config: 13/13, schemas: 22/22, scripts: 42/42, dashboard smoke: 31/31, onboarding smoke: 40/40, transition smoke: 39/39)

### Iteration 4
- Built **Research Agent Workspace** — the L1 agent that was missing from the phase transition target
- Created `agents/research/workspace/` with all 7 workspace files:
  - IDENTITY.md — agent ID, role, L1 activation phase
  - SOUL.md — rigorous, structured, skeptical, efficient, founder-aware traits with confidence-rated communication
  - AGENTS.md — full operating instructions: market scan → direction analysis → brand brief support → L2+ monitoring mode, L1 gate criteria awareness, structured research report format, anti-injection directive
  - TOOLS.md — permissions model: web_search/web_fetch for research, write to vault/research/ and vault/business/direction.json, read founder-profile for context, knowledge graph (insights write), progression engine (read-only)
  - HEARTBEAT.md — 6-hour heartbeat: phase verification, research state, direction state, brand brief state, L1 gate progress, pending requests
  - USER.md — reads founder profile from vault for research context
  - memory/ — empty session memory directory
- Registered research agent in `config/openclaw.json`: Sonnet primary model, 360m heartbeat, workspace mount path
- Added research agent to `agentToAgent.allow` list in gateway config
- Added research workspace volume mount in `docker-compose.yml`
- Updated orchestrator `AGENTS.md`: added L1 agent table with research agent, L1+ routing already existed
- Updated orchestrator `TOOLS.md`: added research agent messaging target, added vault/research/ and vault/business/ read/write access
- Created `knowledge/research/.gitkeep` for L1 gate criterion (market-research-done requires files in this dir)
- Updated `tests/validate-structure.sh`: added agents/research and agents/research/workspace to required dirs, added research to workspace file validation loop
- Smoke test: `smoke/4-research-agent.test.sh` — 49 checks across 9 phases (workspace files, AGENTS.md sections, identity/personality, tool permissions, gateway config, docker config, orchestrator integration, vault structure, progression coherence)
- All 8 test suites pass (structure: 62/62, config: 13/13, schemas: 22/22, scripts: 45/45, dashboard smoke: 31/31, onboarding smoke: 40/40, transition smoke: 39/39, research agent smoke: 49/49)

### Iteration 5
- Built **Workflow Pipeline Definitions** — codifies the two core multi-agent workflows that were missing
- Created `workflows/daily-briefing.lobster` — 8-step pipeline:
  - Steps: gather phase status → gather budget → gather pending tasks → gather recent knowledge → gather phase-specific context (adapts per L0-L6) → compile briefing → deliver to core-assistant → update briefing-state.json
  - Defines trigger (cron with timezone adjustment), agent assignments (orchestrator gathers, core-assistant delivers), data flow (vault inputs → compiled output), alert thresholds (80%/100%/200% budget), error handling, and success criteria
  - Phase-specific context blocks: L0 (onboarding progress), L1 (discovery status), L2 (social metrics), L3+ (revenue/treasury)
  - References founder communication style and quiet hours for delivery formatting
- Created `workflows/discovery.lobster` — 7-step pipeline:
  - Steps: founder profile ingestion → market scan → founder direction selection → competitive deep-dive → brand brief research → brand brief completion → L1 gate verification
  - Defines trigger (event: L1 transition or research request), L1 phase guard, agent assignments (research: steps 1-2,4-5; core-assistant: steps 3,6; orchestrator: step 7)
  - Tracks gate_progress for all 3 L1 criteria (direction-selected, brand-brief-complete, market-research-done)
  - Includes pipeline state tracking for resumption after interruption (state tracked implicitly through vault file existence)
  - Full research report JSON schema with findings, confidence, sources, recommendations
  - Founder interaction protocols: comparison, rejection (loops back), partial selection
  - Tier assignments: Tier 2 for research/scan, Tier 3 for competitive analysis and gate verification
- Updated orchestrator AGENTS.md: added "Workflow Pipelines" section with workflow reference table linking to both .lobster files
- Updated research agent AGENTS.md: added reference to discovery.lobster in the L1 Core Workflow section
- Updated tests/validate-structure.sh: added workflow file existence checks for both .lobster files
- Smoke test: `smoke/5-workflow-definitions.test.sh` — 74 checks across 10 phases (file existence, daily briefing structure, vault references, agent assignments, discovery structure, L1 gate criteria coverage, agent assignments, report format, agent integration, progression coherence)
- All 9 test suites pass (structure: 64/64, config: 13/13, schemas: 22/22, scripts: 48/48, dashboard smoke: 31/31, onboarding smoke: 40/40, transition smoke: 39/39, research agent smoke: 49/49, workflow definitions smoke: 74/74)

## Remaining Opportunities (ranked)

### Feature Completeness (V1 Critical Path)

1. **Channel configuration templates** — Discord/Telegram configs are commented out in openclaw.json. V1 should have a `scripts/enable-channel.sh` helper that uncomments and configures a channel with guided prompts.

2. **Template business types** — `templates/` dir is empty. V1 should include at least 2-3 starter templates (e.g., content-agency, saas-micro, consulting) that pre-seed business direction and brand brief for faster L1 completion.

3. **Knowledge graph propagation** — Backlog F4.1-S2: "insights propagate to relevant agents automatically" is planned. V1 needs at least the notification mechanism spec'd out.

4. **Documentation completeness** — CONTRIBUTING.md exists but could use expansion. No architecture decision records exist.

### Quality & Polish

5. **Dashboard auto-refresh** — Currently requires manual re-run of the generator script. Could add a cron hook or a watch mode.

6. **Schema validation on vault writes** — Currently schemas exist in `config/schemas/` but there's no validation enforced when agents write to vault files.

7. **SECURITY.md improvements** — Exists but could document the actual threat model (agent-to-agent trust, vault integrity, prompt injection defenses).

## Known Issues

1. **No templates** — `templates/` directory is empty. Business-type templates not created.
2. **Channel configuration commented out** — Discord/Telegram configs exist as comments in openclaw.json but no automation to enable them.
3. **Phase start date is hardcoded** — `phase-state.json` has `phaseStartDate: "2026-02-23T00:00:00Z"` which should be set dynamically by BOOT.md on first run. (Phase transition engine now sets the start date correctly on transition.)
4. **shellcheck not installed** — Test suite skips shell linting.
5. **Dashboard is static** — Must be manually regenerated to see current state. No live-refresh mechanism.
