from pathlib import Path
import json
from PIL import Image,ImageChops
from generate_roster import actor
R=Path(__file__).resolve().parents[2];O=R/'reports/visual_qa/v3_fix03';checks=0
def check(ok,label):
 global checks
 checks+=1
 if not ok:raise AssertionError(label)
for hero in ('vex','boros'):
 for frame in range(8):
  back,_=actor('north','run',frame,hero);front,_=actor('south','run',frame,hero)
  check(ImageChops.difference(back.crop((36,47,61,74)),front.crop((36,47,61,74))).getbbox() is not None,hero+' rear cloth')
  check(ImageChops.difference(back.crop((36,72,61,78)),front.crop((36,72,61,78))).getbbox() is not None,hero+' rear heel')
for state in ('idle','run'):
 for direction in ('north','south','east','west'):
  for frame in range(6 if state=='idle' else 8):
   _,weapon=actor(direction,state,frame,'boros')
   check(weapon.getchannel('A').crop((40,28,57,47)).getbbox() is None,'sword carry clear of head')
   check(weapon.getbbox()[3]>69,'blade points downward beside hip')
haste=Image.open(R/'assets/art_v3/vfx/haste.png').convert('RGBA')
check(haste.size==(192,16),'compact haste sheet')
for frame in range(6):
 alpha=haste.crop((frame*32,0,(frame+1)*32,16)).getchannel('A')
 check(sum(v>0 for v in alpha.tobytes())<32,'haste uses sparse ankle accents')
(O/'pose_tests.json').write_text(json.dumps(dict(checks=checks,failures=0,reference_pose='User explicitly selected downward carry beside hip; no face overlap'),indent=2))
print(f'RESULT pose pixels checks={checks} failures=0')
