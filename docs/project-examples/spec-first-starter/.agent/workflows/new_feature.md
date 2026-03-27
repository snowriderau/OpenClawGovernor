---
description: Start a new feature implementation with the correct design-first approach
---

# /new_feature - Spec-Driven Feature Workflow

> **CRITICAL:** Do NOT start coding before completing the Design phase.
> Building without specs leads to wasted effort and rework.

---

## Phase 1: Understand (Before Anything Else)

### 1.1 Read Context
```bash
cat .agent/product/feature_map.md
cat .agent/memory/task_queue.md
```

### 1.2 Check for Existing Spec
Look for a spec linked in the feature map. If one exists:
```bash
cat .agent/product/specs/<FEATURE_ID>_*.md
```

**If spec exists:** Skip to Phase 3 (Implementation)
**If no spec:** Continue to Phase 2 (Design)

---

## Phase 2: Design (Spec-First Approach)

> "What UX do we need? Work backward to data requirements."

### 2.1 Mock the UX First
Before writing any code, visualize what the user sees:
- Generate mockup images for UI components
- Document the user interaction flow
- Define what data appears where

### 2.2 Define Data Requirements
Work backwards from the UX:
- What data does the UI need?
- Where does that data come from?
- What queries/APIs are required?
- What tables/schemas support those queries?

### 2.3 Create Spec Document
Write spec to `.agent/product/specs/<FEATURE_ID>_<name>.md`:

Use the template at `.agent/product/specs/_TEMPLATE_spec.md` as a starting point.

### 2.4 Update Feature Map
Add/update the feature in `.agent/product/feature_map.md` with spec link.

### 2.5 Get User Approval
**STOP HERE.** Present spec to user and wait for approval before coding.

---

## Phase 3: Implementation

Only proceed after spec is approved.

### 3.1 Review Architecture
```bash
cat .agent/product/architecture.md
```

### 3.2 Follow Spec Tasks
Implement each task listed in the spec document.

### 3.3 Verify Against Spec
Run the verification steps defined in the spec.

---

## Phase 4: Complete

### 4.1 Update Status
- Mark feature as Done in feature map
- Move task to Completed in task queue

### 4.2 Run /success
Commit and document the work.

---

## Anti-Patterns to Avoid

| Wrong | Right |
|-------|-------|
| Start coding immediately | Mock UX first |
| Store everything "just in case" | Store only what UX needs |
| Build then ask what user wants | Ask first, then build |
| Huge batch of changes | Small, verifiable increments |
