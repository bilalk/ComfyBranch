# COMFYBranch Agent Handoff

This document is for the next coding agent that picks up the COMFYBranch / remote ComfyUI work.

## 1. Project roots

Main project:

```text
C:\Users\faraz\Desktop\multi-format-content-engine
```

New ComfyUI controller app:

```text
C:\Users\faraz\Desktop\multi-format-content-engine\COMFYBranch
```

Local COMFYBranch URL:

```text
http://127.0.0.1:8788
```

Main original content-engine URL:

```text
http://127.0.0.1:8770
```

## 2. GPU server access

GPU server:

```text
IP: 52.206.69.50
SSH user: ubuntu
SSH key: C:\Users\faraz\Downloads\voicekey.ppk
Pinned PuTTY host key: SHA256:RvZEd0SKvcRmlXBkfN10MWo2KAFE7+WeBhL3Hmyk8Q8
```

Use PuTTY tools already installed on Windows:

```powershell
& "C:\Program Files\PuTTY\plink.exe" -batch -no-antispoof -ssh `
  -hostkey "SHA256:RvZEd0SKvcRmlXBkfN10MWo2KAFE7+WeBhL3Hmyk8Q8" `
  -i "C:\Users\faraz\Downloads\voicekey.ppk" `
  -l ubuntu 52.206.69.50 "hostname && nvidia-smi"
```

Copy files with:

```powershell
& "C:\Program Files\PuTTY\pscp.exe" -batch `
  -hostkey "SHA256:RvZEd0SKvcRmlXBkfN10MWo2KAFE7+WeBhL3Hmyk8Q8" `
  -i "C:\Users\faraz\Downloads\voicekey.ppk" `
  localfile ubuntu@52.206.69.50:/remote/path
```

## 3. GPU server architecture

Important server paths:

```text
/mnt/gpu-work
/mnt/gpu-work/tools/ComfyUI
/mnt/gpu-work/tools/venv/bin/python
/mnt/gpu-work/tools/ComfyUI/models
/mnt/gpu-work/tools/ComfyUI/output
/mnt/gpu-work/tools/ComfyUI/workflows/api
/mnt/gpu-work/logs
/mnt/gpu-work/outputs/comfybranch
```

ComfyUI remote API:

```text
Remote: http://127.0.0.1:8188
Local tunnel: http://127.0.0.1:18188
```

COMFYBranch opens/uses an SSH tunnel:

```text
18188:127.0.0.1:8188
```

Current GPU resources observed:

```text
GPU: NVIDIA L4
VRAM: 23034 MiB
System RAM: 15 GiB
GPU disk: /mnt/gpu-work, 492 GB total, about 395 GB free after current installs
Root disk: /, 6.7 GB total and nearly full; do not download models to root
```

## 4. Local COMFYBranch code structure

Essential app files:

```text
COMFYBranch\server.py
COMFYBranch\static\index.html
COMFYBranch\static\styles.css
COMFYBranch\static\app.js
COMFYBranch\start-comfybranch.ps1
COMFYBranch\README.md
```

Workflow files:

```text
COMFYBranch\workflows\comfyui\sd15_image_smoke_test.json
COMFYBranch\workflows\comfyui\animatediff_sd15_16frames_video.json
COMFYBranch\workflows\comfyui\wan_t2v_1_3b_33frames_video.json
```

Generated job/output folders:

```text
COMFYBranch\data\jobs
COMFYBranch\data\outputs
COMFYBranch\data\last-capabilities.json
COMFYBranch\data\logs
```

GPU server source backup stored locally:

```text
COMFYBranch\gpu_server_source_backup
```

This contains copies of server-side repair/download scripts and API workflow JSON files. If the GPU server is lost, start here.

## 5. GPU-side scripts backed up locally

Local backup folder:

```text
C:\Users\faraz\Desktop\multi-format-content-engine\COMFYBranch\gpu_server_source_backup
```

Files currently backed up:

```text
gpu_repair_comfy.sh
download_comfy_models.py
download_wan_pack.py
validate_comfy_ready.py
comfyui_workflows_api\...
```

Original GPU paths:

```text
/mnt/gpu-work/gpu_repair_comfy.sh
/mnt/gpu-work/download_comfy_models.py
/mnt/gpu-work/download_wan_pack.py
/mnt/gpu-work/validate_comfy_ready.py
/mnt/gpu-work/tools/ComfyUI/workflows/api
```

