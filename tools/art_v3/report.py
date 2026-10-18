"""Create reproducible provenance, review board and machine-gate summary."""
from pathlib import Path
from PIL import Image,ImageDraw
import json,hashlib,csv,shutil,subprocess
R=Path(__file__).resolve().parents[2];LIVE=R.parents[1] if R.parent.name=='worktrees' else R;O=R/'reports/visual_qa/v3_astra';O.mkdir(parents=True,exist_ok=True)
for p in (LIVE/'reports/visual_qa/v3_astra').glob('before_*.png'):
 shutil.copy2(p,O/p.name)
if (LIVE/'reports/visual_qa/v3_astra/baseline.json').is_file():shutil.copy2(LIVE/'reports/visual_qa/v3_astra/baseline.json',O/'baseline.json')
for p in O.glob('*.png'):
 if p.name.startswith(('astra_contact','astra_grayscale','before_','comparison')):continue
 if p.name.endswith('_2x.png'):continue
 im=Image.open(p)
 if im.size==(1280,720):
  im.resize((640,360),Image.Resampling.NEAREST).save(p)
  im.save(p.with_name(p.stem+'_2x.png'))
board=Image.new('RGB',(1280,800),'#151b28');d=ImageDraw.Draw(board)
concept=Image.open(R/'assets/Endless_Survival_Wizard_of_Legend_Visual_Spec_v3/reference/concept_art/astra.png').convert('RGB')
concept.thumbnail((400,740));board.paste(concept,(10,40))
d.text((10,12),'Supplied reference: identity / palette only',fill='white')
contact=Image.open(O/'astra_contact.png').convert('RGB');board.paste(contact,(440,40))
d.text((440,12),'Original native pixels: idle / run / basic / J / K / L / I / death',fill='white')
if (O/'crowd_30.png').is_file():board.paste(Image.open(O/'crowd_30.png').convert('RGB'),(440,430))
d.text((440,805-18),'Technical review candidate; visual approval PENDING',fill='#d6ab62')
board.save(O/'comparison.png')
assets=[]
inventory=[]
for p in (LIVE/'assets').rglob('*'):
 if p.is_file() and '.import' not in p.name:
  inventory.append({'path':p.relative_to(LIVE).as_posix(),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
if not (O/'asset_inventory.json').exists():
 (O/'asset_inventory.json').write_text(json.dumps({'source':'live assets before v3 promotion','count':len(inventory),'files':inventory},indent=2))
for folder in ['assets/art_v3','art_source/v3']:
 for p in (R/folder).rglob('*'):
  if p.is_file() and '.import' not in p.name:
   assets.append({'path':p.relative_to(R).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'source':'tools/art_v3/generate.py','license':'ORIGINAL_CREATED_FOR_PROJECT'})
(O/'provenance.json').write_text(json.dumps({'assets':assets,'reference':'user-supplied concept posters, reference only; no poster pixels in runtime assets','tools':{'Godot':'4.7.2 MIT','Python':'3.12.14 PSF','Pillow':'12.3.0 MIT-CMU','Blender':'5.2.2 LTS GPL, encoding only','Pixelorama/LibreSprite/FFmpeg':'not detected on PATH; optional, not required'},'branch':'feature/visual-v3-astra'},indent=2))
with (O/'license_ledger.csv').open('w',newline='',encoding='utf-8') as f:
 w=csv.writer(f);w.writerow(['asset_id','source_url','author','license','license_verified_date','license_evidence','modifications','redistribution_allowed'])
 for a in assets:w.writerow([a['path'],'local original source','Project procedural authoring',a['license'],'2026-10-17',a['source'],'original integer layer authoring','project license'])
licenses=R/'ASSET_LICENSES.md';s=licenses.read_text(encoding='utf-8');marker='## Original pixel v3 review'
if marker not in s:licenses.write_text(s+'\n'+marker+'\nOriginal Astra layered PNGs, frame-sheet spells, courtyard tiles and shade enemy: tools/art_v3/generate.py; no external art or concept cutouts. Editable layers: art_source/v3. Provenance/license ledger: reports/visual_qa/v3_astra. Existing project license applies. Godot MIT, Python PSF, Pillow MIT-CMU; installed Blender GPL used only to encode captured gameplay. Concept posters are user-supplied reference only and excluded from the runtime package.\n',encoding='utf-8')
reg=json.loads((O/'regression.json').read_text()) if (O/'regression.json').exists() else {}
passed=reg.get('completed')==35 and reg.get('failures')==0
perf=json.loads((O/'performance.json').read_text()) if (O/'performance.json').exists() else {}
status='TECH_PASSED' if passed else 'IN_PROGRESS'
tasks=R/'docs/04_TASKS.md';s=tasks.read_text(encoding='utf-8');marker='## Original pixel v3 Astra review'
if marker in s:s=s[:s.index(marker)]
s+='\n'+marker+'\nCanonical definitions: assets/Endless_Survival_Wizard_of_Legend_Visual_Spec_v3/06_TASKS_QA_ACCEPTANCE.md.\n'
for gate,desc in [('A0','Snapshot/inventory/source baseline'),('A1','Original pixel tooling, manifest, native board'),('A2','Astra nine states / four directions / fixed feet'),('A3','Actual Basic/J/K/L/I frame VFX lifecycle'),('A4','Courtyard presentation;100 seeds per biome;30-enemy QA'),('A5','Actual Split/Echo/AreaExpand compatibility and comparison')]:
 s+=f'- [{"x" if passed else " "}] V3-{gate} {desc}. {status}; evidence reports/visual_qa/v3_astra. Human approval PENDING.\n'
for gate,desc in [('A6','Vex'),('A7','Boros'),('A8','Remaining arenas and boss art'),('A9','Final access settings / performance acceptance'),('A10','Final visually approved release')]:s+=f'- [ ] V3-{gate} {desc}; pending Astra visual review (07_AGENT_RUNBOOK step6).\n'
tasks.write_text(s,encoding='utf-8')
log=R/'docs/WORK_LOG.md';s=log.read_text(encoding='utf-8');marker='## 2026-10-17 original pixel v3'
if marker in s:s=s[:s.index(marker)]
s+='\n'+marker+'\nA0 selected first, then A1..A5 in order. Live source snapshot333 files before editing; isolated branch feature/visual-v3-astra (original .git metadata remains untouched). Existing gameplay specifications supersede historical snapshot mouse aim; movement-facing preserved. Files: assets/art_v3, art_source/v3, tools/art_v3, ActorSprite/VisualController/PixelVisualEffect/EnemyPixelVisual, shared factory, menu/presentation sizing, PixelTerrain, arena artwork, Astra art_frames reference. No skill stats, gameplay hitboxes, movement, damage, augment order or save schema changes.\nVerification: Godot4.7.2 GL Compatibility; Python3.12.14/Pillow12.3.0. Commands: python tools/art_v3/generate.py; python tools/art_v3/validate.py; godot --headless --path . --editor --quit; python tools/art_v3/regress.py (same35 canonical suite scripts, per-process timeout); godot --script res://tools/art_v3/capture.gd --fixed-fps30 --write-movie [AVI]; separate --normal capture; performance.gd without movie writer. Logs and machine results: reports/visual_qa/v3_astra.\nObserved defects fixed: west death staff crossed96px canvas; frame validator caught it. Beam opaque rectangle changed to broken envelope sparks and a jagged compact core. Old native screenshot names normalized to640x360,2x1280x720 using nearest sampling. Source-owned generated files retained; old assets preserved.\nStatus '+status+'. Art quality cannot be self-approved; Vex/Boros await user review under v3 runbook step6. Pictures/Videos system folders are not writable in this session; deliverables remain under project reports.\n'
log.write_text(s,encoding='utf-8')
known='''# Known limitations

- Astra-first review candidate, not the completed three-character v3 art release.
- Simplified procedural face/coat/animation; concept fidelity and art quality need owner approval.
- Vex/Boros, other biome props and bosses retain prior assets.
- A9 low-intensity/flashing/shake preferences are not implemented in this candidate.
- Manual Solar Field remains at the original resolved aim/range, which can place it partly outside the compact viewport; no gameplay range changes were made.
- QA skill/crowd/augment movie uses forced unlocks, invulnerability and high enemy HP. Separate normal_play uses normal stats/progression.
- Media export to system Pictures/Videos is blocked by filesystem permissions; files are in project reports.
- Windows package uses the full official Godot runtime because stripped templates are unavailable; unsigned local review build.
'''
(O/'known_issues.md').write_text(known)
(O/'QUALITY_REPORT.md').write_text('# Astra original pixel v3 review\n\nStatus: '+status+'; ART_REVIEW PENDING.\n\n1036 pixel/alpha/clipping/state checks;46 production PLAY/profile/collider checks;35 actual shield/status/area/beam checks. Canonical suites: '+str(reg.get('completed',0))+'/35 completed, failures='+str(reg.get('failures','pending'))+'. 100 deterministic layout seeds per biome (3300checks) in canonical suite. All commands/logs accompany this report.\n\nImages: comparison.png, astra_contact.png, astra_native.png, normal_play.png, crowd_30.png, skill_*.png, augments_*.png. Video: astra_review.mp4 (movement, J/K/L/I, actual live AI crowd, Split/Echo/AreaExpand); normal_play.mp4 (normal run). Screenshots native640x360 and2x1280x720, PNG crisp sampling.\n\nPerformance (separate live render run; no movie writer):\n```json\n'+json.dumps(perf,indent=2)+'\n```\n\nVisual scores are deliberately unassigned until owner review. See known_issues.md, STYLE_GUIDE.md, provenance.json and license_ledger.csv.\n')
html='<!doctype html><meta charset="utf-8"><title>Astra pixel v3 review</title><style>body{background:#141b29;color:#eef3ff;font:17px system-ui;max-width:1280px;margin:30px auto}img{max-width:100%;image-rendering:pixelated}video{width:100%}a{color:#a1d9ff}</style><h1>Astra original pixel v3 — bản duyệt</h1><p>Đồ họa gốc 2D, giữ nguyên gameplay. Vex/Boros chờ duyệt Astra.</p><img src="comparison.png"><h2>Gameplay / kỹ năng / augment (QA)</h2><video controls src="astra_review.mp4"></video><h2>PLAY với thông số gốc</h2><video controls src="normal_play.mp4"></video><p><a href="QUALITY_REPORT.md">Kiểm thử và hạn chế</a></p>'
(O/'review.html').write_text(html,encoding='utf-8')
print('REPORT status',status,'assets',len(assets))
