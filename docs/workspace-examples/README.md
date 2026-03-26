# Workspace Examples

These are example workspace files based on a real production OpenClaw deployment. Copy and customize for your agents. The Governor creates and maintains these — you never write them manually.

---

## What's Here

| Directory | Agent | Role |
|-----------|-------|------|
| `orchestrator-atlas/` | Atlas | Orchestrator / Executive Assistant — the hub of your fleet |
| `director-forge/` | Forge | Senior Engineer — builds, fixes, and ships |
| `worker-bolt/` | Bolt | Compute Worker — local GPU, execute-and-return |

## The 8-Agent Template Fleet

These examples use a standard 8-agent layout. Adapt names and roles to your setup.

| Name | Role | Dispatched by |
|------|------|---------------|
| Atlas | Orchestrator / EA | User (direct) |
| Conductor | Project Manager | Atlas |
| Forge | Senior Engineer | Atlas, Conductor |
| Hermes | Communications | Atlas |
| Bolt | Compute Worker | Forge |
| Scout | Web Researcher | Atlas, Forge |
| Courier | Email Manager | Atlas |
| Sentinel | Monitor / Watchdog | Atlas |

## How to Use These

1. Copy the relevant directory to your agent's workspace on the machine
2. Replace all `{{PLACEHOLDER}}` values with real data
3. The Governor will maintain these files going forward — you're just providing the starting config

## What These Files Are

- **IDENTITY.md** — Who the agent is (name, creature, vibe, emoji)
- **SOUL.md** — The agent's operating philosophy and hard rules
- **TOOLS.md** — Environment reference: services, credentials, dispatch table
- **HEARTBEAT.md** — What to do on each heartbeat poll
- **TASKS.md** — Live task queue (Now / Next / Later / Done)
- **USER.md** — About the human the agent serves
- **AGENTS.md** — Full workspace guide: memory, red lines, inter-agent dispatch

## Placeholder Reference

| Placeholder | Replace with |
|-------------|-------------|
| `{{OWNER_NAME}}` | Your first name (e.g. "Alex") |
| `{{HOSTNAME}}` | Your machine hostname (e.g. "homelab") |
| `{{TIMEZONE}}` | Your timezone (e.g. "America/New_York") |
| `{{COMPANY}}` | Your company or project name |
| `{{GPU}}` | Your GPU model (e.g. "RTX 4090") |
| `{{NOTIFICATION_BOT}}` | Your Telegram/Slack bot name |
| `{{NAS_HOST}}` | Your NAS IP or hostname |
| `{{INFERENCE_API}}` | Local inference server URL |
| `{{AGENT_EMAIL}}` | Dedicated email address for the agent |
