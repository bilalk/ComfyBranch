from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from pathlib import Path
import subprocess, json, time, html, os
BASE=Path('/mnt/gpu-work')
OUT=BASE/'outputs'
LOG=BASE/'logs'
STATUS=BASE/'status'
app=FastAPI(title='GPU Renderer Dashboard')
app.mount('/outputs', StaticFiles(directory=str(OUT)), name='outputs')
app.mount('/logs', StaticFiles(directory=str(LOG)), name='logs')

def sh(cmd, timeout=8):
    try: return subprocess.check_output(cmd, shell=True, text=True, stderr=subprocess.STDOUT, timeout=timeout)
    except Exception as e: return str(e)

def load_json(p):
    try: return json.loads(Path(p).read_text(encoding='utf-8'))
    except Exception: return None

def tool_status():
    adv=load_json(STATUS/'advanced-readiness.json') or {}
    modules=adv.get('modules',{}) if isinstance(adv,dict) else {}
    tools=adv.get('tools',{}) if isinstance(adv,dict) else {}
    rows=[]
    def add(name, ready, detail, headless='yes'):
        rows.append({'name':name,'ready':bool(ready),'detail':detail,'headless':headless})
    add('NVIDIA L4 / driver', 'NVIDIA L4' in sh('nvidia-smi --query-gpu=name --format=csv,noheader'), sh('nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader').strip())
    add('FFmpeg', Path('/mnt/gpu-work/tools/ffmpeg/ffmpeg').exists(), sh('/mnt/gpu-work/tools/ffmpeg/ffmpeg -version | head -1').strip())
    add('Blender headless', Path('/mnt/gpu-work/tools/blender/blender').exists(), sh('/mnt/gpu-work/tools/blender/blender --version | head -1').strip())
    add('MoviePy / Python video stack', modules.get('moviepy') or Path('/mnt/gpu-work/tools/venv').exists(), 'MoviePy/OpenCV/Pillow installed in venv')
    add('Whisper / subtitle alignment', modules.get('faster_whisper'), 'faster-whisper module in advanced env' if modules.get('faster_whisper') else 'pending/failed')
    add('Manim', modules.get('manim'), 'manim module in advanced env' if modules.get('manim') else 'pending/failed')
    add('ComfyUI API', tools.get('ComfyUI') or Path('/mnt/gpu-work/tools/ComfyUI').exists(), 'source installed; model weights not bundled', 'yes, after models/workflows')
    add('Real-ESRGAN', tools.get('Real-ESRGAN') or Path('/mnt/gpu-work/tools/Real-ESRGAN').exists(), 'source installed; weights required', 'yes')
    add('RIFE', tools.get('RIFE') or Path('/mnt/gpu-work/tools/ECCV2022-RIFE').exists(), 'source installed; weights required', 'yes')
    add('A1111/Forge', tools.get('Forge') or Path('/mnt/gpu-work/tools/stable-diffusion-webui-forge').exists(), 'source installed; models required', 'web/headless API')
    synfig_ready = bool(sh('command -v synfig', timeout=3).strip())
    opentoonz_ready = bool(sh('command -v opentoonz', timeout=3).strip())
    add('Synfig / OpenToonz 2D tools', synfig_ready or opentoonz_ready, ('Synfig installed' if synfig_ready else '') + ('; OpenToonz installed' if opentoonz_ready else '') if (synfig_ready or opentoonz_ready) else 'Optional GUI-heavy 2D tools not installed; not required for current FFmpeg/MoviePy preview renderer', 'limited/headless via CLI where supported')
    svd_ready = Path('/mnt/gpu-work/models/svd/svd_xt.safetensors').exists()
    animatediff_ready = Path('/mnt/gpu-work/models/animatediff/mm_sd_v15_v2.ckpt').exists()
    wan_ready = Path('/mnt/gpu-work/models/wan/Wan2.1-T2V-1.3B/diffusion_pytorch_model.safetensors').exists()
    add('SVD / AnimateDiff / Wan model weights', svd_ready and animatediff_ready and wan_ready, f"SVD={'yes' if svd_ready else 'no'}; AnimateDiff={'yes' if animatediff_ready else 'no'}; Wan={'yes' if wan_ready else 'no'}. Workflows still need end-to-end validation before production use.", 'yes after workflow validation')
    return rows, adv

def videos():
    vids=[]
    for p in sorted(OUT.rglob('*_part2_preview.mp4'), key=lambda x:x.stat().st_mtime, reverse=True):
        rel=p.relative_to(OUT).as_posix()
        manifest=load_json(p.parent/'render_manifest.json') or {}
        vids.append({'rel':rel,'url':'/outputs/'+rel,'name':p.name,'topic':manifest.get('title') or p.parent.name,'size':p.stat().st_size,'mtime':p.stat().st_mtime,'manifest':manifest})
    return vids

