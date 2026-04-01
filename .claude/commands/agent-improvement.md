---
description: Review, improve, and fix OpenClaw agents — tools, permissions, workspace files, spawn rules, and operational issues
---

# Agent Improvement Workflow

The Governor's most frequent task. Review agents, find gaps, fix them, document what changed.

## Phase 1: Assess Current State

1. **SSH to machine, read agent config:**
   ```bash
   ssh {{HOSTNAME}} 'cat ~/.openclaw/openclaw.json' | jq '.agents'
   ```
2. **List agents and status:**
   ```bash
   ssh {{HOSTNAME}} '~/.npm-global/bin/openclaw agents list --json'
   ```
3. **Check recent session logs for errors:**
   ```bash
   ssh {{HOSTNAME}} 'journalctl --user -u openclaw-gateway --since "24h ago" | grep -i "error\|warn\|fail"'
   ```
4. **Read each agent's workspace files:**
   ```bash
   ssh {{HOSTNAME}} 'for agent in $(ls ~/.openclaw/workspace/workspaces/); do echo "=== $agent ==="; cat ~/.openclaw/workspace/workspaces/$agent/IDENTITY.md 2>/dev/null; echo; done'
   ```

## Phase 2: Identify Issues

Look for these categories:

| Issue | What to check | Common fix |
|-------|---------------|------------|
| **Tool gaps** | Agent trying to use tools it doesn't have (grep/glob warnings) | Add tool to alsoAllow or remove from TOOLS.md |
| **Permission issues** | Agent blocked on operations it should do | Update tool permissions in openclaw.json |
| **Spawn rule violations** | Agent trying to dispatch agents it can't reach | Add target to spawn permissions |
| **Stale workspace files** | IDENTITY.md still template, TOOLS.md doesn't match reality | Rewrite with real environment data |
| **Model mismatch** | Cloud model doing local data work, cheap model doing complex reasoning | Swap model assignment |
| **Heartbeat issues** | Not configured, or producing no useful output | Write/rewrite HEARTBEAT.md with actionable checklist |
| **Context rot** | Agent accumulating cross-domain knowledge | Clear session, tighten IDENTITY.md scope |
| **Escalation failures** | Agent not escalating to {{AGENT_MAIN}} when blocked | Fix sessions_spawn config, update SOUL.md |

## Phase 3: Fix

For each issue:
1. Write the fix — prefer `openclaw` CLI over raw JSON edits
2. Update workspace files (IDENTITY.md, TOOLS.md, HEARTBEAT.md, TASKS.md)
3. Restart gateway: `systemctl --user restart openclaw-gateway.service`
4. **Test end-to-end:** spawn the agent, verify it completes a task, verify escalation path works
5. Never declare fixed without seeing the full message path succeed

## Phase 4: Document

- Update `feature_map.md` with what changed
- Update `fleet.md` if spawn rules or agent table changed
- Write or update a rule in `.claude/rules/` if a pattern of failure is identified

## Phase 5: Recommendations

After fixing immediate issues, look ahead:
- **New agents** — "You're doing X manually, an agent could handle this"
- **Model changes** — cost/capability mismatch (local model for simple tasks saves cloud spend)
- **Tool changes** — add based on actual usage, remove tools that generate warnings
- **Schedule follow-up** — agent improvement is a continuous cycle, not a one-time task

Lessons become rules in `.claude/rules/` — not table entries. The system gets smarter every time an agent fails or underperforms.

---

Agent to review: $ARGUMENTS
