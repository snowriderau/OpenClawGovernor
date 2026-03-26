<!-- TEMPLATE: Fill in the sections below to match your infrastructure. -->
<!-- Remove this comment block when your architecture is finalized.      -->

# Architecture

## Overview

This system uses the **Governor pattern**: a Claude Code session on a development machine (the Governor) coordinates a fleet of OpenClaw agents running on a target Linux machine over SSH.

The Governor never executes code on the target directly. It reads logs, verifies output, and assigns work through structured task files. Agents execute autonomously within their defined scope and escalate when blocked.

## System Boundaries

| Layer | Location | Responsibility |
|-------|----------|---------------|
| Governor | Dev machine (this repo) | Planning, oversight, spec management, state tracking |
| Agent Runtime | Target machine (OpenClaw) | Task execution, service management, local inference |
| Infrastructure | Target machine (OS/hardware) | Compute, storage, networking, GPU resources |

## Communication

- **Governor → Agents:** SSH (read task files, push assignments, read logs)
- **Agents → Governor:** File-based state (TASKS.md, status files)
- **Agents → User:** Notification channels (Telegram, Slack, email)
- **Agents → Agents:** OpenClaw RPC (inter-agent messaging within the runtime)

## Key Decisions

1. **No application code in this repo.** This repo is pure governance. Code lives on the target.
2. **SSH as the control plane.** Simple, auditable, no custom protocols.
3. **File-based state.** Agents read/write markdown files. No database required.
4. **Spec-first workflow.** Every non-trivial change starts as a spec before implementation.

## Diagram

See `docs/architecture-diagram.svg` for the visual representation.
