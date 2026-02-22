# Agentic Root

Angelo's monorepo for all agentic work. This is NOT a single project — it contains multiple independent projects, documentation, scripts, and workspace configurations.

## Directory Structure

```
agentic/
├── development/projects/   # ALL code projects live here (see below)
├── docs/                   # Documentation, research, architecture decisions
│   ├── architecture/       # ADRs and system design docs
│   ├── research/           # Market research, AI landscape reports
│   ├── security/           # Security analysis docs
│   └── research/gumroad-bundle/  # Published content bundle
├── scripts/                # Standalone utility scripts (not project-specific)
│   ├── ralph/              # PRD workflow tool
│   ├── public-readiness-check
│   └── ubuntu-migration-backup.sh
└── workspaces/             # Workspace CLAUDE.md templates and creative assets
    ├── creative/           # Remotion video framework, vyzibl-showcase
    ├── presentations/      # PPTX generation engine (presenton)
    ├── development/        # Workspace config (CLAUDE.md only)
    ├── engineering/        # Workspace config (CLAUDE.md only)
    └── research/           # Workspace config (CLAUDE.md only)
```

## Projects (development/projects/)

All code projects — regardless of maturity — live under `development/projects/`. Each may have its own CLAUDE.md with project-specific rules.

| Project | Description | Status |
|---------|-------------|--------|
| `AITriageAgent/` | Azure AI triage agent (Python + MCP) | Deployed |
| `AITriage-Docs/` | Documentation for AITriageAgent | Complete |
| `vyzibl/` | AI visibility analytics SaaS (Next.js, Supabase) | Deployed |
| `claudeswarm/` | Visual command center for Claude Code teams (Turborepo) | Active |
| `mission-control-lib/` | Shared library: types, templates, engine for Mission Control | Active |
| `SwarmOS/` | Multi-agent orchestration layer (TypeScript) | MVP |
| `AgentTrace/` | Cross-agent observability platform (TypeScript) | MVP |
| `Engram/` | 3-tier agent memory infrastructure (TypeScript) | MVP |
| `Jarvis/` | Personal AI assistant with voice, memory, self-extension | Roadmap |
| `AgentProblems/` | Research report: 10 agent problems + solutions | Report |
| `md2pdf/` | Markdown to PDF converter | Utility |

## Agent Roster & Team Compositions

10 agents available in `.claude/agents/`. **Max 3 running simultaneously** (14GB RAM limit).

| Agent | Role | Read-only? |
|-------|------|------------|
| `architect` | System design, ADRs, trade-off analysis | Yes |
| `researcher` | Web search, docs analysis, tech evaluation | Yes |
| `docs-writer` | READMEs, API docs, guides, changelogs | No |
| `observability` | Health checks, log analysis, perf profiling, diagnostics | Yes |
| `frontend-dev` | React/Next.js/Tailwind implementation | No |
| `backend-dev` | Python/FastAPI/Node.js implementation | No |
| `test-writer` | Auto-detects stack, writes + runs tests | No |
| `code-reviewer` | Reviews diffs for bugs/security/perf | Yes |
| `security-auditor` | Secrets, OWASP, dependency vulns | Yes |
| `devops` | Docker, CI/CD, infrastructure | No |

### Team Compositions (pick max 3 for any task)

| Workflow | Agents | Why |
|----------|--------|-----|
| **Full-stack feature** | `frontend-dev` + `backend-dev` + `test-writer` | Parallel UI + API impl, then tests |
| **Backend feature** | `backend-dev` + `test-writer` + `code-reviewer` | Implement, test, review |
| **Frontend feature** | `frontend-dev` + `test-writer` + `code-reviewer` | Implement, test, review |
| **Pre-ship review** | `code-reviewer` + `security-auditor` + `test-writer` | Quality gate before merge |
| **New project/design** | `architect` + `researcher` + `backend-dev` | Research, design, scaffold |
| **Bug triage** | `researcher` + `backend-dev` + `test-writer` | Investigate, fix, regression test |
| **Infra/deploy** | `devops` + `security-auditor` + `backend-dev` | Build, audit, integrate |
| **Incident/diagnostics** | `observability` + `devops` + `backend-dev` | Diagnose, fix infra, patch code |
| **Documentation** | `docs-writer` + `researcher` + `code-reviewer` | Write docs, research context, review accuracy |
| **Research spike** | `researcher` + `architect` | Investigate + design (no impl) |

### Orchestration Rules
- The **lead agent** (you) picks the team based on the task type above
- If the task doesn't fit a template, pick the 2-3 most relevant agents
- **Never spawn all 8** — pick the right 2-3 for the job
- Read-only agents (`architect`, `researcher`, `observability`, `code-reviewer`, `security-auditor`) are cheap — prefer them when you only need analysis
- Implementation agents (`frontend-dev`, `backend-dev`, `devops`, `test-writer`) modify files — spawn these when work needs doing

## Rules

- Do what has been asked; nothing more, nothing less
- NEVER create files unless absolutely necessary
- ALWAYS prefer editing existing files over creating new ones
- ALWAYS read a file before editing it
- NEVER commit secrets, credentials, or .env files
- Individual projects have their own CLAUDE.md — always check for and follow project-specific instructions

## Where Things Go

- **New project?** → `development/projects/<name>/`
- **New documentation?** → `docs/<category>/`
- **New utility script?** → `scripts/`
- **New workspace template?** → `workspaces/<name>/`
- **Research or reports?** → `docs/research/`
- **NEVER** put projects at the repo root or directly in `development/`
- **NEVER** duplicate directories across locations
