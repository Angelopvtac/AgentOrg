# Contributing to AgentOrg

## Adding a New Agent

1. Create the agent directory:
   ```
   agents/<agent-id>/workspace/
   ```

2. Create the required workspace files:
   - `IDENTITY.md` — Agent ID, role, activation phase
   - `SOUL.md` — Core principles, personality traits, decision-making framework
   - `AGENTS.md` — Operating instructions, routing rules, workflow references
   - `TOOLS.md` — Available tools, access control, vault read/write permissions
   - `USER.md` — Information about the user/founder (read from vault)
   - `HEARTBEAT.md` — Periodic tasks (phase verification, state checks, gate progress)
   - `memory/` — Empty directory for session memory

3. Register the agent in `config/openclaw.json` under `agents.list`:
   ```json5
   {
     "id": "your-agent-id",
     "name": "Display Name",
     "workspace": "/home/node/.openclaw/workspace-your-agent-id",
     "agentDir": "/home/node/.openclaw/agents/your-agent-id/agent",
     "model": {
       "primary": "openrouter/anthropic/claude-haiku-4.5"
     },
     "heartbeat": { "every": "1440m" },
     "identity": { "name": "Display Name" }
   }
   ```

4. Add volume mounts in `docker-compose.yml`:
   ```yaml
   - ./agents/your-agent-id/workspace:/home/node/.openclaw/workspace-your-agent-id
   ```

5. Add the agent to `agentToAgent.allow` in `config/openclaw.json` so the orchestrator can message it.

6. Register the agent in the appropriate phase in `config/progression.json`.

7. Update `agents/orchestrator/workspace/AGENTS.md` — add to the agent table and routing rules.

8. Update `agents/orchestrator/workspace/TOOLS.md` — add messaging target for the new agent.

9. Update `tests/validate-structure.sh` — add the new agent directory and workspace files to validation checks.

10. Write a smoke test in `smoke/` that verifies workspace files, gateway config, docker config, and orchestrator integration.

## Adding a New Skill

1. Create the skill directory:
   ```
   skills/<skill-name>/SKILL.md
   ```

2. In `SKILL.md`, define:
   - **Storage** — Vault paths used by the skill
   - **Tools** — Each tool with parameters, behavior, and examples
   - **Access control** — Which agents can read/write

3. Add tool references to each agent's `TOOLS.md` that should have access.

4. If the skill stores data in `knowledge/`, create the initial data file (empty collection/store).

5. Add a JSON schema in `config/schemas/` if the skill introduces a new data format.

## Adding a New Workflow

1. Create the workflow file:
   ```
   workflows/<workflow-name>.lobster
   ```

2. Define the pipeline with:
   - **Trigger** — What starts the pipeline (cron, event, manual)
   - **Steps** — Ordered sequence with agent assignments and data flow
   - **Gate tracking** — Which progression criteria the workflow advances
   - **Error handling** — What happens when a step fails
   - **Success criteria** — How to verify the pipeline completed correctly

3. Reference the workflow in the orchestrator's `AGENTS.md` under the Workflow Pipelines section.

4. Reference the workflow in any agent's `AGENTS.md` that participates in the pipeline.

5. Update `tests/validate-structure.sh` to check the workflow file exists.

## Adding a New Business Template

1. Create the template directory:
   ```
   templates/<template-id>/
   ```

2. Create the required files:
   - `template.json` — Manifest with id, name, description, suggestedSkills, suggestedGoal, files list
   - `direction.json` — Pre-seeded business direction with market, positioning, revenue model, risks, alternatives
   - `brand-brief.json` — Brand brief with name, tagline, voice, audience, visual identity
   - `market-research.json` — Market scan report with findings, confidence levels, sources, recommendations

3. The template is auto-discovered by `scripts/apply-template.py` — no registration needed.

4. Test with: `./scripts/apply-template.sh --preview <template-id>`

## Adding a New Phase

1. Add the phase definition in `config/progression.json`:
   - `name`, `description`, `agents` list
   - `gate.criteria` — measurable conditions for progression
   - `transition.target` and `transition.actions`

2. Create any new vault files referenced by the gate criteria.

3. Add a gate evaluator function in `scripts/phase-transition.py` for the new phase.

4. Update `scripts/generate-dashboard.py` to display the new phase's data if it has unique vault files.

5. Update the orchestrator's `HEARTBEAT.md` if the phase needs periodic evaluation.

## Adding a New Script

Scripts follow a two-file pattern: a bash wrapper and a Python implementation.

1. Create the Python script: `scripts/<script-name>.py`
2. Create the bash wrapper: `scripts/<script-name>.sh`
3. The bash wrapper should:
   - Have `set -euo pipefail` and a shebang line
   - Resolve the script directory for the Python path
   - Forward all arguments to the Python script
4. Update `tests/validate-structure.sh` to check the new scripts exist.
5. Write a smoke test in `smoke/` that exercises all modes.

## Conventions

- **Config files**: kebab-case JSON/JSON5 (e.g., `daily-budget.json`)
- **Agent workspace files**: UPPERCASE.md (e.g., `IDENTITY.md`, `SOUL.md`)
- **Scripts**: kebab-case bash (e.g., `health-check.sh`)
- **Skills**: kebab-case directory with `SKILL.md` inside
- **Templates**: kebab-case directory with `template.json` manifest
- **Workflows**: kebab-case `.lobster` files
- **Smoke tests**: numbered `smoke/<N>-<name>.test.sh`
- All bash scripts must have `set -euo pipefail` and a shebang line
- Never commit `.env` or secrets — use environment variables
- Knowledge files (`knowledge/`) are runtime state — back up with `scripts/backup.sh`

## Validation

Run the full test suite before submitting changes:

```bash
./tests/run-all.sh
```

This runs:
- Structure validation (directories, workspace files, config files, scripts, templates, workflows)
- Config validation (JSON syntax, required fields)
- Schema validation (vault file compliance)
- Script validation (existence, permissions)
- 8 smoke test suites (dashboard, onboarding, transitions, research agent, workflows, templates, channels, lifecycle integration)
