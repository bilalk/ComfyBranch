ï»¿# All-Purpose GPU Video/Reels Renderer Product Plan

## Goal
Build an all-purpose Part 2 renderer that converts Part 1 topic handoffs into polished videos/reels using the best renderer track for the topic: editorial slideshow, product demo, 3D explainer, 2D/cartoon, motion graphics, image-to-video, or hybrid.

Part 2 must use approved local Part 1 assets first. Paid GPT/image/audio APIs are not called during GPU rendering.

## Inputs
Each job receives a topic bundle:

- `data/topics/{topicId}.json`
- `data/topics/{topicId}.md`
- `data/assets/{topicId}/video-outline/{topicId}-part2-renderer-handoff.json`
- `data/assets/{topicId}/images/*`
- `data/assets/{topicId}/audio/*`

The handoff JSON must include:

- `techStack`
- `rendererNotes`
- `videoScript`
- `sceneAssetMap`
- `visuals`
- `audio`
- `approvals`
- `part2Instructions`

## Renderer modes

### 1. Editorial Ken Burns / product explainer
Use when the topic is consumer/ecommerce/editorial and has approved still images.

Tools:
- FFmpeg
- MoviePy
- Pillow/OpenCV

Features:
- pan/zoom on images
- lower thirds
- animated captions
- product callouts
- background music bed
- scene transitions
- audio normalization
- 16:9, 9:16, 1:1 exports

### 2. 3D product/mechanism explainer
Use when the topic needs mechanism explanation, product components, cutaways, physics, or product render.

Tools:
- Blender headless Python
- FFmpeg
- Pillow/OpenCV

Features:
- product geometry or simplified proxy models
- camera paths
- exploded views
- arrows/labels
- material/lighting presets
- render passes
- final assembly with narration

### 3. 2D motion graphics / infographic
Use for science, tech, abstract explanation, comparisons, timelines, charts.

Tools:
- Manim
- FFmpeg
- Pillow

Features:
- diagrams
- charts
- arrows
- formulas
- step-by-step motion
- clean educational transitions

### 4. Character/cartoon/story mode
Use for children/story/mascot/character-led educational content.

Tools:
- OpenToonz/Synfig if installed, otherwise Blender grease-pencil or Manim/Pillow animation
- FFmpeg

Features:
- character sheet reuse
- simple pose changes
- scene backgrounds
- subtitles and narration

### 5. Image-to-video enhancement mode
Use only after approved stills exist and the reviewer wants motion trials.

Tools:
- ComfyUI with AnimateDiff/SVD/Wan workflows when model weights are installed
- RIFE for interpolation
- FFmpeg

Features:
- short motion clips from approved stills
- artifact review gate
- fallback to still-image Ken Burns if generated motion is bad

### 6. Upscale/interpolation mode
Use after video draft approval.

Tools:
- Real-ESRGAN or other local upscalers when weights installed
- RIFE when weights installed
- FFmpeg

Features:
- upscaling selected clips/images
- frame interpolation where appropriate
- avoid soap-opera look

## Job pipeline

1. Ingest topic bundle into `/mnt/gpu-work/inputs/{topicId}`.
2. Validate required files and approvals.
3. Read `techStack.id`, `techStack.rendererRule`, and `sceneAssetMap`.
4. Select renderer mode:
   - product/editorial -> Ken Burns/product explainer
   - mechanism/3D -> Blender 3D
   - science/math/data -> Manim
   - character/story -> 2D/cartoon
   - cinematic stills -> image-to-video trial + fallback
5. Build a per-scene render plan.
6. Generate scene clips locally.
7. Assemble narration/audio/subtitles/music.
8. Export preview MP4.
9. Show preview on dashboard.
10. Human approves/rejects.
11. Export final platform formats.

## Dashboard requirements

The GPU dashboard on port 4000 should show:

- job list
- status/progress logs
- playable previews
- toolchain used per video
- scene-to-asset map
- output downloads
- failure messages
- tool readiness table

## Current GPU readiness

Ready:
- NVIDIA L4 + PyTorch CUDA
- FFmpeg
- MoviePy
- Pillow/OpenCV
- Blender headless
- FastAPI dashboard
- Manim installed in Python 3.12 advanced env
- faster-whisper installed
- ComfyUI source installed
- Real-ESRGAN source installed
- RIFE source installed
- Forge source installed

Not production-ready until model weights/workflows are added:
- SVD
- AnimateDiff
- Wan
- Real-ESRGAN weights
- RIFE weights
- ComfyUI workflows/models
- Forge checkpoint models

OpenToonz/Synfig is not installed yet; decide later if needed because it is GUI-heavy and less central to the initial headless pipeline.

## Immediate next milestones

### Milestone A: Better current renderer
Improve the current FFmpeg/Pillow renderer:
- smooth crossfades
- Ken Burns camera motion
- subtitle burn-in
- logo/end card
- music bed
- per-scene callout overlays

### Milestone B: Blender product renderer
Create Blender templates:
- product turntable
- exploded product view
- pressure/arrow diagram
- ecommerce packshot
- label overlays

### Milestone C: Manim explainer renderer
Create Manim templates:
- comparison table
- timeline
- mechanism diagram
- chart
- numbered process

### Milestone D: ComfyUI motion trials
Install model weights and workflows for:
- SVD or equivalent image-to-video
- AnimateDiff
- Wan if compatible
Run motion trials as optional variants, never as mandatory final output.

### Milestone E: Final export suite
Export:
- 16:9 YouTube
- 9:16 reels
- 1:1 social preview
- thumbnails
- SRT/VTT captions
- manifest JSON

## Multi-agent division

Agent 1: Part 1 app/handoff quality.
Agent 2: GPU ingestion/dashboard/jobs.
Agent 3: FFmpeg/MoviePy editorial renderer.
Agent 4: Blender 3D renderer templates.
Agent 5: Manim/infographic renderer.
Agent 6: ComfyUI/diffusion/AnimateDiff/Wan experimentation.
Agent 7: QA, approvals, export packaging.
