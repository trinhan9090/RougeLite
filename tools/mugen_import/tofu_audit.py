"""Inert source audit/extraction of user-supplied Tofu/Toji source; no MUGEN execution."""
from pathlib import Path
import json,re,hashlib,csv,html
from decode_sff import convert
from parse_air import parse
from build_audio import extract
from audit_directory import sections
ROOT=Path(__file__).resolve().parents[2]
SOURCE=Path('D:/SelfProject/RougeLite/assets/characters/Tofu/Toji Fushiguro')
OUT=ROOT/'reports/tofu/20261018';DATA=ROOT/'experiments/tofu/data'
def sha(b):return hashlib.sha256(b).hexdigest()
def main():
 OUT.mkdir(parents=True,exist_ok=True);DATA.mkdir(parents=True,exist_ok=True)
 files=[dict(path=p.relative_to(SOURCE).as_posix(),bytes=p.stat().st_size,sha256=sha(p.read_bytes())) for p in sorted(SOURCE.rglob('*')) if p.is_file()]
 refs=[]
 for sec in sections(SOURCE/'Toji Fushiguro.def'):
  if sec['section'].lower()=='files':
   for key,values in sec['fields'].items():
    for value in values:
     if not value.strip():continue
     target=(SOURCE/value.strip('"')).resolve();assert target.is_relative_to(SOURCE.resolve())
     refs.append(dict(kind=key,path=value,exists=target.is_file()))
 sprites=convert(SOURCE/'Toji Fushiguro.sff',DATA)
 actions=parse((SOURCE/'Toji Fushiguro.air').read_text(errors='replace'))
 missing=[dict(action=a['id'],sprite=f"{f['group']}_{f['index']}",line=f['line']) for a in actions for f in a['frames'] if f['group']>=0 and f"{f['group']}_{f['index']}" not in sprites['sprites']]
 sounds=extract((SOURCE/'Toji Fushiguro.snd').read_bytes());(DATA/'audio').mkdir(exist_ok=True)
 audio=[]
 for key,(blob,meta) in sounds.items():(DATA/'audio'/f'{key}.wav').write_bytes(blob);audio.append(dict(key=key,sha256=sha(blob),identity='CANDIDATE_NOT_LISTENED',**meta))
 states=[]
 for file in SOURCE.glob('*.cns'):
  current=None
  for sec in sections(file):
   m=re.fullmatch(r'statedef\s+(-?\d+)',sec['section'],re.I)
   if m:current=dict(file=file.name,id=int(m[1]),line=sec['line'],header=sec['fields'],controllers=[]);states.append(current)
   elif current is not None:current['controllers'].append(sec)
 catalog=dict(source=str(SOURCE),files=files,tree_sha256=sha(json.dumps(files,sort_keys=True).encode()),archive_sha256=None,archive_note='No original archive supplied; live extracted tree hashed; handoff SOURCE_MANIFEST.json/SOURCE_STATE_INVENTORY.csv absent',references=refs,sff={k:v for k,v in sprites.items() if k not in ['sprites','entries']},actions=actions,missing_air=missing,states=states,commands=sections(SOURCE/'Toji Fushiguro.cmd'),sounds=audio,rights='unverified_rights/local_prototype_only')
 (OUT/'source_catalog.json').write_text(json.dumps(catalog,indent=2))
 # Offline playback catalog links directly to extracted local files, no media exports.
 base='../../../experiments/tofu/data'
 sound_html='<meta charset="utf-8"><h1>Tofu source audio - CANDIDATE / NOT LISTENED</h1>'
 for row in audio:sound_html+=f"<p>{row['key']} ({row['seconds']:.3f}s) <audio controls preload='none' src='{base}/audio/{row['key']}.wav'></audio></p>"
 (OUT/'sound_catalog.html').write_text(sound_html,encoding='utf-8')
 # Extracted rows retain ticks, axis/offset/blend/scale; canvas viewer uses original geometry.
 viewer="""<meta charset='utf-8'><h1>Tofu source AIR viewer: side-view only</h1><select id='actions'></select><canvas id='view' width='700' height='500' style='background:#222;image-rendering:pixelated'></canvas><script>const data=DATA;const sprites=SPRITES;const select=document.querySelector('select');data.forEach((a,i)=>select.add(new Option(a.id+' / '+a.frames.length+' frames',i)));let index=0,t=0,last=0;select.onchange=()=>{index=0;t=0};const cache={};function run(now){const a=data[+select.value||0];t+=(now-last)*.06;last=now;let f=a.frames[index];if(t>=Math.max(1,f.ticks)){t=0;index=(index+1)%a.frames.length;f=a.frames[index]}const c=document.querySelector('canvas').getContext('2d');c.clearRect(0,0,700,500);const e=sprites[f.group+'_'+f.index];if(e){if(!cache[e.path]){let im=new Image();im.src='../../../experiments/tofu/data/'+e.path;cache[e.path]=im}c.save();c.translate(350+f.offset[0],350+f.offset[1]);c.rotate(-f.angle*Math.PI/180);c.scale(f.scale[0],f.scale[1]);c.scale(f.flip.includes('H')?-1:1,f.flip.includes('V')?-1:1);c.drawImage(cache[e.path],-e.axis[0],-e.axis[1]);c.restore()}requestAnimationFrame(run)}requestAnimationFrame(run)</script>"""
 (OUT/'animation_preview.html').write_text(viewer.replace('DATA',json.dumps(actions)).replace('SPRITES',json.dumps(sprites['sprites'])),encoding='utf-8')
 print('TOFU_AUDIT',len(files),'files',sprites['decoded'],'/',sprites['sprite_count'],'sprites',len(actions),'AIR',len(audio),'sounds',len(missing),'missing AIR sprites',flush=True)
 if sprites['failures']:print('DECODE_WARNINGS',sprites['failures'][:8])
if __name__=='__main__':main()
