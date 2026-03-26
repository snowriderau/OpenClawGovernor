# Agent Escalation & Delegation Protocol

**Purpose:** Define how agents request help, escalate issues, and collaborate without notification channel conflicts.

**Policy:** Only Atlas (main) sends to the notification channel. All other agents escalate through the defined chain.

**Architecture principle:** This protocol enforces the core security architecture — context flows UP, execution flows DOWN, and no single agent has both the full picture and the full toolkit. An agent that can't send notifications can't leak information. An agent that can't spawn workers can't cause cascading failures.

---

## Agent Hierarchy & Delegation

### Tier 1: Orchestrator (delegates, never executes)
- **Atlas** (main, {{PRIMARY_MODEL}})
  - Can dispatch to: Conductor, Forge, Hermes, Bolt, Scout, Courier, Sentinel
  - Can send to notification channel (only agent with this permission)
  - Role: Central coordinator, synthesizes reports, sends status to user, never does domain work itself

### Tier 2: Directors (can dispatch workers, own their domain)
- **Conductor** (pm, {{PRIMARY_MODEL}})
  - Can dispatch to: Forge, Scout, Bolt, Sentinel, Courier
  - Cannot send to notification channel (escalates to Atlas)
  - Role: Project management, task prioritization, coordinate specialists, report status via Atlas
  - Security domain: Project metadata only — reads specs, task queues, status. No code execution.

- **Forge** (engineer, {{PRIMARY_MODEL}})
  - Can dispatch to: Bolt, Scout
  - Cannot send to notification channel (escalates to Atlas)
  - Role: Plans, builds, fixes, ships code. Delegates compute to Bolt, research to Scout.
  - Security domain: Code execution, build tooling, git. No email, no file storage, no infra outside its scope.

- **Hermes** (mail, {{SECONDARY_MODEL}})
  - Cannot dispatch (reports directly to Atlas)
  - Cannot send to notification channel (escalates to Atlas)
  - Role: Email triage, GTD/Inbox Zero, follow-up tracking, structured data extraction
  - Security domain: Email ONLY. Cannot touch code, files, or infrastructure. GTD rules baked into IDENTITY.md.

### Tier 3: Workers (cannot dispatch, execute within locked scope)
- **Bolt** (worker, {{LOCAL_MODEL}}) — local GPU
  - Cannot dispatch (leaf node)
  - Cannot send to notification channel
  - Role: Compute-only worker. Doesn't know WHY it's processing, just executes the WHAT. Keeps cloud models away from real data.
  - Security domain: Local compute only. No network, no email, no user comms. Air-gapped from cloud.

- **Scout** (researcher, {{SECONDARY_MODEL}})
  - Cannot dispatch (leaf node)
  - Cannot send to notification channel
  - Role: Web research, information gathering, source validation. Returns findings to caller.
  - Security domain: Web read-only. Cannot write files, send emails, or execute code.

- **Courier** (files, {{LOCAL_MODEL}})
  - Cannot dispatch (leaf node)
  - Cannot send to notification channel
  - Role: File transfers, backup operations, storage management, rsync operations.
  - Security domain: File system and storage only. No code execution, no email, no web.

- **Sentinel** (tester, {{SECONDARY_MODEL}})
  - Cannot dispatch (leaf node)
  - Cannot send to notification channel
  - Role: Run tests, validate deployments, check acceptance criteria, end-to-end verification.
  - Security domain: Read + execute tests only. Cannot modify source code. Verifies what Forge built.

### Optional Specialists
These agents are domain-specific additions for environments that need them. Governor deploys new specialists on demand — don't be conservative:

- **Hermes** (mail) — already included above as a T2 director in the 8-agent fleet
- **Refiner** (pipeline) — custom pipeline agent for environments with data processing needs. Same security constraints as other T3 workers: no spawn, no notification channel, domain-locked tools.

---

## Escalation Rules

### When to Use `sessions_spawn` (agent-to-agent dispatch)
- **Who:** Any agent with `sessions_spawn` in alsoAllow
- **How:** `sessions_spawn` tool with target `agent: "agent_id"`
- **Purpose:** Request work from another agent in the hierarchy
- **Example:** Conductor dispatches Forge to build a new feature

### When to Escalate to Atlas
- **Condition:** Need to send message to user (notification channel)
- **Method:** `sessions_spawn` to main (Atlas) with context about issue/status
- **Atlas will then:** Send notification to user on behalf of the requesting agent

### When to Send Error/Status Reports
- **Direct tools:**
  - Use `sessions_spawn` to escalate
  - Include full context: what was attempted, why it failed, what's needed
  - Include logs/output as attachments if relevant

