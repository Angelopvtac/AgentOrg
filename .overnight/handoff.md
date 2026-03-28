# Overnight Handoff — AgentOrg

## Meta
- Goal: get this to v1
- Iteration: 11
- Status: COMPLETE
- Timestamp: 2026-03-28T14:00:00Z
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
- **Business Templates**: 3 starter templates (content-agency, saas-micro, consulting) in `templates/` with apply script to pre-seed L1 discovery data
- **Channel Configuration**: Script to enable/disable Discord and Telegram channels in gateway config with env var validation, status reporting, and idempotent operations

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
11. **Template application flow**: `bash scripts/apply-template.sh --list` shows 3 templates → `--preview <id>` shows details → `--apply <id>` writes direction.json, brand-brief.json, and market research report to vault with timestamps → reports L1 gate progress → `--reset` clears L1 data back to empty state
12. **Channel configuration flow**: `bash scripts/enable-channel.sh --status` shows enabled/disabled status + token detection → `--enable discord/telegram` activates the channel in gateway config (warns if token not set, shows setup URL and next steps) → `--disable discord/telegram` deactivates → idempotent operations, config integrity preserved across all operations

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
smoke/6-business-templates.test.sh — Smoke test: business templates & apply-template script (122 checks)
smoke/7-channel-configuration.test.sh — Smoke test: channel configuration manager (61 checks)
smoke/8-lifecycle-integration.test.sh — Smoke test: end-to-end lifecycle integration (52 checks)
templates/content-agency/      — Content & Marketing Agency template (Inkwell Studio)
templates/saas-micro/          — Micro-SaaS Product template (Shiplog)
templates/consulting/          — AI Operations Consulting template (Practical AI Partners)
templates/*/template.json      — Template manifest (id, name, description, suggestedSkills, files)
templates/*/direction.json     — Pre-seeded business direction with market, revenue model, risks, alternatives
templates/*/brand-brief.json   — Pre-seeded brand brief with name, tagline, voice, audience, visual identity
templates/*/market-research.json — Pre-seeded market research report with findings, confidence, sources, recommendations
scripts/apply-template.sh      — Template application (bash wrapper → calls apply-template.py)
scripts/apply-template.py      — Python script: list, preview, apply, reset business-type templates
scripts/enable-channel.sh      — Channel configuration (bash wrapper → calls enable-channel.py)
scripts/enable-channel.py      — Python script: enable/disable Discord/Telegram channels in gateway config
tests/run-all.sh               — Test runner (4 validation suites + smoke tests)
tests/validate-*.sh            — Individual validation scripts
docker-compose.yml             — Single gateway container with volume mounts for 3 agents, security hardening
BACKLOG.md                     — Full product backlog (Epics 1-11+, stories, tasks with status)
README.md                      — Comprehensive project documentation (quick start, phase system, features, scripts, troubleshooting)
CONTRIBUTING.md                — Contribution guide (adding agents, skills, workflows, templates, phases, scripts)
SECURITY.md                    — Security policy and Docker hardening documentation
smoke/9-documentation.test.sh  — Smoke test: documentation completeness (104 checks)
smoke/10-knowledge-propagation.test.sh — Smoke test: knowledge graph propagation mechanism (101 checks)
smoke/11-backlog-consistency.test.sh — Smoke test: backlog status sync with project state (81 checks)
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
- **Templates ↔ Vault**: `scripts/apply-template.py` reads template files from `templates/<id>/` → writes direction.json, brand-brief.json to `vault/business/`, market research to `vault/research/` with timestamps. Templates satisfy all 3 L1 gate criteria (direction-selected, brand-brief-complete, market-research-done), enabling fast-track through L1 Discovery phase. Reset mode restores vault to empty L1 state.
- **Channel Config ↔ Gateway**: `scripts/enable-channel.py` reads/writes `config/openclaw.json` to enable/disable Discord and Telegram channel blocks. Validates env vars in `.env`, preserves all non-channel config sections. Channels use `${ENV_VAR}` token substitution resolved by Docker at runtime via `docker-compose.yml` env forwarding.

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

