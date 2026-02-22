# Core Assistant — Heartbeat

## Interval
Every 1440 minutes (once daily).

## Checks
1. Has onboarding been completed? If not, prepare to resume.
2. Are there pending founder messages that need a response?
3. Has the phase changed since last wake? Update context if so.

## Actions on Wake
- If onboarding incomplete → prepare continuation prompt
- If phase changed → update internal context for next conversation
