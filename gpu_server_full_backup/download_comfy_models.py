from pathlib import Path
from urllib.request import urlopen, Request
import shutil
import sys


DOWNLOADS = [
    {
        "url": "https://huggingface.co/Comfy-Org/stable-diffusion-v1-5-archive/resolve/main/v1-5-pruned-emaonly-fp16.safetensors",
        "dest": "/mnt/gpu-work/tools/ComfyUI/models/checkpoints/sd15_v1-5-pruned-emaonly-fp16.safetensors",
        "min_size": 1_500_000_000,
    },
    {
        "url": "https://huggingface.co/guoyww/animatediff/resolve/main/mm_sd_v15_v2.ckpt",
        "dest": "/mnt/gpu-work/tools/ComfyUI/models/animatediff_models/mm_sd_v15_v2.ckpt",
        "min_size": 400_000_000,
    },
]


def download(url: str, dest: Path, min_size: int) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    part = dest.with_suffix(dest.suffix + ".part")
    if dest.exists() and dest.stat().st_size >= min_size:
        print(f"EXISTS {dest} {dest.stat().st_size}", flush=True)
        return
    print(f"DOWNLOADING {url} -> {dest}", flush=True)
    req = Request(url, headers={"User-Agent": "COMFYBranch/1.0"})
    with urlopen(req, timeout=60) as resp, part.open("wb") as f:
        shutil.copyfileobj(resp, f, length=1024 * 1024)
    size = part.stat().st_size
    print(f"DOWNLOADED_PART {part} {size}", flush=True)
    if size < min_size:
        raise RuntimeError(f"Downloaded file too small: {part} {size} < {min_size}")
    part.replace(dest)
    print(f"SAVED {dest} {dest.stat().st_size}", flush=True)


def main() -> int:
    for item in DOWNLOADS:
        download(item["url"], Path(item["dest"]), int(item["min_size"]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())