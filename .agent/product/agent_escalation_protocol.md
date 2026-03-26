<!-- TEMPLATE: Customize agent names, models, and escalation rules for your deployment. -->
<!-- Remove this comment block when your protocol is finalized.                         -->

# Agent Escalation Protocol

## Purpose

Defines how agents communicate, delegate, and escalate within the OpenClaw runtime. Every agent operates within a tier. Work flows downward. Problems flow upward.

---

## Agent Hierarchy

```
                    ┌─────────────────┐
          Tier 1    │  ops-commander  │   Orchestrator
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
        ┌─────┴─────┐ ┌─────┴─────┐ ┌──────┴─────┐
Tier 2  │sec-sentinel│ │deploy-chief│ │ alert-relay │
        └─────┬─────┘ └─────┬─────┘ └────────────┘
              │              │
        ┌─────┴─────┐ ┌─────┴─────┐
Tier 3  │ web-scout │ │ gpu-runner │
        └───────────┘ └───────────┘
              │
        ┌─────┴─────┐
Tier 3  │ log-parser │
        └───────────┘
```

### Agent Definitions

| Agent | Tier | Model | Scope |
|-------|------|-------|-------|
| `ops-commander` | 1 | {{PRIMARY_MODEL}} | Executive coordination. Reads TASKS.md, dispatches work, reviews completions. |
| `sec-sentinel` | 2 | {{PRIMARY_MODEL}} | Security audits, CVE tracking, compliance checks. Escalates critical findings. |
| `deploy-chief` | 2 | {{PRIMARY_MODEL}} | CI/CD oversight, release management, rollback coordination. |
| `alert-relay` | 2 | {{LOCAL_MODEL}} | Notification routing to Telegram/Slack. Formats and delivers alerts. |
| `gpu-runner` | 3 | {{LOCAL_MODEL}} | Local inference, model serving, GPU resource management. |
| `web-scout` | 3 | {{PRIMARY_MODEL}} | CVE research, documentation lookup, web data gathering. |
| `log-parser` | 3 | {{LOCAL_MODEL}} | Syslog parsing, anomaly detection, log summarization. |

---

## Escalation Rules

### Rule 1: Stay in Your Lane
An agent must not perform actions outside its defined scope. If a task requires capabilities the agent does not have, it must escalate.

### Rule 2: Escalate Upward
- **Tier 3 → Tier 2:** When a task requires coordination with other agents or system-level decisions
- **Tier 2 → Tier 1:** When a task requires cross-domain coordination or user approval
- **Tier 1 → Governor (human):** When a task requires system changes, budget decisions, or policy exceptions

### Rule 3: Delegate Downward
- **Tier 1 → Tier 2:** Assigns domain-specific work (security, deployment, notifications)
- **Tier 2 → Tier 3:** Assigns execution tasks (run inference, research a CVE, parse logs)

### Rule 4: Never Skip Tiers
A Tier 3 agent must not escalate directly to the Governor. It escalates to its Tier 2 supervisor, who decides whether to escalate further.

### Rule 5: Emergency Override
In a declared emergency (service down, security breach, data loss risk), any agent may send a direct alert to the user via `alert-relay`, bypassing the normal hierarchy. The alert must include:
- Severity level (critical / high / medium)
- What happened
- What action was taken (if any)
- What decision is needed from the user

---

## Tool Alignment Matrix

Each agent has access only to the tools required for its role. This prevents scope creep and limits blast radius.

| Agent | SSH | Web Search | File I/O | Notification | Inference | Package Mgmt |
|-------|-----|-----------|----------|-------------|-----------|-------------|
| `ops-commander` | Read/Write | No | Read/Write | Via alert-relay | No | Approval-gated |
| `sec-sentinel` | Read-only | Yes | Read/Write | Via alert-relay | No | No |
| `deploy-chief` | Read/Write | No | Read/Write | Via alert-relay | No | Yes |
| `alert-relay` | No | No | Read-only | **Yes** | No | No |
| `gpu-runner` | No | No | Read/Write | No | **Yes** | No |
| `web-scout` | No | **Yes** | Read/Write | No | No | No |
| `log-parser` | Read-only | No | Read/Write | No | No | No |

---

## Example Scenarios

### Scenario 1: Security Vulnerability Detected

1. `web-scout` discovers a new CVE affecting an installed package during routine research
2. `web-scout` writes finding to its output file and escalates to `sec-sentinel`
3. `sec-sentinel` assesses severity, checks if the system is affected, writes an advisory
4. If critical: `sec-sentinel` escalates to `ops-commander` with a patch recommendation
5. `ops-commander` requests user approval via `alert-relay` (Telegram/Slack)
6. User approves → `ops-commander` delegates patch to `deploy-chief`
7. `deploy-chief` applies the patch, verifies, reports completion

### Scenario 2: GPU Inference Service Unresponsive

1. `log-parser` detects repeated errors in inference service logs
2. `log-parser` escalates to `deploy-chief` with log summary
3. `deploy-chief` checks service status, attempts restart
4. If restart fails: `deploy-chief` escalates to `ops-commander`
5. `ops-commander` notifies user via `alert-relay` with diagnosis and options
6. User decides: restart with different config, roll back, or investigate further

### Scenario 3: Routine Patch Cycle

1. `ops-commander` initiates weekly patch check (scheduled task)
2. `ops-commander` delegates package audit to `sec-sentinel`
3. `sec-sentinel` runs audit, produces list of available updates with risk assessment
4. `ops-commander` sends summary to user via `alert-relay` for approval
5. User approves selective patches → `ops-commander` delegates to `deploy-chief`
6. `deploy-chief` applies patches in order, running health checks between each
7. `deploy-chief` reports results → `ops-commander` logs completion

---

## Approval Workflow

All system-modifying actions require approval. The approval chain depends on severity.

| Action Type | Approval Required From | Channel |
|-------------|----------------------|---------|
| Read logs / status checks | None (automatic) | — |
| Install/update packages | User | Telegram / Slack |
| Modify service configs | User | Telegram / Slack |
| Restart services | User (or Tier 1 in emergency) | Telegram / Slack |
| Modify firewall rules | User (mandatory) | Telegram / Slack |
| Delete files or data | User (mandatory, double-confirm) | Telegram / Slack |

### Notification Configuration

Alerts are routed through `alert-relay` to the configured notification channel:

```
# .env configuration
NOTIFICATION_CHANNEL=telegram        # telegram | slack | email
TELEGRAM_BOT_TOKEN={{TELEGRAM_BOT}}
TELEGRAM_USER_ID={{TELEGRAM_USER_ID}}
# SLACK_WEBHOOK_URL=https://hooks.slack.com/...
# ALERT_EMAIL={{EMAIL}}
```

---

## Adding New Agents

To add a new agent to the hierarchy:

1. **Define the role** — What is its scope? What tier does it belong to?
2. **Assign tools** — What tools does it need? Follow least-privilege.
3. **Set the model** — Use `{{PRIMARY_MODEL}}` for complex reasoning, `{{LOCAL_MODEL}}` for simple/high-frequency tasks.
4. **Define escalation path** — Who is its supervisor? Who can it delegate to?
5. **Update this document** — Add the agent to the hierarchy, definitions table, and tool matrix.
6. **Update OpenClaw config** — Add the agent definition, tool bindings, and routing rules.
