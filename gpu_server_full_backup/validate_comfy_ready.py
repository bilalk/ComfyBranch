import json
import urllib.request
from pathlib import Path


def get_json(url: str):
    with urllib.request.urlopen(url, timeout=20) as resp:
        return json.loads(resp.read().decode("utf-8"))


system = get_json("http://127.0.0.1:8188/system_stats")
print("SYSTEM_OK", system["system"].get("comfyui_version"), system["devices"][0].get("name"))

info = get_json("http://127.0.0.1:8188/object_info")
print("NODE_COUNT", len(info))
for key in ["CheckpointLoaderSimple", "CLIPTextEncode", "KSampler", "VAEDecode", "VHS_VideoCombine", "ADE_LoadAnimateDiffModel", "ADE_UseEvolvedSampling"]:
    print("NODE", key, key in info)

if "CheckpointLoaderSimple" in info:
    print("CHECKPOINTS", info["CheckpointLoaderSimple"]["input"]["required"]["ckpt_name"][0])
if "ADE_LoadAnimateDiffModel" in info:
    print("ANIMATEDIFF_MODELS", info["ADE_LoadAnimateDiffModel"]["input"]["required"]["model_name"][0])

for folder in ["checkpoints", "animatediff_models"]:
    root = Path("/mnt/gpu-work/tools/ComfyUI/models") / folder
    print("FILES", folder)
    for p in sorted(root.glob("*")):
        if p.is_file():
            print(p.name, p.stat().st_size)