### Iteration 6
- Built **Business Type Templates** — 3 starter templates to accelerate L1 Discovery phase
- Created 3 template directories (`templates/content-agency/`, `templates/saas-micro/`, `templates/consulting/`) each with:
  - `template.json` — manifest with id, name, description, suggestedSkills, suggestedGoal, file list
  - `direction.json` — pre-seeded business direction with market, positioning, revenue model, differentiator, target customer, channels, risks, and rejected alternatives
  - `brand-brief.json` — brand brief with name, tagline, voice, audience, positioning, visual identity
  - `market-research.json` — market scan report with categorized findings (market-size, competition, pricing, opportunity), confidence ratings, sources, and recommendations
- Template brands: Inkwell Studio (content agency), Shiplog (micro-SaaS), Practical AI Partners (consulting)
- Created `scripts/apply-template.py` — Python script with 4 modes:
  - `--list`: Lists all available templates with names and descriptions
  - `--preview <id>`: Shows detailed template info (direction summary, brand, skills, files)
  - `--apply <id> [vault]`: Writes template data to vault with timestamps, reports L1 gate progress (all 3 criteria: direction-selected, brand-brief-complete, market-research-done)
  - `--reset [vault]`: Clears L1 business data back to empty state (direction, brand brief, research reports)
- Created `scripts/apply-template.sh` — bash wrapper matching existing script patterns
- Updated `tests/validate-structure.sh`: added template file existence checks (3 templates × 4 files + 2 scripts)
- Smoke test: `smoke/6-business-templates.test.sh` — 122 checks across 13 phases (template structure, manifests, direction files, brand briefs, research reports, script structure, list/preview/apply/reset modes, error handling, progression coherence)
- All 10 test suites pass (structure: 78/78, config: 13/13, schemas: 22/22, scripts: 48/48, dashboard smoke: 31/31, onboarding smoke: 40/40, transition smoke: 39/39, research agent smoke: 49/49, workflow definitions smoke: 74/74, business templates smoke: 122/122)

### Iteration 7
- Built **Channel Configuration Manager** — enables/disables Discord and Telegram channels in the gateway config
- Created `scripts/enable-channel.py` — Python script with 3 modes:
  - `--enable <channel>`: Activates a channel in config/openclaw.json, validates env var in .env, warns if token not set with setup URL, shows next steps (token setup, container restart, platform-specific steps)
  - `--disable <channel>`: Deactivates a channel, restores commented template when last channel disabled
  - `--status`: Shows enabled/disabled status for all channels with masked token display
- Created `scripts/enable-channel.sh` — bash wrapper matching existing script patterns
- Channel management rebuilds the entire channels region on each operation for clean, consistent output
- Supports: enable discord, enable telegram, both simultaneously, disable one while keeping other, disable all (restores original commented template)
- Idempotent: re-enabling an enabled channel or re-disabling a disabled channel is a no-op with informative message
- Token detection reads .env file, strips inline comments, masks displayed values
- Config integrity: all non-channel sections (agents, tools, gateway, hooks, etc.) preserved across all operations
- Updated `tests/validate-structure.sh`: added channel script existence checks
- Smoke test: `smoke/7-channel-configuration.test.sh` — 61 checks across 13 phases (script structure, status modes, enable/disable operations, idempotency, token detection, error handling, config integrity, gateway coherence)
- All 11 test suites pass (structure: 80/80, config: 13/13, schemas: 22/22, scripts: 48/48, dashboard smoke: 31/31, onboarding smoke: 40/40, transition smoke: 39/39, research agent smoke: 49/49, workflow definitions smoke: 74/74, business templates smoke: 122/122, channel configuration smoke: 61/61)

### Iteration 8
- Built **End-to-End Lifecycle Integration Test** — proves the entire progression pipeline works as a connected system
- Created `smoke/8-lifecycle-integration.test.sh` — 52 checks across 13 phases:
  - Phase 1-2: Initialize fresh vault, verify L0 gate rejects empty state
  - Phase 3-4: Simulate complete onboarding, verify L0 gate passes (6/6 criteria)
  - Phase 5: Execute L0→L1 transition, verify state update and history logging
  - Phase 6: Verify L1 gate fails without business data (0/3 criteria)
  - Phase 7: Apply content-agency template, verify all L1 data populated
  - Phase 8: Verify L1 gate passes (3/3 criteria)
  - Phase 9: Execute L1→L2 transition, verify state and history
  - Phase 10-11: Status shows full journey, dashboard renders L2/Presence state
  - Phase 12: Vault state consistency — ordered history, all data survives transitions
  - Phase 13: Reset capabilities — template and onboarding resets work cleanly
