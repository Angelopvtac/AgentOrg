# Knowledge Graph Skill

Shared institutional memory for AgentOrg. Stores decisions, insights, and lessons learned across all agents and phases.

## Collections

| Collection | Path | Description |
|------------|------|-------------|
| decisions | `vault/decisions.json` | Strategic decisions and their rationale |
| insights | `vault/insights.json` | Observations, patterns, and discoveries |
| lessons | `vault/lessons.json` | Lessons learned from successes and failures |

## Tools

### `kg_store`

Add an entry to a knowledge collection.

**Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| collection | string | yes | One of: `decisions`, `insights`, `lessons` |
| title | string | yes | Short descriptive title |
| content | string | yes | Full entry content |
| tags | string[] | yes | Categorization tags (at least 1) |
| relatedIds | string[] | no | UUIDs of related entries |

**Behavior:**
1. Read the collection file from vault
2. Generate a UUID for the new entry
3. Create entry object with: id, timestamp (ISO 8601), author (your agent ID), title, content, tags, phase (from `vault/phase-state.json` currentPhase), relatedIds
4. Append to the collection's `entries` array
5. Write the updated collection back to vault

### `kg_read`

Read a single entry by ID.

**Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| collection | string | yes | One of: `decisions`, `insights`, `lessons` |
| id | string | yes | UUID of the entry |

**Behavior:**
1. Read the collection file from vault
2. Find the entry matching the given ID
3. Return the full entry object
4. If not found, return an error message

### `kg_search`

Search entries by tags, date range, or keyword.

**Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| collection | string | yes | One of: `decisions`, `insights`, `lessons` |
| tags | string[] | no | Filter by any matching tag |
| keyword | string | no | Search in title and content (case-insensitive) |
| since | string | no | ISO 8601 timestamp — entries after this date |
| until | string | no | ISO 8601 timestamp — entries before this date |
| limit | number | no | Max results to return (default: 20) |

**Behavior:**
1. Read the collection file from vault
2. Apply filters in order: tags (any match), keyword (substring in title or content), date range
3. Sort results by timestamp descending (newest first)
4. Apply limit
5. Return matching entries

At least one filter parameter (tags, keyword, since, or until) is required.

### `kg_list`

List recent entries in a collection.

**Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| collection | string | yes | One of: `decisions`, `insights`, `lessons` |
| limit | number | no | Max entries to return (default: 10, max: 50) |

**Behavior:**
1. Read the collection file from vault
2. Sort by timestamp descending
3. Return the most recent entries up to limit

## Access Control

| Agent | decisions | insights | lessons |
|-------|-----------|----------|---------|
| orchestrator | read/write | read/write | read/write |
| core-assistant | read | read/write | read |
| Future agents | Defined at unlock time per phase requirements |

**Enforcement:** Each agent checks its own TOOLS.md for permitted operations before calling a tool. If an agent attempts a write to a collection it doesn't have write access to, it must refuse the operation and log the attempt.

## Entry Schema

```json
{
  "id": "<uuid>",
  "timestamp": "<ISO 8601>",
  "author": "<agent-id>",
  "title": "<string>",
  "content": "<string>",
  "tags": ["<string>"],
  "phase": "<L0-L6>",
  "relatedIds": ["<uuid>"]
}
```

## Collection File Format

```json
{
  "collection": "<name>",
  "description": "<purpose>",
  "entries": []
}
```

## Usage Examples

**Store a decision:**
```
kg_store:
  collection: decisions
  title: "Selected OpenRouter as primary AI provider"
  content: "Chose OpenRouter for model access due to single API key supporting multiple providers, competitive pricing, and fallback routing. Direct Anthropic API kept as optional backup."
  tags: ["infrastructure", "ai-provider", "cost-optimization"]
```

**Search insights from last 24 hours:**
```
kg_search:
  collection: insights
  since: "2026-02-21T00:00:00Z"
  limit: 5
```

**List recent lessons:**
```
kg_list:
  collection: lessons
  limit: 5
```
