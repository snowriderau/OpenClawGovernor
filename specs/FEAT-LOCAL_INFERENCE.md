# FEAT-LOCAL_INFERENCE: Local Inference Server

## Overview
**Feature ID:** FEAT-LOCAL_INFERENCE
**Title:** Local AI Inference Server
**Status:** Draft — choose one option for your environment
**Last Updated:** YYYY-MM-DD

## Why Local Inference Matters (Security + Cost)

Cloud models ({{PRIMARY_MODEL}}, etc.) never touch actual data — files, credentials, network configs, security rules. Local models handle those touchpoints because the data never leaves the machine. This is about **security AND cost**: sensitive data stays local, and cloud API costs drop for high-volume compute tasks.

In the OpenClaw Governor architecture, the Bolt agent (local GPU worker) uses the local inference server exclusively. When Forge needs to analyze config files, process credentials, or work with anything sensitive, it dispatches to Bolt — which runs against the local model, air-gapped from cloud APIs. Bolt also handles compute-heavy tasks where running the same workload against a cloud API would be expensive.

The local inference server needs to:
- Auto-start on boot
- Auto-restart on crash
- Expose an OpenAI-compatible API at `http://127.0.0.1:{{LOCAL_INFERENCE_PORT}}/v1`
- Be available before Openclaw starts

---

## Option Comparison

| | LM Studio | Ollama | vLLM |
|--|-----------|--------|------|
| **Best for** | GUI + headless, easy model management | CLI-first, quick setup, easy model pull | Production serving, multi-GPU, high throughput |
| **Install method** | AppImage or native installer | Single install script | Python package (pip) |
| **Model management** | GUI + `lms` CLI | `ollama pull <model>` | Download manually or via HF |
| **API compatibility** | OpenAI-compatible (port 1234) | OpenAI-compatible (port 11434) | OpenAI-compatible (configurable port) |
| **GPU support** | NVIDIA + AMD + Apple Silicon | NVIDIA + AMD + Apple Silicon | NVIDIA (primary), AMD (experimental) |
| **Headless service** | `--headless` flag or `lms server start` | Runs headless by default | Python process |
| **Complexity** | Low | Very low | Medium-High |
| **Best model formats** | GGUF | GGUF | GGUF, AWQ, GPTQ, safetensors |

**Recommendation by use case:**
- First-time setup or GUI needed: **LM Studio**
- Simple CLI, fastest setup: **Ollama**
- High throughput, production, multiple agents: **vLLM**

---

## Option A: LM Studio

### Install
```bash
# Linux: Download AppImage from https://lmstudio.ai
wget https://releases.lmstudio.ai/linux/x86_64/LM-Studio-<VERSION>-x64.AppImage -O {{MODEL_DIR}}/LM-Studio.AppImage
chmod +x {{MODEL_DIR}}/LM-Studio.AppImage

# macOS: Download .dmg from https://lmstudio.ai and install normally

# Install lms CLI (inside LM Studio GUI: Settings → Enable CLI)
# Or via AppImage mount:
# ~/.lmstudio/bin/lms
```

### Model Setup
```bash
# Download a model (via CLI once installed)
~/.lmstudio/bin/lms get <model-name>

# Or place GGUF files directly in:
# {{MODEL_DIR}}/models/
```

### systemd Service (`/etc/systemd/system/local-inference.service`)

**Option 1: Using lms CLI (recommended)**
```ini
[Unit]
Description=LM Studio Inference Server
After=network.target
Wants=network.target

[Service]
Type=simple
User={{USERNAME}}
Group={{USERNAME}}
Environment=HOME=/home/{{USERNAME}}
WorkingDirectory=/home/{{USERNAME}}
ExecStart=/home/{{USERNAME}}/.lmstudio/bin/lms server start --port {{LOCAL_INFERENCE_PORT}}
Restart=always
RestartSec=15
StartLimitIntervalSec=120
StartLimitBurst=3
StandardOutput=append:/var/log/openclaw/local-inference.log
StandardError=append:/var/log/openclaw/local-inference-error.log
TimeoutStartSec=90
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
```

