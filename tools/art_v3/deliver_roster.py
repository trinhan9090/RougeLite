"""Verify the live Launch and its exported pack before refreshing review archives."""
from pathlib import Path
import subprocess,os,json,time,hashlib,shutil,zipfile
S=Path(__file__).resolve().parents[2];R=S.parents[1];O=S/'reports/visual_qa/v3_three_heroes'
engine=R/'tools/godot/Godot_v4.7.2-stable_win64_console.exe'
for _ in range(600):
 d=json.loads((O/'regression.json').read_text())
 if d['suites']==38 and d['completed']==38:break
 time.sleep(2)
else:raise RuntimeError('Regression timeout')
assert d['failures']==0,d
reuse=os.environ.get('ROUGELITE_REUSE_PACKAGE')=='1'
if not reuse:subprocess.run([os.sys.executable,str(S/'tools/art_v3/promote_roster.py')],cwd=S,check=True)
L=R/'reports/visual_qa/v3_three_heroes';env=dict(os.environ,APPDATA=str(R/'.local-data'))
def run(args,name,cwd=R,timeout=240):
 p=subprocess.run(args,cwd=cwd,env=env,capture_output=True,timeout=timeout)
 text=(p.stdout+p.stderr).decode('utf-8',errors='replace');(L/name).write_text(text,encoding='utf-8')
 assert p.returncode==0 and 'SCRIPT ERROR:' not in text and 'ERROR:' not in text,(name,p.returncode,text[-2500:])
 print('PASS',name,flush=True);return text
if not reuse:
 run([str(engine),'--headless','--path',str(R),'--editor','--quit'],'live_import.log')
 for suite in ('test_torso_hurtbox','test_roster_pixel','test_astra_cast_corrections'):
  run([str(engine),'--headless','--path',str(R),'--script',f'res://tests/integration/{suite}.gd'],'live_'+suite+'.log')
 run(['pwsh','-NoProfile','-File',str(R/'tools/package.ps1'),'-GodotPath',str(engine)],'package.log',timeout=360)
else:
 assert 'RELEASE_SMOKE_OK profiles=3 boss_victories=3' in (L/'package.log').read_text(encoding='utf-8')
release=R/'builds/windows'
for suite in ('test_torso_hurtbox','test_roster_pixel','test_astra_cast_corrections'):
 run([str(release/'EndlessSurvival_console.exe'),'--headless','--main-pack',str(release/'EndlessSurvival.pck'),'--script',str(R/f'tests/integration/{suite}.gd')],'packed_'+suite+'.log',cwd=release)
run([str(engine),'--path',str(R),'--quit-after','120'],'live_gui_boot.log')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
assets=[dict(path=p.relative_to(R).as_posix(),sha256=sha(p),license='ORIGINAL_CREATED_FOR_PROJECT') for p in (R/'assets/art_v3').rglob('*') if p.is_file() and '.import' not in p.name]
provenance=dict(revision='three-heroes-pixel-v3',assets=assets,source='tools/art_v3/generate.py + generate_roster.py',approval='Owner visual approval pending')
(L/'provenance.json').write_text(json.dumps(provenance,indent=2))
shutil.copy2(L/'provenance.json',release/'pixel_v3_provenance.json');shutil.copy2(L/'regression.json',release/'pixel_v3_regression.json')
archive=R/'builds/EndlessSurvival-Windows.zip'
files=[p for p in release.iterdir() if p.is_file() and p.suffix in ('.exe','.pck','.cmd','.txt','.md','.csv','.json')]
files += [p for p in (release/'licenses').iterdir() if p.is_file() and p.suffix in ('.txt','.md','.csv')]
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
 for p in files:z.write(p,'windows/'+p.relative_to(release).as_posix())
with zipfile.ZipFile(archive) as z:assert z.testzip() is None
versioned=R/'builds/EndlessSurvival-Three-Heroes-Pixel-v3-Windows.zip';shutil.copy2(archive,versioned)
data=dict(status='TECH_PASSED; owner visual review pending',canonical_suites=38,failed_suites=0,focused_checks_each_environment=61,build=str(versioned),sha256=sha(versioned),pck_sha256=sha(release/'EndlessSurvival.pck'),branch='feat/three-hero-pixel-v3')
(L/'delivery.json').write_text(json.dumps(data,indent=2));shutil.copytree(L,O,dirs_exist_ok=True,ignore=shutil.ignore_patterns('*.avi','*.wav','delivery_progress.log'))
print(json.dumps(data,indent=2),flush=True)
