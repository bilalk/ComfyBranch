ï»¿# Copy/Paste Prompt for Agent 3 + Agent 6

You are an AI coding/rendering agent working on the Multi-format Content Engine Part 2 GPU renderer.

## Your assigned scope

You own:

- Agent 3: FFmpeg/MoviePy editorial renderer.
- Agent 6: ComfyUI / Stable Video Diffusion / AnimateDiff / Wan experiment renderer.

Do **not** modify Part 1 generation logic unless absolutely necessary. Do **not** break existing working preview rendering, dashboard, topic JSON, handoff JSON, or local asset reuse rules.

## Current environment

Windows Part 1 app folder:

```text
C:\Users\faraz\Desktop\multi-format-content-engine
```

GPU server:

```text
Host: 52.206.69.50
SSH user: ubuntu
Key on Windows: C:\Users\faraz\Downloads\voicekey.ppk
Dashboard: http://52.206.69.50:4000
RDP: 52.206.69.50:3389
GPU work root: /mnt/gpu-work
```

Important GPU paths:

```text
/mnt/gpu-work/inputs/content-engine-data
/mnt/gpu-work/outputs
/mnt/gpu-work/logs
/mnt/gpu-work/models
/mnt/gpu-work/tools
/mnt/gpu-work/runbooks
```

Current practical batch renderer:

```text
/mnt/gpu-work/bin/batch_render_from_handoff.py
```

Current dashboard app:

```text
/mnt/gpu-work/web/gpu_status_server.py
```

Current runbooks:

```text
/mnt/gpu-work/runbooks/GPU_RENDERER_SETUP_AND_OPERATIONS.md
/mnt/gpu-work/runbooks/all-purpose-video-renderer-product-plan.md
```

## Non-negotiable rules

1. Part 2 must use approved local Part 1 assets first.
2. Do not call paid GPT/image/audio APIs during GPU rendering.
3. Do not delete existing outputs, inputs, models, or topic data.
4. Every new renderer must write a manifest JSON explaining tools used, inputs, outputs, duration, and errors.
5. Every generated video must appear on the dashboard at port 4000.
6. Keep all big files under `/mnt/gpu-work`, not root `/`.
7. Preserve compatibility with existing Part 2 handoff JSON.
8. If a model/workflow is missing, fail gracefully with an explanatory manifest; do not silently crash.

## Input contract

Each topic bundle contains:

```text
data/topics/{topicId}.json
data/topics/{topicId}.md
data/assets/{topicId}/video-outline/{topicId}-part2-renderer-handoff.json
data/assets/{topicId}/images/*
data/assets/{topicId}/audio/*
```

The handoff JSON includes:

- `sceneAssetMap`
- `videoScript`
- `audio`
- `visuals`
- `techStack`
- `rendererNotes`
- `part2Instructions`

Your renderers must read this structure.

## Your deliverables

### Deliverable A: Improve FFmpeg/MoviePy editorial renderer

Create or upgrade:

```text
/mnt/gpu-work/bin/render_editorial.py
```

It should:

1. Read a topic id or handoff path.
2. Use `sceneAssetMap` to map scenes to local images.
3. Use the local narration MP3 from handoff/audio folder.
4. Produce a polished 16:9 video with:
   - smooth crossfades,
   - Ken Burns pan/zoom,
   - subtitle/lower-third overlays,
   - simple title card,
   - end card,
   - audio muxing,
   - optional background music if available locally.
5. Export:

```text
/mnt/gpu-work/outputs/{topicId}/editorial/{topicId}_editorial_16x9.mp4
/mnt/gpu-work/outputs/{topicId}/editorial/{topicId}_editorial_manifest.json
```

6. Optionally create reels:

```text
/mnt/gpu-work/outputs/{topicId}/editorial/reels/{topicId}_reel_01.mp4
```

### Deliverable B: ComfyUI/SVD/AnimateDiff/Wan variant scripts

Create these scripts:

```text
/mnt/gpu-work/bin/render_variant_comfy.py
/mnt/gpu-work/bin/render_variant_svd.py
/mnt/gpu-work/bin/render_variant_animatediff.py
/mnt/gpu-work/bin/render_variant_wan.py
```

Each script should:

1. Read topic id / handoff path.
2. Use approved local selected images as image-to-video inputs.
3. Generate short motion clips per selected scene where technically possible.
4. Assemble generated clips with the local narration audio.
5. Output to:

```text
/mnt/gpu-work/outputs/{topicId}/variants/comfy/{topicId}_comfy.mp4
/mnt/gpu-work/outputs/{topicId}/variants/svd/{topicId}_svd.mp4
/mnt/gpu-work/outputs/{topicId}/variants/animatediff/{topicId}_animatediff.mp4
/mnt/gpu-work/outputs/{topicId}/variants/wan/{topicId}_wan.mp4
```

6. Always create a manifest, even on failure:

```text
/mnt/gpu-work/outputs/{topicId}/variants/{variant}/manifest.json
```

The manifest must include:

- model paths used,
- workflow path used,
- input image list,
- output clips,
- final MP4 path,
- error if failed,
- whether fallback was used.

### Deliverable C: ComfyUI workflow files

Create workflow templates under:

```text
/mnt/gpu-work/models/comfy_workflows
```

Minimum expected files:

```text
svd_image_to_video.json
animatediff_image_to_video.json
wan_image_to_video.json
```

If exact workflow nodes differ because installed ComfyUI nodes changed, document what is missing and what node package is required.

### Deliverable D: Dashboard integration

Update:

```text
/mnt/gpu-work/web/gpu_status_server.py
```

Add navigation sections/tabs:

- Main previews
- Editorial renderer outputs
- ComfyUI variants
- SVD variants
- AnimateDiff variants
- Wan variants
- Tool readiness
- Logs

Dashboard must play videos in-browser and show manifest/errors.

### Deliverable E: Tests

Run against at least one topic first:

```text
suction-plate-3d-education-2026-07-02
```

Then run for all available topics if stable.

## Existing generated topics

Current topics include:

```text
default-sunscreen-sticks-consumers-facts
finger-exercise-equipment-consumer-expectations-2026
glueless-wigs-demand-2026-education-workspace
suction-plate-3d-education-2026-07-02
```

## Current advanced install status

Current readiness is stored at:

```text
/mnt/gpu-work/status/advanced-readiness.json
/mnt/gpu-work/status/video-models-readiness.json
```

Installed or downloaded so far:

- PyTorch CUDA available on NVIDIA L4.
- ComfyUI source.
- ComfyUI VideoHelperSuite.
- ComfyUI AnimateDiff-Evolved.
- ComfyUI WanVideoWrapper.
- ComfyUI KJNodes.
- Real-ESRGAN x4plus weights.
- AnimateDiff `mm_sd_v15_v2.ckpt`.
- SVD `svd_xt.safetensors`.
- Wan2.1 T2V 1.3B snapshot.

## Acceptance criteria

You are done when:

1. Existing `/mnt/gpu-work/bin/batch_render_from_handoff.py` still works.
2. New editorial renderer creates visibly smoother videos than current frame-cut preview.
3. At least one Comfy/SVD/AnimateDiff/Wan variant either successfully renders or produces a clear manifest explaining the missing model/workflow blocker.
4. Dashboard on port 4000 shows all outputs in organized sections.
5. No existing videos or handoff files are broken.
6. All code is documented in `/mnt/gpu-work/runbooks`.

## Do not do

- Do not call paid APIs.
- Do not move `/mnt/gpu-work`.
- Do not install large files on `/`.
- Do not delete model weights.
- Do not overwrite existing preview videos unless writing a new versioned output.
