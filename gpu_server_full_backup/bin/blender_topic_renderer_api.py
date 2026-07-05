from fastapi import FastAPI, BackgroundTasks
from pathlib import Path
import subprocess, time, json
app=FastAPI(title='Blender Topic Renderer Service')
BASE=Path('/mnt/gpu-work')
JOBS=BASE/'jobs'/'blender_topic_renderer'; JOBS.mkdir(parents=True, exist_ok=True)
SCRIPT=BASE/'bin'/'blender_topic_renderer_service.py'

def run_job(topic_id:str, job_id:str):
    job=JOBS/f'{job_id}.json'
    log=JOBS/f'{job_id}.log'
    data={'job_id':job_id,'topic_id':topic_id,'status':'running','started':time.time(),'log':str(log)}
    job.write_text(json.dumps(data,indent=2))
    try:
        with log.open('w') as f:
            proc=subprocess.run([str(BASE/'tools'/'venv'/'bin'/'python'), str(SCRIPT), topic_id], stdout=f, stderr=subprocess.STDOUT, text=True, timeout=3600)
        data['returncode']=proc.returncode
        data['status']='done' if proc.returncode==0 else 'failed'
    except Exception as e:
        data['status']='failed'; data['error']=str(e)
    data['finished']=time.time()
    job.write_text(json.dumps(data,indent=2))

@app.post('/render/{topic_id}')
def render(topic_id:str, bg:BackgroundTasks):
    job_id=f'{topic_id}-{int(time.time())}'
    bg.add_task(run_job, topic_id, job_id)
    return {'ok':True,'job_id':job_id,'topic_id':topic_id}

@app.get('/jobs')
def jobs():
    out=[]
    for p in sorted(JOBS.glob('*.json'), key=lambda x:x.stat().st_mtime, reverse=True):
        try: out.append(json.loads(p.read_text()))
        except Exception: pass
    return out

@app.get('/health')
def health(): return {'ok':True,'service':'blender-topic-renderer'}
