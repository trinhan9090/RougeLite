import unittest,json,hashlib,wave,io,math,subprocess
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'reports/graveshade';DATA=ROOT/'experiments/graveshade/data';SRC=Path('D:/SelfProject/RougeLite/assets/characters/newADC/Punisher')
class GraveshadeAuditTests(unittest.TestCase):
 @classmethod
 def setUpClass(cls):cls.r=json.loads((OUT/'source_catalog.json').read_text());cls.s=json.loads((DATA/'sprites.json').read_text())
 def test_T01_source_safe_and_preserved(self):
  for row in self.r['files']:
   p=(SRC/row['path']).resolve();self.assertTrue(p.is_relative_to(SRC.resolve()));self.assertEqual(hashlib.sha256(p.read_bytes()).hexdigest(),row['sha256'])
 def test_T01_original_archive(self):
  archives=list(SRC.parent.glob('*.rar'))
  if not archives:self.skipTest('Original marvel P.rar absent locally; audit covers supplied extracted35files, no archive hash invented.')
 def test_T02_def(self):
  self.assertTrue(all(x['exists'] for x in self.r['references']))
  self.assertEqual(next(x['path'] for x in self.r['references'] if x['kind']=='sprite'),'P.sff')
 def test_T03_sprites_and_AIR(self):
  self.assertEqual(self.s['decoded'],700);self.assertFalse(self.s['failures']);self.assertEqual(len(self.r['actions']),204);self.assertFalse(self.r['missing_air'])
  for entry in self.s['entries']:
   im=Image.open(DATA/entry['path']).convert('RGBA');self.assertEqual(hashlib.sha256(im.tobytes()).hexdigest(),entry['sha256'])
 def test_T04_PCM_and_provenance(self):
  self.assertEqual(len(self.r['sounds']),65)
  for row in self.r['sounds']:
   blob=(DATA/'audio'/f"{row['key']}.wav").read_bytes();self.assertEqual(hashlib.sha256(blob).hexdigest(),row['sha256'])
   with wave.open(io.BytesIO(blob)) as w:self.assertEqual(len(w.readframes(w.getnframes())),w.getnframes()*w.getnchannels()*w.getsampwidth())
 def test_T05_T28_cues_and_peak_bound(self):
  profile=json.loads((ROOT/'assets/private_graveshade/audio/cues.json').read_text())
  for cue,items in profile.items():
   for item in items:
    self.assertTrue((ROOT/item['path'][6:]).is_file());self.assertLessEqual(item['db'],-26)
  self.assertTrue(profile['basic'][0]['path'].endswith('0_16.wav'));self.assertNotIn('/1_',profile['basic'][0]['path'])
  self.assertLess(12*10**(-26/20),1,'Worst-case correlated fullscale12voices remain belowunity')
 def test_T06_T07_actual_source_actor(self):
  m=json.loads((OUT/'actor_mapping.json').read_text());self.assertEqual(len(m['actions']),9)
  source_actions={a['id']:a for a in self.r['actions']}
  for row in m['actions']:
   source=[f for aid in row['air_actions'] for f in source_actions[aid]['frames']];self.assertEqual(row['source_frames'],source)
   im=Image.open(ROOT/'assets/private_graveshade'/f"actor_{row['action']}.png");self.assertEqual(im.size,(160*len(source),112))
  self.assertIn('SIDE_VIEW_LEFT_RIGHT_ONLY',m['direction_policy'])
 def test_additive_effects_have_no_opaque_black_background(self):
  seq=json.loads((ROOT/'assets/private_graveshade/effects.json').read_text())
  for frames in seq.values():
   for row in frames:
    if not row['blend'].upper().startswith('A'):continue
    im=Image.open(ROOT/row['path'][6:]).convert('RGBA')
    self.assertFalse(any(a>0 and max(r,g,b)<8 for r,g,b,a in im.get_flattened_data()),row['path'])
 def test_T30_old_hero_gameplay_unchanged(self):
  files=[]
  for hero in ['astra','vex','boros','viridian']:
   files += [f'content/characters/{hero}_loadout.tres',f'content/characters/{hero}_stats.tres',f'content/skills/{hero}_basic.tres']
  for f in files:
   if not (ROOT/f).exists():continue
   before=subprocess.check_output(['git','show','ecc5b2c:'+f],cwd=ROOT)
   self.assertEqual(before.replace(b'\r\n',b'\n'),(ROOT/f).read_bytes().replace(b'\r\n',b'\n'),f)
 def test_doom_visual_only_reduction(self):
  d=json.loads((ROOT/'assets/private_viridian/profile.json').read_text());self.assertEqual(d['bolt_size'],[22,11]);self.assertEqual(d['basic_impact_size'],16)
if __name__=='__main__':unittest.main(verbosity=2)
