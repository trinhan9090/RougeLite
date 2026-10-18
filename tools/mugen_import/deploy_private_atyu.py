"""Reversible local-only promotion; verifies root baseline before any overwrite."""
import hashlib,json,shutil,subprocess
from datetime import datetime,timezone
from pathlib import Path
S=Path('D:/SelfProject/RougeLite/worktrees/visual_pipeline_v2').resolve()
R=Path('D:/SelfProject/RougeLite').resolve()
BASE='80f0bd6'
def git(*args):
    return subprocess.check_output(['git',*args],cwd=S)
def deploy():
    assert S.is_relative_to(R/'worktrees') and S!=R
    paths=set(git('diff','--name-only',BASE).decode().splitlines())
    paths.update(git('ls-files','--others','--exclude-standard').decode().splitlines())
    paths.update(p.relative_to(S).as_posix() for p in (S/'assets/private_atyu').glob('*.png'))
    paths={p for p in paths if not p.endswith('.translation')}
    paths.discard('docs/atyu_audit/p3_deployment.json')
    journal=R/'docs/atyu_audit/p3_deployment.json'
    previous={entry['path']:entry['sha256'] for entry in json.loads(journal.read_text())['files']} if journal.exists() else {}
    for rel in paths:
        src=(S/rel).resolve();dst=(R/rel).resolve()
        assert src.is_relative_to(S) and dst.is_relative_to(R) and '.git' not in src.parts
        if not src.is_file(): raise RuntimeError(f'unsupported missing source {rel}')
        old=subprocess.run(['git','show',f'{BASE}:{rel}'],cwd=S,capture_output=True)
        normalized=lambda value:value.replace(b'\r\n',b'\n')
        if dst.exists():
            accepted=[normalized(src.read_bytes())]
            if old.returncode==0: accepted.append(normalized(old.stdout))
            owned=hashlib.sha256(dst.read_bytes()).hexdigest()==previous.get(rel)
            if not owned and normalized(dst.read_bytes()) not in accepted:
                raise RuntimeError(f'root has independent change: {rel}')
    backup=R/'.local-data'/('atyu_p3_'+datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S'))
    assert backup.is_relative_to(R/'.local-data')
    entries=[]
    for rel in sorted(paths):
        src=S/rel;dst=R/rel
        if dst.exists():
            archived=backup/rel;archived.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(dst,archived)
        dst.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(src,dst)
        digest=hashlib.sha256(src.read_bytes()).hexdigest()
        assert hashlib.sha256(dst.read_bytes()).hexdigest()==digest
        entries.append({'path':rel,'sha256':digest})
    report={'baseline':BASE,'backup':str(backup),'files':entries,'count':len(entries)}
    for root in [S,R]: (root/'docs/atyu_audit/p3_deployment.json').write_text(json.dumps(report,indent=2),encoding='utf8')
    print('PRIVATE_ATYU_DEPLOYED',len(entries),'backup',backup)
if __name__=='__main__': deploy()
