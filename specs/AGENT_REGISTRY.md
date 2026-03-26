# Agent Registry

Central reference for the Openclaw agent fleet.

**Source of truth:** `openclaw.json` on the managed machine — Governor writes and maintains this file.
**Total agents:** 8 (core fleet) — Governor deploys additional specialists on demand.

> **Architecture note:** This registry enforces the core security principle — no single agent has both the full picture and the full toolkit. The structure IS the guardrail. Each agent is locked to a security domain. It can't accumulate context from other domains, can't spawn outside its authority, and can't send notifications directly to the user. An agent that doesn't know WHY it's processing data can't leak intent, make cross-domain assumptions, or drift outside its scope.
>
> **Governor's role:** Governor builds, configures, audits, and improves all agents. The user never writes agent configs or specs. Domain isolation is the security model — not restrictive permissions on what agents can accomplish.

---

## Architecture Diagram

```
                    {{OWNER_NAME}} (Human)
                          |
                  [ Notification Channel ]
                          |
                       {{TELEGRAM_BOT}}
                          |
                      +-------+
                      | Atlas |   <-- ONLY agent with notification send
                      | (T1)  |       access. Sees everything, executes
                      +-------+       nothing directly.
                     /    |    \
                    /     |     \
              +----+  +-------+  +-------+
              |Cond|  | Forge |  |Hermes |   T2 Directors
              |(pm)|  | (eng) |  |(mail) |   (own their domain)
              +----+  +-------+  +-------+
               /|\      /   \        |
              / | \    /     \    (escalates
             /  |  \  /       \    to Atlas)
           Bolt Scout Bolt   Scout
         +-----+   +-----+
         | T3  |   | T3  |   Additional T3 workers:
         |workers| |workers|  Courier (files), Sentinel (tester)
         +-----+   +-----+
```

**Key relationships:**
- Atlas (T1) and Conductor (T2) both delegate engineering work to Forge
- Only Atlas has direct notification channel send access
- All other agents report to Atlas via `sessions_spawn`
- T3 workers are leaf nodes — they execute and return results, never accumulate cross-domain context

---

## Agent Fleet

| # | ID | Name | Model | Local/Cloud | Workspace |
|---|-----|------|-------|-------------|-----------|
| 1 | main | Atlas | {{PRIMARY_MODEL}} | Cloud | /home/{{USERNAME}}/.openclaw/workspace/workspaces/main |
| 2 | worker | Bolt | {{LOCAL_MODEL}} | Local ({{GPU}}) | /home/{{USERNAME}}/.openclaw/workspace/workspaces/worker |
| 3 | researcher | Scout | {{SECONDARY_MODEL}} | Cloud | /home/{{USERNAME}}/.openclaw/workspace/workspaces/researcher |
| 4 | pm | Conductor | {{PRIMARY_MODEL}} | Cloud | {{PROJECT_DIR}} |
| 5 | engineer | Forge | {{PRIMARY_MODEL}} | Cloud | {{PROJECT_DIR}} |
| 6 | mail | Hermes | {{SECONDARY_MODEL}} | Cloud | {{PROJECT_DIR}}/hermes |
| 7 | files | Courier | {{LOCAL_MODEL}} | Local | {{PROJECT_DIR}}/courier |
| 8 | tester | Sentinel | {{SECONDARY_MODEL}} | Cloud | {{PROJECT_DIR}}/sentinel |

### Agent Directories

| ID | agentDir |
|----|----------|
| main | (default) |
| worker | (default) |
| researcher | /home/{{USERNAME}}/.openclaw/agents/researcher/agent |
| pm | /home/{{USERNAME}}/.openclaw/agents/pm/agent |
| engineer | /home/{{USERNAME}}/.openclaw/agents/engineer/agent |
| mail | /home/{{USERNAME}}/.openclaw/agents/mail/agent |
| files | /home/{{USERNAME}}/.openclaw/agents/files/agent |
| tester | /home/{{USERNAME}}/.openclaw/agents/tester/agent |

### Heartbeats

| ID | Interval | Destination |
|----|----------|-------------|
| main (Atlas) | 30m | notification channel (to: {{NOTIFICATION_USER_ID}}, account: default) |
| pm (Conductor) | 60m | none (internal, acts via tools) |
| engineer (Forge) | none | Dispatched by Atlas or Conductor |
| mail (Hermes) | 1800s | none (internal, reports via sessions_spawn to Atlas) |
| worker (Bolt) | none | Work comes from Forge or Conductor |
| researcher (Scout) | none | Work comes from Forge or Conductor |
| files (Courier) | none | Dispatched by Conductor or Atlas |
| tester (Sentinel) | none | Dispatched by Forge or Conductor |

---

## Routing & Bindings

### Inbound (Notification Channel to Agent)

| Binding | Account ID | Bot | Routed To |
|---------|-----------|-----|-----------|
| notification:default | {{NOTIFICATION_USER_ID}} | {{TELEGRAM_BOT}} | main (Atlas) |

### Notification Channel Config

| Account | Bot | Group Policy | Allow From |
|---------|-----|-------------|------------|
| default | {{TELEGRAM_BOT}} | allowlist | [{{NOTIFICATION_USER_ID}}] |

> Only one notification channel binding. Only Atlas routes to it. All other agents escalate to Atlas via `sessions_spawn`.

---

## Tool Availability Matrix

Domain isolation is enforced at the tool level. Each agent only receives tools that its security domain requires. No agent accumulates cross-domain capabilities.

