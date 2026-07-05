#!/usr/bin/env bash
set -uox pipefail
BASE=/mnt/gpu-work
TOOLS=$BASE/tools
MODELS=$BASE/models
LOGS=$BASE/logs
STATUS=$BASE/status
mkdir -p $MODELS/{checkpoints,vae,loras,controlnet,animatediff,svd,wan,upscale_models,rife,comfy_workflows,diffusion_models,clip_vision} $LOGS $STATUS
exec > >(tee -a $LOGS/video-models-$(date +%Y%m%d-%H%M%S).log) 2>&1
step(){ echo; echo ===== $(date -Is) $* =====; echo $* > $STATUS/video-models.current; }
source /mnt/gpu-work/bin/renderer-env.sh
export MAMBA_ROOT_PREFIX=$TOOLS/micromamba-root
source <($TOOLS/micromamba/bin/micromamba shell hook -s bash)
micromamba activate adv312
step ComfyUI model directory links
mkdir -p $TOOLS/ComfyUI/models
for d in checkpoints vae loras controlnet upscale_models clip_vision animatediff diffusion_models; do
  mkdir -p $MODELS/$d
  rm -rf $TOOLS/ComfyUI/models/$d
  ln -s $MODELS/$d $TOOLS/ComfyUI/models/$d
done
step ComfyUI custom nodes
cd $TOOLS/ComfyUI/custom_nodes
[ -d ComfyUI-Manager ] || git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Manager.git || true
[ -d ComfyUI-VideoHelperSuite ] || git clone --depth 1 https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git || true
[ -d ComfyUI-AnimateDiff-Evolved ] || git clone --depth 1 https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved.git || true
[ -d ComfyUI-KJNodes ] || git clone --depth 1 https://github.com/kijai/ComfyUI-KJNodes.git || true
[ -d ComfyUI-WanVideoWrapper ] || git clone --depth 1 https://github.com/kijai/ComfyUI-WanVideoWrapper.git || true
for req in */requirements.txt; do pip install -r $req || true; done
step Download practical weights
# Upscaler
wget -nc -O $MODELS/upscale_models/RealESRGAN_x4plus.pth https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth || true
ln -sf $MODELS/upscale_models/RealESRGAN_x4plus.pth $TOOLS/Real-ESRGAN/weights/RealESRGAN_x4plus.pth || true
# AnimateDiff motion module
wget -nc -O $MODELS/animatediff/mm_sd_v15_v2.ckpt https://huggingface.co/guoyww/animatediff/resolve/main/mm_sd_v15_v2.ckpt || true
# SVD single-file if accessible
wget -nc -O $MODELS/svd/svd_xt.safetensors https://huggingface.co/stabilityai/stable-video-diffusion-img2vid-xt/resolve/main/svd_xt.safetensors || true
ln -sf $MODELS/svd/svd_xt.safetensors $MODELS/checkpoints/svd_xt.safetensors || true
# Try small Wan 1.3B text model metadata/weights if accessible (I2V 14B is too heavy for automatic install by default)
python - <<'PY' || true
from huggingface_hub import snapshot_download
from pathlib import Path
base=Path('/mnt/gpu-work/models/wan/Wan2.1-T2V-1.3B')
base.mkdir(parents=True, exist_ok=True)
snapshot_download('Wan-AI/Wan2.1-T2V-1.3B', local_dir=str(base), local_dir_use_symlinks=False, resume_download=True)
print('wan snapshot attempted', base)
PY
step Create ComfyUI workflow templates
cat > $MODELS/comfy_workflows/README.md <<'MD'
# ComfyUI workflow templates
These templates are placeholders/input contracts for Part 2 variants. They require model weights in /mnt/gpu-work/models.

- SVD: use approved still image + local audio, create short motion clips, then FFmpeg assembles.
- AnimateDiff: use approved still/image prompt conditioning where workflow supports it.
- Wan: requires Wan model weights; recommended only after confirming VRAM compatibility.
MD
step Create variant scripts
cat > /mnt/gpu-work/bin/render_variant_comfy.py <<'PY'
#!/usr/bin/env python3
print('ComfyUI variant runner placeholder: ComfyUI/custom nodes installed. Add workflow JSON and model weights, then submit to ComfyUI API. Current production fallback is /mnt/gpu-work/bin/batch_render_from_handoff.py')
PY
cat > /mnt/gpu-work/bin/render_variant_svd.py <<'PY'
#!/usr/bin/env python3
from pathlib import Path
model=Path('/mnt/gpu-work/models/svd/svd_xt.safetensors')
print('SVD model present:', model.exists(), model)
print('SVD variant runner placeholder: model/workflow validation required before production generation.')
PY
cat > /mnt/gpu-work/bin/render_variant_wan.py <<'PY'
#!/usr/bin/env python3
from pathlib import Path
p=Path('/mnt/gpu-work/models/wan')
print('Wan model files:', sum(1 for _ in p.rglob('*') if _.is_file()) if p.exists() else 0)
print('Wan variant runner placeholder: Wan I2V workflow requires selected model and VRAM validation.')
PY
chmod +x /mnt/gpu-work/bin/render_variant_*.py
step Write readiness
python - <<'PY'
from pathlib import Path
import json, importlib.util
models=Path('/mnt/gpu-work/models')
report={
 'custom_nodes': {p.name:p.exists() for p in [Path('/mnt/gpu-work/tools/ComfyUI/custom_nodes/ComfyUI-VideoHelperSuite'),Path('/mnt/gpu-work/tools/ComfyUI/custom_nodes/ComfyUI-AnimateDiff-Evolved'),Path('/mnt/gpu-work/tools/ComfyUI/custom_nodes/ComfyUI-WanVideoWrapper'),Path('/mnt/gpu-work/tools/ComfyUI/custom_nodes/ComfyUI-KJNodes')]},
 'weights': {
  'RealESRGAN_x4plus': (models/'upscale_models/RealESRGAN_x4plus.pth').exists(),
  'AnimateDiff_mm_sd_v15_v2': (models/'animatediff/mm_sd_v15_v2.ckpt').exists(),
  'SVD_svd_xt': (models/'svd/svd_xt.safetensors').exists(),
  'Wan_files': sum(1 for _ in (models/'wan').rglob('*') if _.is_file()) if (models/'wan').exists() else 0,
 },
 'modules': {m: bool(importlib.util.find_spec(m)) for m in ['torch','diffusers','transformers','faster_whisper','manim','cv2','moviepy']},
 'notes': 'Variant scripts are installed as placeholders. Production SVD/Wan/AnimateDiff requires validated workflow JSON and model compatibility tests.'
}
Path('/mnt/gpu-work/status/video-models-readiness.json').write_text(json.dumps(report, indent=2))
print(json.dumps(report, indent=2))
PY
echo DONE > $STATUS/video-models.done
echo DONE > $STATUS/video-models.current
