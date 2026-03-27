# Project Structure Examples

> For initial setup, see [INSTALL.md](../../INSTALL.md).

Example project layout for repos that your OpenClaw agent fleet works on. This follows the **spec-first-starter** pattern — the same template used in production.

---

## What's Here

| Directory | Description |
|-----------|-------------|
| `spec-first-starter/` | Canonical project template — copy `.agent/` into any project to get spec-driven development |

## How Projects Work

Every project your agents build follows the spec-first pattern:

1. **Discovery** — `/discovery` workflow initializes vision, personas, requirements
2. **Spec** — `/new_feature` writes a spec before any code
3. **Implement** — code follows the spec's tasks and verification criteria
4. **Loop** — `/loop` enables autonomous task queue execution
5. **Finalize** — `/success` commits, updates living docs, evolves the spec into reference documentation

The PM agent (Conductor) manages the task flow across projects — scanning queues, spawning agents for implementation, and following up on results.

## Structure

```
your-project/
  CLAUDE.md                         # Project-level agent instructions
  .agent/
    README.md                       # Quick navigation index
    product/
      problem.md                    # Vision, audience, constraints
      users.md                      # Target personas
      requirements.md               # Functional & non-functional requirements
      architecture.md               # Technical blueprint
      feature_map.md                # Feature inventory with status
      specs/
        _TEMPLATE_spec.md           # Spec template for new features
    memory/
      active_state.md               # Current context & decisions
      task_queue.md                 # Claimable work items
      backlog.md                    # Future work
      failures.md                   # Failure log for learning
    workflows/
      discovery.md                  # /discovery — init project
      new_feature.md                # /new_feature — spec-first dev
      update_feature.md             # /update_feature — evolve specs
      loop.md                       # /loop — autonomous execution
      success.md                    # /success — finalize & commit
    skills/                         # Reusable agent knowledge
  src/                              # Your application code
  tests/                            # Test suite
```

## How to Use

1. Copy `spec-first-starter/.agent/` into your project root
2. Copy `spec-first-starter/CLAUDE.md` into your project root
3. Run the `/discovery` workflow to initialize product definition
4. Fill in product docs (problem, users, requirements, architecture, feature_map)
5. Queue initial tasks in `task_queue.md`
6. Use `/new_feature` for new specs, `/loop` for autonomous execution

## Key Principles

- **Spec first** — never code without a spec. Design first, build second.
- **Living docs** — specs describe what is currently built, not stale plans. After implementation, `/success` rewrites the spec as reference documentation.
- **Multi-agent safe** — task claiming prevents conflicts in parallel execution.
- **Failures are learning** — every mistake becomes a documented prevention rule.
