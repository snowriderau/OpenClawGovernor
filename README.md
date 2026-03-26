# OpenClaw Governor Template

**A spec-first framework for managing Linux infrastructure with Claude Code + OpenClaw**

---

## What Is This?

The **Governor pattern** separates _oversight_ from _execution_. Instead of one monolithic AI agent doing everything, you run a hierarchy:

- A **Governor** (this repo) lives on your dev machine. It holds specs, tracks state, reviews work, and dispatches tasks.
- **Agents** (OpenClaw) live on the target Linux machine. They execute tasks, run services, and report back.

The Governor never runs code on the target directly. It SSHs in to read logs, verify output, and assign work. Agents never touch this repo. Clean separation, clear accountability.

---

## Quick Start

```bash
# 1. Clone the template
git clone https://github.com/YOUR_ORG/OpenClawGovernor.git my-infra
cd my-infra

# 2. Run the init script
./scripts/init.sh

# 3. Configure your environment
cp .env.example .env
# Edit .env with your host details, agent names, model preferences

# 4. Set up SSH access to your target machine
# The Governor communicates with agents over SSH

# 5. Define your problem
# Edit .agent/product/problem.md with your infrastructure goals
```

---

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│  YOUR DEV MACHINE (Governor)                    │
│                                                 │
│  Claude Code ←→ This Repo                      │
│    ├── specs/          (feature specs)          │
│    ├── .agent/memory/  (state tracking)         │
│    ├── .agent/product/ (architecture docs)      │
│    └── CLAUDE.md       (workflow rules)         │
│                                                 │
│            │ SSH                                │
│            ▼                                    │
│  ┌─────────────────────────────────────┐        │
│  │  TARGET MACHINE (Agents)            │        │
│  │                                     │        │
│  │  OpenClaw Runtime                   │        │
│  │    ├── ops-commander (orchestrator) │        │
│  │    ├── gpu-runner    (inference)    │        │
│  │    ├── web-scout     (research)    │        │
│  │    ├── deploy-chief  (CI/CD)       │        │
│  │    └── alert-relay   (notifications)│       │
│  └─────────────────────────────────────┘        │
└─────────────────────────────────────────────────┘
```

See `docs/architecture-diagram.svg` for the full visual.

---

## Directory Structure

```
OpenClawGovernor/
├── CLAUDE.md                    # Workflow rules, self-correction table
├── README.md                    # This file
├── .env.example                 # Environment variable template
├── .gitignore
├── LICENSE
│
├── .agent/
│   ├── memory/
│   │   ├── active_state.md      # Current task tracking
│   │   └── failures.md          # Incident log and lessons
│   ├── product/
│   │   ├── architecture.md      # System architecture decisions
│   │   ├── problem.md           # Problem definition
│   │   ├── requirements.md      # Functional requirements
│   │   ├── users.md             # User personas
│   │   ├── agent_escalation_protocol.md  # Agent hierarchy rules
│   │   └── specs/               # Individual feature specs
│   └── workflows/
│       ├── incident_response.md
│       ├── machine_recovery.md
│       ├── patch_management.md
│       └── security_audit.md
│
├── .claude/
│   └── rules/                   # Claude Code custom rules
│
├── docs/                        # Diagrams and reference docs
│
└── scripts/
    └── init.sh                  # First-run setup script
```

---

## Agent Hierarchy

The template ships with a professional agent hierarchy. Customize names and roles to fit your infrastructure.

| Tier | Role | Default Name | Purpose |
|------|------|-------------|---------|
| Tier 1 | Orchestrator | `ops-commander` | Executive coordination, dispatches work to other agents |
| Tier 2 | Security Auditor | `sec-sentinel` | Vulnerability scanning, compliance checks, CVE tracking |
| Tier 2 | Deploy Manager | `deploy-chief` | CI/CD pipeline oversight, release management |
| Tier 2 | Notification Hub | `alert-relay` | Routes alerts to Telegram, Slack, or other channels |
| Tier 3 | GPU Worker | `gpu-runner` | Local inference, model serving, GPU resource management |
| Tier 3 | Research Agent | `web-scout` | CVE research, documentation lookup, web data gathering |
| Tier 3 | Log Analyzer | `log-parser` | Syslog parsing, anomaly detection, trend analysis |

Tier 1 agents delegate to Tier 2. Tier 2 delegates to Tier 3. Escalation flows upward. See `.agent/product/agent_escalation_protocol.md` for full rules.

---

## How To Use

### 1. Define the Problem
Edit `.agent/product/problem.md` with what your infrastructure needs to do.

### 2. Write Specs First
Before implementing anything, create a spec in `.agent/product/specs/`. A spec includes: goal, approach, acceptance criteria, rollback plan.

### 3. Use Slash Commands
- `/plan` — Enter plan mode for complex tasks
- `/status` — Check agent state via SSH
- `/audit` — Run a security or performance audit
- `/deploy` — Trigger a deployment workflow

### 4. Let the Governor Work
The Governor reads `CLAUDE.md` rules automatically. It will plan before acting, verify before completing, and log lessons when corrected.

---

## Design Principles

1. **Spec-First Development** — Write the spec before writing the code. Reduces ambiguity, catches design issues early.

2. **Approval-Gated Execution** — No system changes (packages, configs, services) without explicit user approval. Read-only by default.

3. **Self-Correcting Memory** — Every mistake becomes a rule in `CLAUDE.md`. The system gets smarter over time without manual tuning.

4. **Hierarchical Delegation** — Work flows downward through agent tiers. Escalation flows upward. No agent operates outside its tier without explicit override.

5. **Separation of Concerns** — The Governor observes and directs. Agents execute. Code lives on the target machine. State lives in this repo.

---

## License

See [LICENSE](LICENSE) for details.
