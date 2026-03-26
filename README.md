# OpenClaw Governor Template

A template for running a structured Openclaw agent fleet on any machine. This repo holds specs, audit logs, security baselines, and feature progress — not application code. Application code and agent workspaces live on the machine itself.

Run `scripts/init.sh` to configure this template for your environment.

## Navigation

### Product Context
- [Problem & Goals](problem.md) — Security objectives and threat model
- [Users & Roles](users.md) — Who accesses the system
- [Requirements](requirements.md) — Security requirements and compliance
- [Architecture](architecture.md) — System design and components
- [Feature Map](feature_map.md) — All features and their status

### Specifications
- [Agent Registry](specs/AGENT_REGISTRY.md) — Full Openclaw fleet reference
- [All specs](specs/) — Individual feature specs

### Runtime State
- [Active State](.agent/memory/active_state.md) — Current tasks and blockers
- [Task Queue](.agent/memory/task_queue.md) — Prioritized work items
- [Backlog](.agent/memory/backlog.md) — Future improvements
- [Failure Log](.agent/memory/failures.md) — Issues and resolutions

### Workflows (Governor Commands)
- [Incident Response](.claude/commands/incident_response.md) — Handle security issues
- [Machine Recovery](.claude/commands/machine_recovery.md) — Diagnose and recover from outages
- [Patch Management](.claude/commands/patch_management.md) — System updates
- [Security Audit](.claude/commands/security_audit.md) — Comprehensive system audit

## Quick Start

1. Clone this repo to your local machine
2. Run `scripts/init.sh` to set up your environment and placeholders
3. Tell your Governor what you need — it handles all agent configuration automatically

## Repo Structure

```
.agent/
  memory/          # Active state, task queue, failures log
.claude/
  commands/        # Governor commands + workflows (slash commands)
  mcp-lmstudio/    # MCP server for local inference integration
  rules/           # Openclaw config reference
  skills/          # Openclaw config skill
specs/             # Feature specs and agent registry
docs/              # Best practices, FAQ, architecture diagram
scripts/           # Setup and initialization
CLAUDE.md          # Project instructions and self-correction table
architecture.md    # System design and components
feature_map.md     # All features and their status
problem.md         # Security objectives and threat model
requirements.md    # Security requirements
users.md           # Who accesses the system
```

## Capabilities

- **Openclaw Agent Fleet** — Autonomous agents with notification integration, delegation hierarchy, and local GPU inference
- **Local LLM Serving** — LM Studio, Ollama, or vLLM with OpenAI-compatible API for on-device inference
- **Autonomous Domain Agents** — Specialized agents for code, email, infrastructure, security, DevOps, and research workloads
- **Agent Improvement Workflow** — Governor continuously reviews, fixes, and optimises agents (`/agent-improvement`)
- **Security Baseline** — Automated audits, vulnerability scanning, hardening rules
- **MCP LM Studio Server** — Model Context Protocol bridge to local models
- **Notification Pipeline** — Agent-to-owner alerting via configurable channels
- **Battle-Tested Workspace Examples** — Real production workspace files for [orchestrator](docs/workspace-examples/orchestrator-atlas/), [director](docs/workspace-examples/director-forge/), and [worker](docs/workspace-examples/worker-bolt/) tiers

## License

MIT
