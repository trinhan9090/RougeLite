"""Offline SFF1/PCX + AIR + SND catalog. Never executes source state code."""
from pathlib import Path
import struct,io,json,re,hashlib,shutil,html,csv,sys
from PIL import Image
from parse_air import parse
from build_audio import extract

ROOT=Path(__file__).resolve().parents[2]
SUPPLIED=Path('D:/SelfProject/RougeLite/assets/characters/Viridian/Viridian_Agent_Handoff')
SOURCE=SUPPLIED/'MVC2_DrDoom-AI(Maro)'
RAW=ROOT/'tools/mugen_sources/viridian_original'
OUT=ROOT/'reports/viridian/20261017'
DATA=ROOT/'experiments/viridian/data'

def sha(b): return hashlib.sha256(b).hexdigest()
def fields(text):
    result={}
    for line in text.splitlines():
        line=line.split(';',1)[0].strip()
        if '=' in line:
            k,v=line.split('=',1);result.setdefault(k.strip().lower(),[]).append(v.strip())
    return result

def states(path):
    t=path.read_text(errors='replace');parts=re.split(r'(?im)^\s*\[statedef\s+(-?\d+)\s*\]',t);result=[]
    for i in range(1,len(parts),2):
        blocks=re.split(r'(?im)^\s*\[state[^\]]*\]',parts[i+1])
        result.append(dict(id=int(parts[i]),path=path.relative_to(RAW).as_posix(),header=fields(blocks[0]),controllers=[fields(b) for b in blocks[1:]]))
    return result

def sff1(path,out):
    b=path.read_bytes()
    if b[:12]!=b'ElecbyteSpr\0' or b[15]!=1: raise ValueError('SFF1 required')
    _,count,offset,header=struct.unpack_from('<4I',b,16)
    entries=[];seen=set();images=[];last_palette=None;failures=[]
    (out/'sprites').mkdir(parents=True,exist_ok=True)
    for i in range(count):
        if offset in seen or offset+header>len(b):raise ValueError('SFF1 linked header')
        seen.add(offset)
        nxt,length,x,y,g,n,link,same=struct.unpack_from('<IIhhHHHB',b,offset)
        try:
            if not length:
                if link>=len(images) or images[link] is None: raise ValueError('invalid linked PCX')
                image=images[link].copy()
            else:
                pcx=b[offset+header:offset+header+length]
                if len(pcx)!=length: raise ValueError('truncated PCX')
                if len(pcx)<769 or pcx[-769]!=12:
                    if last_palette is None: raise ValueError('missing PCX palette')
                    pcx+=b'\x0c'+bytes(last_palette)
                im=Image.open(io.BytesIO(pcx));im.load()
                palette=im.getpalette()
                if palette is None: raise ValueError('indexed PCX required')
                last_palette=palette[:768]
                im.info['transparency']=0;image=im.convert('RGBA')
            name=f'sprites/{i:05d}.png';image.save(out/name)
            entries.append(dict(key=f'{g}_{n}',path=name,axis=[x,y],width=image.width,height=image.height,index=i,linked=not length,same_palette=same,sha256=sha(image.tobytes())))
            images.append(image)
        except Exception as e:
            failures.append(dict(index=i,key=f'{g}_{n}',error=str(e)));images.append(None)
        offset=nxt
    return dict(version=list(b[12:16]),count=count,decoded=len(entries),entries=entries,failures=failures)

