---
description: Evolve an existing feature — update config, improve behavior, fix regressions.
---

# Update Feature

Improve or change an existing feature.

## Phase 1: Understand

1. Read the spec from `specs/` for `$ARGUMENTS`
2. Check `feature_map.md` for current status
3. Verify current state on the machine (read config, check service, test endpoint)

## Phase 2: Plan

1. Define what's changing — scope it clearly
2. Update the spec if the design is changing
3. For non-trivial changes: enter plan mode, get approval

## Phase 3: Implement

1. Record in `active_state.md` → Current Task
2. Follow implementation pipeline: implement → validate → verify
3. Show evidence (config diff, test output, log entry)

## Phase 4: Finalize

Run `/success` to commit, update docs, and wrap up.

---

The feature to update: $ARGUMENTS
