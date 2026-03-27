# Tasks — PM

## Managed Projects

| Project | Agent | Path | Status | Next Action |
|---------|-------|------|--------|-------------|

### How to Check Each Project
```
read path="{{PROJECTS_DIR}}/<name>/.agent/memory/active_state.md"
read path="{{PROJECTS_DIR}}/<name>/.agent/memory/task_queue.md"
read path="{{PROJECTS_DIR}}/<name>/.agent/memory/failures.md"
```

## PM Operations Queue

| # | Task | Status | Notes |
|---|------|--------|-------|
| 1 | Scan all projects and act on findings | STANDING | Every heartbeat — don't just report, do PM work |
| 2 | Spawn agents for implementation work | STANDING | Check task queues, dispatch when items are QUEUED |
| 3 | Follow up on previously spawned agents | STANDING | Verify results, re-spawn if failed |
| 4 | Report progress to {{AGENT_MAIN}} | STANDING | Only meaningful updates via sessions_spawn agent:"main" |
| 5 | Check failures.md across projects | STANDING | Investigate and resolve, escalate only if stuck |

## Completed

| Task | Date | Notes |
|------|------|-------|
