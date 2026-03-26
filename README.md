# OpenClaw Governor Template

Run an autonomous AI agent fleet on your own machine. You do the thinking, the robots do the work.

## What is this?

This template sets up **OpenClaw** — an open-source framework for running persistent AI agents on your hardware — with a **Governor** layer that oversees, improves, and manages the entire fleet. You never touch config files. You just tell the Governor what you need.

The Governor (Claude Code, Codex, or any coding AI agent you like) sits separately from the agent fleet. It monitors agents, fixes issues, deploys new ones, and writes corrective rules when things go wrong. The system gets smarter every time something fails.

Your agents talk to you via Telegram, Slack, or Discord. When you want to change or improve the system, you talk to the Governor. That's it.

**Any hardware. Any GPU. Any OS.** Raspberry Pi to server rack — the architecture is the same.

> New here? Read the [FAQ](docs/faq.md) for the full picture.

## Quick Start

### Don't have OpenClaw yet?

```bash
# Install OpenClaw
curl -fsSL https://www.openclaw.ai/install.sh | bash

# Enterprise security? Add NemoClaw (optional — OpenClaw + NVIDIA sandbox + Privacy Router)
curl -fsSL https://www.nvidia.com/nemoclaw.sh | bash
```

### Already have OpenClaw installed?

```bash
# 1. Clone the Governor template
git clone https://github.com/snowriderau/OpenClawGovernor.git
cd OpenClawGovernor

# 2. Run the setup wizard — configures everything
bash scripts/init.sh

# 3. Open your Governor (Claude Code or preferred coding agent)
#    Tell it: "Set up my agent fleet using this template"
```

The Governor handles everything from there — agent config, workspace files, systemd services, the lot.

## How it works

**Three tiers, domain-locked agents, no single point of failure:**

| Tier | Role | Example |
|------|------|---------|
| **Orchestrator** | Coordinates the fleet, talks to you, never executes | Atlas |
| **Directors** | Own a domain (code, email, projects), can dispatch workers | Forge, Hermes, Conductor |
| **Workers** | Execute tasks, don't know WHY, data never leaves the machine | Bolt (local GPU), Scout, Courier, Sentinel |

No single agent has the full picture AND the full toolkit. The orchestrator sees everything but can't execute. Workers execute but don't know the broader goal. This is the security model — architecture, not restrictions.

> See the [architecture diagram](docs/architecture-diagram.svg) and [agent registry](specs/AGENT_REGISTRY.md) for the full fleet breakdown.

## What the Governor does for you

- **Deploys agents** — "I need an agent for email triage" → Governor builds it, configures workspace files, sets up spawn rules
- **Fixes agents** — agent failing? Governor reads logs, identifies the issue, adds missing tools, rewrites instructions
- **Writes all config** — you never touch `openclaw.json` or workspace files. Governor writes them.
- **Creates specs automatically** — say "new feature: backup to NAS" and the Governor writes the spec, dispatches agents, tracks progress
- **Runs security audits** — weekly automated review of agent permissions, system state, and recommendations
- **Self-corrects** — every mistake becomes a permanent rule in `CLAUDE.md`. The system learns from failures.

## What's in this repo

This repo is the Governor's workspace — not application code. Application code and agent workspaces live on the target machine.

```
CLAUDE.md              # Governor instructions + self-correction table
feature_map.md         # All features and their status
specs/                 # Feature specs and agent registry
.agent/memory/         # Runtime state (tasks, backlog, failures)
.claude/commands/      # Governor commands (/agent-improvement, /new-feature, etc.)
.claude/skills/        # OpenClaw config reference (the crown jewel)
docs/                  # Best practices, FAQ, workspace examples
scripts/               # Setup and initialization
```

## Key resources

| What | Where |
|------|-------|
| Full FAQ | [docs/faq.md](docs/faq.md) |
| Best practices | [docs/best-practices.md](docs/best-practices.md) |
| Workspace file examples | [docs/workspace-examples/](docs/workspace-examples/) |
| Agent registry | [specs/AGENT_REGISTRY.md](specs/AGENT_REGISTRY.md) |
| Escalation protocol | [agent_escalation_protocol.md](agent_escalation_protocol.md) |
| Feature map | [feature_map.md](feature_map.md) |
| Architecture | [architecture.md](architecture.md) |

## License

MIT
