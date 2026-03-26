---
name: openclaw-config
description: Reference guide for configuring OpenClaw agents, models, providers, and workspace files. Auto-loads when tasks involve OpenClaw setup, agent configuration, model routing, or openclaw.json changes.
user-invocable: false
---

# OpenClaw Configuration Guide

**Read this before touching `~/.openclaw/openclaw.json` directly.** OpenClaw has CLI commands for most config operations — prefer them over raw JSON edits.

## Key Paths

| What | Where |
|------|-------|
| Config file | `~/.openclaw/openclaw.json` |
| Agent state | `~/.openclaw/agents/<id>/agent/` |
| Agent workspaces | `~/.openclaw/workspace/workspaces/<id>/` |
| Auth profiles | `~/.openclaw/agents/<id>/agent/auth-profiles.json` |
| Memory | `~/.openclaw/memory/` (SQLite) |
| Binary | `~/.npm-global/bin/openclaw` |
| Gateway service | `~/.config/systemd/user/openclaw-gateway.service` |
| Gateway port | `{{GATEWAY_PORT}}` (loopback) |
| Docs | https://docs.openclaw.ai/cli |

## CLI First — Don't Raw-Edit When You Can CLI

### Models

```bash
# See current model state (default, fallbacks, aliases, auth)
openclaw models status --json

# Set default model
openclaw models set <model-id>

# Manage fallbacks
openclaw models fallbacks list
openclaw models fallbacks add <model-id>
openclaw models fallbacks remove <model-id>

# Manage aliases (shorthand names for models)
openclaw models aliases list
openclaw models aliases add <alias> <model-id>
openclaw models aliases remove <alias>

# Scan OpenRouter free models for tool-use + image support
openclaw models scan
```

### Agents

```bash
# List agents
openclaw agents list --json

# Add a new agent
openclaw agents add <name> --model <model-id> --workspace <dir>
# Non-interactive:
openclaw agents add <name> --model <model-id> --workspace <dir> --non-interactive

# Set agent identity
openclaw agents set-identity --agent <id>  # interactive

# Route channels to agents
openclaw agents bind --agent <id> --bind telegram
openclaw agents bind --agent <id> --bind telegram:<chat-id>
openclaw agents unbind --agent <id> --bind telegram

# Delete an agent
openclaw agents delete  # interactive
```

### Config (dot-path get/set)

```bash
# Read any config value
openclaw config get agents.defaults.model.primary
openclaw config get agents.defaults.heartbeat

# Set any config value (JSON5 or raw string)
openclaw config set agents.defaults.model.primary "<provider>/<model-id>"
openclaw config set agents.defaults.heartbeat.every "30m"

# Remove a config value
openclaw config unset agents.defaults.model.fallbacks[3]

# Validate config
openclaw config validate

# Print config file path
openclaw config file
```

### Other Useful Commands

```bash
# Health check
openclaw health

# Doctor (diagnostics + quick fixes)
openclaw doctor

# Show channel health + recent sessions
openclaw status

# Restart gateway
systemctl --user restart openclaw-gateway.service

# Tail logs
openclaw logs

# Run a one-shot agent turn
openclaw agent --agent main --message "test" --json

# Send a message via channel
openclaw message send --channel telegram --target <chat-id> --message "hi"
```

## Config Structure (openclaw.json)

When you DO need to edit JSON directly, here's the structure:

### Provider (under `models.providers`)

```json
"models": {
  "mode": "merge",
  "providers": {
    "<provider-name>": {
      "baseUrl": "http://<host>:<port>/v1",
      "apiKey": "<api-key-or-placeholder>",
      "api": "openai-responses",
      "models": [
        {
          "id": "<model-id>",
          "name": "Human Readable Name",
          "reasoning": true,
          "input": ["text"],
          "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
          "contextWindow": 131072,
          "maxTokens": 32768
        }
      ]
    }
  }
}
```

- `mode: "merge"` means custom providers merge with built-in ones
- Provider name becomes the prefix: `<provider-name>/<model-id>`
- `api` can be `"openai-responses"` for OpenAI-compatible endpoints
- Models with `cost: 0` are free/local

### Agent (under `agents.list[]`)

```json
{
  "id": "{{AGENT_WORKER}}",
  "workspace": "/home/{{USERNAME}}/.openclaw/workspace/workspaces/{{AGENT_WORKER}}",
  "model": "<provider>/<model-id>",
  "tools": {
    "profile": "coding",
    "alsoAllow": ["message", "web_search", "web_fetch", "read", "write", "edit", "process", "session_status"]
  },
  "subagents": {
    "allowAgents": ["{{AGENT_WORKER}}"]
  }
}
```