**Option 2: Headless AppImage**
```ini
[Service]
# ... (same Unit/Install sections)
ExecStart={{MODEL_DIR}}/LM-Studio.AppImage --no-sandbox --headless
```

Note: Headless flag behavior varies by version. Prefer the `lms` CLI method once installed.

### Health Check
```bash
curl -sf http://127.0.0.1:{{LOCAL_INFERENCE_PORT}}/v1/models > /dev/null && echo "UP" || echo "DOWN"
```

### Key Settings (`~/.lmstudio/settings.json`)
```json
"enableLocalService": true,
"defaultContextLength": { "type": "custom", "value": 4096 },
"developer.appUpdateChannel": "stable"
```

### Provider Config (openclaw.json)
```json
{
  "id": "lmstudio",
  "type": "openai",
  "baseUrl": "http://127.0.0.1:{{LOCAL_INFERENCE_PORT}}/v1",
  "models": ["{{LOCAL_MODEL}}"]
}
```

---

## Option B: Ollama

### Install
```bash
# Single command install (Linux and macOS)
curl -fsSL https://ollama.com/install.sh | sh

# Or manual:
# https://github.com/ollama/ollama/releases
```

### Model Setup
```bash
# Pull a model
ollama pull {{LOCAL_MODEL}}

# List available models
ollama list
```

### systemd Service

Ollama installs its own systemd service (`ollama.service`) automatically. Verify and customize:

```ini
[Unit]
Description=Ollama Inference Server
After=network-online.target

[Service]
Type=simple
User={{USERNAME}}
Group={{USERNAME}}
Environment=HOME=/home/{{USERNAME}}
Environment=OLLAMA_HOST=127.0.0.1:{{LOCAL_INFERENCE_PORT}}
Environment=OLLAMA_MODELS={{MODEL_DIR}}/ollama-models
ExecStart=/usr/local/bin/ollama serve
Restart=always
RestartSec=10
StartLimitIntervalSec=120
StartLimitBurst=3
StandardOutput=append:/var/log/openclaw/local-inference.log
StandardError=append:/var/log/openclaw/local-inference-error.log

[Install]
WantedBy=multi-user.target
```

Ollama's default port is `11434`. Set `OLLAMA_HOST` to use a custom port (e.g. `1234` for consistency).

### Health Check
```bash
curl -sf http://127.0.0.1:{{LOCAL_INFERENCE_PORT}}/api/tags > /dev/null && echo "UP" || echo "DOWN"
# OpenAI-compatible endpoint:
curl -sf http://127.0.0.1:{{LOCAL_INFERENCE_PORT}}/v1/models > /dev/null && echo "UP" || echo "DOWN"
```

### Provider Config (openclaw.json)
```json
{
  "id": "ollama",
  "type": "openai",
  "baseUrl": "http://127.0.0.1:{{LOCAL_INFERENCE_PORT}}/v1",
  "models": ["{{LOCAL_MODEL}}"]
}
```

---

## Option C: vLLM

### Install
```bash
# Requires Python 3.9+, CUDA toolkit installed (NVIDIA) or ROCm (AMD)
pip install vllm

# Or with specific CUDA version:
pip install vllm --extra-index-url https://download.pytorch.org/whl/cu121
```

### Model Setup
```bash
# Download model from HuggingFace (example)
# Models can be referenced by HF model ID directly
# Or downloaded to {{MODEL_DIR}}/

# Test locally:
python -m vllm.entrypoints.openai.api_server \
  --model {{LOCAL_MODEL}} \
  --port {{LOCAL_INFERENCE_PORT}} \
  --host 127.0.0.1
```

