# Local Inference Server Setup

## Overview
**Title:** Local Inference Server
**Author:** Claude / System Owner
**Status:** Template
**Last Updated:** 2026-03-26

## Problem
The agent system needs a local inference endpoint for on-device AI processing. Running models locally provides:
- Lower latency for frequent operations
- No per-token cloud costs
- Privacy for sensitive workloads
- Offline capability

## Goals
- Local inference server running on `{{GPU_MODEL}}` ({{GPU_VRAM}} VRAM)
- OpenAI-compatible API on port `{{INFERENCE_PORT}}`
- Auto-start via systemd
- Agent gateway can route requests to local models
- Health check integration with watchdog

## Out of Scope
- Cloud provider configuration (separate spec)
- Model fine-tuning
- Multi-GPU clustering

---

## Option A: LM Studio

LM Studio provides a GUI + headless server with OpenAI-compatible API. Good for easy model management.

### Install
```bash
# Download AppImage
wget -O {{MODEL_DIR}}/LM-Studio.AppImage \
    "https://releases.lmstudio.ai/linux/x86_64/LM-Studio-latest.AppImage"
chmod +x {{MODEL_DIR}}/LM-Studio.AppImage

# Install CLI (after first launch)
~/.lmstudio/bin/lms bootstrap

# Verify CLI
lms version
lms status
```

### Load a Model
```bash
# Search available models
lms search {{LOCAL_MODEL}}

# Download a model
lms get {{LOCAL_MODEL}}

# Start server with model loaded
lms server start --port {{INFERENCE_PORT}}

# List loaded models
lms ps
```

### systemd Service (headless)
```ini
[Unit]
Description=LM Studio Inference Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User={{USERNAME}}
WorkingDirectory={{MODEL_DIR}}
# xvfb-run enables headless operation (no display needed)
ExecStart=/usr/bin/xvfb-run --auto-servernum {{MODEL_DIR}}/LM-Studio.AppImage --no-sandbox
ExecStartPost=/bin/sleep 10
ExecStartPost=/home/{{USERNAME}}/.lmstudio/bin/lms server start --port {{INFERENCE_PORT}}
Restart=always
RestartSec=10
StartLimitIntervalSec=120
StartLimitBurst=3
Environment=HOME=/home/{{USERNAME}}
Environment=DISPLAY=:99
StandardOutput=append:/var/log/openclaw/lmstudio.log
StandardError=append:/var/log/openclaw/lmstudio-error.log
TimeoutStartSec=120
KillMode=process

[Install]
WantedBy=multi-user.target
```

### Health Check
```bash
curl -sf http://127.0.0.1:{{INFERENCE_PORT}}/v1/models | jq '.data[].id'
```

---

## Option B: Ollama

Ollama is a lightweight inference server optimized for ease of use. Good for quick setup.

### Install
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

### Pull and Run Models
```bash
# Pull a model
ollama pull {{LOCAL_MODEL}}

# List available models
ollama list

# Run interactively (test)
ollama run {{LOCAL_MODEL}} "Hello, how are you?"

# Start the server (if not already running)
ollama serve
```

### systemd Service

Ollama installs its own service, but you can customize it:

```ini
[Unit]
Description=Ollama Inference Server
After=network-online.target

[Service]
Type=simple
User={{USERNAME}}
ExecStart=/usr/local/bin/ollama serve
Environment=OLLAMA_HOST=0.0.0.0:{{INFERENCE_PORT}}
Environment=OLLAMA_MODELS={{MODEL_DIR}}/ollama-models
Environment=OLLAMA_NUM_PARALLEL=2
Restart=always
RestartSec=10
StandardOutput=append:/var/log/openclaw/ollama.log
StandardError=append:/var/log/openclaw/ollama-error.log

[Install]
WantedBy=multi-user.target
```

### OpenAI-Compatible Endpoint
Ollama exposes an OpenAI-compatible API at:
```
http://127.0.0.1:{{INFERENCE_PORT}}/v1/chat/completions
http://127.0.0.1:{{INFERENCE_PORT}}/v1/models
```

### Health Check
```bash
curl -sf http://127.0.0.1:{{INFERENCE_PORT}}/api/tags | jq '.models[].name'
```

---

## Option C: vLLM

vLLM is a high-performance inference engine. Best for production workloads needing high throughput.

### Install
```bash
pip install vllm
```

### Serve a Model
```bash
vllm serve {{LOCAL_MODEL}} \
    --host 0.0.0.0 \
    --port {{INFERENCE_PORT}} \
    --gpu-memory-utilization 0.9 \
    --max-model-len 32768 \
    --dtype auto
```

### systemd Service
```ini
[Unit]
Description=vLLM Inference Server
After=network-online.target

[Service]
Type=simple
User={{USERNAME}}
ExecStart=/usr/local/bin/vllm serve {{LOCAL_MODEL}} \
    --host 0.0.0.0 \
    --port {{INFERENCE_PORT}} \
    --gpu-memory-utilization 0.9 \
    --max-model-len 32768
Environment=HOME=/home/{{USERNAME}}
Environment=HF_HOME={{MODEL_DIR}}/huggingface
Restart=always
RestartSec=15
StandardOutput=append:/var/log/openclaw/vllm.log
StandardError=append:/var/log/openclaw/vllm-error.log
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
```

### Health Check
```bash
curl -sf http://127.0.0.1:{{INFERENCE_PORT}}/v1/models | jq '.data[].id'
```

---

## Agent Gateway Integration

Whichever inference server you choose, configure OpenClaw to use it as a provider:

```json
{
  "providers": {
    "local": {
      "type": "openai-compatible",
      "baseUrl": "http://127.0.0.1:{{INFERENCE_PORT}}/v1",
      "models": ["{{LOCAL_MODEL}}"]
    }
  }
}
```

Then assign the local provider to agents that should use on-device inference:
```json
{
  "agents": {
    "gpu-runner": {
      "model": "local/{{LOCAL_MODEL}}",
      "description": "Local GPU inference worker"
    }
  }
}
```

## GPU Verification

Before starting any inference server, verify GPU is accessible:
```bash
# NVIDIA GPU
nvidia-smi
# Should show: {{GPU_MODEL}}, {{GPU_VRAM}} VRAM

# Check CUDA
nvcc --version

# Monitor GPU during inference
watch -n 1 nvidia-smi
```

## Acceptance Criteria

- [ ] Inference server running on port `{{INFERENCE_PORT}}`
- [ ] At least one model loaded and responding
- [ ] OpenAI-compatible API works: `curl http://127.0.0.1:{{INFERENCE_PORT}}/v1/models`
- [ ] systemd service enabled and starts on boot
- [ ] Auto-restarts on crash
- [ ] GPU utilization visible in `nvidia-smi` during inference
- [ ] Agent gateway can route requests to local provider
- [ ] Health check integrated with watchdog

## Rollback Plan
- Stop the service: `sudo systemctl stop local-inference`
- Disable auto-start: `sudo systemctl disable local-inference`
- Agents fall back to cloud providers automatically
