"""Hash-guarded reversible promotion to the current local Launch project."""
from pathlib import Path
from datetime import datetime
import json,hashlib,shutil,subprocess
S=Path('D:/SelfProject/RougeLite/worktrees/visual_pipeline_v2').resolve()
R=Path('D:/SelfProject/RougeLite').resolve()
BASE='ecc5b2c'
def git(*args):return subprocess.check_output(['git',*args],cwd=S).decode().splitlines()
def main():
    tracked=set(git('ls-tree','-r','--name-only',BASE))
    paths=set(git('diff','--name-only',BASE)+git('ls-files','--others','--exclude-standard'))
    for directory in [S/'assets/private_graveshade',S/'experiments/graveshade/data']:
        paths.update(p.relative_to(S).as_posix() for p in directory.rglob('*') if p.is_file() and p.suffix not in ['.import'] and p.name!='inspection.png')
    journal=R/'reports/graveshade/deployment.json'
    old_report=json.loads(journal.read_text()) if journal.exists() else {}
    previous=old_report.get('owned_hashes',{i['path']:i['sha256'] for i in old_report.get('files',[])})
    paths={p for p in paths if p!='reports/graveshade/deployment.json' and not p.endswith('.translation') and not p.endswith('.running.log')}
    norm=lambda b:b.replace(b'\r\n',b'\n')
    for rel in paths:
        src=(S/rel).resolve();dst=(R/rel).resolve()
        assert src.is_relative_to(S) and dst.is_relative_to(R) and '.git' not in src.parts and src.is_file(),rel
        old=subprocess.check_output(['git','show',f'{BASE}:{rel}'],cwd=S) if rel in tracked else None
        if dst.exists():
            expected=[norm(src.read_bytes())]+([norm(old)] if old is not None else [])
            assert norm(dst.read_bytes()) in expected or hashlib.sha256(dst.read_bytes()).hexdigest()==previous.get(rel),'Independent root change: '+rel
    backup=R/'.local-data'/('graveshade_'+datetime.now().strftime('%Y%m%d_%H%M%S'))
    files=[]
    for rel in sorted(paths):
        src=S/rel;dst=R/rel
        if dst.exists():
            saved=backup/rel;saved.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dst,saved)
        dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
        digest=hashlib.sha256(src.read_bytes()).hexdigest()
        assert hashlib.sha256(dst.read_bytes()).hexdigest()==digest,rel
        files.append(dict(path=rel,sha256=digest));previous[rel]=digest
    report=dict(baseline=BASE,backup=str(backup),files=files,owned_hashes=previous)
    for root in [S,R]:(root/'reports/graveshade/deployment.json').write_text(json.dumps(report,indent=2))
    print('GRAVESHADE_DEPLOYED',len(files),'rollback',backup)
if __name__=='__main__':main()
