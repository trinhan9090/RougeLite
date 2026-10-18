"""Promote only branch changes to the user's Launch, with verified rollback copies."""
from pathlib import Path
import subprocess,json,hashlib,shutil,datetime
S=Path(__file__).resolve().parents[2];R=S.parents[1];O=S/'reports/visual_qa/v3_three_heroes'
reg=json.loads((O/'regression.json').read_text())
assert reg['suites']==38 and reg['completed']==38 and reg['failures']==0
assert R.name=='RougeLite' and (R/'Launch.cmd').exists()
paths=subprocess.check_output(['git','ls-files','--modified','--others','--exclude-standard','-z'],cwd=S).decode().split('\0')
backup=R/'.local-data'/('three_heroes_'+datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d_%H%M%S'))
rows=[]
for rel in sorted(set(paths)):
 if not rel or rel.startswith(('reports/','builds/','.local-data/')):continue
 src=S/rel;dst=R/rel
 if not src.is_file():continue
 digest=hashlib.sha256(src.read_bytes()).hexdigest()
 if dst.is_file() and hashlib.sha256(dst.read_bytes()).hexdigest()==digest:continue
 if dst.is_file():
  old=backup/rel;old.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dst,old)
 dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
 assert hashlib.sha256(dst.read_bytes()).hexdigest()==digest
 rows.append(dict(path=rel,sha256=digest))
shutil.copytree(O,R/O.relative_to(S),dirs_exist_ok=True,ignore=shutil.ignore_patterns('*.avi','*.wav'))
data=dict(rollback=str(backup),files=rows)
for base in (S,R):(base/'reports/visual_qa/v3_three_heroes/deployment.json').write_text(json.dumps(data,indent=2))
print('PROMOTED',len(rows),'files; rollback',backup)
