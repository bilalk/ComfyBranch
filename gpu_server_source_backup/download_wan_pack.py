from huggingface_hub import hf_hub_download
from pathlib import Path
import shutil, os
os.environ['HF_HOME']='/mnt/gpu-work/hf-cache'
os.environ['TMPDIR']='/mnt/gpu-work/tmp'
base=Path('/mnt/gpu-work/tools/ComfyUI/models')
items=[
 ('Kijai/WanVideo_comfy','Wan2_1-T2V-1_3B_fp8_e4m3fn.safetensors',base/'diffusion_models'/'Wan2_1-T2V-1_3B_fp8_e4m3fn.safetensors'),
 ('Kijai/WanVideo_comfy','Wan2_1_VAE_bf16.safetensors',base/'vae'/'Wan2_1_VAE_bf16.safetensors'),
 ('Kijai/WanVideo_comfy','umt5-xxl-enc-fp8_e4m3fn.safetensors',base/'text_encoders'/'umt5-xxl-enc-fp8_e4m3fn.safetensors'),
]
for repo,fn,dest in items:
 dest.parent.mkdir(parents=True, exist_ok=True)
 if dest.exists() and dest.stat().st_size>1024*1024:
  print('EXISTS', dest, dest.stat().st_size, flush=True); continue
 print('DOWNLOADING', fn, '->', dest, flush=True)
 p=hf_hub_download(repo, fn, cache_dir='/mnt/gpu-work/hf-cache')
 shutil.copy2(p,dest)
 print('SAVED', dest, dest.stat().st_size, flush=True)