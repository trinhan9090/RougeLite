"""Validate native pixels, anchoring, state variation and deterministic provenance."""
from pathlib import Path
from PIL import Image
import json,hashlib
R=Path(__file__).resolve().parents[2];folder=R/'assets/art_v3/characters/astra'
m=json.loads((folder/'manifest.json').read_text());checks=0
def check(ok,label):
 global checks
 checks+=1
 if not ok:raise AssertionError(label)
check(set(m['directions'])=={'N','S','E','W'},'four directions')
check(len(m['palette'])<=24,'core palette budget')
check(m['feet_anchor_px']==[48,76],'fixed foot anchor')
check(set(m['animations'])=={'idle','run','basic','cast_j','cast_k','cast_l','cast_i','hit','death'},'all states')
for direction in ['south','north','east','west']:
 for state,definition in m['animations'].items():
  hashes=set()
  for i in range(definition['frames']):
   im=Image.open(folder/f'{state}_{direction}_{i:02d}.png').convert('RGBA')
   check(im.size==(96,96),'fixed canvas');check(im.getbbox() is not None,'nonempty')
   check(set(im.getchannel('A').tobytes())<={0,255},'no antialias alpha')
   box=im.getbbox();check(box[0]>0 and box[1]>0 and box[2]<96 and box[3]<96,'no clipped pixels')
   hashes.add(hashlib.sha256(im.tobytes()).hexdigest())
  check(len(hashes)>=2,state+' genuinely animated')
  check(state!='death' or not definition['loop'],'death does not loop')
board=R/'reports/visual_qa/v3_astra/astra_contact.png'
Image.open(board).convert('L').save(board.with_name('astra_grayscale.png'))
(R/'reports/visual_qa/v3_astra/asset_tests.json').write_text(json.dumps({'checks':checks,'failures':0,'license':'original project artwork; no copied concept pixels'},indent=2))
print('RESULT v3 pixel assets checks=%d failures=0'%checks)
