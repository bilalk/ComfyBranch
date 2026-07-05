#!/usr/bin/env python3
from __future__ import annotations
import json, re, subprocess, textwrap, shutil
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

BASE = Path('/mnt/gpu-work')
INPUT = BASE / 'inputs' / 'content-engine-data'
DATA = INPUT / 'data' if (INPUT / 'data').exists() else INPUT
OUTBASE = BASE / 'outputs'
FFMPEG = BASE / 'tools' / 'ffmpeg' / 'ffmpeg'
W, H = 1280, 720

def seconds(t: str) -> int:
    m = re.search(r'(\d{1,2}):(\d{2})', str(t or ''))
    return int(m.group(1))*60 + int(m.group(2)) if m else 0

def parse_scene_time(label: str):
    ts = re.findall(r'(\d{1,2}:\d{2})', str(label or ''))
    start = seconds(ts[0]) if ts else 0
    end = seconds(ts[1]) if len(ts) > 1 else start + 10
    return start, max(end, start + 1)

def wrap(draw, text, font, max_width):
    words = str(text or '').split()
    lines=[]; cur=''
    for w in words:
        test=(cur+' '+w).strip()
        if draw.textbbox((0,0), test, font=font)[2] <= max_width:
            cur=test
        else:
            if cur: lines.append(cur)
            cur=w
    if cur: lines.append(cur)
    return lines

def asset_path_from_url(url: str) -> Path | None:
    if not url: return None
    if url.startswith('/assets/'):
        return DATA / 'assets' / url.replace('/assets/', '', 1)
    p=Path(url)
    return p if p.exists() else None

def first_audio(topic_id: str, handoff: dict) -> Path | None:
    audio = handoff.get('audio') or {}
    url = ((audio.get('generatedAudio') or {}).get('url') or '') if isinstance(audio, dict) else ''
    p = asset_path_from_url(url)
    if p and p.exists(): return p
    audiodir = DATA / 'assets' / topic_id / 'audio'
    mp3s = sorted(audiodir.glob('*.mp3'), key=lambda x: x.stat().st_mtime, reverse=True)
    return mp3s[0] if mp3s else None

def collect_scenes(handoff: dict):
    scenes = handoff.get('sceneAssetMap') or []
    if scenes:
        return scenes
    # fallback from visuals only
    out=[]
    for i,v in enumerate(handoff.get('visuals') or []):
        url=v.get('selectedImageUrl') or ((v.get('generatedImages') or [{}])[0].get('url') if v.get('generatedImages') else '')
        out.append({'sceneIndex':i,'sceneTime':v.get('timestamp','00:00'),'subtitle':v.get('title',''), 'assetUrl':url, 'visualTitle':v.get('title',''), 'mappingRule':'visual fallback'})
    return out

def make_frame(img_path: Path|None, subtitle: str, title: str, out: Path):
    canvas = Image.new('RGB', (W,H), (12,18,32))
    if img_path and img_path.exists():
        try:
            im=Image.open(img_path).convert('RGB')
            im.thumbnail((W, H-120), Image.LANCZOS)
            x=(W-im.width)//2; y=30
            canvas.paste(im,(x,y))
        except Exception:
            pass
    draw=ImageDraw.Draw(canvas)
    try:
        font_big=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 34)
        font_small=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 24)
    except Exception:
        font_big=font_small=None
    # bottom caption box
    draw.rectangle((0,H-115,W,H), fill=(0,0,0))
    lines = wrap(draw, subtitle or title, font_big, W-80)[:2]
    y=H-100
    for line in lines:
        draw.text((40,y), line, fill=(255,255,255), font=font_big)
        y += 40
    if title and title != subtitle:
        small = wrap(draw, title, font_small, W-80)[:1]
        for line in small:
            draw.text((40,y), line, fill=(160,220,255), font=font_small)
    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out, quality=95)

def render_topic(topic_json: Path):
    topic=json.loads(topic_json.read_text(encoding='utf-8-sig'))
    topic_id=topic['id']
    handoff_path = DATA / 'assets' / topic_id / 'video-outline' / f'{topic_id}-part2-renderer-handoff.json'
    if not handoff_path.exists():
        return {'topic':topic_id,'ok':False,'error':'missing handoff'}
    handoff=json.loads(handoff_path.read_text(encoding='utf-8-sig'))
    outdir=OUTBASE/topic_id
    frames=outdir/'frames'
    outdir.mkdir(parents=True, exist_ok=True)
    scenes=collect_scenes(handoff)
    if not scenes:
        return {'topic':topic_id,'ok':False,'error':'no scenes'}
    concat=[]
    for i,sc in enumerate(scenes):
        start,end=parse_scene_time(sc.get('sceneTime',''))
        dur=max(2, end-start)
        imgp=asset_path_from_url(sc.get('assetUrl',''))
        frame=frames/f'frame_{i:03d}.jpg'
        make_frame(imgp, sc.get('subtitle',''), sc.get('visualTitle',''), frame)
        concat.append((frame,dur))
    concat_file=outdir/'concat.txt'
    with concat_file.open('w', encoding='utf-8') as f:
        for frame,dur in concat:
            f.write(f"file '{frame.as_posix()}'\n")
            f.write(f'duration {dur}\n')
        f.write(f"file '{concat[-1][0].as_posix()}'\n")
    silent=outdir/'video_silent.mp4'
    cmd=[str(FFMPEG),'-y','-f','concat','-safe','0','-i',str(concat_file),'-vsync','vfr','-pix_fmt','yuv420p','-c:v','libx264',str(silent)]
    subprocess.check_call(cmd)
    audio=first_audio(topic_id,handoff)
    final=outdir/f'{topic_id}_part2_preview.mp4'
    if audio:
        cmd=[str(FFMPEG),'-y','-i',str(silent),'-i',str(audio),'-c:v','copy','-c:a','aac','-shortest',str(final)]
    else:
        cmd=[str(FFMPEG),'-y','-i',str(silent),'-c','copy',str(final)]
    subprocess.check_call(cmd)
    backup_dir=BASE/'rendered-video-backups'/topic_id
    backup_dir.mkdir(parents=True, exist_ok=True)
    backup_final=backup_dir/final.name
    shutil.copy2(final, backup_final)
    manifest={'topic':topic_id,'title':topic.get('title'),'ok':True,'output':str(final),'backupOutput':str(backup_final),'audio':str(audio) if audio else None,'scenes':len(scenes),'toolchain':['Pillow','FFmpeg','local Part1 images/audio']}
    (outdir/'render_manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
    (backup_dir/'render_manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
    return manifest

def main():
    topics=sorted((DATA/'topics').glob('*.json'))
    results=[]
    for t in topics:
        try:
            print('RENDER', t.name, flush=True)
            results.append(render_topic(t))
        except Exception as e:
            results.append({'topic':t.name,'ok':False,'error':str(e)})
            print('ERROR', t.name, e, flush=True)
    (OUTBASE/'batch_render_results.json').write_text(json.dumps(results, indent=2), encoding='utf-8')
    print(json.dumps(results, indent=2))
if __name__=='__main__': main()

