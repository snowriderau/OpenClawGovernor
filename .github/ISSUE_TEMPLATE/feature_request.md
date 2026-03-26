---
name: Feature request
about: Propose an improvement or addition to the Governor template
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

## What do you want to do?

Describe the capability you're trying to add. Focus on the outcome, not the implementation. "I want to be able to tell the Governor to set up a daily digest agent" is more useful than "add a cron job."

## How does this fit the Governor pattern?

The Governor template is built around a specific architecture: agents are domain-locked, config is written by the Governor not the user, and the system is self-correcting. Where does your feature fit?

- [ ] New agent type — what domain? what tier (orchestrator / director / worker)?
- [ ] New workflow — what trigger? what outcome?
- [ ] New spec — what setup task does it automate?
- [ ] Something else — explain below

## What form would this take?

- [ ] A Governor slash command (`.claude/commands/`)
- [ ] A workspace example (`docs/workspace-examples/`)
- [ ] A spec template (`specs/`)
- [ ] A change to `init.sh`
- [ ] Other

## Why isn't this already handled?

Is there a gap in the current template, or a pattern that's missing? If there's a workaround, describe it — that context helps evaluate the request.

## Additional context

Anything else that would help — examples from other systems, related issues, constraints to be aware of.
