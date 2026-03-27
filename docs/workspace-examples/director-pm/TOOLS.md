# Tools

## Delegation: sessions_spawn

Your primary action tool. Use it to dispatch work to agents.

### Dispatch to engineer agent (code/pipeline work)
```
sessions_spawn agent="{{ENGINEER_AGENT}}" message="[clear instructions — what to do, where, what done looks like]"
```

### Dispatch to research agent (web research)
```
sessions_spawn agent="{{RESEARCH_AGENT}}" message="[research task with clear deliverable and output path]"
```

### Dispatch to local ops agent (system/GPU ops)
```
sessions_spawn agent="{{LOCAL_AGENT}}" message="[system task]"
```

### Report to {{AGENT_MAIN}} (escalation/progress)
```
sessions_spawn agent="main" message="PM reporting: [your update]"
```

## Your Own Tools

You have `read`, `write`, `edit` — use them to manage specs, task queues, and project docs directly. This is your primary PM work.

| Tool | Use For |
|------|---------|
| `read` | Read project state, task queues, specs, active state |
| `write` | Create new specs, task queue files, feature maps |
| `edit` | Update existing docs, mark tasks complete, revise specs |
| `process` | Git commands, `ls` to scan directories |
| `session_status` | Check on dispatched agent sessions |
| `agents_list` | See available agents and their status |

## Key Paths

| What | Where |
|------|-------|
| All projects | `{{PROJECTS_DIR}}` |
| PM workspace | `{{PROJECTS_DIR}}/_pm/` |
| Spec-first template | `{{PROJECTS_DIR}}/spec-first-starter/` |

## Project Setup

When creating a new project:

1. Create the project directory:
   ```bash
   mkdir -p {{PROJECTS_DIR}}/<project-name>
   ```

2. Copy the spec-first-starter template into it:
   ```bash
   cp -r {{PROJECTS_DIR}}/spec-first-starter/.agent {{PROJECTS_DIR}}/<project-name>/
   cp {{PROJECTS_DIR}}/spec-first-starter/CLAUDE.md {{PROJECTS_DIR}}/<project-name>/
   ```

3. Run `/discovery` on the new project to initialize product docs

4. Add the project to your TASKS.md managed projects table

5. Initialize git:
   ```bash
   cd {{PROJECTS_DIR}}/<project-name> && git init && git add -A && git commit -m "init: spec-first project scaffold"
   ```

## Managed Projects

| Project | Agent | Status |
|---------|-------|--------|
| (project-name) | (agent-id) | (Active / Queued / Idle) |

## Routing Table

| Task Type | Who | How |
|-----------|-----|-----|
| Code / pipeline work | **Engineer** | `sessions_spawn agent="{{ENGINEER_AGENT}}" message="..."` |
| Web research | **Research** | `sessions_spawn agent="{{RESEARCH_AGENT}}" message="..."` |
| System / GPU ops | **Local ops** | `sessions_spawn agent="{{LOCAL_AGENT}}" message="..."` |
| Specs / planning / task queues | **You (PM)** | Direct — use read/write/edit |
| Progress reports / escalation | **{{AGENT_MAIN}}** | `sessions_spawn agent="main" message="..."` |
