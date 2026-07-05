#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
BASE=/mnt/gpu-work
TOOLS=$BASE/tools
LOGS=$BASE/logs
STATUS=$BASE/status
WEB=$BASE/web
mkdir -p $TOOLS $LOGS $STATUS $WEB $BASE/{inputs,outputs,jobs,projects,models,tmp,cache,runbooks}
exec > >(tee -a $LOGS/bootstrap-$(date +%Y%m%d-%H%M%S).log) 2>&1
step(){ echo; echo ===== $(date -Is) $* =====; echo $* > $STATUS/bootstrap.current; }
step System inventory
uname -a || true
lsb_release -a || true
nvidia-smi || true
df -h / $BASE || true
step Minimal apt dependencies
sudo apt-get clean || true
sudo rm -rf /var/lib/apt/lists/* || true
sudo apt-get update
sudo apt-get install -y --no-install-recommends ca-certificates curl wget git unzip xz-utils tar jq build-essential pkg-config libgl1 libglib2.0-0 libxrender1 libxext6 libsm6 libx11-6 libxi6 libxrandr2 libxxf86vm1 libxfixes3 libxkbcommon0 libdbus-1-3 libfontconfig1 libfreetype6 libegl1 libxinerama1 libxcursor1 libpulse0 libasound2t64 nginx python3-venv python3-pip
step Python virtual environment
python3 -m venv $TOOLS/venv
source $TOOLS/venv/bin/activate
python -m pip install --upgrade pip wheel setuptools
pip install fastapi uvicorn[standard] moviepy opencv-python-headless pillow numpy scipy tqdm pydantic python-multipart requests imageio imageio-ffmpeg pysrt srt ffmpeg-python scenedetect[opencv] rich watchdog
step FFmpeg static binary
if [ ! -x $TOOLS/ffmpeg/ffmpeg ]; then
  mkdir -p $TOOLS/ffmpeg
  cd $TOOLS/ffmpeg
  wget -q --show-progress -O ffmpeg.tar.xz https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz
  tar -xf ffmpeg.tar.xz --strip-components=1
fi
step Blender portable
if [ ! -x $TOOLS/blender/blender ]; then
  mkdir -p $TOOLS/blender
  cd $TOOLS/blender
  wget -q --show-progress -O blender.tar.xz https://download.blender.org/release/Blender4.3/blender-4.3.2-linux-x64.tar.xz || wget -q --show-progress -O blender.tar.xz https://download.blender.org/release/Blender4.2/blender-4.2.5-linux-x64.tar.xz
  tar -xf blender.tar.xz --strip-components=1
fi
step Helper command wrappers
mkdir -p $BASE/bin
cat > $BASE/bin/renderer-env.sh <<'ENV'
#!/usr/bin/env bash
export GPU_WORK=/mnt/gpu-work
export PATH=/mnt/gpu-work/tools/ffmpeg:/mnt/gpu-work/tools/blender:/mnt/gpu-work/tools/venv/bin:/mnt/gpu-work/bin:$PATH
ENV
chmod +x $BASE/bin/renderer-env.sh
cat > $BASE/bin/render_smoke_test.sh <<'SMOKE'
#!/usr/bin/env bash
set -euo pipefail
source /mnt/gpu-work/bin/renderer-env.sh
mkdir -p /mnt/gpu-work/outputs/smoke
ffmpeg -y -f lavfi -i testsrc=size=1280x720:rate=30 -f lavfi -i sine=frequency=1000:sample_rate=48000 -t 3 -c:v libx264 -pix_fmt yuv420p -c:a aac /mnt/gpu-work/outputs/smoke/ffmpeg-smoke.mp4
python - <<'PY'
from moviepy import ColorClip
clip=ColorClip((640,360), color=(20,80,160), duration=2)
clip.write_videofile('/mnt/gpu-work/outputs/smoke/moviepy-smoke.mp4', fps=24, codec='libx264', audio=False, logger=None)
PY
blender -b --factory-startup --python-expr import bpy; bpy.ops.mesh.primitive_cube_add(); bpy.ops.wm.save_as_mainfile(filepath='/mnt/gpu-work/outputs/smoke/blender-smoke.blend')
nvidia-smi > /mnt/gpu-work/outputs/smoke/nvidia-smi.txt
SMOKE
chmod +x $BASE/bin/render_smoke_test.sh
step Web status/download service
cat > $WEB/gpu_status_server.py <<'PY'
from fastapi import FastAPI
from fastapi.responses import HTMLResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from pathlib import Path
import subprocess, json, os, time
BASE=Path('/mnt/gpu-work')
app=FastAPI(title='GPU Renderer Status')
app.mount('/outputs', StaticFiles(directory=str(BASE/'outputs')), name='outputs')
app.mount('/logs', StaticFiles(directory=str(BASE/'logs')), name='logs')
def sh(cmd):
    try: return subprocess.check_output(cmd, shell=True, text=True, stderr=subprocess.STDOUT, timeout=8)
    except Exception as e: return str(e)
@app.get('/')
def index():
    outs=[]
    for p in sorted((BASE/'outputs').rglob('*'), key=lambda x: x.stat().st_mtime if x.exists() else 0, reverse=True)[:200]:
        if p.is_file():
            rel=p.relative_to(BASE/'outputs').as_posix(); outs.append(f'<li><a href=/outputs/{rel}>{rel}</a> ({p.stat().st_size/1024/1024:.1f} MB)</li>')
    logs=[]
    for p in sorted((BASE/'logs').glob('*'), key=lambda x: x.stat().st_mtime, reverse=True)[:50]:
        if p.is_file(): logs.append(f'<li><a href=/logs/{p.name}>{p.name}</a></li>')
    html=f"<html><head><title>GPU Renderer Status</title><style>body{{font-family:Arial;background:#111;color:#eee}}a{{color:#7dd3fc}}pre{{background:#222;padding:10px;white-space:pre-wrap}}</style></head><body><h1>GPU Renderer Status</h1><p>Base: {BASE}</p><h2>GPU</h2><pre>{sh('nvidia-smi')}</pre><h2>Disk</h2><pre>{sh('df -h / /mnt/gpu-work')}</pre><h2>Recent outputs</h2><ul>{''.join(outs) or '<li>No outputs yet</li>'}</ul><h2>Logs</h2><ul>{''.join(logs)}</ul></body></html>"
    return HTMLResponse(html)
@app.get('/api/status')
def status():
    return {'time':time.time(),'base':str(BASE),'nvidia_smi':sh('nvidia-smi'),'disk':sh('df -h / /mnt/gpu-work')}
PY
cat > $BASE/runbooks/gpu-renderer.service <<'SERVICE'
[Unit]
Description=GPU Renderer Status Web Service
After=network.target
[Service]
User=ubuntu
WorkingDirectory=/mnt/gpu-work/web
ExecStart=/mnt/gpu-work/tools/venv/bin/uvicorn gpu_status_server:app --host 0.0.0.0 --port 8787
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
SERVICE
sudo cp $BASE/runbooks/gpu-renderer.service /etc/systemd/system/gpu-renderer.service
sudo systemctl daemon-reload
sudo systemctl enable --now gpu-renderer.service
step Sanity tests
source $BASE/bin/renderer-env.sh
which ffmpeg; ffmpeg -version | head -3
which blender; blender --version | head -5
python - <<'PY'
import cv2, moviepy, PIL, numpy
print('python-video-stack-ok')
PY
bash $BASE/bin/render_smoke_test.sh
curl -fsS http://127.0.0.1:8787/api/status | jq '.base' || true
step Runbook markdown
cat > $BASE/runbooks/GPU_RENDERER_SETUP_AND_OPERATIONS.md <<'MD'
# GPU Renderer Setup and Operations

## Purpose
This GPU server assembles final videos from Part 1 handoff folders produced by the Windows Multi-format Content Engine. Part 2 must reuse local approved images/audio only; do not call paid GPT/image/audio APIs during GPU rendering.

## Server
- Ubuntu 26.04 LTS
- NVIDIA L4 GPU, driver 580.x, CUDA runtime reported by `nvidia-smi`
- Work disk: `/mnt/gpu-work`

## Important paths
- Inputs copied from Windows: `/mnt/gpu-work/inputs/{topicId}`
- Outputs: `/mnt/gpu-work/outputs/{topicId}`
- Jobs: `/mnt/gpu-work/jobs`
- Logs: `/mnt/gpu-work/logs`
- Tools: `/mnt/gpu-work/tools`
- Runbooks: `/mnt/gpu-work/runbooks`
- Status web app: `http://SERVER_IP:8787`

## Installed tools
- FFmpeg static: `/mnt/gpu-work/tools/ffmpeg/ffmpeg`
- Blender portable/headless: `/mnt/gpu-work/tools/blender/blender`
- Python venv: `/mnt/gpu-work/tools/venv`
- Python packages: FastAPI, Uvicorn, MoviePy, OpenCV headless, Pillow, NumPy, SciPy, PySceneDetect, subtitle libraries
- NGINX installed for future reverse proxy use

## Environment
Run:
```bash
source /mnt/gpu-work/bin/renderer-env.sh
```

## Smoke tests
```bash
/mnt/gpu-work/bin/render_smoke_test.sh
```
Outputs appear in `/mnt/gpu-work/outputs/smoke`.

## Status/download web UI
Service:
```bash
sudo systemctl status gpu-renderer.service
sudo journalctl -u gpu-renderer.service -f
```
Open:
```text
http://3.220.231.239:8787
```
If unreachable, open AWS Security Group TCP 8787 or use SSH tunnel:
```bash
ssh -L 8787:127.0.0.1:8787 ubuntu@3.220.231.239
```

## Input contract from Part 1
Copy the complete topic bundle containing:
- `data/topics/{topicId}.json`
- `data/topics/{topicId}.md`
- `data/assets/{topicId}/video-outline/{topicId}-part2-renderer-handoff.json`
- `data/assets/{topicId}/images/*`
- `data/assets/{topicId}/audio/*`

The handoff JSON contains `sceneAssetMap`, `videoScript`, `audio`, `visuals`, `techStack`, and `part2Instructions`.

## Maintenance
- Check disk: `df -h / /mnt/gpu-work`
- Check GPU: `nvidia-smi`
- Restart web UI: `sudo systemctl restart gpu-renderer.service`
- Re-run bootstrap: `bash /mnt/gpu-work/runbooks/bootstrap_gpu_renderer.sh`
- Keep large models and outputs off `/`; use `/mnt/gpu-work`.

## Rebuild from fresh server
1. SSH as ubuntu.
2. Mount large work disk at `/mnt/gpu-work`.
3. Run this bootstrap script: `/mnt/gpu-work/runbooks/bootstrap_gpu_renderer.sh`.
4. Run smoke test.
5. Copy Part 1 handoff bundles into `/mnt/gpu-work/inputs`.
MD
echo DONE > $STATUS/bootstrap.done
step DONE
