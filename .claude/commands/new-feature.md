---
description: Architect and build a new feature — plugins, config tools, governance tooling, or dispatch app features through PM.
---

# New Feature

Build something new. System/infra features → Governor builds directly. Application features → write spec, dispatch through PM.

## Phase 1: Understand

1. Check `feature_map.md` — does this already exist? If so → `/update-feature`
2. Check `specs/` — is there a spec already?
3. Determine scope: **system** (plugin, config, monitoring) or **application** (user-facing app feature)

## Phase 2: Design

1. Enter plan mode for non-trivial features
2. Write spec at `specs/FEAT-XXX_<name>.md`
3. Add entry to `feature_map.md` with spec link
4. Get approval before implementation

**Application features:** Spec is the deliverable. PM dispatches agents to build it.
**System features:** Proceed to Phase 3.

## Phase 3: Implement (system features only)

1. Record in `active_state.md` → Current Task
2. Follow implementation pipeline: implement → validate → verify
3. Show evidence that it works (logs, test output, config readback)

## Phase 4: Finalize

Run `/success` to commit, update docs, and wrap up.

---

The feature: $ARGUMENTS
