# OpenClaw Governor -- Best Practices Guide

> A practical reference for operating AI agent infrastructure with the Governor pattern.
> Designed to accompany the [OpenClaw Governor Template](https://github.com/{{GITHUB_USER}}/OpenClawGovernor).

---

## 1. The Governor Pattern

The Governor pattern separates oversight from execution. Your Mac or laptop runs Claude Code as the "Governor" -- it monitors, verifies, and unblocks, but never builds application code itself. The actual work happens on a Linux server where OpenClaw agents build, deploy, and maintain your infrastructure.

**Why separate machines?** Three reasons. First, isolation: if an agent misbehaves on the Linux box, your personal machine is untouched. Second, clean context: the Governor's repo contains only specs, audit logs, and operational state, keeping its context window focused on oversight rather than drowning in application code. Third, auditability: every interaction between the Governor and the target machine flows through SSH, creating a natural audit boundary.

The Governor's core responsibilities are:

- **Monitor**: Check agent health, review logs, verify outputs match specs.
- **Verify**: Don't trust status codes -- read actual output, compare against expected behavior.
- **Unblock**: When an agent is stuck (missing dependency, needs sudo, unclear requirement), the Governor resolves the blocker or escalates to the human.

Think of it like a site reliability engineer who watches dashboards and responds to incidents but doesn't write application features. The Governor ensures the system runs correctly; the agents do the actual building.

A common mistake is letting the Governor start writing application code. Resist this. The moment your Governor is authoring React components or Dockerfiles, you've lost the separation that makes this pattern valuable. If you catch yourself doing this, stop -- SSH into the target, delegate the work to an agent, and go back to oversight.

---

## 2. Setting Up Your Agent Hierarchy

**Start small.** The most common failure mode is launching with seven agents when you need two. Begin with `ops-commander` (Tier 1 orchestrator) and one worker, such as `gpu-runner`. Add agents only when you have a concrete, recurring need that the existing agents cannot cover efficiently.

**Tier rules govern dispatch authority:**

| From | Can dispatch to | Cannot dispatch to |
|------|----------------|-------------------|
| Tier 1 (ops-commander) | Tier 2 and Tier 3 | -- |
| Tier 2 (sec-sentinel, deploy-chief, alert-relay) | Tier 3 only | Tier 1, other Tier 2 |
| Tier 3 (gpu-runner, web-scout, log-parser) | Nobody | Any higher tier |

This hierarchy prevents circular dependencies and ensures clear accountability. If `web-scout` discovers a critical CVE, it reports up to `ops-commander`, which then dispatches `sec-sentinel` to audit. Workers never give orders to directors.

**Tool allocation** follows the principle of least privilege. Each agent should have access to only the tools it needs. `gpu-runner` needs access to the inference server and model directory -- it does not need SSH keys or the ability to modify firewall rules. `sec-sentinel` needs read access to system configs and audit logs but should not be deploying containers. Define tool access in each agent's configuration and resist the temptation to give everyone admin-level access "for convenience."

**Model selection** depends on the task. Cloud models (Claude, GPT) excel at reasoning, planning, and complex analysis -- use them for orchestrators, security auditors, and anything requiring nuanced judgment. Local models (Llama, Qwen via LM Studio or Ollama) are ideal for high-frequency, lower-complexity tasks like log parsing, inference serving, and research summarization. The cost savings of running Tier 3 workers on local models are significant when those tasks run continuously.

Configure heartbeats for every agent. A simple "I'm alive" signal every 60 seconds lets `ops-commander` detect failures within two minutes. Without heartbeats, you discover a dead agent only when its work stops appearing -- which could be hours later.

---

## 3. Spec-First Development

Every non-trivial change should start with a spec, not code. This is the single practice that most dramatically improves agent output quality.

**Why specs first?** Agents are excellent executors but mediocre requirement-gatherers. When you hand an agent a vague request like "set up monitoring," you get whatever the model's training data considers default monitoring. When you hand it a spec that says "install Prometheus on port 9090, scrape these 4 endpoints at 15s intervals, alert via Telegram when CPU exceeds 85% for 5 minutes," you get exactly what you need.

**Using the template**: The repo includes `specs/_TEMPLATE_spec.md`. Copy it for each new feature or change. The template captures the problem, proposed solution, acceptance criteria, and affected systems. The critical section is acceptance criteria -- these are the conditions the Governor checks to verify the work is done correctly.

**The workflow in Claude Code:**

1. Identify the need (from monitoring, user request, or incident).
2. Copy the spec template: `cp specs/_TEMPLATE_spec.md specs/NNN_feature_name.md`
3. Fill in the spec with concrete details, constraints, and acceptance criteria.
4. Hand the spec to the appropriate agent via `ops-commander`.
5. The agent executes against the spec.
6. The Governor verifies each acceptance criterion.

**When to skip specs**: Simple, obvious fixes that take less than five minutes and have no architectural impact. Restarting a crashed service, fixing a typo in a config, updating a package version. If you're asking "should I write a spec for this?" the answer is usually yes -- the question itself suggests enough complexity to warrant one.

Specs also create an invaluable audit trail. Six months from now, when you're wondering why the firewall rules look the way they do, you can trace back to `spec_042_firewall_hardening.md` and see the reasoning, constraints, and approval history. This institutional memory is priceless.

---

## 4. Security Workflows

Security is not a one-time setup -- it's a continuous practice. The Governor template includes workflows for ongoing security management.

**Initial baseline audit**: When you first deploy the Governor to a new target machine, run a full security audit. This is `sec-sentinel`'s first job. It should check: open ports, running services, firewall rules, SSH configuration (key-only auth, no root login), user permissions, installed packages with known CVEs, file permissions on sensitive directories, and cron jobs. The output becomes your baseline in `audit_logs/`.

**Ongoing security checks** should run on a weekly cadence at minimum. Configure a recurring task where `sec-sentinel` performs a focused scan. Each week, rotate through these areas:

- Week 1: Package CVE scan (check installed packages against vulnerability databases)
- Week 2: Access control review (who has sudo, SSH keys, service accounts)
- Week 3: Network exposure scan (open ports, listening services, firewall rules)
- Week 4: Log review (auth failures, unusual patterns, privilege escalations)

**Incident response** follows the workflow in `.agent/workflows/incident_response.md`. The key principle: contain first, investigate second, remediate third. When `sec-sentinel` or `log-parser` detects something suspicious, the immediate action is containment (block the IP, disable the account, stop the service), not investigation. You can investigate at leisure once the threat is contained.

**Patch management** should be systematic, not reactive. Use the workflow in `.agent/workflows/patch_management.md`. `web-scout` monitors for new CVEs relevant to your stack. When a critical patch drops, `sec-sentinel` assesses impact, `deploy-chief` plans the rollout, and `ops-commander` coordinates the execution. Test on a staging environment if possible; roll back immediately if anything breaks.

**Access control hardening** is often overlooked after initial setup. Review quarterly: remove unused SSH keys, rotate service account credentials, audit sudo access, check for world-readable files containing secrets. Every access point is a potential attack surface.

---

## 5. Self-Correcting Agent Memory

The most powerful feature of this template is the self-correction loop. Every mistake the system makes becomes a permanent rule that prevents repetition.

**The CLAUDE.md lessons table** is the primary mechanism. When the Governor or any agent makes an error -- misreads a log, uses the wrong command, forgets a step -- add a row to the lessons table immediately. The format is simple:

| # | Date | Lesson | Rule |
|---|------|--------|------|
| 1 | 2025-01-15 | Forgot to check disk space before large download | Always verify 2x required disk space before any download operation |

The "Rule" column is critical. It's not a description of what went wrong -- it's an imperative instruction that prevents recurrence. Write it as a command the agent must follow. Claude reads CLAUDE.md at the start of every session, so these rules accumulate into an increasingly robust operating manual.

**`active_state.md`** serves as working memory. It tracks what the Governor is currently doing, what tasks are assigned to which agents, and what's pending verification. Think of it as the Governor's scratchpad. It should be updated frequently and reviewed at the start of every session to resume context.

**`failures.md`** is institutional memory for larger incidents. When something goes seriously wrong -- a service outage, a security incident, a botched deployment -- write a post-mortem in `failures.md`. Include what happened, why it happened, what the impact was, and what permanent changes were made to prevent recurrence. This file becomes increasingly valuable over time as it captures hard-won operational knowledge.

The compounding effect is remarkable. After a few weeks, your CLAUDE.md might have 20-30 lessons. After a few months, it has 100+. Each one represents a mistake that will never happen again. The system literally gets better every time it fails. No human team achieves this level of consistent learning because humans forget -- these rules persist.

---

## 6. Escalation Protocols

Well-designed escalation prevents both dangerous autonomous action and unnecessary human interruption.

**Design your escalation chain** explicitly. Not every issue needs to reach the human operator. A crashed service that can be safely restarted? `ops-commander` handles it. A security alert that might be a false positive? `sec-sentinel` investigates and reports findings to `ops-commander`. A failed deployment that requires rollback? `deploy-chief` rolls back and notifies. Only genuinely ambiguous situations, destructive actions, or novel problems should reach the human.

**When agents should escalate vs. act autonomously:**

| Situation | Action |
|-----------|--------|
| Service crashed, known restart procedure | Act autonomously, log the event |
| Disk space low, safe cleanup targets exist | Act autonomously, notify after |
| Unknown process consuming resources | Escalate -- could be legitimate or malicious |
| Security alert from monitoring | Contain autonomously, escalate for investigation |
| Needs sudo for a new operation | Escalate -- never assume sudo authority |
| Spec is ambiguous or contradictory | Escalate -- don't guess at requirements |

**Notification channel discipline**: Only `ops-commander` and `alert-relay` should communicate with the human operator. If `log-parser` detects an anomaly, it reports to `ops-commander`, which decides whether the human needs to know. This prevents notification fatigue. If every agent can ping your Telegram, you'll quickly start ignoring all messages -- including critical ones.

**Approval-gated operations** are any actions that are destructive, irreversible, or require elevated privileges. Deleting data, modifying firewall rules, updating DNS records, running commands as root -- these all require explicit human approval. The agent should present the exact command it wants to run, explain why, and wait for a "yes" before proceeding. Never batch approval-gated operations; each one gets individual review.

---

## 7. Monitoring & Recovery

Monitoring is your early warning system. Without it, you discover problems from users complaining, not from your agents catching issues proactively.

**Health check patterns:**

- **Heartbeat**: Each agent sends a periodic "alive" signal. If two consecutive heartbeats are missed, `ops-commander` investigates. This catches agent crashes and hangs.
- **Watchdog**: A lightweight process monitors the inference server (LM Studio, Ollama, vLLM). If the server becomes unresponsive, the watchdog restarts it and notifies `ops-commander`.
- **Probe**: Active checks that verify functionality, not just availability. Don't just check that port 1234 is open -- send a test inference request and verify the response is coherent. A service can be "up" but functionally broken.

**Multi-layer monitoring** catches different classes of failure:

1. **Infrastructure**: CPU, memory, disk, GPU utilization, temperatures
2. **Service**: Is the inference server responding? Is the gateway routing correctly?
3. **Application**: Are agent outputs meeting quality thresholds? Are tasks completing in expected timeframes?
4. **Security**: Auth failures, unusual network traffic, file integrity changes

**Machine recovery runbook**: Document your recovery procedure for total machine failure. What's the boot order? Which services need to start first? Where are the backups? How long does full recovery take? Write this down before you need it. When your server is down at 2 AM, you want a checklist, not a puzzle.

**Graceful degradation**: Design your system to function with reduced capability rather than failing completely. If the GPU goes down, can agents fall back to CPU inference with a smaller model? If the internet drops, can local agents continue operating? If `sec-sentinel` crashes, does `ops-commander` take over basic security checks? Plan for partial failures because they're far more common than total failures.

---

## 8. Operational Tips

These are lessons from running the Governor pattern in production:

**Keep the Governor repo clean.** This repo should contain specs, audit logs, agent configs, and operational memory. It should not contain application code, container images, or large data files. If you find yourself committing Python scripts or Dockerfiles here, you're violating the separation of concerns. Application code belongs on the target machine, in the agents' workspaces.

**Domain knowledge belongs in the agent that owns it.** `sec-sentinel` should know about CVE databases and hardening techniques. `deploy-chief` should know about your CI/CD pipeline and rollback procedures. Don't centralize all knowledge in `ops-commander` -- that creates a bottleneck and bloats its context window. Each agent should be an expert in its domain.

**Verify output, not just status codes.** "Exit code 0" doesn't mean the operation succeeded correctly. A deployment script can exit cleanly while deploying the wrong version. A security scan can complete without actually scanning everything. Read the actual output. Compare it against expected behavior. This is the Governor's primary responsibility.

**When in doubt, re-plan.** If execution is going sideways -- tests are failing unexpectedly, outputs look wrong, the approach feels hacky -- stop and re-plan. The cost of re-planning is minutes. The cost of pushing through a bad plan is hours of debugging and cleanup. Enter plan mode in Claude Code, reassess the situation, and chart a new course.

**Don't over-architect.** Three well-configured agents covering your actual needs beats ten agents where half are idle and the other half are stepping on each other. Every agent adds coordination overhead. Start with the minimum viable hierarchy (orchestrator + 1-2 workers), operate it for a week, and add agents only when you identify concrete gaps. The goal is effective infrastructure management, not an impressive org chart.

**Rotate your attention.** It's easy to focus on the exciting parts (new features, new agents) and neglect the mundane but critical parts (log review, backup verification, access audits). Set a weekly cadence where you review each operational area, even if just for five minutes. The vulnerabilities you catch during routine review are the ones that would have become incidents.

**Document decisions, not just actions.** When you make a non-obvious choice (using port 18789 instead of 8080, choosing Tailscale over WireGuard, running two inference servers instead of one), write down why. Future-you will thank present-you when revisiting these decisions months later.
