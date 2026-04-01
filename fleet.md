# Fleet — Openclaw Agent Architecture

*Source of truth is `~/.openclaw/openclaw.json` on the target machine. This file is a point-in-time snapshot.*
*Last verified: {{SETUP_DATE}}*

## Hierarchy

```
Governor (Claude Code) — monitors, verifies, fixes the system
  Tier 1: Coordinators — delegate, never execute
    {{AGENT_MAIN}} (main)  — EA, user comms, agent dispatch
    PM              — spec-first project management, dispatches engineers
  Tier 2: Specialists — domain-locked execution
    Forge           — senior engineer, builds features
    [Add your specialist agents here]
  Tier 3: Workers — stateless task execution
    [Add your worker agents here]
```

## Agent Table

| ID | Name | Model | Tier | Profile | Heartbeat | Workspace |
|----|------|-------|------|---------|-----------|-----------|
| main | {{AGENT_MAIN}} | {{PRIMARY_MODEL}} | Coordinator | minimal | 30m → telegram | workspaces/main |
| pm | PM | {{PRIMARY_MODEL}} | Coordinator | coding | 60m → none | {{PROJECTS_DIR}} |
| forge | Forge | {{PRIMARY_MODEL}} | Specialist | coding | none | {{PROJECTS_DIR}}/forge |

*Add rows for each agent configured in openclaw.json*

Default fallbacks: primary cloud → local model (if configured)

## Spawn Permissions

| Agent | Can spawn | Cannot spawn |
|-------|-----------|-------------|
| {{AGENT_MAIN}} | pm, [workers] | **forge** (config-enforced — all engineering through PM) |
| PM | forge, [specialists], [workers] | — |
| Forge | [workers] | — |

**Routing rule:** All project/feature work flows {{AGENT_MAIN}} → PM → Forge. {{AGENT_MAIN}} cannot bypass PM for engineering work.

## Communication

- Only {{AGENT_MAIN}} sends to Telegram (message tool). All others escalate via `sessions_spawn`.
- Heartbeats use `isolatedSession: true` + `lightContext: true` (fleet-wide).
- heartbeat-guard plugin caps tool calls per trigger type (heartbeat: 10, cron: 30, user: unlimited).

## Governance Audit

`governance-audit` cron runs every 6h on PM. Checks for:
1. Routing violations ({{AGENT_MAIN}} spawning forge directly)
2. Unverified completions (work done without PM verification)
3. Stuck work (timed out with no follow-up)

Results appended to `governance-ledger.md`. Governor reviews and applies structural fixes.
