# TOOLS.md — Atlas

## Agent Dispatch

> **CRITICAL: DO NOT use the `message` tool for inter-agent dispatch — use `sessions_spawn`.**
> The `message` tool routes through your notification channel (Telegram, etc.) and will fail for internal agents.
> `sessions_spawn` routes internally through the Openclaw gateway. Always use it.

---

### Conductor (Project Manager) — `conductor`

- **Model:** {{CONDUCTOR_MODEL}}
- **Cost:** {{CONDUCTOR_COST}}
- **Role:** Autonomous project manager — scans task queues, prioritizes, dispatches agents, verifies results
- **How to call:** `sessions_spawn(agent: "conductor", message: "...")`

#### Good tasks for Conductor
- Review project status across all active projects
- Prioritize the work queue and identify what's blocked
- Dispatch Forge to implement a queued feature
- Write or update project specs

#### Not for Conductor
- Writing code — that's Forge
- Talking to {{OWNER_NAME}} directly — that's Atlas

---

### Forge (Senior Engineer) — `forge`

- **Model:** {{FORGE_MODEL}}
- **Cost:** {{FORGE_COST}}
- **Role:** Full-stack engineering — builds, fixes, deploys, debugs
- **How to call:** `sessions_spawn(agent: "forge", message: "...")`

> Same rule: **DO NOT use `message(to: "forge", ...)`** — use `sessions_spawn`.

#### Good tasks for Forge
- Feature implementation and bug fixes
- Infrastructure setup and config (Docker, systemd, nginx)
- Script writing and automation
- Debugging failing services
- Code review and refactoring
- Deployment (containers, services, ports)

#### Not for Forge
- Research tasks → dispatch Scout
- System health checks → dispatch Bolt
- Project scanning → dispatch Conductor
- Sending notifications → that's Atlas only

#### Example
```
sessions_spawn(agent: "forge", message: "The home dashboard is returning 502. Check the service status, review logs, fix the issue, and report back with what you found and what you changed.")
```

---

### Hermes (Communications) — `hermes`

- **Model:** {{HERMES_MODEL}}
- **Cost:** {{HERMES_COST}}
- **Role:** Drafts and sends communications — emails, summaries, reports
- **How to call:** `sessions_spawn(agent: "hermes", message: "...")`

#### Good tasks for Hermes
- Draft an email to a client or service
- Format a status report for {{OWNER_NAME}}
- Write a summary of project progress
- Compose structured updates

#### Not for Hermes
- Sending to notification channel without Atlas approval
- Engineering tasks
- Research

---

### Bolt (Compute Worker) — `bolt`

- **Model:** {{BOLT_MODEL}} (local GPU, {{GPU}})
- **Cost:** Zero — runs on local compute
- **Role:** Local compute muscle — health checks, file ops, system tasks, GPU inference
- **How to call:** `sessions_spawn(agent: "bolt", message: "...")`

> Same rule: **DO NOT use `message(to: "bolt", ...)`** — use `sessions_spawn`.

#### Good tasks for Bolt
- Check if services are running (Openclaw gateway, inference server, etc.)
- Disk space, GPU usage, system health
- Log analysis and diagnostics
- File discovery and migration
- Local tool management

#### Not for Bolt
- Writing code
- Talking to {{OWNER_NAME}} — Bolt has no notification access
- Complex reasoning or research

#### Example
```
sessions_spawn(agent: "bolt", message: "Check GPU utilization, disk usage on all mounts, and confirm the inference server is responding. Report back a health summary.")
```

---

### Scout (Web Researcher) — `scout`

- **Model:** {{SCOUT_MODEL}}
- **Cost:** {{SCOUT_COST}}
- **Role:** Web research, document analysis, deep dives
- **How to call:** `sessions_spawn(agent: "scout", message: "...")`

#### Good tasks for Scout
- Research a tool, library, or service
- Find documentation or pricing information
- Compare alternatives
- Summarize an article or report

#### Not for Scout
- Local machine access
- Writing code
- Sending notifications

---

### Courier (Email Manager) — `courier`

- **Model:** {{COURIER_MODEL}}
- **Cost:** {{COURIER_COST}}
- **Role:** Email management — inbox triage, data extraction, follow-up tracking, daily digest
- **How to call:** `sessions_spawn(agent: "courier", message: "...")`
- **Account:** {{AGENT_EMAIL}}

#### Commands for Courier
- `check email` / `inbox` — Current inbox summary
- `search [query]` — Search emails (Gmail query syntax)
- `read [messageId]` — Full email content
- `archive [messageId]` — Remove from inbox
- `draft [to] [subject] [body]` — Create email draft
- `send [to] [subject] [body]` — Send email (ONLY when {{OWNER_NAME}} explicitly asks)
- `digest` — Force daily digest
- `follow-ups` — List overdue items in waiting-for tracker

#### When {{OWNER_NAME}} asks about email
Always delegate to Courier. Examples:
```
sessions_spawn(agent: "courier", message: "check email")
sessions_spawn(agent: "courier", message: "search from:stripe.com newer_than:7d")
sessions_spawn(agent: "courier", message: "digest")
```

---

### Sentinel (Monitor / Watchdog) — `sentinel`

- **Model:** {{SENTINEL_MODEL}}
- **Cost:** {{SENTINEL_COST}}
- **Role:** Monitoring, alerting, automated health checks
- **How to call:** `sessions_spawn(agent: "sentinel", message: "...")`

#### Good tasks for Sentinel
- Run a full system health check and report
- Monitor a specific service for N minutes
- Check recent log output for errors

#### Sentinel escalates to Atlas
When Sentinel finds something requiring action, it spawns Atlas with a structured report. Atlas then decides whether to dispatch Forge, notify {{OWNER_NAME}}, or handle it.

---

## External Services

### Notification Channel
- **Service:** {{NOTIFICATION_SERVICE}} (e.g., Telegram)
- **Bot:** {{NOTIFICATION_BOT}}
- **Owner ID:** {{OWNER_NOTIFICATION_ID}}
- **Note:** Only Atlas sends to this channel. All other agents escalate to Atlas.

### NAS / Storage
- **SSH:** `ssh {{NAS_HOST}}` (port {{NAS_PORT}}, user: {{NAS_USER}})
- **Key:** {{NAS_SSH_KEY}}
- Delegate NAS operations to Bolt (has SSH access)

### Local Inference Server
- **API:** {{INFERENCE_API}} (OpenAI-compatible)
- **Model(s):** {{INFERENCE_MODELS}}
- **CLI:** {{INFERENCE_CLI}}

### Version Control / Code Host
- **Service:** {{VCS_SERVICE}}
- **Org/User:** {{VCS_ORG}}

---

## Apps & Projects You Manage

_Update this section as projects come online. Pattern: name, URL, repo path, service name, what it does._

### Example: Home Dashboard
- **URL:** http://{{MACHINE_IP}}:{{DASHBOARD_PORT}}
- **Repo:** `{{PROJECTS_DIR}}/home-dashboard/`
- **Service:** `home-dashboard.service` (systemd user, auto-restart)
- **Stack:** FastAPI + Jinja2
- **Shows:** Agent status, system health, GPU stats

_Add your projects here as they're deployed._
