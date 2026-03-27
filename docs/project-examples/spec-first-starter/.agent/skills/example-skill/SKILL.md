# Example Skill

Skills are reusable agent knowledge — reference material that agents load when working on specific tasks.

## When to Use

Place domain-specific reference material here. Examples:
- API documentation for a service you integrate with
- Configuration reference for a framework
- Deployment runbooks for specific environments

## Structure

Each skill is a directory under `.agent/skills/` with a `SKILL.md` file.

```
.agent/skills/
  my-api/
    SKILL.md          # Reference docs, commands, gotchas
  deployment/
    SKILL.md          # Deploy procedures and rollback steps
```
