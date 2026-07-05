import math
from pathlib import Path

import bpy
from mathutils import Vector


OUTPUT = "/mnt/gpu-work/outputs/comfyui-renders/futuristic-fidget-spinner-3d.mp4"


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def material(name, color, metallic=0.0, roughness=0.3, emission=None, strength=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Metallic"].default_value = metallic
        bsdf.inputs["Roughness"].default_value = roughness
        if emission:
            bsdf.inputs["Emission Color"].default_value = emission
            bsdf.inputs["Emission Strength"].default_value = strength
    return mat


def add_cylinder(name, radius, depth, location, mat, vertices=96):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    try:
        bevel = obj.modifiers.new("soft bevel", "BEVEL")
        bevel.width = 0.035
        bevel.segments = 8
        obj.modifiers.new("polished smoothing", "WEIGHTED_NORMAL")
    except Exception:
        pass
    return obj


def add_torus(name, major, minor, location, mat):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=144, minor_segments=18, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    return obj


def add_spoke(name, angle, length, width, depth, mat):
    x = math.cos(angle) * length / 2
    y = math.sin(angle) * length / 2
    bpy.ops.mesh.primitive_cube_add(size=1, location=(x, y, 0))
    obj = bpy.context.object
    obj.name = name
    obj.rotation_euler[2] = angle
    obj.dimensions = (length, width, depth)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    bevel = obj.modifiers.new("rounded machined edges", "BEVEL")
    bevel.width = 0.08
    bevel.segments = 10
    obj.modifiers.new("weighted normals", "WEIGHTED_NORMAL")
    return obj


def parent_to(obj, parent):
    obj.parent = parent
    return obj


def build_spinner():
    chrome = material("brushed dark titanium chrome", (0.63, 0.68, 0.74, 1), metallic=1.0, roughness=0.18)
    gunmetal = material("gunmetal inner bevels", (0.12, 0.14, 0.17, 1), metallic=1.0, roughness=0.24)
    blue_glow = material("cyan studio glow accents", (0.05, 0.75, 1.0, 1), metallic=0.2, roughness=0.18, emission=(0.03, 0.7, 1.0, 1), strength=1.8)
    black = material("black bearing shadow", (0.005, 0.006, 0.008, 1), metallic=0.0, roughness=0.45)

    rotor = bpy.data.objects.new("smooth spinning futuristic fidget spinner rotor", None)
    bpy.context.collection.objects.link(rotor)

    parts = []
    parts.append(add_cylinder("central metallic bearing", 0.46, 0.28, (0, 0, 0), chrome))
    parts.append(add_torus("central cyan luminous ring", 0.48, 0.035, (0, 0, 0.16), blue_glow))
    parts.append(add_cylinder("central dark bearing cap", 0.24, 0.31, (0, 0, 0.02), gunmetal))

    for i in range(3):
        angle = i * math.tau / 3
        cx = math.cos(angle) * 1.65
        cy = math.sin(angle) * 1.65
        parts.append(add_spoke(f"aerospace triangular spoke {i+1}", angle, 1.85, 0.32, 0.18, chrome))
        parts.append(add_cylinder(f"rounded metallic spinner lobe {i+1}", 0.72, 0.22, (cx, cy, 0), chrome))
        parts.append(add_torus(f"cyan glowing lobe ring {i+1}", 0.48, 0.035, (cx, cy, 0.14), blue_glow))
        parts.append(add_cylinder(f"dark circular lobe cutout {i+1}", 0.34, 0.25, (cx, cy, 0.015), black))
        parts.append(add_cylinder(f"small inner bearing highlight {i+1}", 0.18, 0.28, (cx, cy, 0.035), gunmetal))

    for obj in parts:
        parent_to(obj, rotor)

    rotor.rotation_euler[0] = math.radians(10)
    rotor.keyframe_insert(data_path="rotation_euler", frame=1)
    rotor.rotation_euler[2] = math.radians(1440)
    rotor.keyframe_insert(data_path="rotation_euler", frame=144)
    if rotor.animation_data and rotor.animation_data.action:
        for fc in rotor.animation_data.action.fcurves:
            for kp in fc.keyframe_points:
                kp.interpolation = "LINEAR"
    return rotor


def add_environment():
    floor_mat = material("dark reflective studio floor", (0.015, 0.018, 0.026, 1), metallic=0.0, roughness=0.18)
    bpy.ops.mesh.primitive_plane_add(size=9, location=(0, 0, -0.19))
    floor = bpy.context.object
    floor.name = "dark premium studio floor"
    floor.data.materials.append(floor_mat)

    bpy.ops.object.light_add(type="AREA", location=(0, -3.8, 4.2))
    key = bpy.context.object
    key.name = "large softbox key light"
    key.data.energy = 650
    key.data.size = 5

    bpy.ops.object.light_add(type="AREA", location=(-3.2, 2.5, 2.4))
    rim = bpy.context.object
    rim.name = "cool cyan rim light"
    rim.data.energy = 240
    rim.data.size = 3
    rim.data.color = (0.55, 0.86, 1.0)

    bpy.ops.object.camera_add(location=(0, -4.9, 2.25), rotation=(math.radians(66), 0, 0))
    camera = bpy.context.object
    bpy.context.scene.camera = camera
    camera.name = "cinematic product camera"
    camera.data.lens = 58
    camera.data.dof.use_dof = True
    camera.data.dof.focus_distance = 5.0
    camera.data.dof.aperture_fstop = 5.6


def configure_render():
    scene = bpy.context.scene
    scene.frame_start = 1
    scene.frame_end = 144
    scene.frame_set(1)
    scene.render.fps = 24
    scene.render.resolution_x = 1920
    scene.render.resolution_y = 1080
    scene.render.resolution_percentage = 100

    scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in [item.identifier for item in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items] else "BLENDER_EEVEE"
    if hasattr(scene, "eevee"):
        if hasattr(scene.eevee, "use_bloom"):
            scene.eevee.use_bloom = True
        if hasattr(scene.eevee, "use_motion_blur"):
            scene.eevee.use_motion_blur = True
        if hasattr(scene.eevee, "motion_blur_shutter"):
            scene.eevee.motion_blur_shutter = 0.6

    scene.world = bpy.data.worlds.new("deep blue gradient studio") if not scene.world else scene.world
    scene.world.color = (0.01, 0.015, 0.035)

    scene.render.filepath = OUTPUT
    scene.render.image_settings.file_format = "FFMPEG"
    scene.render.ffmpeg.format = "MPEG4"
    scene.render.ffmpeg.codec = "H264"
    scene.render.ffmpeg.constant_rate_factor = "HIGH"
    scene.render.ffmpeg.ffmpeg_preset = "GOOD"


def main():
    Path(OUTPUT).parent.mkdir(parents=True, exist_ok=True)
    clear_scene()
    build_spinner()
    add_environment()
    configure_render()
    bpy.ops.render.render(animation=True)


if __name__ == "__main__":
    main()