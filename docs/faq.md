# Frequently Asked Questions

---

## General

### What is OpenClaw?

OpenClaw is an open-source framework for running autonomous AI agent fleets on your own hardware. Agents run as persistent processes on your machine, communicate with each other via a gateway, and can interact with you through notification channels (Telegram, Slack, Discord, etc.). Unlike cloud-only agent frameworks, OpenClaw supports hybrid inference — cloud models for reasoning, local models for data that should never leave your machine or tasks that don't need to burn API tokens.

### What is the Governor pattern?

The Governor pattern adds a coding AI agent — Claude Code, Codex, Antigravity, anything you like — as an oversight layer that sits above your OpenClaw agent fleet. The key requirement is that it runs separately from your OpenClaw folders and agents, giving it independent context and genuine oversight capability. It can run locally, on a remote workstation, anywhere you can access your machine from.

The Governor doesn't do project work — it monitors the agents, verifies their outputs, improves their configurations, writes corrective rules when something goes wrong, and builds new agents on demand. The key distinction: OpenClaw agents are operational (they execute tasks continuously). The Governor is meta-operational (it improves and oversees the agents that execute tasks). Separating these layers means you always have an independent observer that cannot be co-opted by the agents it is watching.

### What hardware does this support?

Any hardware. Raspberry Pi, VPS, desktop, server, Mac, whatever you have. Any GPU or no GPU. This template is about structure and architecture — not hardware requirements. The patterns work the same whether you're running on a beefy workstation with a high-end GPU or a $50 SBC. Pick your hardware, tell the Governor what you're working with, and it handles the rest.

### Can I use this without Claude Code as the Governor?

Absolutely. The Governor can be any capable coding AI agent — Claude Code, Codex, Antigravity, or anything else that can reason, write files, and execute commands. What matters is the separation: your Governor agent runs with its own context, separate from the OpenClaw fleet it's watching. That separation is what enables genuine oversight. Pick the tool that works for you.

---

## Working with the Governor

### What commands do I use?

Everything runs through Governor commands. These trigger spec-driven workflows — you don't manually edit specs, config, or workspace files.

| Command | What happens |
|---------|-------------|
| `/new-feature` | Governor writes a spec, you approve it, Governor implements, runs `/success` |
| `/create-task` | Governor matches to existing feature, executes, updates status |
| `/update-feature` | Governor reads existing spec, plans changes, implements, runs `/success` |
| `/agent-improvement` | Governor audits fleet — finds gaps, fixes issues, improves workspace files |
| `/success` | Governor commits, updates feature map, syncs OpenClaw, documents learnings |
| `/security_audit` | Full security review of permissions, configs, and vulnerabilities |
| `/patch_management` | Check for updates, assess risk, apply with rollback |
| `/incident_response` | Rapid detection, isolation, evidence preservation |
| `/machine_recovery` | Restore from backup, reconfigure, verify |

**The rule:** no code without a spec, no completion without `/success`. Every piece of work follows this pattern. The Governor enforces it automatically.

### How does spec-driven development work?

You describe what you need. The Governor handles everything else:

1. You say "I need a backup system"
2. Governor runs `/new-feature backup` — writes `specs/FEAT-BACKUP.md`
3. You approve the spec (or ask for changes)
4. Governor implements per the spec
5. Governor runs `/success` — commits, updates `feature_map.md`, documents learnings

This cycle applies to everything — infrastructure, agents, security, maintenance. The Governor writes specs, you approve or redirect, agents execute, and the system self-documents.

For projects managed by the agent fleet, the same pattern applies via the spec-first-starter template (see [project examples](../docs/project-examples/)). The PM agent enforces this across all managed projects.

### What if the Governor seems lost or isn't following the workflow?

Give it a specific command. Instead of "set up my system," say `/new-feature openclaw-setup` or `/agent-improvement`. The commands activate structured workflows that the Governor follows step-by-step.

If the Governor skips the spec step or tries to implement without approval, correct it — "write the spec first" or "run /new-feature." Every correction gets added to the self-correction table in `CLAUDE.md`, so it won't make the same mistake twice.

---

## Setup and Configuration

### How do I connect the Governor to my machine via SSH?

The Governor connects over SSH. Configure your SSH client with entries pointing at your machine — via Tailscale for remote access, via LAN if you're local. Run `scripts/init.sh` and it populates everything from your `.env` file automatically. Once configured, your Governor agent can SSH directly to your machine without you touching anything further.

### How do I customise the template for my use case?

Run `scripts/init.sh`. It asks you questions and replaces all `{{PLACEHOLDER}}` values across template files. That's it — you're done with configuration. The Governor handles everything else from there. You describe what you need, the Governor reads your setup and adapts it.

### How many agents should I start with?

Three tiers minimum, five to eight agents is a solid starting point. Don't be conservative. The Governor builds and deploys agents on demand, so adding one is trivial — you just tell the Governor what you need.

The tier structure matters more than the count. You want:
- **Tier 1 (Orchestration):** One agent that owns user communication and cross-domain coordination
- **Tier 2 (Directors):** Domain specialists — engineering, project management, security, whatever your work demands
- **Tier 3 (Workers):** Execution agents, including at least one running local inference for sensitive or high-volume tasks

Scale up freely. Got a new domain? Add an agent. Want email triage, file operations, weather data, web research, security monitoring? Each gets its own agent. The Governor manages all of it. More agents is better — more specialisation, cleaner context, tighter execution.

### What permissions do agents need?

