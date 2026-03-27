---
description: Commit work, update docs, and capture learnings on successful feature completion
---

# /success - Finalize Feature Workflow

Run this workflow when a feature or fix is complete and working.

---

## 1. Review Changes

```bash
git status
```

---

## 2. Quick Architecture Check

Before committing, verify against your core architectural principles. Note any violations in `.agent/memory/failures.md`.

---

## 3. Stage & Commit

```bash
git add -A
git commit -m "feat: <DESCRIBE_WHAT_WAS_ACCOMPLISHED>"
```

**Prefixes:** `feat:` | `fix:` | `refactor:` | `docs:` | `data:` | `chore:`

---

## 4. Update Task Queue (FOR /loop)

If running in autonomous loop mode, update `.agent/memory/task_queue.md`:
1. Move completed task to `## Completed` section with date
2. Clear the "Claimed By" field

---

## 5. Update Feature Map

Mark the feature as Done in `.agent/product/feature_map.md`.

---

## 6. Update Feature Spec

**Specs are living documents, not throwaway planning artifacts.** They serve as the permanent documentation for each feature and MUST describe what is currently in production.

If the completed work has a spec in `.agent/product/specs/`:

1. **Set status** to `Done (YYYY-MM-DD)` or `Living Reference`
2. **Rewrite the document** to act as a complete specification of what is actually built and running
3. **Delete outdated planning sections.** If a feature changed during implementation, rewrite so it describes what exists now
4. **Do NOT append an "Implementation Outcomes" log.** This is not a change tracker; it is a source of truth
5. If there are future ideas, put them in a dedicated `Future Enhancements` section

> A spec goes from "what we plan to build" → "how it currently works in production." Future agents use specs as reference manuals, so outdated plans cause bad follow-on work.

---

## 7. Quick Doc Updates

| Changed | Update |
|---------|--------|
| Architecture | `.agent/product/architecture.md` |
| New commands | `README.md` |
| Learnings | `.agent/memory/active_state.md` |

---

## 8. Commit Docs

```bash
git add -A && git commit -m "docs: update after <feature>"
```

---

## 9. Final Check

```bash
git status && git log --oneline -3
```

**For /loop:** After this, return to loop and pick next task.
