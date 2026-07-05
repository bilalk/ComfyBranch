#!/usr/bin/env bash
set -u

BASE=/mnt/gpu-work/tools/ComfyUI
PY=/mnt/gpu-work/tools/venv/bin/python
LOGDIR=/mnt/gpu-work/logs
mkdir -p "$LOGDIR"

echo "=== START $(date) ==="
echo "HOST=$(hostname) USER=$(whoami)"
echo "DISK"
df -h / /mnt/gpu-work || true
echo "GPU"
nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader || true

echo "=== STOP STALE COMFY ==="
fuser -k 8188/tcp 2>/dev/null || true
pkill -9 -f "$BASE/main.py" 2>/dev/null || true
pkill -9 -f "main.py --listen" 2>/dev/null || true
sleep 3
ss -ltnp | grep 8188 || true

echo "=== PYTHON ==="
"$PY" --version

echo "=== INSTALL EXTRA DEPS ==="
"$PY" -m pip install accelerate gguf diffusers imageio-ffmpeg opencv-python-headless huggingface_hub >/mnt/gpu-work/logs/comfy-extra-deps-full.log 2>&1
echo "PIP_EXIT=$?"
tail -80 /mnt/gpu-work/logs/comfy-extra-deps-full.log || true

echo "=== IMPORT CHECK ==="
"$PY" - <<'PY'
mods = ['sqlalchemy', 'accelerate', 'gguf', 'torch', 'diffusers', 'cv2']
for m in mods:
    try:
        mod = __import__(m)
        print(m, 'OK', getattr(mod, '__version__', ''))
    except Exception as exc:
        print(m, 'FAIL', exc)
PY

echo "=== START COMFY ==="
cd "$BASE" || exit 1
rm -f comfyui-headless.log
nohup "$PY" main.py --listen 127.0.0.1 --port 8188 --disable-auto-launch --disable-metadata > comfyui-headless.log 2>&1 < /dev/null &
echo "PID=$!"

for i in $(seq 1 60); do
  if curl -sS --max-time 3 http://127.0.0.1:8188/system_stats >/tmp/comfy-system-stats.json 2>/tmp/comfy-curl.err; then
    echo "API_READY_AT=$i"
    cat /tmp/comfy-system-stats.json | head -c 2000
    echo
    break
  fi
  if ! ps -p "$!" >/dev/null 2>&1; then
    echo "COMFY_PROCESS_EXITED_AT=$i"
    break
  fi
  sleep 2
done

echo "=== PORT ==="
ss -ltnp | grep 8188 || true
echo "=== OBJECT_INFO SAMPLE ==="
curl -sS --max-time 10 http://127.0.0.1:8188/object_info >/tmp/comfy-object-info.json 2>/tmp/comfy-object-info.err || true
python3 - <<'PY'
import json
from pathlib import Path
p = Path('/tmp/comfy-object-info.json')
if p.exists() and p.stat().st_size:
    data = json.loads(p.read_text())
    keys = sorted(data.keys())
    print('NODE_COUNT', len(keys))
    for needle in ['CheckpointLoaderSimple','CLIPTextEncode','KSampler','VAEDecode','SaveImage','VHS_VideoCombine','ADE_AnimateDiffLoaderGen1','WanVideoModelLoader']:
        print(needle, needle in data)
    print('VIDEO_KEYS', [k for k in keys if 'Video' in k or 'VHS' in k or 'Wan' in k][:80])
else:
    print('NO_OBJECT_INFO')
    print(Path('/tmp/comfy-object-info.err').read_text() if Path('/tmp/comfy-object-info.err').exists() else '')
PY

echo "=== LOG TAIL ==="
tail -160 "$BASE/comfyui-headless.log" || true
echo "=== END $(date) ==="