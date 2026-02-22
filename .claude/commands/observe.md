Run observability diagnostics: $ARGUMENTS

If no specific target given, run a full system health check.

## Process
1. Parse the target from $ARGUMENTS:
   - **Service/container name** → focus diagnostics on that service
   - **Project path** → check that project's running services
   - **"logs"** → deep log analysis across all services
   - **"perf"** or **"performance"** → resource and performance profiling
   - **No target** → full system health sweep
2. Discover what's running:
   - `docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'`
   - `docker compose ps` if a compose file exists nearby
   - Check system resources: `free -h`, `df -h`, `uptime`
3. For each service/container, check:
   - Container status and uptime (restart count, exit codes)
   - Recent logs for errors: `docker logs --since 5m <container> 2>&1 | tail -100`
   - Resource usage: `docker stats --no-stream`
   - Port accessibility: `curl -sf http://localhost:<port>/health || echo "unreachable"`
4. For performance targets:
   - System: `htop -b -n1 | head -20`, `free -h`, `df -h`
   - Per-container: `docker stats --no-stream`
   - Network: `ss -tlnp` to check listening ports
5. Produce a structured report:
   - Overall status: HEALTHY / DEGRADED / DOWN
   - Per-service status with evidence
   - Issues found with root cause analysis
   - Recommended actions
