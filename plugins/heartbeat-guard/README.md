# heartbeat-guard

Circuit breaker plugin for [Openclaw](https://openclaw.dev) that prevents runaway tool-calling loops in automated agent runs.

When an agent exceeds its configured tool call or token budget, heartbeat-guard blocks further tool calls and logs the event. This protects against infinite loops, token blowouts, and API rate-limit exhaustion — especially in unattended heartbeat and cron triggers.

## Install

Copy the plugin directory into your Openclaw plugins folder:

```bash
cp -r heartbeat-guard ~/.openclaw/plugins/
```

Then enable it in `~/.openclaw/openclaw.json`:

```json
{
  "plugins": {
    "entries": {
      "heartbeat-guard": {
        "enabled": true
      }
    }
  }
}
```

## Configuration

All limits are optional. Unset values use the defaults below.

```json
{
  "plugins": {
    "entries": {
      "heartbeat-guard": {
        "enabled": true,
        "limits": {
          "heartbeat": { "maxToolCalls": 10, "maxTokens": 50000 },
          "cron":      { "maxToolCalls": 30, "maxTokens": 150000 },
          "user":      { "maxToolCalls": -1, "maxTokens": -1 },
          "memory":    { "maxToolCalls": 20, "maxTokens": 100000 },
          "default":   { "maxToolCalls": 50, "maxTokens": 200000 }
        }
      }
    }
  }
}
```

Set `maxToolCalls` or `maxTokens` to `-1` to disable that limit (unlimited).

### Default Limits

| Trigger     | Max Tool Calls | Max Tokens |
|-------------|----------------|------------|
| `heartbeat` | 10             | 50,000     |
| `cron`      | 30             | 150,000    |
| `user`      | unlimited      | unlimited  |
| `memory`    | 20             | 100,000    |
| `default`   | 50             | 200,000    |

## How It Works

The plugin registers four hooks in the Openclaw agent lifecycle:

```
before_agent_start  →  Initialize per-run counters
llm_output          →  Accumulate token usage
before_tool_call    →  Check limits, block if exceeded
agent_end           →  Clean up counter state
```

### Trigger Detection

The trigger type is read from `ctx.trigger` when available. If not set, the plugin infers it from the session key:

| Session key pattern | Trigger     |
|---------------------|-------------|
| `:heartbeat:`       | `heartbeat` |
| `:cron:`            | `cron`      |
| `:telegram:`        | `user`      |
| `:direct:`          | `user`      |
| `:subagent:`        | `default`   |
| (anything else)     | `default`   |

### Blocking Behavior

When a limit is exceeded, the plugin returns `{ block: true, blockReason: "..." }` from the `before_tool_call` hook. The agent receives the block reason as a tool error message and stops executing tools for that run.

## Testing

```bash
node --test test/heartbeat-guard.test.js
```

## Requirements

- Node.js >= 20
- Openclaw with plugin SDK support

## License

MIT
