#!/usr/bin/env bash
set -euo pipefail
source /mnt/gpu-work/bin/renderer-env.sh
mkdir -p /mnt/gpu-work/outputs/smoke
ffmpeg -y -f lavfi -i testsrc=size=1280x720:rate=30 -f lavfi -i sine=frequency=1000:sample_rate=48000 -t 3 -c:v libx264 -pix_fmt yuv420p -c:a aac /mnt/gpu-work/outputs/smoke/ffmpeg-smoke.mp4
cat > /mnt/gpu-work/tmp/moviepy_smoke.py <<'PY'
from moviepy import ColorClip
clip = ColorClip((640, 360), color=(20, 80, 160), duration=2)
clip.write_videofile('/mnt/gpu-work/outputs/smoke/moviepy-smoke.mp4', fps=24, codec='libx264', audio=False, logger=None)
PY
python /mnt/gpu-work/tmp/moviepy_smoke.py
cat > /mnt/gpu-work/tmp/blender_smoke.py <<'PY'
import bpy
bpy.ops.mesh.primitive_cube_add()
bpy.ops.wm.save_as_mainfile(filepath='/mnt/gpu-work/outputs/smoke/blender-smoke.blend')
PY
blender -b --factory-startup --python /mnt/gpu-work/tmp/blender_smoke.py
nvidia-smi > /mnt/gpu-work/outputs/smoke/nvidia-smi.txt
