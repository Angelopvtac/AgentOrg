# Gamify

Developer achievement engine — turn shipping code into a game. Tracks git activity, awards XP/levels/achievements/streaks, generates beautiful reports.

## Dev

- `npm run build` — compile TypeScript
- `npm run lint` — type check
- `npm run test` — run tests (44 tests)
- `npm run dev -- <command>` — run CLI in dev mode

## Architecture

```
src/
├── engine/                  # Core engine
│   ├── gamify-store.ts      # SQLite database layer (better-sqlite3)
│   ├── xp-calculator.ts     # XP calculation + level system
│   ├── event-processor.ts   # Event → XP → streak → achievement pipeline
│   ├── achievement-evaluator.ts  # Declarative condition evaluator
│   └── streak-tracker.ts    # Streak tracking with freeze logic
├── adapters/
│   └── git.ts               # Git log → EngEvent adapter
├── achievements/
│   └── builtin.ts           # 16 built-in achievement definitions
├── cli/
│   └── commands.ts          # CLI command handlers
├── types.ts                 # All types (engine + report)
├── index.ts                 # Public API exports
├── generator.ts             # HTML report generator
└── cli.ts                   # CLI entry point (routes commands + legacy)
```

## CLI Usage

```bash
gamify init [--name <name>]         # Initialize player + DB
gamify sync [--since <date>]        # Collect events from git
gamify status                       # Show level, XP, streaks
gamify achievements [--all]         # List achievements
gamify <input.json> [out.html]      # Legacy: generate HTML report
```

## Key Design Decisions

- **SQLite storage** via better-sqlite3 at `~/.config/gamify/gamify.db`
- **Sync not watch** — adapters collect on demand, no background processes
- **Achievements as data** — JSON-serializable conditions, not code
- **Backward-compatible** — `gamify <input.json>` and `generateReport()` still work
- **Streaks with safeguards** — 2 freeze charges per 30 days, grace period, positive messaging on break
