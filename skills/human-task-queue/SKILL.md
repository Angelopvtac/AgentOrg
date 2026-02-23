# Human Task Queue Skill

Task management for items that require founder action. Agents create tasks, the founder completes them. Supports priority levels, deadlines, and quiet hours awareness.

## Storage

| Path | Description |
|------|-------------|
| `vault/human-tasks.json` | Task store with all tasks |

## Tools

### `htq_create`

Create a task for the founder.

**Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| title | string | yes | Short task title |
| description | string | yes | What needs to be done and why |
| priority | string | yes | One of: `critical`, `high`, `medium`, `low` |
| estimatedMinutes | number | no | Estimated time to complete (null if unknown) |
| deadline | string | no | ISO 8601 deadline (null if no deadline) |

**Behavior:**
1. Read `vault/human-tasks.json`
2. Generate a UUID for the new task
3. Create task object with: id, createdBy (your agent ID), title, description, priority, estimatedMinutes, deadline, status ("pending"), createdAt (ISO 8601), completedAt (null), completionNotes (null)
4. Append to the `tasks` array
5. Write the updated file back to vault
6. If priority is `critical`, notify founder immediately via core-assistant (bypasses quiet hours)
7. If priority is not `critical`, check `vault/founder-profile.json` `availability.quietHours` — if currently in quiet hours, the task is queued silently for delivery after `quietHours.end`

### `htq_list`

List tasks by status with optional priority filter.

**Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| status | string | no | Filter by: `pending`, `in-progress`, `done`, `cancelled` (default: `pending`) |
| priority | string | no | Filter by: `critical`, `high`, `medium`, `low` |
| limit | number | no | Max results (default: 20) |

**Behavior:**
1. Read `vault/human-tasks.json`
2. Filter by status (default: pending)
3. If priority specified, filter further
4. Sort by priority (critical > high > medium > low), then by createdAt ascending
5. Apply limit
6. Return matching tasks

### `htq_complete`

Mark a task as done.

**Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| taskId | string | yes | UUID of the task to complete |
| completionNotes | string | no | Notes about the completion |

**Behavior:**
1. Read `vault/human-tasks.json`
2. Find task by ID
3. Update: status → "done", completedAt → now (ISO 8601), completionNotes
4. Write back to vault
5. If task not found, return error

### `htq_digest`

Generate a summary of pending tasks for the daily briefing.

**Parameters:**

None.

**Behavior:**
1. Read `vault/human-tasks.json`
2. Filter to `pending` and `in-progress` tasks
3. Group by priority
4. For each group, count tasks and list titles
5. Calculate total estimated minutes (where available)
6. Return structured digest:
   ```
   Pending Tasks: {total count}
   - Critical ({count}): {titles}
   - High ({count}): {titles}
   - Medium ({count}): {titles}
   - Low ({count}): {titles}
   Estimated time: ~{total} minutes
   Overdue: {count of tasks past deadline}
   ```

## Quiet Hours

Tasks respect the founder's quiet hours from `vault/founder-profile.json` `availability.quietHours`.

| Priority | During Quiet Hours | Outside Quiet Hours |
|----------|-------------------|---------------------|
| critical | Deliver immediately (bypass quiet hours) | Deliver immediately |
| high | Queue for after `quietHours.end` | Deliver immediately |
| medium | Queue for after `quietHours.end` | Deliver at next briefing or on request |
| low | Queue for after `quietHours.end` | Deliver at next briefing or on request |

**If quiet hours are not set** (founder hasn't completed onboarding or skipped the section), treat all tasks as deliverable immediately.

## Access Control

| Agent | Permissions |
|-------|-------------|
| orchestrator | Full access: create, list, complete, digest |
| core-assistant | Read (list, digest) and create only. Cannot complete tasks (founder action). |
| Future agents | Defined at unlock time |

## Task Schema

```json
{
  "id": "<uuid>",
  "createdBy": "<agent-id>",
  "title": "<string>",
  "description": "<string>",
  "priority": "critical|high|medium|low",
  "estimatedMinutes": "<number|null>",
  "deadline": "<ISO 8601|null>",
  "status": "pending|in-progress|done|cancelled",
  "createdAt": "<ISO 8601>",
  "completedAt": "<ISO 8601|null>",
  "completionNotes": "<string|null>"
}
```

## Task Store Format

```json
{
  "tasks": [],
  "stats": {
    "totalCreated": 0,
    "totalCompleted": 0,
    "totalCancelled": 0
  }
}
```

## Usage Examples

**Create a task:**
```
htq_create:
  title: "Set up Discord server"
  description: "Create a Discord server for community engagement. Orchestrator needs the server ID and bot token to enable the Discord channel."
  priority: high
  estimatedMinutes: 30
```

**List pending critical tasks:**
```
htq_list:
  status: pending
  priority: critical
```

**Complete a task:**
```
htq_complete:
  taskId: "abc-123-def-456"
  completionNotes: "Discord server created. Server ID: 123456789. Bot invited with manage messages permission."
```

**Get digest for briefing:**
```
htq_digest
```