- `id` must be unique
- `model` is `provider/model-id` format
- `tools.profile` — built-in profile (`coding`, etc.)
- `tools.alsoAllow` — additional tools beyond the profile
- `subagents.allowAgents` — which agents this one can spawn

### Model Aliases & Fallbacks (under `agents.defaults`)

```json
"agents": {
  "defaults": {
    "model": {
      "primary": "<provider>/<primary-model-id>",
      "fallbacks": [
        "<provider>/<fallback-model-1>",
        "<provider>/<fallback-model-2>"
      ]
    },
    "models": {
      "<provider>/<model-id>": { "alias": "<short-name>" }
    }
  }
}
```

- `primary` — default model for all agents unless overridden
- `fallbacks` — tried in order if primary fails
- `models` — per-model config; `alias` gives it a shorthand name

### Heartbeat (under agent-specific config, NOT defaults)

```json
"heartbeat": {
  "every": "30m",
  "target": "<channel-type>",
  "to": "<channel-chat-id>",
  "directPolicy": "allow",
  "suppressToolErrorWarnings": true
}
```

- `target` must be set explicitly — defaults to `"none"` (goes nowhere)
- `to` is the chat/channel ID for delivery
- Place on specific `agents.list[]` entries, NOT in `agents.defaults`

### Workspace Files (in agent workspace dir)

| File | Purpose |
|------|---------|
| `IDENTITY.md` | Agent name, personality, emoji |
| `USER.md` | Who the operator is |
| `TOOLS.md` | Available tools, services, and how to use them |
| `AGENTS.md` | Inter-agent routing instructions |
| `HEARTBEAT.md` | What to do on heartbeat ticks |
| `TASKS.md` | Current task queue for the agent |
| `OPS.md` | Operational procedures |

## Adding a Provider (Template)

To add a new model provider, insert a block under `models.providers` in `openclaw.json`:

### Local Inference Server (e.g., LM Studio, Ollama, vLLM)
```json
"local-inference": {
  "baseUrl": "http://127.0.0.1:{{INFERENCE_PORT}}/v1",
  "apiKey": "local",
  "api": "openai-responses",
  "models": [
    {
      "id": "your-model-name",
      "name": "Your Model Display Name",
      "reasoning": true,
      "input": ["text"],
      "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
      "contextWindow": 131072,
      "maxTokens": 32768
    }
  ]
}
```

### Cloud Provider (e.g., OpenRouter, Together, Groq)
```json
"cloud-provider": {
  "baseUrl": "https://api.provider.com/v1",
  "apiKey": "your-api-key-here",
  "api": "openai-responses",
  "models": [
    {
      "id": "provider-model-id",
      "name": "Model Display Name",
      "reasoning": true,
      "input": ["text", "image"],
      "cost": { "input": 0.5, "output": 1.5, "cacheRead": 0.25, "cacheWrite": 0.5 },
      "contextWindow": 131072,
      "maxTokens": 8192
    }
  ]
}
```

## Agent Roster (Template)

| Agent | Model | Role | Alias |
|-------|-------|------|-------|
| **main** ({{AGENT_MAIN}}) | `<provider>/<model-id>` | Primary agent — coding, orchestration, user comms | -- |
| **{{AGENT_WORKER}}** | `<provider>/<model-id>` | Worker agent — specialized tasks, research, tool ops | `{{AGENT_WORKER}}` |
| **{{AGENT_RESEARCHER}}** | `<provider>/<model-id>` | Research agent — web search, documentation, analysis | `{{AGENT_RESEARCHER}}` |

## Learnings & Gotchas

1. **Always restart gateway after config changes:** `systemctl --user restart openclaw-gateway.service`
2. **`heartbeat.target` defaults to `"none"`** — must explicitly set to your channel type with a `to` field
3. **`gateway.auth.scopes` is NOT valid** — OpenClaw uses device pairing for scopes
4. **Inter-agent dispatch uses `sessions_spawn`** — the `message` tool routes through the notification channel
5. **`tools.elevated.allowFrom`** should be set at global level, not per-agent (duplicates cause confusion)
6. **Exec approvals `mode: "both"`** means both notification channel and webchat can approve
7. **Config validate before restart:** `openclaw config validate` catches JSON errors before they break the gateway
8. **MCP provider bridges:** Some providers (e.g., OpenCode) don't need a provider block in openclaw.json — they route through MCP bridge automatically
