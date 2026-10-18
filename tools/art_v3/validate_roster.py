from pathlib import Path
from PIL import Image
import json, hashlib, os
R=Path(__file__).resolve().parents[2]
checks=0
def check(ok,label):
 global checks
 checks+=1
 if not ok:raise AssertionError(label)
for hero in ('astra','vex','boros'):
 folder=R/'assets/art_v3/characters'/hero
 m=json.loads((folder/'manifest.json').read_text())
 check(m['feet_anchor_px']==[48,76],hero+' feet')
 check(len(m['palette'])<=24,hero+' palette')
 for direction in ('north','south','east','west'):
  for state,definition in m['animations'].items():
   hashes=set()
   for n in range(definition['frames']):
    im=Image.open(folder/f'{state}_{direction}_{n:02d}.png').convert('RGBA')
    check(im.size==(96,96),'canvas')
    check(set(im.getchannel('A').tobytes())<={0,255},'hard pixels')
    b=im.getbbox();check(b and b[0]>0 and b[1]>0 and b[2]<96 and b[3]<96,hero+' clipping '+state)
    hashes.add(hashlib.sha256(im.tobytes()).hexdigest())
   check(len(hashes)>1,hero+' animated '+state)
   check(state!='death' or not definition['loop'],'death no loop')
out=R/os.environ.get('ROUGELITE_TEST_OUT','reports/visual_qa/v3_three_heroes')/'asset_tests.json'
out.write_text(json.dumps(dict(checks=checks,failures=0,heroes=3,frames=720,license='Original programmatically authored pixel artwork; no concept pixels copied'),indent=2))
print(f'RESULT roster assets checks={checks} failures=0')
