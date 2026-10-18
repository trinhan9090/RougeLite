"""Promote tested v3 runtime files to the user's existing Launch.cmd project.
Back up each overwritten file first. No .git metadata is changed.
"""
from pathlib import Path
import shutil,hashlib,json,datetime
SOURCE=Path(__file__).resolve().parents[2];LIVE=SOURCE.parents[1]
assert LIVE.name=='RougeLite' and (LIVE/'Launch.cmd').is_file()
stamp=datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d_%H%M%S')
backup=LIVE/'.local-data'/('pixel_v3_backup_'+stamp)
files=[Path(p) for p in ['project.godot','export_presets.cfg','content/characters/astra_loadout.tres','scripts/ui/actor_sprite.gd','scripts/ui/visual_controller.gd','scripts/ui/combat_visual_factory.gd','scripts/ui/pixel_visual_effect.gd','scripts/ui/enemy_pixel_visual.gd','scripts/ui/pixel_terrain.gd','scripts/ui/foundation_menu.gd','scripts/ui/run_presentation.gd','scripts/core/combat_run_root.gd','scripts/actors/enemy_actor.gd','scripts/world/arena_geometry.gd','tests/run_all.gd','tests/integration/test_art_frames.gd','tests/integration/test_astra_celestial_vfx.gd','tests/integration/test_pixel_v3.gd','tools/package.ps1','ASSET_LICENSES.md','docs/04_TASKS.md','docs/WORK_LOG.md']]
for folder in ['assets/art_v3','art_source/v3','tools/art_v3']:
 files += [p.relative_to(SOURCE) for p in (SOURCE/folder).rglob('*') if p.is_file() and '.import' not in p.name and '__pycache__' not in p.parts]
files += [p.relative_to(SOURCE) for p in (SOURCE/'assets/vfx/generated').glob('astra_*.json')]
files += [Path('tools/release_archive.ps1'),Path('tools/visual_pipeline/encode_video.py')]
files += [p.relative_to(SOURCE) for p in (SOURCE/'licenses').glob('*') if p.is_file() and (p.suffix in ['.txt','.md','.csv'] or p.name=='.gdignore')]
rows=[]
for rel in files:
 src=SOURCE/rel;dst=LIVE/rel
 if dst.is_file():
  old=backup/rel;old.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dst,old)
 dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
 rows.append({'path':rel.as_posix(),'sha256':hashlib.sha256(src.read_bytes()).hexdigest()})
(LIVE/'art_source/.gdignore').touch()
shutil.copytree(SOURCE/'reports/visual_qa/v3_astra',LIVE/'reports/visual_qa/v3_astra',dirs_exist_ok=True,ignore=shutil.ignore_patterns('*.avi','*.wav'))
(LIVE/'reports/visual_qa/v3_astra/deployment.json').write_text(json.dumps({'backup':str(backup),'files':rows},indent=2))
print('DEPLOYED',len(rows),'files; backup',backup)
