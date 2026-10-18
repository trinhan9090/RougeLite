"""Snapshot the live project into the isolated visual branch without Git resets."""
from pathlib import Path
import shutil, json, hashlib, subprocess
ROOT=Path(__file__).resolve().parents[2]
BRANCH=ROOT/'worktrees/visual_pipeline_v2'
REPORT=ROOT/'reports/visual_qa/v3_astra'
REPORT.mkdir(parents=True,exist_ok=True)
paths=[]
for folder in ['scripts','scenes','content','tests']:
    for p in (ROOT/folder).rglob('*'):
        if p.is_file(): paths.append(p.relative_to(ROOT))
paths += [Path(n) for n in ['project.godot','export_presets.cfg','docs/04_TASKS.md','docs/WORK_LOG.md','ASSET_LICENSES.md']]
paths += [p.relative_to(ROOT) for p in (ROOT/'assets/vfx/generated').glob('*.json')]
inventory=[]
for rel in paths:
    src=ROOT/rel; dst=BRANCH/rel
    dst.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(src,dst)
    inventory.append({'path':rel.as_posix(),'sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'bytes':src.stat().st_size})
(REPORT/'baseline.json').write_text(json.dumps({'source':'live Launch.cmd project; existing working modifications preserved','branch':'feature/visual-v3-astra','files':inventory},indent=2))
pack=ROOT/'assets/Endless_Survival_Wizard_of_Legend_Visual_Spec_v3'
(pack/'.gdignore').touch()
shutil.copytree(pack,BRANCH/pack.relative_to(ROOT),dirs_exist_ok=True)
shutil.copytree(ROOT/'tools/art_v3',BRANCH/'tools/art_v3',dirs_exist_ok=True)
print('BASELINE',len(inventory),'runtime files backed up on isolated branch')
