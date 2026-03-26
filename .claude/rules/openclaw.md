---
paths:
  - "specs/FEAT-OPENCLAW_setup.md"
  - "specs/openclaw_setup.md"
---

When working on Openclaw configuration (agents, models, providers, workspace files, openclaw.json):

1. Load the openclaw-config skill first — it has CLI commands, config structure, and gotchas
2. Prefer `openclaw` CLI commands over raw JSON edits to `openclaw.json`
3. Always run `openclaw config validate` before restarting the gateway
4. Always restart the gateway after config changes: `systemctl --user restart openclaw-gateway.service`
5. The binary is at `~/.npm-global/bin/openclaw` (not in PATH on the server)
6. When changing notification channel config, always verify the FULL message path:
   - `bindings` — which agent receives inbound messages
   - `agents.list[].tools` — what tools each agent has (message, sessions_spawn, etc.)
   - `channels` — groupPolicy, allowFrom, dmPolicy for your notification channel
   - `agents.defaults` vs `agents.list[]` — inherited config vs agent-specific overrides
   Never claim "verified" without checking all four sections.
7. Known invalid tools (not available in Openclaw runtime):
   - `glob`, `grep` — require a plugin that isn't enabled. Agents use `exec` (via coding profile) to run shell grep/find instead.
   - `apply_patch`, `cron` — shipped core but unavailable in current runtime/provider/model/config.
   Do NOT add these to `alsoAllow` lists — they generate warnings and do nothing.
8. Heartbeat placement: put heartbeat config on specific `agents.list[]` entries, NOT in `agents.defaults` (which applies to ALL agents). Only agents that need autonomous loops should heartbeat.
9. Delegation model: {{AGENT_MAIN}} is the only notification-channel-facing agent. All other agents report to the primary orchestrator agent via `sessions_spawn agent:"main"`. The primary orchestrator agent decides what reaches the user.
