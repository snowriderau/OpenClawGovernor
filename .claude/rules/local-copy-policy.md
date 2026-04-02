# Local Copy Policy

The Governor repo keeps version-controlled copies of **platform infrastructure** — not project work.

## Copy to this repo
- Openclaw plugins (guard plugins, any new plugins)
- Openclaw workspace templates (if we build reusable ones)
- systemd service files (gateway, watchdog)
- Governance scripts (audit cron, health checks)
- Specs for platform features (FEAT-xxx in specs/)

## Do NOT copy to this repo
- Project application code (agent-built projects)
- Agent session data or logs
- Secrets or credentials
- Workspace task queues (TASKS.md is per-agent, ephemeral)

## Rule
When building something that changes how the platform operates (plugin, hook, service, governance tool), copy the source to this repo after deployment. Project work stays in its own repo.
