#!/usr/bin/env bash
set -euo pipefail
BASE=/mnt/gpu-work
TOOLS=$BASE/tools
LOGS=$BASE/logs
STATUS=$BASE/status
mkdir -p $TOOLS $LOGS $STATUS $BASE/models
exec > >(tee -a $LOGS/advanced-stack-$(date +%Y%m%d-%H%M%S).log) 2>&1
step(){ echo; echo ===== $(date -Is) $* =====; echo $* > $STATUS/advanced.current; }
source $BASE/bin/renderer-env.sh
step Install system libs for Manim/OpenCV/GUI helpers
sudo apt-get clean || true
sudo rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*.deb || true
sudo apt-get update
sudo apt-get install -y --no-install-recommends libcairo2-dev libpango1.0-dev ffmpeg sox libsox-fmt-all graphviz fonts-dejavu git-lfs
sudo apt-get clean || true
sudo rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*.deb || true
step Python advanced packages
pip install --upgrade manim faster-whisper onnxruntime-gpu || pip install --upgrade manim faster-whisper onnxruntime
step Clone ComfyUI without model weights
if [ ! -d $TOOLS/ComfyUI ]; then git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git $TOOLS/ComfyUI; fi
pip install -r $TOOLS/ComfyUI/requirements.txt || true
step Clone Real-ESRGAN source without weights
if [ ! -d $TOOLS/Real-ESRGAN ]; then git clone --depth 1 https://github.com/xinntao/Real-ESRGAN.git $TOOLS/Real-ESRGAN; fi
pip install basicsr facexlib gfpgan || true
step Clone RIFE source without weights
if [ ! -d $TOOLS/ECCV2022-RIFE ]; then git clone --depth 1 https://github.com/megvii-research/ECCV2022-RIFE.git $TOOLS/ECCV2022-RIFE || true; fi
step Clone Stable Diffusion WebUI Forge source without weights
if [ ! -d $TOOLS/stable-diffusion-webui-forge ]; then git clone --depth 1 https://github.com/lllyasviel/stable-diffusion-webui-forge.git $TOOLS/stable-diffusion-webui-forge || true; fi
step Create advanced readiness report
python - <<'PY'
from pathlib import Path
import importlib.util, json, subprocess
mods=['manim','faster_whisper','onnxruntime','cv2','moviepy','PIL','numpy']
report={'modules':{},'tools':{},'note':'Model weights are intentionally not downloaded. Put weights under /mnt/gpu-work/models before using ComfyUI/Real-ESRGAN/RIFE/Forge.'}
for m in mods: report['modules'][m]=bool(importlib.util.find_spec(m))
for name,path in {'ComfyUI':'/mnt/gpu-work/tools/ComfyUI','Real-ESRGAN':'/mnt/gpu-work/tools/Real-ESRGAN','RIFE':'/mnt/gpu-work/tools/ECCV2022-RIFE','Forge':'/mnt/gpu-work/tools/stable-diffusion-webui-forge'}.items(): report['tools'][name]=Path(path).exists()
Path('/mnt/gpu-work/status/advanced-readiness.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report, indent=2))
PY
echo DONE > $STATUS/advanced.done
step DONE
