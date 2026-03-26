---
name: openclaw-config
description: Reference guide for configuring Openclaw agents, models, providers, and workspace files. Auto-loads when tasks involve Openclaw setup, agent configuration, model routing, or openclaw.json changes.
user-invocable: false
---

# Openclaw Configuration Guide

**The Governor loads this before any Openclaw config operation.** Openclaw has CLI commands for most config operations — prefer them over raw JSON edits. OpenClaw agents can also self-configure, but the Governor is recommended for config management due to its oversight perspective and separation of concerns.

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
| Gateway port | `18789` (loopback) |
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
openclaw agents bind --agent <id> --bind telegram:{{TELEGRAM_USER_ID}}
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
openclaw config set agents.defaults.model.primary "opencode/nemotron-3-super-free"
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
openclaw message send --channel telegram --target {{TELEGRAM_USER_ID}} --message "hi"
```

## Config Structure (openclaw.json)

When you DO need to edit JSON directly, here's the structure:

### Provider (under `models.providers`)

```json
"models": {
  "mode": "merge",
  "providers": {
    "<provider-name>": {
      "baseUrl": "http://...",
      "apiKey": "...",
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
- Provider name becomes the prefix: `lmstudio/qwen3.5-35b-a3b`
- `api` can be `"openai-responses"` for OpenAI-compatible endpoints
- Models with `cost: 0` are free/local

### Agent (under `agents.list[]`)

```json
{
  "id": "worker",
  "workspace": "/home/{{USERNAME}}/.openclaw/workspace/workspaces/worker",
  "model": "lmstudio/{{LOCAL_MODEL}}",
  "tools": {
    "profile": "coding",
    "alsoAllow": ["message", "web_search", "web_fetch", "read", "write", "edit", "process", "session_status"]
  },
  "subagents": {
    "allowAgents": ["worker"]
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
      "primary": "{{PRIMARY_MODEL}}",
      "fallbacks": [
        "opencode/nemotron-3-super-free",
        "lmstudio/{{LOCAL_MODEL}}"
      ]
    },
    "models": {
      "lmstudio/{{LOCAL_MODEL}}": { "alias": "local" },
      "opencode/nemotron-3-super-free": { "alias": "nemotron" }
    }
  }
}
```

- `primary` — default model for all agents unless overridden
- `fallbacks` — tried in order if primary fails
- `models` — per-model config; `alias` gives it a shorthand name

### Heartbeat (under `agents.defaults.heartbeat`)

```json
"heartbeat": {
  "every": "30m",
  "target": "telegram",
  "to": "{{TELEGRAM_USER_ID}}",
  "directPolicy": "allow",
  "suppressToolErrorWarnings": true
}
```

- `target` must be set explicitly — defaults to `"none"` (goes nowhere)
- `to` is the chat/channel ID for delivery

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

## Provider Examples

### LM Studio (local GPU — OpenAI-compatible API)

```json
"lmstudio": {
  "baseUrl": "http://127.0.0.1:{{INFERENCE_PORT}}/v1",
  "apiKey": "lmstudio",
  "api": "openai-responses",
  "models": [
    {
      "id": "{{LOCAL_MODEL}}",
      "name": "Local Model (LM Studio)",
      "input": ["text"],
      "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
      "contextWindow": 131072,
      "maxTokens": 32768
    }
  ]
}
```

- Default LM Studio port is `1234`
- `apiKey` is a dummy string — LM Studio doesn't enforce auth
- Use this when LM Studio is running on the **same machine** (loopback)
- For remote access over Tailscale: replace `127.0.0.1` with `{{TAILSCALE_IP}}`

### Ollama (local — OpenAI-compatible API)

```json
"ollama": {
  "baseUrl": "http://127.0.0.1:11434/v1",
  "apiKey": "ollama",
  "api": "openai-responses",
  "models": [
    {
      "id": "{{LOCAL_MODEL}}",
      "name": "Local Model (Ollama)",
      "input": ["text"],
      "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
      "contextWindow": 131072,
      "maxTokens": 32768
    }
  ]
}
```

- Default Ollama port is `11434`
- Model IDs must match exactly what `ollama list` returns

### vLLM (local or server — OpenAI-compatible API)

```json
"vllm": {
  "baseUrl": "http://127.0.0.1:{{INFERENCE_PORT}}/v1",
  "apiKey": "EMPTY",
  "api": "openai-responses",
  "models": [
    {
      "id": "{{LOCAL_MODEL}}",
      "name": "Local Model (vLLM)",
      "input": ["text"],
      "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
      "contextWindow": 131072,
      "maxTokens": 32768
    }
  ]
}
```

- vLLM uses `"EMPTY"` as the conventional dummy API key
- Typical port: `8000`; adjust to match your `--port` flag

### Cloud provider (OpenAI-compatible pattern)

```json
"myprovider": {
  "baseUrl": "https://api.{{CLOUD_PROVIDER}}.com/v1",
  "apiKey": "{{API_KEY}}",
  "api": "openai-responses",
  "models": [
    {
      "id": "{{CLOUD_MODEL}}",
      "name": "Cloud Model",
      "input": ["text", "image"],
      "cost": { "input": 0.50, "output": 1.50, "cacheRead": 0.05, "cacheWrite": 0.25 },
      "contextWindow": 128000,
      "maxTokens": 16384
    }
  ]
}
```

- `cost` values are per-million-tokens; set to `0` for free/local
- `input: ["text", "image"]` enables multimodal for that model

### OpenRouter free tier (via OpenCode bridge)

```json
// No explicit provider block needed for opencode/* models.
// Openclaw routes these through the OpenCode MCP bridge automatically.
// Configure OpenCode separately: opencode-cli auth login
// Then reference models as: "opencode/model-name"
// Browse free models: openclaw models scan
```

- `opencode/*` model IDs are resolved by the OpenCode MCP bridge
- Free tier has rate limits — use local models for high-volume tasks
- Useful for secondary/researcher agents that don't need premium capability

### Adding a Provider (template)

```json
"<provider-name>": {
  "baseUrl": "http://<host>:<port>/v1",
  "apiKey": "<key-or-dummy>",
  "api": "openai-responses",
  "models": [
    {
      "id": "<model-id-as-served>",
      "name": "<human-readable-name>",
      "reasoning": false,
      "input": ["text"],
      "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
      "contextWindow": 32768,
      "maxTokens": 8192
    }
  ]
}
```

After adding a provider: `openclaw config validate && systemctl --user restart openclaw-gateway.service`

## Agent Roster (Domain-Locked Fleet)

The architecture enforces security through isolation: each agent is locked to a specific domain. No agent has both the full picture and the full toolkit. Context flows UP, execution flows DOWN.

| Agent ID | Name | Model | Role | Security Domain |
|----------|------|-------|------|----------------|
| `main` | Atlas | `{{PRIMARY_MODEL}}` | Orchestrator — delegates, synthesizes, never executes directly | Coordination only. No direct file/code/email access. |
| `pm` | Conductor | `{{PRIMARY_MODEL}}` | Project Manager — scans, prioritizes, delegates | Project metadata only. Reads specs, task queues, status. No code execution. |
| `engineer` | Forge | `{{PRIMARY_MODEL}}` | Senior Engineer — builds, fixes, ships code | Code execution, build tooling, git. No email, no storage, no infra. |
| `mail` | Hermes | `{{SECONDARY_MODEL}}` | Mail Agent — email triage, GTD, follow-ups | Email domain ONLY. Cannot touch code, files, or infrastructure. |
| `worker` | Bolt | `{{LOCAL_MODEL}}` | Compute Worker — cheap, dumb, local, air-gapped | Local compute only. No network, no email, no user comms. Nothing leaves the machine. |
| `researcher` | Scout | `{{SECONDARY_MODEL}}` | Web Researcher — searches, reads, reports | Web read-only. Cannot write files, send emails, or execute code. |
| `files` | Courier | `{{LOCAL_MODEL}}` | File Agent — transfers, backups, storage ops | File system and storage only. No code execution, no email, no web. |
| `tester` | Sentinel | `{{SECONDARY_MODEL}}` | Test & Verify — validates, never modifies source | Read + execute tests only. Cannot modify source code. Verifies what Forge built. |

**Design principle:** Workers (Bolt, Courier) use `{{LOCAL_MODEL}}` — sensitive data never leaves the machine. Cloud models (Atlas, Forge) handle coordination and code but never touch raw data files or credentials. Sentinel verifies what Forge builds — the agent that writes code is never the agent that validates it.

## Learnings & Gotchas

1. **Always restart gateway after config changes:** `systemctl --user restart openclaw-gateway.service`
2. **`heartbeat.target` defaults to `"none"`** — must explicitly set to `"telegram"` (or your channel) with a `to` field
3. **`gateway.auth.scopes` is NOT valid** — Openclaw uses device pairing for scopes
4. **Inter-agent dispatch uses `sessions_spawn`** — the `message` tool routes through the notification channel (Telegram/Discord/Slack)
5. **`tools.elevated.allowFrom`** should be set at global level, not per-agent (duplicates cause confusion)
6. **Exec approvals `mode: "both"`** means both notification channel and webchat can approve
7. **Config validate before restart:** `openclaw config validate` catches JSON errors before they break the gateway
8. **OpenCode as provider bridge:** `opencode/*` models don't need a provider block in openclaw.json — they route through the MCP bridge automatically
9. **When adding a new agent, always populate workspace files (IDENTITY.md, TOOLS.md, HEARTBEAT.md, TASKS.md)** — blank templates cause agents to hallucinate their capabilities. An agent without a populated IDENTITY.md doesn't know its role, scope, or constraints. Fill all workspace files before the first dispatch.
10. **Test agent dispatch end-to-end after adding:** spawn from orchestrator, verify response arrives, check notification delivery. Don't assume it works because config validates — a missing binding or wrong channel ID will silently drop messages.
11. **Workspace files are living documents** — review them on every agent improvement cycle. Stale TOOLS.md (listing tools the agent doesn't have, or missing tools it does have) is the #1 cause of agent confusion. See `docs/workspace-examples/` for battle-tested templates.
12. **Check conversation history before adding tools.** When an agent fails a task, often it had the tools but IDENTITY.md or SOUL.md didn't give clear enough instructions about WHEN to use them. Fix the instructions first, add tools second.
13. **Cost optimization: route simple tasks through local models.** Cloud API tokens add up fast on tasks that don't need reasoning — file operations, health checks, log parsing. Bolt on local GPU costs nothing.
14. **Governor should review agent sessions weekly.** Look for: tools the agent tried but failed to use (need adding), tasks the agent escalated unnecessarily (needs better instructions), repeated errors (needs a rule in IDENTITY.md). Use `/agent-improvement` to run the full audit.
