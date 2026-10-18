"""Shared inert MUGEN directory audit: no state code execution."""
from pathlib import Path
import re,json,hashlib,shutil,csv,argparse
from decode_sff import convert
from parse_air import parse
from build_audio import extract
ROOT=Path(__file__).resolve().parents[2]
def digest(b):return hashlib.sha256(b).hexdigest()
def sections(file):
 rows=[];current=None
 for line,text in enumerate(file.read_text(errors='replace').splitlines(),1):
  clean=text.split(';',1)[0].strip()
  if clean.startswith('[') and clean.endswith(']'):
   current=dict(section=clean[1:-1],line=line,fields={},field_lines={});rows.append(current)
  elif current is not None and '=' in clean:
   k,v=clean.split('=',1);k=k.strip().lower();current['fields'].setdefault(k,[]).append(v.strip());current['field_lines'].setdefault(k,[]).append(line)
 return rows

def audit(source,out,data):
 out.mkdir(parents=True,exist_ok=True);data.mkdir(parents=True,exist_ok=True);(data/'.gdignore').touch()
 source=source.resolve();files=[]
 for p in sorted(source.rglob('*')):
  if p.is_file():
   assert p.resolve().is_relative_to(source),'escaping source symlink'
   files.append(dict(path=p.relative_to(source).as_posix(),size=p.stat().st_size,sha256=digest(p.read_bytes())))
 supplied=json.loads((source.parent/'SOURCE_MANIFEST.json').read_text())
 for key,item in supplied['files'].items():assert digest((source/key).read_bytes())==item['sha256'],key
 defs=sections(source/'Punisher.def');references=[]
 for section in defs:
  if section['section'].lower()=='files':
   for key,values in section['fields'].items():
    for value in values:
     target=(source/value.strip('"')).resolve();assert target.is_relative_to(source)
     references.append(dict(kind=key,path=value,exists=target.is_file(),line=section['field_lines'][key][0]))
 sprites=convert(source/'P.sff',data)
 actions=parse((source/'P.air').read_text(errors='replace'));keys=set(sprites['sprites'])
 missing=[dict(action=a['id'],line=f['line'],key=f"{f['group']}_{f['index']}") for a in actions for f in a['frames'] if f['group']>=0 and f"{f['group']}_{f['index']}" not in keys]
 sounds=extract((source/'P.snd').read_bytes());(data/'audio').mkdir(exist_ok=True);audio=[]
 for key,(blob,meta) in sounds.items():
  (data/'audio'/f'{key}.wav').write_bytes(blob);audio.append(dict(key=key,sha256=digest(blob),**meta))
 states=[]
 for p in sorted(source.glob('*.cns')):
  current=None
  for section in sections(p):
   m=re.fullmatch(r'statedef\s+(-?\d+)',section['section'],re.I)
   if m:current=dict(file=p.name,id=int(m[1]),line=section['line'],header=section['fields'],controllers=[]);states.append(current)
   elif current is not None:current['controllers'].append(section)
 report=dict(source=str(source),archive_present=False,archive_sha256=None,archive_note='Local extracted Punisher source supplied; archive not present locally. Per-file supplied hashes verified.',files=files,tree_sha256=digest(json.dumps(files,sort_keys=True).encode()),references=references,sff={k:v for k,v in sprites.items() if k not in ['sprites','entries']},actions=actions,missing_air=missing,states=states,commands=sections(source/'P.cmd'),sounds=audio,rights='unverified_rights/local_prototype_only')
 (out/'source_catalog.json').write_text(json.dumps(report,indent=2))
 print('GRAVESHADE_AUDIT',len(files),'files',sprites['decoded'],'sprites',len(actions),'actions',len(audio),'sounds','missing',len(missing))
 if sprites['failures']:raise RuntimeError(sprites['failures'])
 return report
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--source',required=True);p.add_argument('--out',required=True);p.add_argument('--data',required=True);a=p.parse_args();audit(Path(a.source),Path(a.out),Path(a.data))