### systemd Service (`/etc/systemd/system/local-inference.service`)
```ini
[Unit]
Description=vLLM Inference Server
After=network.target
Wants=network.target

[Service]
Type=simple
User={{USERNAME}}
Group={{USERNAME}}
Environment=HOME=/home/{{USERNAME}}
Environment=CUDA_VISIBLE_DEVICES=0
WorkingDirectory=/home/{{USERNAME}}
ExecStart=/usr/local/bin/python -m vllm.entrypoints.openai.api_server \
    --model {{LOCAL_MODEL}} \
    --port {{LOCAL_INFERENCE_PORT}} \
    --host 127.0.0.1 \
    --max-model-len 4096 \
    --dtype auto
Restart=always
RestartSec=15
StartLimitIntervalSec=180
StartLimitBurst=3
StandardOutput=append:/var/log/openclaw/local-inference.log
StandardError=append:/var/log/openclaw/local-inference-error.log
TimeoutStartSec=120
TimeoutStopSec=60

[Install]
WantedBy=multi-user.target
```

### Health Check
```bash
curl -sf http://127.0.0.1:{{LOCAL_INFERENCE_PORT}}/v1/models > /dev/null && echo "UP" || echo "DOWN"
```

### Provider Config (openclaw.json)
```json
{
  "id": "vllm",
  "type": "openai",
  "baseUrl": "http://127.0.0.1:{{LOCAL_INFERENCE_PORT}}/v1",
  "apiKey": "not-needed",
  "models": ["{{LOCAL_MODEL}}"]
}
```

---

## Shared Setup (All Options)

### Log Directory
```bash
sudo mkdir -p /var/log/openclaw
sudo chown {{USERNAME}}:{{USERNAME}} /var/log/openclaw
sudo chmod 750 /var/log/openclaw
```

### Enable and Start Service
```bash
sudo systemctl daemon-reload
sudo systemctl enable local-inference
sudo systemctl start local-inference
```

### Verify API
```bash
# List loaded models
curl http://127.0.0.1:{{LOCAL_INFERENCE_PORT}}/v1/models | python3 -m json.tool

# Test inference
curl http://127.0.0.1:{{LOCAL_INFERENCE_PORT}}/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "{{LOCAL_MODEL}}",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 50
  }'
```

---

## Implementation Tasks

- [ ] Choose inference option (LM Studio / Ollama / vLLM)
- [ ] Install inference server
- [ ] Download target model to `{{MODEL_DIR}}/`
- [ ] Create `/var/log/openclaw/` log directory
- [ ] Create `/etc/systemd/system/local-inference.service`
- [ ] `sudo systemctl enable local-inference`
- [ ] `sudo systemctl start local-inference`
- [ ] Verify API responds at `:{{LOCAL_INFERENCE_PORT}}`
- [ ] Add to health check script
- [ ] Update Bolt agent config to point to local inference endpoint

---

## Acceptance Criteria

- [ ] Inference API responds at `http://127.0.0.1:{{LOCAL_INFERENCE_PORT}}/v1/models`
- [ ] `systemctl status local-inference` shows active
- [ ] Survives kill + auto-restarts within 30 seconds
- [ ] Starts automatically on boot (tested after reboot)
- [ ] Logs written to `/var/log/openclaw/local-inference.log`
- [ ] Bolt agent successfully routes inference requests to local endpoint
- [ ] Cloud providers cannot access local model data (loopback only)

---

## Notes

- The local inference server must start BEFORE Openclaw (see FEAT-OPENCLAW_setup.md systemd `After=` directive)
- GPU must be initialized before the inference server starts (nvidia-persistenced or equivalent handles this)
- Model loading happens after startup — first inference request may be slow while model loads into VRAM
- For GGUF models: context length is set at load time — plan your `--max-model-len` or LM Studio context length setting against available VRAM
- `{{GPU}}` VRAM determines max model size and context length — consult model card for recommendations
- Local inference reduces cloud API costs significantly for high-volume compute tasks — route repetitive or bulk operations through Bolt
