ï»¿# GPU Renderer Setup and Operations

## Purpose
This GPU server assembles final videos from Part 1 handoff folders produced by the Windows Multi-format Content Engine. Part 2 must reuse local approved images/audio only. Do not call paid GPT/image/audio APIs during GPU rendering.

## Server
- Public IP: 52.206.69.50
- SSH user: ubuntu
- GPU: NVIDIA L4, driver 580.159.03, CUDA reported by nvidia-smi as 13.0
- OS: Ubuntu 26.04 LTS
- Root disk is small; do not store tools/models/outputs on `/`.
- Work disk: `/mnt/gpu-work` (~229GB)

## Important paths
- Inputs copied from Windows: `/mnt/gpu-work/inputs/{topicId}`
- Outputs/downloads: `/mnt/gpu-work/outputs/{topicId}`
- Job files/status: `/mnt/gpu-work/jobs`
- Logs: `/mnt/gpu-work/logs`
- Tools: `/mnt/gpu-work/tools`
- Runbooks: `/mnt/gpu-work/runbooks`
- Status web app: `http://52.206.69.50:4000`

## Installed tools
- NVIDIA driver already present; verify with `nvidia-smi`.
- FFmpeg static: `/mnt/gpu-work/tools/ffmpeg/ffmpeg`
- Blender portable/headless: `/mnt/gpu-work/tools/blender/blender`
- Python venv: `/mnt/gpu-work/tools/venv`
- Python packages: FastAPI, Uvicorn, MoviePy, OpenCV headless, Pillow, NumPy, SciPy, PySceneDetect, subtitle libs, watchdog.
- Web status service: `gpu-renderer.service` on port 4000.
- Optional GUI/RDP: XRDP + Openbox if installed; connect to TCP 3389 only if AWS security group allows it.

## Environment
```bash
source /mnt/gpu-work/bin/renderer-env.sh
```

## Smoke tests
```bash
/mnt/gpu-work/bin/render_smoke_test.sh
```
Expected outputs:
- `/mnt/gpu-work/outputs/smoke/ffmpeg-smoke.mp4`
- `/mnt/gpu-work/outputs/smoke/moviepy-smoke.mp4`
- `/mnt/gpu-work/outputs/smoke/blender-smoke.blend`
- `/mnt/gpu-work/outputs/smoke/nvidia-smi.txt`

## Status/download web UI
```bash
sudo systemctl status gpu-renderer.service
sudo journalctl -u gpu-renderer.service -f
```
Open:
```text
http://52.206.69.50:4000
```
If unreachable, open AWS Security Group TCP 4000 or use SSH tunnel:
```bash
ssh -L 4000:127.0.0.1:4000 ubuntu@52.206.69.50
```

## Input contract from Part 1
Copy a complete topic bundle containing:
- `data/topics/{topicId}.json`
- `data/topics/{topicId}.md`
- `data/assets/{topicId}/video-outline/{topicId}-part2-renderer-handoff.json`
- `data/assets/{topicId}/images/*`
- `data/assets/{topicId}/audio/*`

The handoff JSON contains:
- `sceneAssetMap`
- `videoScript`
- `audio`
- `visuals`
- `techStack`
- `part2Instructions`

## Part 2 rule
Use local assets only. No paid GPT/image/audio APIs during GPU rendering.

## Maintenance
- Check disk: `df -h / /mnt/gpu-work`
- Check GPU: `nvidia-smi`
- Restart web UI: `sudo systemctl restart gpu-renderer.service`
- View web logs: `sudo journalctl -u gpu-renderer.service -f`
- Keep large models and outputs off `/`; use `/mnt/gpu-work`.

## Rebuild from fresh server
1. SSH as ubuntu.
2. Mount the large data disk at `/mnt/gpu-work`.
3. Run `/mnt/gpu-work/runbooks/bootstrap_gpu_renderer.sh` if present, or recreate from this runbook.
4. Install minimal apt packages, then portable FFmpeg/Blender into `/mnt/gpu-work/tools`.
5. Run `/mnt/gpu-work/bin/render_smoke_test.sh`.
6. Copy Part 1 bundles into `/mnt/gpu-work/inputs`.


## Current outputs generated

The first batch preview render produced MP4 previews for all four uploaded topics under /mnt/gpu-work/outputs/{topicId}/{topicId}_part2_preview.mp4. These are playable from the dashboard on port 4000.

