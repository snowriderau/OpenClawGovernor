---
description: Take a spec and add or improve a feature - audit existing work, evolve the spec, then implement.
---

# /update_feature - Improve an Existing Feature

> This is NOT `/new_feature`. A spec already exists. Read it, understand what's built, then extend it.

---

## Phase 1: Get Context

### 1.1 Read the Spec
```bash
cat .agent/product/specs/<FEATURE_ID>_*.md
```

### 1.2 Read System State
```bash
cat .agent/product/feature_map.md
cat .agent/memory/active_state.md
```

### 1.3 Understand What's Built
Search for key files. Don't over-research; get oriented.

---

## Phase 2: Evolve the Spec

### 2.1 Append an Update Section
Edit the spec and add below existing content:

```markdown
## Update: <YYYY-MM-DD> - <Brief Title>

> **Status:** In Progress
> **Triggered by:** <user request / bug / improvement>

### What's Changing
<What's being added or improved>

### Implementation Tasks
1. <Task>
2. <Task>

### Verification
- <How to test it works>
```

Don't delete anything — old content is decision history.

### 2.2 Update Feature Map
Set status to In Progress in `.agent/product/feature_map.md`.

### 2.3 Get User Approval
**STOP.** Show the updated spec. Wait for approval.

---

## Phase 3: Build

### 3.1 Follow Dependency Order
1. Schema/data changes first
2. Server/API second
3. Shared types third
4. Client/UI last

### 3.2 Verify
- Check existing spec verification still passes (regression)
- Check new verification from the Update section

---

## Phase 4: Complete

### 4.1 Update Status
- Feature → Done in `feature_map.md`
- Task → Completed in `task_queue.md` (if applicable)

### 4.2 Run /success
Commit and document.

---

## When to Use This vs /new_feature

| Scenario | Use |
|----------|-----|
| No spec exists | `/new_feature` |
| Spec exists, extending or fixing | `/update_feature` |
| Spec exists but needs total redesign | `/new_feature` |