---

## Tool Alignment Matrix

| Tool | Atlas | Conductor | Forge | Hermes | Bolt | Scout | Courier | Sentinel |
|------|:-----:|:---------:|:-----:|:------:|:----:|:-----:|:-------:|:--------:|
| message (notification) | ✓ | | | | | | | |
| sessions_spawn | ✓ | ✓ | ✓ | | | | | |
| canvas | ✓ | | | | | | | |
| tts | ✓ | | | | | | | |
| coding profile | | | ✓ | | ✓ | | | |
| browser | | ✓ | ✓ | | | ✓ | | |
| web_search / web_fetch | | | | | | ✓ | | |
| memory | | ✓ | | | | ✓ | | |
| exec (email CLI) | | | | ✓ | | | | |
| exec (rsync/scp/mv) | | | | | | | ✓ | |
| exec (test runners) | | | | | | | | ✓ |
| read | | | | ✓ | | | ✓ | ✓ |
| write (workspace only) | | | | ✓ | | | ✓ | |
| git | | | ✓ | | | | | |
| process | | | | | ✓ | | | |
| glob / grep | | | | | | | | ✓ |

### Spawn Permissions

| Agent | Can Spawn |
|-------|-----------|
| Atlas | All agents |
| Conductor | Forge, Scout, Bolt, Sentinel, Courier |
| Forge | Bolt, Scout |
| Hermes | none (reports to Atlas) |
| Bolt | none (leaf node) |
| Scout | none (leaf node) |
| Courier | none (leaf node) |
| Sentinel | none (leaf node) |

---

## Example Scenarios

These scenarios demonstrate domain isolation in practice. Notice that no single agent ever has both the knowledge and the tools to cause damage outside its domain.

### Scenario A: Feature Build with Local Compute Verification
1. Conductor dispatches Forge to build a feature
2. Forge spawns Bolt for local compute tasks (Bolt receives input — it does NOT know what feature is being built or why)
3. Forge spawns Sentinel to verify the result
4. Sentinel reports pass/fail to Forge, Forge reports to Atlas
5. Atlas sends status to user via notification channel

**Why this works:** Bolt never accumulates context about the broader goal. Sentinel can't modify what it verifies. Forge can't send notifications directly.

### Scenario B: Email-Triggered Development Task
1. Hermes triages email, finds urgent feature request
2. Hermes escalates structured summary to Atlas (Hermes never sees the codebase)
3. Atlas dispatches Conductor with the requirement
4. Conductor assigns Forge to implement
5. Forge never sees the original email — only the requirement

**Why this works:** Hermes knows email rules, not codebase structure. Forge knows code, not email policies. Neither can cross into the other's domain.

### Scenario C: Backup Failure Escalation
1. Courier runs nightly backup
2. Courier detects disk full condition
3. Courier escalates to Atlas with full context (disk usage, what failed, what's needed)
4. Atlas notifies user via notification channel

**Why this works:** Courier never tries to fix code, delete source files, or make decisions outside its file/storage domain. It observes, reports, escalates — nothing more.

### Scenario D: Security Research to Patch
1. Scout researches a reported vulnerability (web read-only — no code execution)
2. Scout returns structured findings to Conductor
3. Conductor dispatches Forge to implement the patch
4. Sentinel verifies the fix independently (cannot modify what it tests)
5. Atlas reports outcome to user

**Why this works:** Scout never writes code. Forge never browses the web. Sentinel never modifies source. The separation means a mistake in any one agent cannot cascade into the others' domains.

---

## Approval & Permissions

### Elevated Tool Access (sudo commands)
- **Who:** Any agent needing elevated access
- **How:** Request through elevated tool (system.run, systemctl, package manager, etc)
- **Approval:** Requires user approval via notification channel (gateway auth mode)
- **Who approves:** System owner ({{NOTIFICATION_USER_ID}})

### Model-Specific Constraints
- **Bolt:** {{LOCAL_MODEL}} (local GPU, compute-heavy tasks)
  - Good for: compute, code analysis, local inference where data must not leave the machine — saves cost and protects data
  - Does not have: network access, spawn authority, user comms

- **Scout:** {{SECONDARY_MODEL}} (cloud)
  - Good for: research, web browsing, information synthesis
  - Does not have: local inference, write access, dispatch authority

---

## Maintenance & Updates

- Config source: `~/.openclaw/openclaw.json` — Governor writes and maintains this file
- Review cadence: Weekly (during security audits)
- Changes require: user approval + gateway restart
- When adding agents: assign a locked security domain FIRST, then define tools. Governor builds the agent config — domain isolation is the architecture, not a restriction on what agents can do.
