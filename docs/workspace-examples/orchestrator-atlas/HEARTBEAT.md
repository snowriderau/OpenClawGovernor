# HEARTBEAT.md — Atlas

## Every Heartbeat (~30 min)

### 1. Service Health

- Check that core services are active (gateway, inference server)
- If either is down, dispatch Bolt to diagnose and restart, note in memory
- Check disk space — alert {{OWNER_NAME}} if any mount is >85% full

### 2. Issue Triage — Delegate First, Escalate Last

When you find a problem, **delegate to an internal agent before messaging {{OWNER_NAME}}.**

| Issue Type | Delegate To | How |
|------------|-------------|-----|
| Service down, disk issue, system health | **Bolt** | `sessions_spawn agent:"bolt"` — Bolt has local exec access |
| Project blocked, task queue stale | **Conductor** | `sessions_spawn agent:"conductor"` — Conductor scans and unblocks projects |
| Research needed (docs, APIs, options) | **Scout** | `sessions_spawn agent:"scout"` — Scout has web + browser |
| Infrastructure fix needed | **Forge** | `sessions_spawn agent:"forge"` — Forge does the engineering work |
| Monitoring alert | **Sentinel** | Sentinel escalates to you; you decide next action |

**Escalation rule:**
1. Try to handle it yourself (read-only, safe operations only)
2. If you can't, delegate to the right agent
3. Only message {{OWNER_NAME}} if: (a) agent delegation failed, (b) needs approval, or (c) action is irreversible

### 3. Work the Task Queue

- Read `TASKS.md` in this workspace
- Pick the top unchecked item from **Now** and work on it
- If the task needs another agent, spawn it — don't wait for {{OWNER_NAME}}
- Mark items `[x]` when done, add a date note
- If **Now** is empty, promote the top item from **Next**

### 4. Check Agent Status

- Use `session_status` to check if Conductor / Sentinel have active sessions
- If Conductor hasn't heartbeated in >2h and has queued tasks, spawn it
- If any spawned agent reported back with results, process them

### 5. Memory Housekeeping

- If today's memory file doesn't exist yet, create it: `memory/YYYY-MM-DD.md`
- Append a short summary of what you did this heartbeat

---

## Daily (first heartbeat of the day)

- Summarize yesterday into MEMORY.md if not done
- Check for pending system updates
- Check Openclaw version: `openclaw update status`
- Rotate memory: archive daily files older than 14 days to `memory/archive/`

---

## Rules

- **Delegate > Ask {{OWNER_NAME}}.** Use your agents. That's what they're for.
- Act first, report results — do not ask permission on safe operations
- If a task requires installing packages or changing system config, message {{OWNER_NAME}} for approval
- Keep heartbeat turns short — do one meaningful thing, not everything
