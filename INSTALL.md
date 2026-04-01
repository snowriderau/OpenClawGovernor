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
1. Read fleet.md for the agent hierarchy, models, and spawn rules
2. Verify agents are configured: ~/.npm-global/bin/openclaw agents list
3. Deploy workspace files from docs/workspace-examples/ for each agent
4. Enable fleet-wide heartbeat isolation: isolatedSession: true + lightContext: true
5. Verify {{AGENT_MAIN}} heartbeat is working and reaching notification channel
```

### 2.4 heartbeat-guard Plugin
```
1. Verify plugin exists at ~/.openclaw/plugins/heartbeat-guard/
2. If missing, build from specs/FEAT-020_heartbeat_guard/ (BUILD_REQUIREMENTS.md has steps)
3. Register in openclaw.json plugins.entries (see SPEC.md for config schema)
4. Restart gateway and verify: openclaw plugins list
5. Check ~/.openclaw/logs/heartbeat-guard.log after first heartbeat runs
```

### 2.5 PM Agent
```
1. Verify {{PROJECTS_DIR}}/_pm/ exists with workspace files
2. Ensure PM agent is configured in openclaw.json with 60m heartbeat
3. PM must know where to scan for projects: {{PROJECTS_DIR}}/
4. Test PM heartbeat: does it scan projects and report status?
```

---

## Phase 3: Validate Spec-Driven Workflow

The trinity commands are how ALL work happens:

| Command | What it does | When to use |
|---------|-------------|-------------|
| `/new-feature` | Write spec → get approval → implement → `/success` | New capability |
| `/create-task` | Match to existing feature → execute → update status | Work against existing spec |
| `/update-feature` | Read existing spec → plan changes → implement → `/success` | Modify existing capability |
| `/agent-improvement` | Audit fleet → find gaps → fix → document | Regular maintenance |
| `/security-audit` | Full security review | Scheduled or on-demand |

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

Every project lives in `{{PROJECTS_DIR}}` on the target machine using the spec-first-starter structure:

```
project-name/
  CLAUDE.md                         # Project instructions
  .agent/
    product/                        # problem.md, feature_map.md, specs/
    memory/                         # active_state.md, task_queue.md
    workflows/                      # discovery.md, new_feature.md, success.md
```

### Creating a new project
```
1. mkdir {{PROJECTS_DIR}}/<project-name>
2. cp -r {{PROJECTS_DIR}}/spec-first-starter/.agent {{PROJECTS_DIR}}/<project-name>/
3. cd {{PROJECTS_DIR}}/<project-name> && git init && git add -A && git commit -m "init: spec-first scaffold"
4. Add to PM agent's managed projects
```

---

## Phase 5: Ongoing Operations

### Regular maintenance
```
/agent-improvement   — Weekly audit of agent fleet
/security-audit      — Periodic security review
```

### Repo maintenance rules (non-negotiable)
```
1. feature_map.md stays current — every change updates this file
2. active_state.md always tracks current work (root, under 50 lines)
3. Specs before implementation — /new-feature writes a spec BEFORE building
4. /success is mandatory after completing any feature work
5. Corrections become rules in .claude/rules/ — not table entries
6. Never let the user manually edit config — the Governor writes all config
```

---

## Reference

| What | Where |
|------|-------|
| Feature roadmap | `feature_map.md` |
| Agent fleet | `fleet.md` |
| Workspace examples | `docs/workspace-examples/` |
| Project template | `docs/project-examples/spec-first-starter/` |
| Operational best practices | `docs/best-practices.md` |
| FAQ | `docs/faq.md` |
| OpenClaw config rules | `.claude/rules/openclaw.md` |
