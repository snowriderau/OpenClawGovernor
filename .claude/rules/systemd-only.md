# Systemd-Only Service Management

NEVER use `kill`, `pkill`, or signal-based process management for services that have systemd units.

Always use:
- `systemctl --user restart <service>` (not kill + wait for auto-restart)
- `systemctl --user stop <service>` (not kill)
- `systemctl --user status <service>` (not ps aux | grep)

Requires these env vars (added to .bashrc):
```
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus
```

Why: Killing processes directly orphans them from the supervisor. If the bare process then dies (crash, power loss, OOM), nothing restarts it. Systemd handles restart, logging, env vars, and secret injection.
