# TASKS.md — Forge

## Now

- [ ] Example: [dispatched by Conductor] Implement rate limiting on the home dashboard API — spec at `{{PROJECTS_DIR}}/home-dashboard/.agent/product/specs/FEAT-002_rate-limit.md`

## Next

- [ ] Example: Migrate home dashboard from uvicorn to gunicorn with worker processes
- [ ] Example: Add health check endpoint `/health` to all managed services

## Later

- [ ] Example: Write deployment runbook template for future projects
- [ ] Example: Containerize inference server wrapper script

## Done

- [x] Example: [dispatched by Atlas] Fixed 502 on home dashboard — uvicorn process had crashed, restarted and added memory limit to systemd unit (2026-01-01)
- [x] Example: [dispatched by Conductor] Initial home dashboard deployment — FastAPI + Jinja2, systemd service, :{{DASHBOARD_PORT}} (2026-01-01)

---

_Work arrives via sessions_spawn from Atlas or Conductor. Complete and return results. Include: what you found, what you changed, how to verify it._