@app.get('/')
def index():
    vids=videos(); rows,adv=tool_status()
    video_options=''.join([
        f"<option value='{html.escape(v['rel'])}'>{html.escape(v['topic'])} ??? {html.escape(v['name'])}</option>"
        for v in vids
    ])
    initial=vids[0] if vids else None
    initial_manifest=json.dumps(initial.get('manifest',{}) if initial else {}, indent=2) if initial else '{}'
    toolrows=''.join([f"<tr><td>{html.escape(r['name'])}</td><td class={'ok' if r['ready'] else 'bad'}>{'READY' if r['ready'] else 'NOT READY'}</td><td>{html.escape(r['headless'])}</td><td>{html.escape(r['detail'])}</td></tr>" for r in rows])
    useful_logs=[p for p in sorted(LOG.glob('*'), key=lambda x:x.stat().st_mtime, reverse=True) if p.is_file() and (p.name.endswith('.log') and ('render' in p.name or 'batch' in p.name or 'smoke' in p.name))][:12]
    logs=''.join([f"<li><a href='/logs/{p.name}'>{p.name}</a></li>" for p in useful_logs]) or '<li>No focused render logs yet.</li>'
    videos_json=json.dumps(vids)
    html_doc=f"""<!doctype html><html><head><title>GPU Renderer Dashboard</title><style>
    body{{font-family:Segoe UI,Arial;background:#101522;color:#eef;margin:20px}} a{{color:#80d8ff}} .card{{background:#17213a;border:1px solid #334;padding:16px;border-radius:12px;margin:14px 0}} video{{width:100%;max-width:960px;background:#000;border-radius:8px}} table{{border-collapse:collapse;width:100%}} td,th{{border:1px solid #334;padding:8px;text-align:left}} .ok{{color:#8f8;font-weight:bold}} .bad{{color:#ffb86b;font-weight:bold}} pre{{white-space:pre-wrap;background:#0b1020;padding:10px;border-radius:8px;max-height:220px;overflow:auto}} select{{width:100%;max-width:960px;padding:10px;border-radius:8px;background:#0b1020;color:#eef;border:1px solid #445;margin:8px 0 14px}}
    </style></head><body>
    <h1>GPU Renderer Dashboard</h1>
    <p>Base: /mnt/gpu-work ??? Port: 4000 ??? Time: {time.ctime()} ??? Rendered videos: {len(vids)}</p>
    <h2>Rendered video preview</h2>
    <section class='card'>
      <label for='videoSelect'><strong>Select one finished rendered video:</strong></label><br>
      <select id='videoSelect'>{video_options}</select>
      <h2 id='videoTitle'>{html.escape(initial.get('topic','No rendered videos yet') if initial else 'No rendered videos yet')}</h2>
      <video id='player' controls preload='metadata' src='{('/outputs/'+initial['rel']) if initial else ''}'></video>
      <p id='downloadLine'>{('<a id="downloadLink" href="/outputs/'+html.escape(initial['rel'])+'" download>Download MP4</a> ??? '+format(initial['size']/1024/1024,'.2f')+' MB ??? scenes: '+html.escape(str(initial.get('manifest',{}).get('scenes','?')))) if initial else 'No rendered videos yet.'}</p>
      <pre id='manifestBox'>{html.escape(initial_manifest[:4000])}</pre>
    </section>
    <h2>Tool readiness</h2><table><tr><th>Tool</th><th>Status</th><th>Headless?</th><th>Detail</th></tr>{toolrows}</table>
    <h2>GPU</h2><pre>{html.escape(sh('nvidia-smi'))}</pre>
    <h2>Disk</h2><pre>{html.escape(sh('df -h / /mnt/gpu-work'))}</pre>
    <h2>Logs</h2><ul>{logs}</ul>
    <script>
    const videos = {videos_json};
    const select = document.getElementById('videoSelect');
    function esc(s){{return String(s ?? '').replace(/[&<>"']/g, c=>({{'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}}[c]));}}
    function renderSelected(){{
      const v = videos.find(x => x.rel === select.value) || videos[0];
      if(!v) return;
      document.getElementById('videoTitle').textContent = v.topic || v.name;
      document.getElementById('player').src = '/outputs/' + v.rel;
      document.getElementById('downloadLine').innerHTML = `<a id="downloadLink" href="/outputs/${{esc(v.rel)}}" download>Download MP4</a> ??? ${{(v.size/1024/1024).toFixed(2)}} MB ??? scenes: ${{esc(v.manifest?.scenes ?? '?')}}`;
      document.getElementById('manifestBox').textContent = JSON.stringify(v.manifest || {{}}, null, 2);
    }}
    if(select) select.addEventListener('change', renderSelected);
    </script>
    </body></html>"""
    return HTMLResponse(html_doc)

@app.get('/api/status')
def status():
    rows,adv=tool_status()
    return {'time':time.time(),'base':str(BASE),'videos':videos(),'tools':rows,'advanced':adv,'gpu':sh('nvidia-smi'),'disk':sh('df -h / /mnt/gpu-work')}