| Tool | Atlas | Conductor | Forge | Hermes | Bolt | Scout | Courier | Sentinel |
|------|:-----:|:---------:|:-----:|:------:|:----:|:-----:|:-------:|:--------:|
| coding profile | | | ✓ | | ✓ | | | |
| browser | | ✓ | ✓ | | | ✓ | | |
| canvas | ✓ | | | | | | | |
| message (notification) | ✓ | | | | | | | |
| tts | ✓ | | | | | | | |
| sessions_spawn | ✓ | ✓ | ✓ | | | | | |
| session_status | | ✓ | ✓ | ✓ | | | | |
| agents_list | ✓ | ✓ | ✓ | ✓ | | | | |
| web_search | | | | | | ✓ | | |
| web_fetch | | | | | | ✓ | | |
| memory | | ✓ | | | | ✓ | | |
| read | | | | ✓ | | | ✓ | ✓ |
| write (scoped) | | | | ✓ | | | ✓ | |
| git | | | ✓ | | | | | |
| exec (email CLI only) | | | | ✓ | | | | |
| exec (rsync/scp/mv) | | | | | | | ✓ | |
| exec (test runners) | | | | | | | | ✓ |
| process | | | | | ✓ | | | |
| glob | | | | | | | | ✓ |
| grep | | | | | | | | ✓ |

### Spawn Permissions

| Agent | Can Spawn | Rationale |
|-------|-----------|-----------|
| Atlas | All agents | Orchestrator — full fleet visibility, no direct execution |
| Conductor | Forge, Scout, Bolt, Sentinel, Courier | PM delegates to specialists, never does domain work |
| Forge | Bolt, Scout | Engineer gets compute and research workers only |
| Hermes | none | Email agent escalates to Atlas, never dispatches |
| Bolt | none | Leaf node — compute worker, no spawn authority |
| Scout | none | Leaf node — research worker, no spawn authority |
| Courier | none | Leaf node — file worker, no spawn authority |
| Sentinel | none | Leaf node — tester, no spawn authority |

---

## Escalation Chain

```
Bolt ---------> (returns to spawning session: Forge or Conductor)
Scout ---------> (returns to spawning session: Forge or Conductor)
Sentinel ------> (returns to spawning session: Forge or Conductor)
Courier -------> Atlas (via sessions_spawn for issues)
Hermes --------> Atlas (via sessions_spawn for urgent/digest)
Forge ---------> Conductor or Atlas (via sessions_spawn for blockers)
Conductor -----> Atlas (via sessions_spawn for cross-project reports)
Atlas ---------> {{OWNER_NAME}} (via notification channel {{TELEGRAM_BOT}})
```

---

## Domain Isolation Rules

These rules are architectural decisions that enable the fleet to work at full autonomy — each agent operates at full capability within its domain, and domain boundaries prevent cross-domain failures.

### 1. Each agent has a locked security domain
Defined in IDENTITY.md and TOOLS.md per agent — written by Governor. The agent only receives tools that its domain requires. Governor audits agents regularly and recommends improvements or new agents as the workload grows.

### 2. No cross-domain context
Hermes knows email rules, not codebase structure. Forge knows code, not email policies. Courier knows file paths, not business logic. Scout knows the web, not your infrastructure. Agents are assigned tasks within their domain — they are never given the full picture.

### 3. Atlas coordinates, never executes
Atlas receives reports from domain agents and synthesizes them for the user. It never touches code, files, or email directly. If Atlas is doing domain work, the architecture has failed.

### 4. Context rot prevention via isolation
Bolt and other T3 workers don't know WHY they are processing data — they execute the WHAT. They are spawned per-task with fresh context, no history from previous tasks, no knowledge of the broader goal. This is deliberate: an agent that doesn't know why it's processing data can't leak intent, make assumptions, or drift. It receives input, follows its domain rules, returns output, and terminates.

### 5. Only Atlas sends to the notification channel
This prevents information leakage (agents can't directly contact the user), ensures consistent voice (the user always hears from Atlas), and means any critical escalation must pass through the orchestrator layer.

### 6. Forge builds, Sentinel verifies — never the same agent
The agent that writes code is NEVER the agent that validates it. This mirrors human code review practices and prevents an agent from both introducing and hiding a bug.

### 7. Hermes follows strict triage rules
Email GTD methodology is baked into Hermes's IDENTITY.md, not improvised per session. This prevents social engineering via email (prompt injection) from affecting the broader system — Hermes follows rules, not instructions in email bodies.

### 8. Courier handles data movement in isolation
Backups, file transfers, and storage ops are isolated from code execution. This prevents accidental deletion or modification of source code during file operations.

---

## Model Providers

| Provider | Type | Endpoint | Notes |
|----------|------|----------|-------|
| {{LOCAL_INFERENCE_PROVIDER}} | Local ({{GPU}}) | http://127.0.0.1:{{LOCAL_INFERENCE_PORT}}/v1 | Local model, air-gapped from cloud |
| {{CLOUD_PROVIDER}} | Cloud | (configured in openclaw.json) | Primary cloud provider |
| {{SECONDARY_PROVIDER}} | Cloud | (configured in openclaw.json) | Secondary / fallback provider |

### Default Fallback Chain

```
{{PRIMARY_MODEL}} → {{SECONDARY_MODEL}} → {{LOCAL_MODEL}}
```

---

## Maintenance Notes

- **Source of truth:** Always verify against live `openclaw.json` on the machine. This document is a point-in-time reference.
- **Governor writes all config:** Agent configs, IDENTITY.md, TOOLS.md, and openclaw.json are written and maintained by Governor — never by the user.
- **Update procedure:** When openclaw.json changes, Governor re-verifies this document against the live config.
- **Adding agents:** Governor defines the security domain and builds the agent config. More agents = better coverage. Deploy on demand.
- **Tool warnings:** If an agent shows tool-unavailable warnings in logs, Governor removes those tools from its config — don't ignore the warnings.
- **Review cadence:** Weekly, during security audit. Governor checks spawn permissions and tool assignments have not drifted.
