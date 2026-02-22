# Orchestrator — Heartbeat

## Interval
Every 60 minutes.

## Checks
1. Review pending inbound messages across all channels
2. Check current phase state and gate progress
3. Verify agent health (are registered agents responsive?)
4. Check daily budget consumption vs limit
5. Process any queued agent-to-agent messages

## Actions on Wake
- If pending messages → route to appropriate agent
- If budget > 80% → send founder alert
- If gate criteria changed → log for next evaluation cycle