- **Bug fix discovered and resolved**: L1 gate evaluator field mismatches with template data:
  - `direction.get("targetMarket")` → now checks `direction.direction.market` or `direction.direction.targetCustomer` (nested dict)
  - `brand.get("tone")` → now checks `brand.get("voice")` with `tone` fallback
  - Research report counter now filters to `.json` files only (excludes `.gitkeep`)
- This integration test exercises the full chain: simulate-onboarding.py → phase-transition.py → apply-template.py → phase-transition.py → generate-dashboard.py
- All 12 test suites pass (structure: 80/80, config: 13/13, schemas: 22/22, scripts: 48/48, dashboard smoke: 31/31, onboarding smoke: 40/40, transition smoke: 39/39, research agent smoke: 49/49, workflow definitions smoke: 74/74, business templates smoke: 122/122, channel configuration smoke: 61/61, lifecycle integration smoke: 52/52)

### Iteration 9
- Built **V1 Documentation** — comprehensive README rewrite + CONTRIBUTING update + documentation smoke test
- **README.md rewritten from scratch** — was frozen at "Sprint 3 complete" and missing 8 iterations of features:
  - Added "How It Works" section with architecture diagram explaining the configuration-driven agent framework model
  - Added Python 3 as a prerequisite (required by dashboard, simulation, transition, template scripts)
  - Expanded Quick Start to include dashboard generation step
  - Added full sections for: Founder Dashboard, Onboarding Simulation, Business Templates, Channel Configuration, Workflow Pipelines
  - Added "Working with Phases" section with concrete CLI commands for phase-transition.sh modes
  - Added Skills reference table with all 4 skills and their tool interfaces
  - Updated Scripts Reference table from 4 scripts to all 8
  - Updated Directory Structure table to include all directories (agents/research, workflows, templates, smoke)
  - Updated Testing section to reference 8 smoke test suites and 500+ checks
  - Added Troubleshooting entry for stale dashboard data
  - Removed stale "Current Status" / "Sprint 3 complete" / "What's working" sections
- **CONTRIBUTING.md expanded** — was only 88 lines covering 3 contribution types:
  - Added "Adding a New Workflow" section (Lobster pipeline format)
  - Added "Adding a New Business Template" section (template.json manifest, auto-discovery)
  - Added "Adding a New Script" section (bash wrapper + Python implementation pattern)
  - Expanded "Adding a New Agent" from 6 steps to 10 (includes agentToAgent.allow, orchestrator TOOLS.md, validate-structure.sh, smoke test)
  - Added "Adding a New Phase" step for gate evaluator in phase-transition.py
  - Updated Conventions section to include templates, workflows, and smoke test naming patterns
  - Updated Validation section to describe all 4 validation suites + 8 smoke test suites
- **Smoke test: `smoke/9-documentation.test.sh`** — 104 checks across 17 phases:
  - Phase 1: Documentation files exist (README, CONTRIBUTING, SECURITY, LICENSE, CLAUDE.md, BACKLOG.md)
  - Phase 2-3: README covers all agents (3) and all scripts (8)
  - Phase 4: README covers all skills (4)
  - Phase 5: README covers all 7 phases with names
  - Phase 6: README covers all 3 model tiers with names
  - Phase 7: README covers all key features (dashboard, simulation, transitions, templates, channels, workflows)
  - Phase 8: README covers environment variables (6 key vars)
  - Phase 9: README covers directory structure (9 directories)
  - Phase 10: README covers testing
  - Phase 11: No stale content (no "Sprint 3 complete", no "What's working" section)
  - Phase 12-13: Quick start and troubleshooting completeness
  - Phase 14-15: CONTRIBUTING covers all 6 contribution types and conventions
  - Phase 16: SECURITY covers key hardening areas
  - Phase 17: Cross-document consistency — verifies README references match actual disk state (templates, agents, skills, workflows)
- All 13 test suites pass (structure: 80/80, config: 13/13, schemas: 22/22, scripts: 48/48, dashboard smoke: 31/31, onboarding smoke: 40/40, transition smoke: 39/39, research agent smoke: 49/49, workflow definitions smoke: 74/74, business templates smoke: 122/122, channel configuration smoke: 61/61, lifecycle integration smoke: 52/52, documentation smoke: 104/104)

