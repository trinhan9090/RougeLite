"""Run canonical Godot suites with per-suite timeouts and durable progress logs."""
from pathlib import Path
import re,subprocess,os,json,time
R=Path(__file__).resolve().parents[2]
engine=R/'tools/godot/Godot_v4.7.2-stable_win64_console.exe'
if not engine.is_file():engine=R.parents[1]/'tools/godot/Godot_v4.7.2-stable_win64_console.exe'
env=dict(os.environ,APPDATA=str(R/'.local-data'))
suites=re.findall(r'"(res://tests/[^\"]+\.gd)"',(R/'tests/run_all.gd').read_text().split('func _initialize')[0])
results=[];out=R/os.environ.get('ROUGELITE_TEST_OUT','reports/visual_qa/v3_astra')
out.mkdir(parents=True,exist_ok=True)
with (out/'regression_bounded.log').open('w',encoding='utf-8') as log:
 for suite in suites:
  start=time.monotonic()
  try:
   p=subprocess.run([str(engine),'--headless','--path',str(R),'--script',suite],env=env,capture_output=True,timeout=90)
   text=(p.stdout+p.stderr).decode('utf-8',errors='replace')
   passed=p.returncode==0 and 'failures=0' in text and not any(x in text for x in ['ERROR:','WARNING:','SCRIPT ERROR:'])
   row={'suite':suite,'exit_code':p.returncode,'passed':passed,'seconds':round(time.monotonic()-start,3)}
  except subprocess.TimeoutExpired:
   text='TIMEOUT after90s';row={'suite':suite,'passed':False,'error':text}
  results.append(row);log.write(suite+'\n'+text+'\n');log.flush()
  (out/'regression.json').write_text(json.dumps({'suites':len(suites),'completed':len(results),'failures':sum(not x['passed'] for x in results),'results':results},indent=2))
  print(('PASS ' if row['passed'] else 'FAIL ')+suite,flush=True)
raise SystemExit(1 if any(not x['passed'] for x in results) else 0)
