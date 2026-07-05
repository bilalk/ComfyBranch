#!/usr/bin/env bash
set -uox pipefail
BASE=/mnt/gpu-work
TOOLS=$BASE/tools
LOGS=$BASE/logs
STATUS=$BASE/status
mkdir -p $LOGS $STATUS
exec > >(tee -a $LOGS/advanced-continue-$(date +%Y%m%d-%H%M%S).log) 2>&1
step(){ echo; echo ===== $(date -Is) $* =====; echo $* > $STATUS/advanced.current; }
export MAMBA_ROOT_PREFIX=$TOOLS/micromamba-root
source <($TOOLS/micromamba/bin/micromamba shell hook -s bash)
micromamba activate adv312
step Install Manim via conda-forge
micromamba install -y -n adv312 -c conda-forge manim || true
step Install advanced pip packages except Manim
pip install --upgrade faster-whisper opencv-python-headless moviepy pydantic fastapi uvicorn pillow numpy scipy tqdm einops safetensors transformers accelerate diffusers onnxruntime-gpu || pip install --upgrade faster-whisper opencv-python-headless moviepy pydantic fastapi uvicorn pillow numpy scipy tqdm einops safetensors transformers accelerate diffusers onnxruntime
step Clone ComfyUI/Real-ESRGAN/RIFE/Forge
[ -d $TOOLS/ComfyUI ] || git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git $TOOLS/ComfyUI
pip install -r $TOOLS/ComfyUI/requirements.txt || true
[ -d $TOOLS/Real-ESRGAN ] || git clone --depth 1 https://github.com/xinntao/Real-ESRGAN.git $TOOLS/Real-ESRGAN
pip install basicsr facexlib gfpgan || true
[ -d $TOOLS/ECCV2022-RIFE ] || git clone --depth 1 https://github.com/megvii-research/ECCV2022-RIFE.git $TOOLS/ECCV2022-RIFE || true
[ -d $TOOLS/stable-diffusion-webui-forge ] || git clone --depth 1 https://github.com/lllyasviel/stable-diffusion-webui-forge.git $TOOLS/stable-diffusion-webui-forge || true
step Write advanced readiness
python - <<'PY'
from pathlib import Path
import importlib.util, json
mods=['torch','torchvision','faster_whisper','manim','cv2','moviepy','PIL','numpy','diffusers','transformers','onnxruntime']
report={'modules':{},'tools':{},'note':'Model weights are not downloaded. Put model weights under /mnt/gpu-work/models before using ComfyUI/Real-ESRGAN/RIFE/Forge/AnimateDiff/Wan/SVD.'}
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
print(json.dumps(report,indent=2))
PY
echo DONE > $STATUS/advanced.done
echo DONE > $STATUS/advanced.current