### Iteration 10
- Built **Knowledge Graph Propagation Mechanism** — the last V1 critical path feature (F4.1-S2)
- **Updated `skills/knowledge-graph/SKILL.md`** — added "Propagation Protocol" section:
  - After any `kg_store` call, the storing agent must send a `[KG_STORED]` notification to `agent:orchestrator:main` via `sessions_send`
  - Notification format includes: Collection, Entry ID, Title, Tags, Author, Phase
  - Documents that orchestrator self-stores skip the notification step
  - Specifies Tier 1 cost for propagation with Tier 3 escalation for strategic/critical entries
- **Updated `agents/orchestrator/workspace/AGENTS.md`** — added "Knowledge Propagation" section:
  - Propagation routing table: 6 rules mapping collection × tags to target agents (core-assistant, research) with phase gating (L0+, L1+)
  - `[KG_NOTIFICATION]` format sent to target agents with Summary, Tags, Action, and kg_read reference
  - 5 propagation rules: phase gating, deduplication, batch during briefing, cost control (Tier 1), quiet hours respect
  - Urgent/critical entries bypass batching for immediate delivery
  - Updated "Messages you receive" table with `[KG_STORED]` from any agent
  - Updated "Messages you send" table with `[KG_NOTIFICATION]` to core-assistant and research
- **Updated `agents/core-assistant/workspace/AGENTS.md`** — added "Knowledge Notifications" section:
  - Handles `[KG_NOTIFICATION]` from orchestrator
  - Decisions: always inform founder at next opportunity
  - Insights: mention if relevant to current topic, else batch for daily briefing
  - Lessons: include in daily briefing unless urgent
  - Anti-spam: batch informational entries, don't re-interpret content, don't act without founder input
- **Updated `agents/research/workspace/AGENTS.md`** — added "Knowledge Notifications" section:
  - Handles `[KG_NOTIFICATION]` from orchestrator
  - Direction/market decisions: re-evaluate in-progress analysis, flag conflicts
  - Competitive insights: add to intelligence context, consider ad-hoc trend report
  - Methodology lessons: adjust research approach
  - Anti-circular: don't re-send notifications, don't fabricate findings to align with stored entries
- **Smoke test: `smoke/10-knowledge-propagation.test.sh`** — 101 checks across 14 phases:
  - Phase 1: Skill propagation protocol (notification format, all fields)
  - Phase 2: Cost awareness (Tier 1, strategic/critical escalation, self-store handling)
  - Phase 3: Orchestrator propagation specification (section, routing table, formats)
  - Phase 4: Routing table completeness (all 6 collection→agent routes)
  - Phase 5: Phase gating (L0+, L1+, activity checks)
  - Phase 6: Propagation rules (dedup, batching, cost, quiet hours, urgent/critical)
  - Phase 7: Notification format (KG_NOTIFICATION fields, kg_read reference)
  - Phase 8: Orchestrator message table integration (KG_STORED received, KG_NOTIFICATION sent)
  - Phase 9: Core-assistant notification handling (all collections, batching, anti-spam)
  - Phase 10: Research agent notification handling (direction, competitive, methodology, anti-circular)
  - Phase 11: Cross-reference consistency (SKILL→orchestrator→agents, all collections)
  - Phase 12: Existing agent functionality preserved (all sections across all 3 agents)
  - Phase 13: Skill definition integrity (all 4 tools, access control, schema, examples)
  - Phase 14: Tag-based routing coverage (11 key tags in routing table)
- All 14 test suites pass (structure: 80/80, config: 13/13, schemas: 22/22, scripts: 48/48, dashboard smoke: 31/31, onboarding smoke: 40/40, transition smoke: 39/39, research agent smoke: 49/49, workflow definitions smoke: 74/74, business templates smoke: 122/122, channel configuration smoke: 61/61, lifecycle integration smoke: 52/52, documentation smoke: 104/104, knowledge propagation smoke: 101/101)