## 6. GPT-5.5 planner configuration

The GPT planner is in:

```text
COMFYBranch\server.py
```

Important constants:

```python
GPT55_RESPONSES_ENDPOINT = "https://testercoder.services.ai.azure.com/openai/v1/responses"
GPT55_DEPLOYMENT = "gpt-5.5"
PROJECT_AZURE_KEY = os.environ.get("AZURE_OPENAI_KEY") or os.environ.get("AZURE_API_KEY") or "..."
```

Current hardcoded fallback key exists inside `COMFYBranch\server.py` and also the original `server.py`. For safer future maintenance, move it to an environment variable:

```powershell
$env:AZURE_OPENAI_KEY="your-new-key"
$env:GPT55_RESPONSES_ENDPOINT="https://your-resource.services.ai.azure.com/openai/v1/responses"
$env:GPT55_DEPLOYMENT="gpt-5.5"
```

Then restart:

```powershell
& "C:\Users\faraz\Desktop\multi-format-content-engine\COMFYBranch\start-comfybranch.ps1"
```

If replacing GPT-5.5 with another model/provider, edit `analyze_prompt_with_gpt()` in `COMFYBranch\server.py`. The function must return the same JSON shape expected by the UI:

```text
detectedType
style
recommendedChunks
productionPrompt
negativePrompt
chunks[] with index/title/durationSeconds/purpose/prompt
recommendedProductVideoWorkflow
longerVideoStrategy
```

## 7. Current model and workflow status

Installed and validated:

```text
SD1.5 checkpoint:
/mnt/gpu-work/tools/ComfyUI/models/checkpoints/sd15_v1-5-pruned-emaonly-fp16.safetensors

AnimateDiff motion model:
/mnt/gpu-work/tools/ComfyUI/models/animatediff_models/mm_sd_v15_v2.ckpt

SVD checkpoint:
/mnt/gpu-work/tools/ComfyUI/models/checkpoints/svd_xt.safetensors

Wan 1.3B low/quantized pack:
/mnt/gpu-work/tools/ComfyUI/models/diffusion_models/Wan2_1-T2V-1_3B_fp8_e4m3fn.safetensors
/mnt/gpu-work/tools/ComfyUI/models/vae/Wan2_1_VAE_bf16.safetensors
/mnt/gpu-work/tools/ComfyUI/models/text_encoders/umt5-xxl-enc-fp8_e4m3fn.safetensors
```

Workflows:

```text
sd15_image_smoke_test.json - image smoke test, validated
animatediff_sd15_16frames_video.json - AnimateDiff text-to-video, validated after fixing M_MODELS wiring
wan_t2v_1_3b_33frames_video.json - Wan T2V workflow, accepted by ComfyUI /prompt
```

Important: `wan-video` must not fall back to Blender. In `run_async_generation()`, every mode must have an explicit branch. Unknown modes must raise an error.

## 8. Known bug history and fixes

### Fidget-spinner contamination

Earlier Blender fallback was hardcoded around a fidget spinner. Do not use Blender fallback as a generic AI renderer. It is procedural and should only be used when explicitly selected or when a subject-specific Blender script is written.

### Repeated chunks

Earlier planner repeated the full prompt for every chunk. Fixed by adding GPT-5.5 planner in `analyze_prompt_with_gpt()`. Local fallback also has suction-plate-specific beats.

### Invalid filenames

GPT chunk titles can contain `?`, `/`, etc. Blender fallback now sanitizes output filenames before writing MP4s.

### Mode fallthrough

Earlier `wan-video` fell through to Blender. Fixed by adding explicit `wan-video` branch in `run_async_generation()`.

### Busy ComfyUI falsely disabling modes

Capability scan now calls `ensure_tunnel()` and treats `/queue` as evidence the API is alive if `/system_stats` is slow while a job runs.

## 9. How to redeploy GPU server from scratch

Assuming a fresh Ubuntu GPU instance with `/mnt/gpu-work` mounted:

1. Install system basics:

```bash
sudo apt update
sudo apt install -y git curl wget ffmpeg python3-venv python3-pip build-essential
```

2. Create work folders:

