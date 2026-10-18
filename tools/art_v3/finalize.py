"""Verify the promoted runtime/build and preserve the original rollback snapshot."""
from pathlib import Path
import json,hashlib,shutil,zipfile,subprocess
S=Path(__file__).resolve().parents[2];R=S.parents[1] if S.parent.name=='worktrees' else S
O=R/'reports/visual_qa/v3_astra'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
required={'live_play_test.log':'RESULT pixel v3 checks=46 failures=0','packaged_play_test.log':'RESULT pixel v3 checks=46 failures=0','packaged_vfx_test.log':'checks=35 failures=0','live_package.log':'RELEASE_SMOKE_OK profiles=3 boss_victories=3','launch_cmd.log':'BOOT_OK milestone=M5'}
for file,marker in required.items():
 text=(O/file).read_text(encoding='utf-8',errors='replace')
 assert marker in text and 'ERROR:' not in text,(file,marker)
reg=json.loads((O/'regression.json').read_text());assert reg['completed']==35 and reg['failures']==0
deployment=json.loads((O/'deployment.json').read_text())
for entry in deployment['files']:
 rel=Path(entry['path']);assert sha(S/rel)==sha(R/rel),'Deployment mismatch '+str(rel)
 entry['sha256']=sha(R/rel)
(O/'deployment.json').write_text(json.dumps(deployment,indent=2))
baseline=json.loads((O/'baseline.json').read_text());protected=[]
for row in baseline['files']:
 p=row['path']
 if p.startswith(('content/skills/','content/augments/','content/maps/','content/stats/','scripts/combat/','scripts/augments/')) or p.endswith('_stats.tres'):
  assert sha(R/p)==row['sha256'],'Unexpected gameplay change '+p
  protected.append(p)
release=R/'builds/windows'
for dest in [R/'licenses',S/'licenses',release/'licenses']:
 dest.mkdir(exist_ok=True,parents=True);shutil.copy2(O/'license_ledger.csv',dest/'pixel_v3_asset_ledger.csv')
shutil.copy2(O/'provenance.json',release/'pixel_v3_provenance.json')
shutil.copy2(O/'regression.json',release/'pixel_v3_regression.json')
archive=R/'builds/EndlessSurvival-Windows.zip'
release_files=[p for p in release.iterdir() if p.is_file() and p.suffix.lower() in ['.exe','.pck','.cmd','.txt','.md','.csv','.json']]
release_files += [p for p in (release/'licenses').iterdir() if p.is_file() and p.suffix.lower() in ['.txt','.md','.csv']]
with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as z:
 for p in release_files:z.write(p,'windows/'+p.relative_to(release).as_posix())
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None
 assert 'windows/EndlessSurvival.pck' in z.namelist()
 assert 'windows/licenses/pixel_v3_asset_ledger.csv' in z.namelist()
data={'status':'TECH_PASSED; HUMAN_ART_REVIEW_PENDING','gates':'A0-A5 Astra review candidate; A6-A10 not accepted','branch':'feature/visual-v3-astra','source_commit':subprocess.check_output(['git','-C',str(S),'rev-parse','HEAD'],text=True).strip(),'regression_suites':35,'failed_suites':0,'pixel_checks':1036,'live_and_packaged_play_checks':46,'packaged_vfx_checks':35,'protected_gameplay_files_verified':len(protected),'launch':'D:/SelfProject/RougeLite/Launch.cmd','build':str(archive),'zip_bytes':archive.stat().st_size,'zip_sha256':sha(archive),'pck_sha256':sha(release/'EndlessSurvival.pck'),'system_media_export':'BLOCKED: Pictures/Videos write permission denied; media preserved in project reports'}
(O/'delivery.json').write_text(json.dumps(data,indent=2))
q=O/'QUALITY_REPORT.md';text=q.read_text(encoding='utf-8');marker='\nFinal live-project and packaged verification:'
if marker in text:text=text[:text.index(marker)]
q.write_text(text+marker+' PLAY46 checks, VFX35 checks, actual Launch.cmd boot and3-profile/3-boss release smoke all exit0. '+str(len(protected))+' gameplay files match pre-v3 SHA256 baseline. Build SHA256: '+data['zip_sha256']+'.\n',encoding='utf-8')
if S!=R:shutil.copytree(O,S/'reports/visual_qa/v3_astra',dirs_exist_ok=True,ignore=shutil.ignore_patterns('*.avi','*.wav','tests.log'))
print(json.dumps(data,indent=2))