### Iteration 11
- Built **Backlog Status Sync** — updated BACKLOG.md to accurately reflect V1 completion state
- **13 story status changes** from `planned` to `done`:
  - F1.3-S2 (cost attribution per tier) — economics engine skill defines this
  - F3.1-S3 (phase transition on criteria) — phase-transition.py (iteration 3)
  - F4.1-S2 (insight propagation) — knowledge propagation (iteration 10)
  - F8.1-S1/S2/S3 (research agent capabilities) — research workspace (iteration 4)
  - F8.2-S1 (discovery workflow) — discovery.lobster (iteration 5)
  - F9.5-S1 (daily briefing workflow) — daily-briefing.lobster (iteration 5)
  - F14.1-S1/S2 (founder dashboard) — dashboard generator (iteration 1)
  - F15.1-S1 (business templates) — 3 templates + apply script (iteration 6)
  - F16.1-S1 (untrusted input) — anti-injection in agent prompts
  - F16.2-S1/S2 (financial safety) — economics engine + orchestrator kill switch
  - F16.3-S1 (local data + env secrets) — .env pattern + .gitignore
- **Updated backlog summary table** — replaced stale "42% complete" / "MVP DONE" entries with accurate V1 status per epic
- **Updated sprint descriptions** — consolidated Sprints 1-3 as "V1 Foundation" (done), removed stale Sprint 4 (done), documented overnight iteration contributions
- **Verified L2+ items remain correctly `planned`** — content agent, social agent, sales agent, finance agent, etc. are future-phase work
- Smoke test: `smoke/11-backlog-consistency.test.sh` — 81 checks across 14 phases (story statuses, summary table accuracy, sprint descriptions, cross-reference with disk artifacts)
- All 15 test suites pass (structure: 80/80, config: 13/13, schemas: 22/22, scripts: 48/48, dashboard smoke: 31/31, onboarding smoke: 40/40, transition smoke: 39/39, research agent smoke: 49/49, workflow definitions smoke: 74/74, business templates smoke: 122/122, channel configuration smoke: 61/61, lifecycle integration smoke: 52/52, documentation smoke: 104/104, knowledge propagation smoke: 101/101, backlog consistency smoke: 81/81)

## Remaining Opportunities (ranked)

### Polish (non-blocking)

1. **Dashboard auto-refresh** — Currently requires manual re-run of the generator script. Could add a watch mode that regenerates on vault file changes.

2. **Schema validation on vault writes** — Currently schemas exist in `config/schemas/` but there's no validation enforced when agents write to vault files.

3. **SECURITY.md threat model** — Could document the actual threat model (agent-to-agent trust, vault integrity, prompt injection defenses) beyond the Docker hardening already documented.

## Known Issues

1. **Phase start date is hardcoded** — `phase-state.json` has `phaseStartDate: "2026-02-23T00:00:00Z"` which should be set dynamically by BOOT.md on first run. (Phase transition engine now sets the start date correctly on transition.)
2. **shellcheck not installed** — Test suite skips shell linting.
3. **Dashboard is static** — Must be manually regenerated to see current state. No live-refresh mechanism.
4. **Channel config default state is commented** — Channels start commented out in openclaw.json but `scripts/enable-channel.sh` automates enabling/disabling. After a full disable→re-enable cycle, the commented template format differs slightly from the original (JSON-formatted vs hand-formatted) — functionally equivalent.

## V1 Completion Assessment

The V1 goal is achieved. The complete L0-L1 infrastructure is operational:

- **3 agents** (orchestrator, core-assistant, research) fully configured with workspace files
- **4 skills** (knowledge-graph, human-task-queue, progression-engine, economics-engine) defined with tool interfaces
- **2 workflows** (daily-briefing, discovery) codified as Lobster pipelines
- **3 business templates** (content-agency, saas-micro, consulting) with apply/reset script
- **Full lifecycle proven** — L0→L1→L2 transition tested end-to-end
- **Founder dashboard** — static HTML generated from vault data
- **8 operational scripts** — setup, health-check, backup, dashboard, simulation, transition, templates, channels
- **Channel configuration** — Discord and Telegram enable/disable with env var validation
- **Knowledge propagation** — notification protocol across all agents
- **15 test suites, 800+ checks** — comprehensive coverage of all features
- **Documentation** — README, CONTRIBUTING, SECURITY, CLAUDE.md all current
- **BACKLOG.md** — accurately reflects V1 completion state

Remaining backlog items (Epics 9-13: content agent, social agent, sales agent, finance agent, operations agent, audit agent, strategy agent, pivot protocol) are L2+ features that require a live deployed gateway with real platform API access. They are correctly scoped as post-V1 work.
