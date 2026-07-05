# COMFYBranch Remote Video Lab

COMFYBranch is a localhost Windows controller for the remote Ubuntu GPU server.

It provides:

- A simple prompt box.
- Automatic production-prompt expansion.
- Automatic 6–10 second chunk planning.
- Capability-driven UI based on what is actually installed on the GPU server.
- A safe Blender procedural 3D fallback that is already proven on the GPU server.
- ComfyUI API workflow support once ComfyUI dependencies, models, and API-format workflow JSON files are available.

Run:

```powershell
& "C:\Users\faraz\Desktop\multi-format-content-engine\COMFYBranch\start-comfybranch.ps1"
```

Open:

```text
http://127.0.0.1:8788
```

## Current detected GPU server reality

- GPU: NVIDIA L4, about 23 GB VRAM.
- Installed/seen ComfyUI custom nodes:
  - ComfyUI-Manager
  - ComfyUI-VideoHelperSuite
  - ComfyUI-WanVideoWrapper
  - ComfyUI-KJNodes
  - ComfyUI-AnimateDiff-Evolved
- Installed tools:
  - Blender headless
  - FFmpeg
- Current blocker:
  - ComfyUI API is not ready yet because dependencies/models/workflow templates still need validation.

## Workflow folder

Put ComfyUI API-format workflow JSON files here:

```text
C:\Users\faraz\Desktop\multi-format-content-engine\COMFYBranch\workflows\comfyui
```

Until model files and working API workflow JSON files exist, the UI will not falsely enable ComfyUI video modes. It will keep the proven Blender fallback available.