def run():
    OUT.mkdir(parents=True,exist_ok=True);DATA.mkdir(parents=True,exist_ok=True);(DATA/'.gdignore').touch()
    RAW.parent.mkdir(parents=True,exist_ok=True);shutil.copytree(SOURCE,RAW,dirs_exist_ok=True);(RAW/'.gdignore').touch()
    files=[dict(path=f.relative_to(SOURCE).as_posix(),bytes=f.stat().st_size,sha256=sha(f.read_bytes())) for f in sorted(SOURCE.rglob('*')) if f.is_file()]
    defs={}
    for f in RAW.glob('*.def'):
        body=re.split(r'(?im)^\s*\[files\]',f.read_text(errors='replace'))[1].split('[Arcade]')[0]
        defs[f.name]=[dict(kind=k,path=v[0],exists=(RAW/v[0]).is_file()) for k,v in fields(body).items()]
    sprites=sff1(RAW/'MVC2_DrDoom.sff',DATA)
    (DATA/'sprites.json').write_text(json.dumps(sprites,indent=2))
    actions={};state_rows=[];commands={}
    for name,air in [('base','MVC2_DrDoom.air'),('maro','Maro/MVC2_DrDoom.air')]:
        actions[name]=parse((RAW/air).read_text(errors='replace'))
    for f in RAW.rglob('*.cns'): state_rows+=states(f)
    for f in RAW.rglob('*.cmd'):
        commands[f.relative_to(RAW).as_posix()]=[fields(b) for b in re.split(r'(?im)^\s*\[state[^\]]*\]',f.read_text(errors='replace'))[1:]]
    sounds=extract((RAW/'MVC2_DrDoom.snd').read_bytes());(DATA/'audio').mkdir(exist_ok=True)
    sound_rows=[]
    for key,(blob,meta) in sounds.items():
        (DATA/'audio'/f'{key}.wav').write_bytes(blob);sound_rows.append(dict(key=key,sha256=sha(blob),**meta))
    sprite_keys={e['key'] for e in sprites['entries']};missing=[]
    for variant,rows in actions.items():
        for a in rows:
            for f in a['frames']:
                if f['group']>=0 and f"{f['group']}_{f['index']}" not in sprite_keys:missing.append(dict(variant=variant,action=a['id'],frame=f['raw']))
    report=dict(archive_sha256=None,archive_note='Supplied extracted directory; requested ZIP not present. Per-file hashes and tree hash recorded, no ZIP hash invented.',tree_sha256=sha(json.dumps(files,sort_keys=True).encode()),files=files,defs=defs,sff={k:v for k,v in sprites.items() if k!='entries'},actions=actions,states=state_rows,commands=commands,sounds=sound_rows,missing_air_sprite_refs=missing,rights='THIRD_PARTY_PRIVATE_TEST_ONLY',source_direction_coverage='2_DIR_POC_ONLY',sound_identity='CNS_LINKED_PREVIEW_AVAILABLE_NOT_HEARD_BY_AGENT')
    (OUT/'source_catalog.json').write_text(json.dumps(report,indent=2))
    # Inline data plus relative local files: browser playback works without network/server.
    rel='../../../experiments/viridian/data/'
    look={e['key']:e for e in sprites['entries']}
    rows=[dict(id=a['id'],frames=[dict(path=rel+look[f"{f['group']}_{f['index']}"]['path'],ticks=max(1,f['ticks']),axis=look[f"{f['group']}_{f['index']}"]['axis'],offset=f['offset'],flip=f['flip']) for f in a['frames'] if f"{f['group']}_{f['index']}" in look]) for a in actions['base']]
    page='''<!doctype html><meta charset="utf-8"><title>Viridian source catalog</title><style>body{background:#182028;color:#ddd;font:16px sans-serif}canvas{background:#303b48;image-rendering:pixelated}button,select{font:inherit;margin:8px}</style><h1>Source AIR/SFF catalog — private test</h1><p>Horizontal source frames:2_DIR_POC_ONLY. 60 source ticks/sec. Collision boxes/loop/blend details in JSON.</p><select id="sel"></select><button onclick="playing=!playing">Play/pause</button><canvas id="c" width="900" height="450"></canvas><pre id="info"></pre><script>const rows=DATA;let playing=true,i=0,t=0,last=0;const sel=document.querySelector('#sel'),ctx=document.querySelector('#c').getContext('2d'),images={};rows.forEach((a,k)=>{sel.add(new Option(a.id+' / '+a.frames.length+' frames',k));a.frames.forEach(f=>{let im=new Image();im.src=f.path;images[f.path]=im})});sel.onchange=()=>{i=0;t=0};function step(now){let a=rows[+sel.value];if(a.frames.length){let f=a.frames[i];if(playing)t+=(now-last)*.06;t%=a.frames.reduce((sum,f)=>sum+f.ticks,0);let steps=0;while(t>=f.ticks&&steps++<a.frames.length){t-=f.ticks;i=(i+1)%a.frames.length;f=a.frames[i]}ctx.clearRect(0,0,900,450);ctx.save();ctx.translate(420+f.offset[0],350+f.offset[1]);if(f.flip.includes('H'))ctx.scale(-1,1);if(f.flip.includes('V'))ctx.scale(1,-1);ctx.drawImage(images[f.path],-f.axis[0],-f.axis[1]);ctx.restore();document.querySelector('#info').textContent=JSON.stringify({action:a.id,frame:i,...f},null,2)}last=now;requestAnimationFrame(step)}requestAnimationFrame(step)</script>'''.replace('DATA',json.dumps(rows))
    (OUT/'animation_preview.html').write_text(page)
    (OUT/'sound_catalog.html').write_text('<!doctype html><meta charset="utf-8"><h1>Source SND — private test</h1><p>Group/index provenance only; identity/listening approval pending.</p>'+''.join(f'<p>{s["key"]} — {s["seconds"]:.3f}s <audio controls preload="none" src="{rel}audio/{s["key"]}.wav"></audio></p>' for s in sound_rows))
    print('AUDIT',sprites['decoded'],'sprites /',sprites['count'],'failures',len(sprites['failures']),'AIR',len(actions['base']),'sounds',len(sounds),'missing_refs',len(missing))
    if sprites['failures']: raise SystemExit(1)

if __name__=='__main__':run()
