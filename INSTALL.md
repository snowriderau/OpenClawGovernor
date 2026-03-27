# Governor Bootstrap Sequence

**This file is for you, the Governor agent. Not for humans.**

After `init.sh` has been run, read this top to bottom and execute each phase. The user has already answered the setup questions — your job is to verify the environment, deploy the fleet, and validate that spec-driven development works end-to-end.

If anything fails, stop and tell the user what's wrong. Don't guess. Don't skip phases.

---

## Phase 1: Verify Environment

Confirm init.sh completed successfully before doing anything else.

```
1. Read .env — confirm all values are populated
2. Confirm CLAUDE.md contains Governor instructions (not template-editing instructions)
3. Check for unreplaced placeholders: grep -r '{{' *.md | grep -v TEMPLATE | grep -v _TEMPLATE
4. Test SSH to target machine
5. Verify OpenClaw is installed: ssh <target> "~/.npm-global/bin/openclaw --version"
```

If any check fails, stop and report to the user. Do not proceed with a broken environment.

---

## Phase 2: Deploy Infrastructure

SSH to the target machine and set up the foundation.

### 2.1 Projects Directory
```
1. Verify {{PROJECTS_DIR}} exists (init.sh should have created it)
2. Verify {{PROJECTS_DIR}}/spec-first-starter/ exists with .agent/ structure
3. If missing, deploy from docs/project-examples/spec-first-starter/
```

### 2.2 OpenClaw Gateway
```
1. Read specs/FEAT-OPENCLAW_setup.md for full requirements
2. Validate openclaw.json: ~/.npm-global/bin/openclaw config validate
3. Verify gateway service: systemctl --user status openclaw-gateway.service
4. If not running: follow the spec to configure and start
```

### 2.3 Agent Fleet
```
1. Read specs/AGENT_REGISTRY.md for the 8-agent fleet layout
2. Verify agents are configured: ~/.npm-global/bin/openclaw agents list
3. Deploy workspace files from docs/workspace-examples/ for each agent
4. Verify heartbeat is working for autonomous agents (Atlas, Conductor)
```

### 2.4 PM Agent
```
1. Verify {{PROJECTS_DIR}}/_pm/ exists with workspace files
2. Ensure PM agent is configured in openclaw.json
3. PM must know:
   - Where the spec-first-starter template lives: {{PROJECTS_DIR}}/spec-first-starter/
   - Where to scan for projects: {{PROJECTS_DIR}}/
   - How to dispatch agents: sessions_spawn
4. Test PM heartbeat: does it scan projects and report status?
```

---

## Phase 3: Validate Spec-Driven Workflow

The spec-driven workflow is the core of this system. Verify it works end-to-end.

### Governor commands — these are how ALL work happens

| Command | What it does | When to use |
|---------|-------------|-------------|
| `/new-feature` | Write spec → get approval → implement → `/success` | New capability |
| `/create-task` | Match to existing feature → execute → update status | Work against existing spec |
| `/update-feature` | Read existing spec → plan changes → implement → `/success` | Modify existing capability |
| `/agent-improvement` | Audit fleet → find gaps → fix → document | Regular maintenance |
| `/success` | Commit → update feature_map → sync OpenClaw → document | After completing any work |
| `/security_audit` | Full security review | Scheduled or on-demand |
| `/patch_management` | Check updates → assess → apply with rollback | Scheduled or on-demand |
| `/incident_response` | Detect → isolate → preserve evidence → log | Active incidents |
| `/machine_recovery` | Restore from backup → reconfigure → verify | After failures |

### Verify the loop works
```
1. Run /agent-improvement to audit current state (safe — read-only until approved)
2. Check feature_map.md — are all items accurately reflecting system state?
3. Pick the highest-priority unchecked item from feature_map.md
4. Run /new-feature or /create-task to address it
5. Verify /success updates feature_map.md and commits correctly
```

---

## Phase 4: Project Management Setup

### How projects work on this system

Every project lives in `{{PROJECTS_DIR}}` on the target machine. Every project uses the spec-first-starter structure:

```
project-name/
  CLAUDE.md                         # Project instructions + self-correction
  .agent/
    product/                        # problem.md, users.md, requirements.md, architecture.md, feature_map.md, specs/
    memory/                         # active_state.md, task_queue.md, backlog.md, failures.md
    workflows/                      # discovery.md, new_feature.md, update_feature.md, loop.md, success.md
    skills/                         # Reusable agent knowledge
```

### Creating a new project
```
1. mkdir {{PROJECTS_DIR}}/<project-name>
2. cp -r {{PROJECTS_DIR}}/spec-first-starter/.agent {{PROJECTS_DIR}}/<project-name>/
3. cp {{PROJECTS_DIR}}/spec-first-starter/CLAUDE.md {{PROJECTS_DIR}}/<project-name>/
4. cd {{PROJECTS_DIR}}/<project-name> && git init && git add -A && git commit -m "init: spec-first scaffold"
5. Run /discovery on the new project to initialize product definition
6. Add to PM agent's TASKS.md managed projects table
```

### PM agent's role

The PM agent enforces spec-driven development across all managed projects:

- Scans `task_queue.md` across `{{PROJECTS_DIR}}/*/` every heartbeat
- Spawns agents for implementation work with clear instructions
- Ensures no code is written without a spec
- Catches gaps: missing specs, stale task queues, unclaimed work
- Reports meaningful progress to the orchestrator
- Scaffolds new projects from `{{PROJECTS_DIR}}/spec-first-starter/` when needed

---

## Phase 5: Ongoing Operations

After setup is complete, the Governor's daily work follows these patterns:

### Regular maintenance
```
/agent-improvement     — Weekly audit of agent fleet
/security_audit        — Weekly security review
/patch_management      — Weekly patch check
```

### Feature work (spec-driven, always)
```
/new-feature <name>    — New capability: spec → approve → implement → /success
/create-task <task>    — Execute against existing feature
/update-feature <name> — Evolve existing feature
```

### Repo maintenance rules (non-negotiable)
```
1. feature_map.md stays current — every change updates this file
2. .agent/memory/active_state.md always tracks current work
3. Specs before code — /new-feature writes a spec BEFORE implementation
4. /success is mandatory after completing any feature work
5. Self-correction table in CLAUDE.md is updated after every user correction
6. Never let the user manually edit config — the Governor writes all config
```

---

## Reference

| What | Where |
|------|-------|
| Feature roadmap | `feature_map.md` |
| Architecture | `architecture.md` |
| Agent fleet layout | `specs/AGENT_REGISTRY.md` |
| Agent hierarchy | `agent_escalation_protocol.md` |
| Workspace examples | `docs/workspace-examples/` |
| Project template | `docs/project-examples/spec-first-starter/` |
| Operational best practices | `docs/best-practices.md` |
| FAQ | `docs/faq.md` |
| OpenClaw config rules | `.claude/rules/openclaw.md` |
