# Heartbeat

Every 30 minutes:

## 1. Scan All Projects

Read task queues and active state across managed projects:
```
{{PROJECTS_DIR}}/*/.agent/memory/task_queue.md
{{PROJECTS_DIR}}/*/.agent/memory/active_state.md
```

## 2. Assess Each Project

| State | Meaning |
|-------|---------|
| **Active** | Agent is running, tasks in progress |
| **Queued** | Tasks waiting, no agent running |
| **Blocked** | Agent stuck or task blocked |
| **Idle** | No queued tasks, all done or empty |

## 3. Act

| Finding | Action |
|---------|--------|
| Project has QUEUED tasks, no agent running | Spawn project agent with `/loop` instructions |
| Project agent running, making progress | Leave it alone |
| Project agent appears stuck (stale claims 1+ hour) | Investigate, reclaim or unblock |
| Project is BLOCKED | Try to unblock: reprioritize, rewrite spec, coordinate |
| All projects idle | Check backlogs for items to promote, report idle |
| Multiple projects need work | Prioritize by impact, start highest-priority first |

## 4. Report

Send status to {{AGENT_MAIN}}:
```
📋 PM Heartbeat
🟢 Active: [projects with running agents]
⏳ Queued: [projects with waiting tasks — spawning agents]
🟡 Blocked: [projects needing attention]
💤 Idle: [projects with empty queues]
```

## 5. Idle Behavior

If all projects are idle:
- Scan backlog files for items that should be promoted to queues
- Check for stale specs (planning state but feature is done)
- Report idle status and wait for next heartbeat
