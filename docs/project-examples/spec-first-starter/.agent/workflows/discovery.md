---
description: Run discovery — initialise project vision, personas, and requirements
---

# Discovery — initialise project (vision, personas, requirements)

Help the user complete **problem.md**, **users.md**, and **requirements.md** using a lightweight, top-down discovery flow: start with vision and context, then who we're building for, then what we need to build.

Work through **one doc at a time**. Ask the user questions, then write or update the file together. Stay solution-agnostic where possible (describe needs and outcomes, not tech).

---

## 1. Vision & problem → `.agent/product/problem.md`

**Goal:** A shared vision and problem statement that act as a compass. Solution-agnostic: the "why", priorities, and what success looks like.

- **Problem statement:** What problem are we solving? Who feels it? Why do current options fall short?
- **Audience:** Primary and secondary user segments (high-level; personas come next).
- **Constraints:** Technical, legal, time, budget, platform — what's fixed?
- **Success definition:** 30 / 60 / 90 days (or similar): what does "done" look like at each milestone?
- **Non-goals:** What we are explicitly not building (scope boundaries).

Prompt the user for each section. Then update `.agent/product/problem.md` with their answers. Reference the vision later when checking requirements.

---

## 2. Personas → `.agent/product/users.md`

**Goal:** Key roles we're designing for: purpose, behaviour, pain points, and needs.

For each persona (start with one primary, then secondary if needed):

- **Role & behaviour:** What do they do today? What workarounds or tools do they use?
- **Pain points:** Quote-style frustrations; what's broken or painful?
- **Needs:** What must the product do for them? (Needs, not features.)

Ask the user to describe the main user type first; extract role, behaviour, pain points, and needs. Fill one persona in `.agent/product/users.md`, then offer to add another.

---

## 3. Requirements → `.agent/product/requirements.md`

**Goal:** Functional and non-functional requirements plus clear acceptance criteria.

- **Functional:** Group by area. 3-5 concrete requirements per area; only include what's in scope.
- **Non-functional:** Performance, reliability, data integrity, security — only what matters for this project.
- **Acceptance criteria:** 3-5 measurable conditions for "ready to ship".

Cross-check that requirements support the vision in `problem.md` and the needs in `users.md`.

---

## Flow summary

1. Run step 1 → complete **problem.md** (vision, problem, success, non-goals).
2. Run step 2 → complete **users.md** (personas, pain points, needs).
3. Run step 3 → complete **requirements.md** (functional, non-functional, acceptance criteria).

After all three are filled, suggest next steps: `.agent/product/architecture.md` and `.agent/product/feature_map.md`.
