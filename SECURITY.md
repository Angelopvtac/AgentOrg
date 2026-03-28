# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.3.x   | Yes       |
| < 0.3   | No        |

## Reporting a Vulnerability

**Do NOT open a public issue for security vulnerabilities.**

Instead, please report security issues by emailing the maintainer directly or using GitHub's private vulnerability reporting feature on this repository.

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if you have one)

You'll receive an acknowledgment within 48 hours. We'll work with you to understand and address the issue before any public disclosure.

## Security Design

AgentOrg runs AI agents inside a Docker container with defense-in-depth hardening:

- **Capability restriction**: `cap_drop: ALL`, only `NET_BIND_SERVICE` added back
- **Privilege escalation blocked**: `security_opt: no-new-privileges`
- **Read-only filesystem**: Container root is read-only, explicit tmpfs for runtime
- **Network isolation**: Gateway bound to `127.0.0.1` only — never exposed to `0.0.0.0`
- **Resource limits**: Memory and CPU caps prevent runaway agents
- **No secrets in code**: All API keys via environment variables, `.env` is gitignored
- **Config mounted read-only**: `openclaw.json` is a read-only bind mount

## What We Consider In-Scope

- Secret leakage (API keys, tokens in logs or config)
- Container escape or privilege escalation
- Unauthorized access to the gateway API
- Agent behavior that bypasses safety constraints
- Dependency vulnerabilities in the Docker image

## Out of Scope

- Vulnerabilities in upstream OpenClaw (report to that project directly)
- Social engineering attacks
- Denial of service against local-only services
