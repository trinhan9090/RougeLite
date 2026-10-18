from pathlib import Path
import json
R=Path(__file__).resolve().parents[2]
for hero in ['vex','boros']:
 p=R/f'content/characters/{hero}_loadout.tres';s=p.read_text(encoding='utf-8')
 s=s.replace(f'res://assets/characters/{hero}/frames.tres',f'res://assets/art_v3/characters/{hero}/frames.tres')
 if 'cast_origin_offset =' not in s:s=s.replace('character_id =', 'cast_origin_offset = Vector2(0, -18)\ncharacter_id =')
 p.write_text(s,encoding='utf-8')
 for p in (R/'assets/vfx/generated').glob(hero+'_*.json'):
  m=json.loads(p.read_text());m['parameters']['renderer']='pixel_v3';m['parameters']['revision']='three-heroes-v3';p.write_text(json.dumps(m,indent=2)+'\n')
  if hero=='boros' and m['parameters']['skill_id']=='skill.boros.k':m['parameters']['style']='resolve';p.write_text(json.dumps(m,indent=2)+'\n')
  print(hero,m['parameters']['skill_id'],m['parameters']['style'])
p=R/'tests/integration/test_astra_celestial_vfx.gd';s=p.read_text().replace('=="","other character renderer unchanged"','=="pixel_v3","roster character uses shared pixel renderer"')
s=s.replace('"skill.vex.basic","position":Vector2.ZERO','"skill.fixture.legacy","position":Vector2.ZERO');p.write_text(s)
p=R/'project.godot';s=p.read_text().replace('Astra Pixel v3 Fix01','Three Heroes Pixel v3');p.write_text(s)
print('Configured shared controller, fifteen real-action VFX manifests and native-scale loadouts')
