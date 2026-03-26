# scripts/examples/

Example scripts and systemd units based on a real deployment. The Governor copies, customizes, and deploys these — you don't touch them directly.

## How It Works

These files contain `{{PLACEHOLDER}}` tokens. The Governor substitutes real values during deployment using the machine's `.env` or active state config.

## Files

| File | Purpose |
|------|---------|
| `watchdog-healthcheck.sh` | Checks services and disk usage; appends to state log |
| `watchdog-healthcheck.timer` | Systemd timer to run the healthcheck on a schedule |
| `openclaw-gateway.service` | User-level systemd unit for the OpenClaw gateway process |
| `local-inference.service` | User-level systemd unit for local LLM inference (LM Studio, Ollama, or vLLM) |
| `backup.sh` | Rsync-based backup of configs and agent state to a NAS |

## Placeholders

| Placeholder | Description |
|-------------|-------------|
| `{{USERNAME}}` | Linux username on the target machine |
| `{{AGENT_MAIN}}` | Primary agent name (used for log dirs and labels) |
| `{{GATEWAY_PORT}}` | Port the OpenClaw gateway listens on |
| `{{MODEL_DIR}}` | Mount path or directory where model files live |
| `{{NAS_HOST}}` | Hostname or IP of the backup NAS |
| `{{BACKUP_PATH}}` | Root path on the NAS for backups |
| `{{INFERENCE_HOST}}` | Host/port of the local inference server |
