"""Reversible local promotion of the training and combat HUD change."""
from pathlib import Path
from datetime import datetime,timezone
import subprocess,shutil,hashlib,json
S=Path('D:/SelfProject/RougeLite/worktrees/visual_pipeline_v2').resolve()
R=Path('D:/SelfProject/RougeLite').resolve()
BASE='a1b2c8f'
def main():
    assert S.is_relative_to(R/'worktrees') and S!=R
    def git(*args): return subprocess.check_output(['git',*args],cwd=S).decode().splitlines()
    paths=set(git('diff','--name-only',BASE)+git('ls-files','--others','--exclude-standard'))
    paths={p for p in paths if not p.endswith('.translation') and p!='docs/atyu_audit/training_deployment.json'}
    journal=R/'docs/atyu_audit/training_deployment.json'
    previous={v['path']:v['sha256'] for v in json.loads(journal.read_text())['files']} if journal.exists() else {}
    norm=lambda value:value.replace(b'\r\n',b'\n')
    for rel in paths:
        src=(S/rel).resolve();dst=(R/rel).resolve()
        assert src.is_relative_to(S) and dst.is_relative_to(R) and '.git' not in src.parts and src.is_file()
        old=subprocess.run(['git','show',f'{BASE}:{rel}'],cwd=S,capture_output=True)
        if dst.exists():
            expected=[norm(src.read_bytes())]
            if old.returncode==0: expected.append(norm(old.stdout))
            owned=hashlib.sha256(dst.read_bytes()).hexdigest()==previous.get(rel)
            if not owned and norm(dst.read_bytes()) not in expected: raise RuntimeError('independent root change: '+rel)
    backup=R/'.local-data'/('training_'+datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S'))
    assert backup.is_relative_to(R/'.local-data')
    files=[]
    for rel in sorted(paths):
        src=S/rel;dst=R/rel
        if dst.exists():
            saved=backup/rel;saved.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dst,saved)
        dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
        digest=hashlib.sha256(src.read_bytes()).hexdigest()
        assert hashlib.sha256(dst.read_bytes()).hexdigest()==digest
        files.append({'path':rel,'sha256':digest})
    report={'baseline':BASE,'backup':str(backup),'files':files}
    for root in [S,R]: (root/'docs/atyu_audit/training_deployment.json').write_text(json.dumps(report,indent=2),encoding='utf8')
    print('TRAINING_DEPLOYED',len(files),'backup',backup)
if __name__=='__main__': main()