```bash
sudo mkdir -p /mnt/gpu-work/tools /mnt/gpu-work/logs /mnt/gpu-work/outputs
sudo chown -R ubuntu:ubuntu /mnt/gpu-work
```

3. Clone ComfyUI:

```bash
cd /mnt/gpu-work/tools
git clone https://github.com/comfyanonymous/ComfyUI.git
python3 -m venv /mnt/gpu-work/tools/venv
/mnt/gpu-work/tools/venv/bin/python -m pip install --upgrade pip
cd /mnt/gpu-work/tools/ComfyUI
/mnt/gpu-work/tools/venv/bin/python -m pip install -r requirements.txt
```

4. Install extra dependencies used during this project:

```bash
/mnt/gpu-work/tools/venv/bin/python -m pip install accelerate gguf ftfy diffusers imageio-ffmpeg opencv-python-headless huggingface_hub
```

5. Install custom nodes:

```bash
cd /mnt/gpu-work/tools/ComfyUI/custom_nodes
git clone https://github.com/ltdrdata/ComfyUI-Manager.git
git clone https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved.git
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git
git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git
git clone https://github.com/kijai/ComfyUI-KJNodes.git
```

6. Copy or rerun model download scripts from local backup:

```text
COMFYBranch\gpu_server_source_backup\download_comfy_models.py
COMFYBranch\gpu_server_source_backup\download_wan_pack.py
```

Upload and run:

```bash
/mnt/gpu-work/tools/venv/bin/python /mnt/gpu-work/download_comfy_models.py
/mnt/gpu-work/tools/venv/bin/python /mnt/gpu-work/download_wan_pack.py
```

7. Copy workflow JSON files:

```bash
mkdir -p /mnt/gpu-work/tools/ComfyUI/workflows/api
# copy JSON files from COMFYBranch\workflows\comfyui or gpu_server_source_backup\comfyui_workflows_api
```

8. Start ComfyUI:

```bash
cd /mnt/gpu-work/tools/ComfyUI
nohup /mnt/gpu-work/tools/venv/bin/python main.py --listen 127.0.0.1 --port 8188 --disable-auto-launch --disable-metadata > comfyui-headless.log 2>&1 &
```

9. Validate:

```bash
curl http://127.0.0.1:8188/system_stats
curl http://127.0.0.1:8188/object_info
```

## 10. Essential files for git

Track these:

```text
COMFYBranch\server.py
COMFYBranch\static\index.html
COMFYBranch\static\styles.css
COMFYBranch\static\app.js
COMFYBranch\start-comfybranch.ps1
COMFYBranch\README.md
COMFYBranch\AGENT_HANDOFF_COMFYBRANCH.md
COMFYBranch\workflows\comfyui\*.json
COMFYBranch\gpu_repair_comfy.sh
COMFYBranch\download_comfy_models.py
COMFYBranch\download_wan_pack.py
COMFYBranch\validate_comfy_ready.py
COMFYUI_REMOTE_VIDEO_ROADMAP.md
```

Do not commit generated media or huge models:

```text
COMFYBranch\data\outputs
COMFYBranch\data\jobs
COMFYBranch\data\logs
*.mp4
*.png generated outputs
*.safetensors
*.ckpt
*.gguf
```

## 11. Generated media locations

Local generated outputs:

```text
C:\Users\faraz\Desktop\multi-format-content-engine\COMFYBranch\data\outputs
```

Local job manifests/status:

```text
C:\Users\faraz\Desktop\multi-format-content-engine\COMFYBranch\data\jobs
```

Remote ComfyUI outputs:

```text
/mnt/gpu-work/tools/ComfyUI/output/COMFYBranch
```

Remote Blender fallback outputs:

```text
/mnt/gpu-work/outputs/comfybranch
```

## 12. Remaining production-grade work

Still needed:

1. SVD full image-to-video workflow with generated/uploaded keyframe input.
2. LTX model install and workflow.
3. CogVideoX/Hunyuan quantized model install and workflow if feasible on L4.
4. UI controls per workflow family: steps, CFG, resolution, frames, FPS, scheduler, seed, model, VAE tiling, offload mode.
5. Better job cancellation and queue management.
6. Per-job server logs visible in the UI.
7. Reference-image upload and use for SVD/Wan/I2V.
8. Final interpolation/upscale pipeline.
