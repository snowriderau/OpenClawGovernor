---
description: Create and execute a targeted task against an existing feature. Looks up the feature map and specs for context, then does the work. Suggests /new-feature if nothing in scope matches.
---

# Create Task

A lightweight command for targeted tasks against existing features. No design phase, no spec-first — just look up context and do the work.

## Step 1: Load Context

Read these files to understand current state:
- `feature_map.md` — what exists and its completion status
- `.agent/memory/task_queue.md` — what's already queued
- `.agent/memory/active_state.md` — what's in progress

## Step 2: Match Task to Feature

Scan the feature map for features related to the task in `$ARGUMENTS`.

**If no existing feature matches:**
> This task looks like new functionality. Use `/new-feature` instead so a spec can be written first.

Stop here. Do not proceed.

**If a matching feature exists:**
- Read its spec from `specs/` (link is in the feature map)
- If no spec exists yet, use the feature map entry and task queue description as context
- Note the feature's current completion status (which items are `[x]` vs `[ ]`)

## Step 3: Record in Active State

Before doing any work, update `.agent/memory/active_state.md`:
- Add the task to **"Current Task"** with a short description, the matched feature/spec, and a timestamp
- This ensures there's always a record of what's in progress — even if the session is interrupted

## Step 4: Do the Task

Execute the task using the spec context. Follow the operating principles in `CLAUDE.md`:
- Execute autonomously — the architecture (tiered agents, domain isolation) is the guardrail
- Keep changes targeted — only what the task requires

## Step 5: Post-Completion Check

After the task is done:

1. **Update active state** — move the task from "Current Task" to "Completed Today" in `.agent/memory/active_state.md`

2. **Assess feature impact:**

   **If the task completes or advances a feature item** (e.g., a `[ ]` item is now done):
   > Task complete. This updates the state of [feature name]. Run `/success` to commit, mark the feature map, and sync docs.

   **If the task was purely operational** (log check, report, config read, etc.) with no feature state change:
   > Task complete. No spec updates needed.

---

Task: $ARGUMENTS
