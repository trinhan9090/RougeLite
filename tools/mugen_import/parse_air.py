"""AIR rows/boxes/loop metadata; duplicate actions remain separate occurrences."""
import re,json,argparse,collections
from pathlib import Path
def parse(text):
 actions=[];current=None;defaults={};temporary={};target=None
 for number,line in enumerate(text.splitlines(),1):
  raw=line.split(';',1)[0].strip()
  if not raw:continue
  m=re.fullmatch(r'\[begin\s+action\s+(-?\d+)\s*\]',raw,re.I)
  if m:
   current=dict(id=int(m[1]),line=number,frames=[],loop_start=0,unknown=[]);actions.append(current);defaults={};temporary={};continue
  if current is None:continue
  if raw.lower()=='loopstart':current['loop_start']=len(current['frames']);continue
  m=re.fullmatch(r'Clsn([12])(Default)?\s*:\s*(\d+)',raw,re.I)
  if m:
   target=defaults if m[2] else temporary;target[m[1]]=[];continue
  m=re.fullmatch(r'Clsn([12])\s*\[\d+\]\s*=\s*(.*)',raw,re.I)
  if m:
   (target if target is not None else temporary).setdefault(m[1],[]).append([int(x.strip()) for x in m[2].split(',')]);continue
  if raw.lower().startswith('interpolate '):
   if current['frames']:current['frames'][-1].setdefault('interpolate',[]).append(raw[12:].lower())
   else:current.setdefault('wrap_interpolate',[]).append(raw[12:].lower())
   continue
  if re.match(r'^-?\d+\s*,\s*-?\d+\s*,',raw):
   t=[x.strip() for x in raw.split(',')];vals=[int(x) for x in t[:5]]
   if len(vals)!=5:raise ValueError('invalid frame '+str(number))
   extra=t[5:]+['']*5
   frame=dict(group=vals[0],index=vals[1],offset=vals[2:4],ticks=vals[4],flip=extra[0].upper(),blend=extra[1].upper(),scale=[float(extra[2] or 1),float(extra[3] or 1)],angle=float(extra[4] or 0),raw=raw,line=number,boxes={k:temporary.get(k,defaults.get(k,[])) for k in ('1','2')})
   current['frames'].append(frame);temporary={};continue
  current['unknown'].append(dict(line=number,text=raw))
 seen=collections.Counter()
 for action in actions:
  seen[action['id']]+=1;action['occurrence']=seen[action['id']]
  if action.get('wrap_interpolate') and action['frames']:action['frames'][-1].setdefault('interpolate',[]).extend(action['wrap_interpolate'])
 return actions
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--source',required=True);p.add_argument('--out',required=True);a=p.parse_args()
 actions=parse(Path(a.source).read_text(encoding='utf-8-sig',errors='replace'));Path(a.out).write_text(json.dumps(dict(ticks_per_second=60,actions=actions),indent=2))
 print('AIR_RESULT actions',len(actions),'frames',sum(len(x['frames']) for x in actions),'unknown',sum(len(x['unknown']) for x in actions))
