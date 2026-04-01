# FEAT-020: Heartbeat Guard Plugin

**Status:** Complete
**Owner:** Governor
**Priority:** P1 — prevents runaway token spend and Telegram spam

---

## Problem Statement

Openclaw heartbeats have **no turn limit**. When a model's tool-calling behavior degenerates, a single heartbeat can:
- Send 1,300+ messages in one session
- Burn huge token budgets
- Spam Telegram every ~10 seconds
- Exhaust API rate limits

## Solution

A lightweight Openclaw plugin — `heartbeat-guard` — that acts as a runtime circuit breaker using the Plugin SDK's `before_tool_call` hook.

### Architecture

```
Agent turn starts
  └─ before_agent_start hook → stash trigger type + init counters (keyed by runId)
      └─ LLM generates response
          └─ llm_output hook → accumulate token usage
              └─ Model requests tool call
                  └─ before_tool_call hook → CHECK COUNTERS
                      ├─ Under limits → allow (return undefined)
                      └─ Over limits → { block: true, blockReason: "..." }
                          └─ Agent run terminates
  └─ agent_end hook → cleanup counters map
```

### Configuration Example

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
            "user":      { "maxToolCalls": -1, "maxTokens": -1 },
            "default":   { "maxToolCalls": 50, "maxTokens": 200000 }
          },
          "log": true
        }
      }
    }
  }
}
```

- `-1` means unlimited
- `log: true` writes blocked events to `~/.openclaw/logs/heartbeat-guard.log`

## Acceptance Criteria
- [x] Heartbeat tool calls are capped at configured `maxToolCalls`
- [x] Token accumulation tracked per-run via `llm_output`
- [x] Breaker fires with clear `blockReason`
- [x] User-triggered sessions are NOT affected (unlimited)
- [x] Blocked events logged when `log: true`
