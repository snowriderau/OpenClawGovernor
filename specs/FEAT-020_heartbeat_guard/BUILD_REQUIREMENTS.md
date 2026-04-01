# Build Requirements — heartbeat-guard plugin

## Target

```
~/.openclaw/plugins/heartbeat-guard/
├── package.json          # Plugin manifest + openclaw entry point
├── index.js              # Plugin source
```

## Compilation

Write `index.js` directly. No TypeScript, no compilation. The plugin is <100 lines.

## Dependencies

- **None.** The plugin uses only the Openclaw Plugin SDK API passed via `register(api)`.
- No npm install needed.
- No external packages.

## Installation

```bash
# Register with Openclaw
openclaw plugins install ~/.openclaw/plugins/heartbeat-guard --link

# Or add manually to openclaw.json plugins.entries
# Then restart gateway
```

## Session Key Patterns (fallback trigger detection)

```
agent:<id>:main              → primary session (user or heartbeat)
agent:<id>:telegram:direct:* → user DM
agent:<id>:telegram:slash:*  → user slash command
agent:<id>:cron:<uuid>       → cron job
agent:<id>:subagent:<uuid>   → spawned subagent
agent:<id>:heartbeat:*       → heartbeat (if isolated)
```
