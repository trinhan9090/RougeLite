"""Reversible promotion of the Tofu vertical slice to the actual Launch project."""
from pathlib import Path
import subprocess,shutil,json,hashlib,datetime
S=Path('D:/SelfProject/RougeLite/worktrees/visual_pipeline_v2').resolve();R=Path('D:/SelfProject/RougeLite').resolve();BASE='9f0aea8'
STATIC=['ASSET_LICENSES.md','content/catalog.tres','docs/04_TASKS.md','docs/05_DECISIONS.md','docs/WORK_LOG.md','docs/TOFU.md','docs/adr/ADR-2026-012-tofu-melee-sequence.md','scripts/core/combat_run_root.gd','scripts/training/training_panel.gd','scripts/ui/foundation_menu.gd','tests/integration/test_atyu.gd','tests/integration/test_graveshade.gd','tests/run_all.gd','tools/deploy_tofu.py']
NEW=['content/characters/tofu_stats.tres','content/characters/tofu_loadout.tres','content/skills/tofu_basic.tres','scripts/data/melee_combo_basic.gd','scripts/data/melee_sequence_executor.gd','scripts/combat/melee_sequence_runtime.gd','scripts/combat/melee_fear.gd','scripts/ui/melee_actor_effects.gd','scripts/ui/melee_visual_effect.gd','tests/integration/test_tofu.gd','tests/integration/measure_tofu.gd','tools/mugen_import/tofu_audit.py','tools/mugen_import/tofu_build.py','tools/mugen_import/tofu_content.py','tools/mugen_import/test_tofu.py']
def main():
 tracked=set(subprocess.check_output(['git','ls-tree','-r','--name-only',BASE],cwd=S).decode().splitlines())
 paths=set(STATIC+NEW)
 for rel in NEW:
  if (S/(rel+'.uid')).exists():paths.add(rel+'.uid')
 for directory in ['assets/private_tofu','experiments/tofu/data','reports/tofu/20261018']:
  paths.update(p.relative_to(S).as_posix() for p in (S/directory).rglob('*') if p.is_file() and p.suffix!='.import' and p.name!='deployment.json')
 journal=R/'reports/tofu/20261018/deployment.json';previous=json.loads(journal.read_text()).get('owned_hashes',{}) if journal.exists() else {}
 norm=lambda b:b.replace(b'\r\n',b'\n')
 for rel in paths:
  src=S/rel;dst=R/rel;assert src.is_file() and src.resolve().is_relative_to(S) and dst.resolve().is_relative_to(R),rel
  if dst.exists() and norm(dst.read_bytes())!=norm(src.read_bytes()):
   old=subprocess.check_output(['git','show',BASE+':'+rel],cwd=S) if rel in tracked else None
   assert (old is not None and norm(dst.read_bytes())==norm(old)) or hashlib.sha256(dst.read_bytes()).hexdigest()==previous.get(rel),'Independent root edit: '+rel
 backup=R/'.local-data'/('tofu_'+datetime.datetime.now().strftime('%Y%m%d_%H%M%S'))
 for rel in sorted(paths):
  src=S/rel;dst=R/rel
  if dst.exists():saved=backup/rel;saved.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dst,saved)
  dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst);previous[rel]=hashlib.sha256(dst.read_bytes()).hexdigest()
  assert previous[rel]==hashlib.sha256(src.read_bytes()).hexdigest(),rel
 report=dict(baseline=BASE,backup=str(backup),file_count=len(paths),owned_hashes=previous,raw_source_preserved=True)
 for root in (S,R):p=root/'reports/tofu/20261018/deployment.json';p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(report,indent=2))
 print('TOFU_DEPLOYED',len(paths),'files; backup',backup)
if __name__=='__main__':main()
