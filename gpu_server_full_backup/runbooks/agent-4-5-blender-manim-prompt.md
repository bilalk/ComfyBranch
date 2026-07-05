ï»¿# Copy/Paste Prompt for Agent 4 + Agent 5

You are an AI coding/rendering agent working on the Multi-format Content Engine Part 2 GPU renderer.

## Your assigned scope

You own:

- Agent 4: Blender 3D renderer templates.
- Agent 5: Manim / infographic renderer.

Do **not** work on ComfyUI/SVD/Wan unless needed only for compatibility notes. Do **not** break the existing FFmpeg/MoviePy preview renderer or dashboard.

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
GPU work root: /mnt/gpu-work
```

Important GPU paths:

```text
/mnt/gpu-work/inputs/content-engine-data
/mnt/gpu-work/outputs
/mnt/gpu-work/logs
/mnt/gpu-work/tools/blender
/mnt/gpu-work/tools/micromamba-root/envs/adv312
/mnt/gpu-work/runbooks
```

## Non-negotiable rules

1. Use local Part 1 assets and handoff JSON.
2. Do not call paid GPT/image/audio APIs.
3. Keep big generated outputs under `/mnt/gpu-work/outputs`.
4. Do not break existing dashboard or generated preview videos.
5. Every output must have a manifest JSON.
6. All renderer templates must be callable headlessly from command line.

## Input contract

Each topic bundle contains:

```text
data/topics/{topicId}.json
data/assets/{topicId}/video-outline/{topicId}-part2-renderer-handoff.json
data/assets/{topicId}/images/*
data/assets/{topicId}/audio/*
```

Handoff JSON contains:

- `sceneAssetMap`
- `videoScript`
- `techStack`
- `rendererNotes`
- `part2Instructions`

## Your deliverables

### Deliverable A: Blender 3D product renderer

Create:

```text
/mnt/gpu-work/bin/render_blender_product.py
```

It should:

1. Read topic id or handoff path.
2. Decide if Blender renderer is appropriate from `techStack` and `rendererNotes`.
3. Generate simple 3D scene templates for:
   - product turntable,
   - exploded product view,
   - mechanism/cutaway view,
   - arrow/pressure/flow diagram,
   - product comparison layout.
4. Render short clips per scene or per selected subset.
5. Use local audio during final assembly.
6. Export:

```text
/mnt/gpu-work/outputs/{topicId}/blender/{topicId}_blender_3d.mp4
/mnt/gpu-work/outputs/{topicId}/blender/manifest.json
```

Initial target topic:

```text
suction-plate-3d-education-2026-07-02
```

For that topic, create a Blender scene that explains:

```text
press -> seal -> resist -> release
```

with:

- a simplified silicone divided plate,
- flexible base/rim representation,
- downward pressure arrows,
- air escape arrows,
- release tab animation,
- clean ecommerce educational style.

### Deliverable B: Blender template library

Create reusable Blender Python modules under:

```text
/mnt/gpu-work/projects/blender_templates
```

Suggested files:

```text
materials.py
camera.py
lighting.py
text_labels.py
arrows.py
product_plate.py
turntable.py
exploded_view.py
pressure_diagram.py
```

Every module should be usable headlessly.

### Deliverable C: Manim infographic renderer

Create:

```text
/mnt/gpu-work/bin/render_manim_infographic.py
```

It should:

1. Read topic id or handoff path.
2. Generate Manim scenes for:
   - process steps,
   - comparison tables,
   - timelines,
   - mechanism diagrams,
   - buyer checklists.
3. Export transparent/solid clips.
4. Assemble with local audio and/or existing visual assets.
5. Output:

```text
/mnt/gpu-work/outputs/{topicId}/manim/{topicId}_manim_infographic.mp4
/mnt/gpu-work/outputs/{topicId}/manim/manifest.json
```

Initial target topics:

```text
suction-plate-3d-education-2026-07-02
finger-exercise-equipment-consumer-expectations-2026
```

### Deliverable D: Dashboard integration

Update:

```text
/mnt/gpu-work/web/gpu_status_server.py
```

Add sections for:

- Blender 3D outputs
- Manim infographic outputs
- manifest/errors

Videos must be playable in browser.

### Deliverable E: Tests

Run smoke tests:

```bash
source /mnt/gpu-work/bin/renderer-env.sh
/mnt/gpu-work/tools/blender/blender -b --python your_test_script.py
micromamba activate adv312
manim --version
```

Then render at least one short Blender clip and one short Manim clip.

## Acceptance criteria

You are done when:

1. Blender renderer creates at least one usable 3D MP4 for suction plate.
2. Manim renderer creates at least one infographic MP4.
3. Both outputs appear on dashboard port 4000.
4. Existing preview videos remain playable.
5. Scripts are documented and versioned.
6. All outputs are written under `/mnt/gpu-work/outputs/{topicId}`.

## Do not do

- Do not call paid APIs.
- Do not modify Part 1 generation logic.
- Do not delete existing outputs.
- Do not store large files on `/`.
- Do not break dashboard port 4000.
