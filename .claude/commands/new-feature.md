---
description: Implement a new maintenance feature (backup, watchdog, hardening, etc.)
---

# New Feature Workflow

Implement a new maintenance feature following spec-first approach.

## Phase 1: Understand

1. **Read the specs:**
   - Check `specs/` — does a spec already exist?
   - Check `feature_map.md` — what's in scope?
   - Read `requirements.md` — constraints and dependencies

2. **Check task queue:**
   - Is this in `.agent/memory/task_queue.md`?
   - Any blockers in `.agent/memory/failures.md`?

## Phase 2: Design (NO CODING YET)

1. **Mock the behavior** — what does this feature do? What's the step-by-step workflow?
2. **Define requirements** — what data/tools/permissions are needed?
3. **Write the spec** — copy `specs/_TEMPLATE_spec.md` to a new file:
   ```
   specs/FEAT-XXX_<name>.md
   ```
4. **Update feature map** — add entry with spec link and status
5. **Get approval** before writing any code

## Phase 3: Implement

1. **Follow operational rules** — read `architecture.md`
2. **Create checkpoint:**
   ```bash
   git add -A && git commit -m "checkpoint: before FEAT-XXX_<name>"
   ```
3. **Implement per spec** — follow spec tasks and acceptance criteria
4. **Test on the machine** — verify via SSH

## Phase 4: Finalize

Run `/success` to commit, update docs, and wrap up.

---

The feature to implement: $ARGUMENTS