Full autonomy. Give your agent user wide-open sudo. The architecture is the guardrail — not restrictive permissions. The tiered structure promotes good behaviour even with broad access, because no single agent has both full system knowledge and full toolkit. Push sensitive keys and access down to lower tiers that only run local models, and those credentials never leave your machine. The structure enforces good behaviour structurally. You don't need to micromanage permissions to get safe outcomes.

---

## Agents and Architecture

### How do agents communicate with each other?

Agents communicate via `sessions_spawn` — one agent spawns a new session for another, passing context and a task. The spawned agent executes and returns results. This is direct delegation, not a message bus or pub/sub system.

The escalation chain runs upward: workers return results to whoever spawned them. Directors escalate to the top-tier orchestrator when they need user notification or cross-domain coordination. The orchestrator owns the notification channel. There's no shared message bus and agents don't broadcast — isolation is intentional, so one agent's context can't pollute another's decision-making.

Three tiers. Clean separation of concerns. Add as many workers as you want within each tier — the Governor manages the config, you manage the vision.

### What happens when an agent fails or gets stuck?

Failures surface through three channels:

1. **Escalation:** The failing agent spawns a session with the orchestrator, providing full context — what was attempted, what failed, what's needed. The orchestrator notifies you.
2. **Heartbeat check:** The PM-layer agent scans `TASKS.md` files on a regular cycle. If a task has been in-progress too long without updates, it escalates.
3. **Governor review:** The Governor periodically SSHes to your machine and reads agent logs and task files directly. This catches failures that didn't produce an escalation.

When something fails: go back to the Governor. It reads the conversation history, diagnoses what the agent needed, and gives it what it was missing — updated config, additional tools, permissions, context. You never touch the config files yourself. The Governor writes everything and resets the agent.

### How do I add a new agent?

Tell the Governor what you need. That's it.

Say "I want an agent that handles email triage" or "add an agent for security monitoring" and the Governor responds with what it thinks you need — probably "I think you want two agents for that, one director and one worker, here's what I'm planning" — and then it builds them. It writes the spec, creates the workspace, updates `openclaw.json`, writes `IDENTITY.md`, `TOOLS.md`, `TASKS.md`, all of it. You stay completely hands-off.

If the new agent fails or gets blocked, bring it back to the Governor. Show it the conversation history. It'll figure out what the agent needs and update its config to unblock it.

---

## Inference and Models

### Should I use Ollama or LM Studio for local inference?

Pick one. All three major options expose an OpenAI-compatible API and work with OpenClaw's provider configuration:

- **Ollama** — easiest setup, pure CLI, lightweight daemon, good model library. Best if you want something running in the background with no fuss.
- **LM Studio** — better GUI for experimentation, visual model browser, easy VRAM management. The `lms` CLI supports headless operation.
- **vLLM** — production-grade, locked-in performance. Best if you're not switching models often and want maximum throughput.

The Governor sets it up. You touch no JSON whatsoever. Tell the Governor which option you prefer (or just ask it to recommend one based on your hardware) and it handles the full configuration.

### Which local model should I run?

The Governor recommends and applies best-practice models based on your hardware. On weekly review, it evaluates whether your current models are still optimal and surfaces recommendations if something better fits your setup. You engage with the Governor, it optimises — you don't dig through model benchmarks yourself.

That said: MoE (Mixture of Experts) models are generally the best fit for agent workloads. They activate only a fraction of their parameters per token, giving you speed and capability that fits in reasonable VRAM. The Governor will point you toward whatever's currently performing best for your hardware.

---

## Security

### How do I run a security audit?

You don't — the Governor does. Security audits are automatic. Check in with the Governor periodically and it reports on the current state: agent permissions, gateway configuration, SSH setup, service logs, anything anomalous. If it spotted something since your last check-in, it tells you. If something needs a decision from you, it escalates.

You're not managing a cron job or running audit commands. The Governor handles the workflow. You check in, you get a report, you make calls on anything that needs a human decision.

### Why do local models matter?

Two reasons: security and cost.

**Security:** Cloud APIs receive every prompt and every piece of data included in them. When an agent processes credentials, private keys, security configurations, or sensitive business data, those tokens are leaving your machine. Local models never make network calls. The architecture enforces this structurally — agents that touch sensitive data only have access to local providers.

**Cost:** Simple execution tasks don't need cloud reasoning. Running a worker that does file operations, log parsing, or routine data processing through a cloud API burns tokens unnecessarily. Offload those tasks locally and you cut your API spend significantly while keeping your sensitive data on-machine. It's not either/or — it's both.

### What are specs and why do they matter?

Specs exist in two places, and they serve different purposes.

**Governor repo specs** (`specs/` in this repo) are the Governor's record of system changes. Every time you add a feature, upgrade infrastructure, or fix something significant on your OpenClaw system, the Governor writes a spec documenting what was done, why, and what decisions were made. These live in the Governor repo as a permanent record of your system's evolution.

**OpenClaw project folder specs** (inside project directories on your target machine) drive the agents' own work. When agents build apps, tools, or features, specs in the project folder define what they're building, how they're coordinating, and what done looks like. This is spec-driven development for the agents themselves — they read the spec, execute against it, and update it as they go.

The important thing across both contexts: nobody writes specs manually. You say "new feature: email triage" or "I want X" and the Governor creates the spec, plans the work, dispatches agents, and documents everything. OpenClaw agents do the same within their project folders when building their own things.

Specs are how you see what happened, why it happened, and what decisions were made — without reading every conversation. When you come back after being away, specs combined with `feature_map.md` and `active_state.md` tell you exactly where things stand. Park an idea, disappear for a week, come back and pick up seamlessly. Everything was documented automatically while you were gone.

You do the thinking. The Governor and agents handle the rest.
