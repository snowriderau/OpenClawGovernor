---
name: Agent workspace example
about: Contribute a new agent workspace example to docs/workspace-examples/
title: '[AGENT EXAMPLE] '
labels: agent-example
assignees: ''
---

## Agent name and tier

**Name:** e.g. Sentinel

**Tier:**
- [ ] Orchestrator — coordinates the fleet, never executes directly
- [ ] Director — owns a domain, can dispatch workers
- [ ] Worker — executes tasks, no access to broader context

## Domain

What does this agent do? Be specific about the problem space.

e.g. "Security monitoring — watches system logs, alerts on anomalies, runs nightly permission audits."

## Workspace files included

Which files are you contributing? Check all that apply.

- [ ] `IDENTITY.md` — who the agent is and what it's responsible for
- [ ] `TOOLS.md` — tool permissions and constraints
- [ ] `INSTRUCTIONS.md` — operating procedures and decision rules
- [ ] `SPAWN_RULES.md` — when and how the agent launches workers
- [ ] `ESCALATION.md` — what triggers escalation to the orchestrator

## Design decisions worth noting

Are there any non-obvious choices in this workspace — tool restrictions, escalation thresholds, domain boundaries — that someone adapting this should understand?

## Real deployment tested

- [ ] Yes — I've run this agent in a live setup and it behaves as described
- [ ] Partially — tested some functions but not exhaustively
- [ ] No — this is a draft based on the architecture pattern

If tested: what hardware/model configuration did you use?

## Additional context

Related agents this example works alongside, known limitations, or setup steps required before deploying.
