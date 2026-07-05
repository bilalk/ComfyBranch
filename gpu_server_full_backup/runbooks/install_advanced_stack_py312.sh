#!/usr/bin/env bash
set -euo pipefail
BASE=/mnt/gpu-work
TOOLS=$BASE/tools
LOGS=$BASE/logs
STATUS=$BASE/status
mkdir -p $TOOLS $LOGS $STATUS $BASE/models
exec > >(tee -a $LOGS/advanced-py312-$(date +%Y%m%d-%H%M%S).log) 2>&1
step(){ echo; echo ===== $(date -Is) $* =====; echo $* > $STATUS/advanced.current; }
step Install micromamba
if [ ! -x $TOOLS/micromamba/bin/micromamba ]; then
  mkdir -p $TOOLS/micromamba/bin
  cd $TOOLS/micromamba/bin
  curl -L https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj --strip-components=1 bin/micromamba
fi
export MAMBA_ROOT_PREFIX=$TOOLS/micromamba-root
step Create Python 3.12 advanced env
$TOOLS/micromamba/bin/micromamba create -y -n adv312 -c conda-forge python=3.12 pip git git-lfs ffmpeg cairo pango pkg-config numpy pillow
source <($TOOLS/micromamba/bin/micromamba shell hook -s bash)
micromamba activate adv312
python --version
step Install PyTorch CUDA 12.8 wheels
pip install --upgrade pip wheel setuptools
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
step Install advanced Python packages
pip install faster-whisper manim opencv-python-headless moviepy pydantic fastapi uvicorn pillow numpy scipy tqdm einops safetensors transformers accelerate diffusers onnxruntime-gpu
step Clone/install ComfyUI
if [ ! -d $TOOLS/ComfyUI ]; then git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git $TOOLS/ComfyUI; fi
pip install -r $TOOLS/ComfyUI/requirements.txt || true
step Clone Real-ESRGAN and RIFE and Forge source
if [ ! -d $TOOLS/Real-ESRGAN ]; then git clone --depth 1 https://github.com/xinntao/Real-ESRGAN.git $TOOLS/Real-ESRGAN; fi
pip install basicsr facexlib gfpgan || true
if [ ! -d $TOOLS/ECCV2022-RIFE ]; then git clone --depth 1 https://github.com/megvii-research/ECCV2022-RIFE.git $TOOLS/ECCV2022-RIFE || true; fi
if [ ! -d $TOOLS/stable-diffusion-webui-forge ]; then git clone --depth 1 https://github.com/lllyasviel/stable-diffusion-webui-forge.git $TOOLS/stable-diffusion-webui-forge || true; fi
step Advanced sanity report
python - <<'PY'
from pathlib import Path
import importlib.util, json, subprocess
mods=['torch','torchvision','faster_whisper','manim','cv2','moviepy','PIL','numpy','diffusers','transformers','onnxruntime']
report={'modules':{},'tools':{},'gpu':None,'note':'Model weights are not downloaded. Put weights under /mnt/gpu-work/models before using ComfyUI/Real-ESRGAN/RIFE/Forge.'}
for m in mods:
    report['modules'][m]=bool(importlib.util.find_spec(m))
try:
    import torch
    report['torch_cuda_available']=torch.cuda.is_available()
    report['torch_cuda_device']=torch.cuda.get_device_name(0) if torch.cuda.is_available() else None
except Exception as e:
    report['torch_error']=str(e)
for name,path in {'ComfyUI':'/mnt/gpu-work/tools/ComfyUI','Real-ESRGAN':'/mnt/gpu-work/tools/Real-ESRGAN','RIFE':'/mnt/gpu-work/tools/ECCV2022-RIFE','Forge':'/mnt/gpu-work/tools/stable-diffusion-webui-forge'}.items():
    report['tools'][name]=Path(path).exists()
Path('/mnt/gpu-work/status/advanced-readiness.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report, indent=2))
PY
echo DONE > $STATUS/advanced.done
step DONE
