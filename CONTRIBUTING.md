# Contributing to AgentOrg

## Adding a New Agent

1. Create the agent directory:
   ```
   agents/<agent-id>/workspace/
   ```

2. Create the required workspace files:
   - `AGENTS.md` — Defines which agents this agent knows about and can interact with
   - `IDENTITY.md` — Agent name, role, personality, and behavioral guidelines
   - `SOUL.md` — Core principles, values, and decision-making framework
   - `TOOLS.md` — Available tools, access control, and usage instructions
   - `USER.md` — Information about the user/founder (copied from onboarding data)
   - `HEARTBEAT.md` — Cron-triggered tasks (daily checks, periodic actions)

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

5. Register the agent in the appropriate phase in `config/progression.json`.

6. Update `agents/orchestrator/workspace/AGENTS.md` so the orchestrator knows about the new agent.

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

## Adding a New Phase

1. Add the phase definition in `config/progression.json`:
   - `name`, `description`, `agents` list
   - `gate.criteria` — measurable conditions for progression
   - `transition.target` and `transition.actions`

2. Create any new vault files referenced by the gate criteria.

3. Update the orchestrator's `HEARTBEAT.md` if the phase needs periodic evaluation.

## Conventions

- **Config files**: kebab-case JSON/JSON5 (e.g., `daily-budget.json`)
- **Agent workspace files**: UPPERCASE.md (e.g., `IDENTITY.md`, `SOUL.md`)
- **Scripts**: kebab-case bash (e.g., `health-check.sh`)
- **Skills**: kebab-case directory with `SKILL.md` inside
- All bash scripts must have `set -euo pipefail` and a shebang line
- Never commit `.env` or secrets — use environment variables
- Knowledge files (`knowledge/`) are runtime state — back up with `scripts/backup.sh`

## Validation

Run the test suite before submitting changes:

```bash
./tests/run-all.sh
```

This checks project structure, JSON validity, schema compliance, and script quality.
