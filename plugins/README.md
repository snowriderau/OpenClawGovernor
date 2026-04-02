# Openclaw Guard Plugins

Version-controlled source for the Governor's Openclaw plugins. These enforce structural constraints on agent behavior at the runtime level — where workspace instructions alone aren't enough.

Deploy live instances to `~/.openclaw/plugins/<name>/` on the target machine.

## Plugins

### heartbeat-guard v2.0.0
**Problem:** Runaway tool-calling loops burning tokens and spamming notification channels. A single heartbeat can consume thousands of messages with no abort mechanism.
**Solution:** Circuit breaker on `before_tool_call`. Tracks tool calls and tokens per run, blocks when limits exceeded.
**Scope:** All agents. Limits configurable per trigger type (heartbeat, cron, user, default).
**Spec:** `specs/FEAT-020_heartbeat_guard/`

### announce-guard v1.0.0
**Problem:** Openclaw runtime injects a hardcoded instruction telling coordinator agents to forward every subagent completion as a user-facing message. Creates noise for background orchestration.
**Solution:** `before_prompt_build` hook injects a system-prompt-level override forcing `::silent::` replies to subagent announce events. System prompt outranks the runtime's user-message instruction.
**Scope:** Configurable — defaults to the `main` agent (your primary coordinator).

### role-guard v1.0.0
**Problem:** Coordinator agents go rogue — writing files directly instead of delegating to specialists. Workspace instructions alone aren't enough under pressure.
**Solution:** Two-layer enforcement:
1. `before_tool_call` — blocks write/edit tools and exec commands with file-write patterns (redirects, tee, sed -i, cp, mv, mkdir, touch, rm)
2. `before_prompt_build` — injects role guidance into system prompt with delegation targets
**Config:** Set `opsAgent` and `projectAgent` to name your fleet's delegation targets in block messages.
**Escape:** On block, writes alert to `/tmp/openclaw-governor-alerts.jsonl` for Governor visibility.
**Scope:** Configurable — defaults to the `main` agent.

## Configuration Example

In `~/.openclaw/openclaw.json`:

```json
{
  "plugins": {
    "entries": {
      "heartbeat-guard": {
        "enabled": true,
        "config": {
          "limits": {
            "heartbeat": { "maxToolCalls": 10, "maxTokens": 50000 },
            "cron":      { "maxToolCalls": 30, "maxTokens": 150000 },
            "user":      { "maxToolCalls": -1, "maxTokens": -1 }
          }
        }
      },
      "announce-guard": {
        "enabled": true,
        "config": {
          "agents": ["main"]
        }
      },
      "role-guard": {
        "enabled": true,
        "config": {
          "agents": ["main"],
          "opsAgent": "larry",
          "projectAgent": "pm"
        }
      }
    }
  }
}
```

## Deployment

```bash
# Copy plugin source to live directory
cp -r plugins/<name>/ ~/.openclaw/plugins/<name>/

# Validate and restart
openclaw config validate
systemctl --user restart openclaw-gateway.service

# Verify
openclaw plugins list | grep <name>
```

## Testing

Each plugin with a `test/` directory can be run with Node.js test runner:

```bash
node --test plugins/<name>/test/*.test.js
```
