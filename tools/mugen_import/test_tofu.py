import unittest,json,hashlib,wave,io,subprocess,re
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[2];SOURCE=Path('D:/SelfProject/RougeLite/assets/characters/Tofu/Toji Fushiguro');OUT=ROOT/'reports/tofu/20261018';DATA=ROOT/'experiments/tofu/data'
class TofuSourceTests(unittest.TestCase):
 def setUp(self):self.catalog=json.loads((OUT/'source_catalog.json').read_text());self.sprites=json.loads((DATA/'sprites.json').read_text())
 def test_offline_catalog_links_resolve(self):
  text=(OUT/'sound_catalog.html').read_text()
  paths=re.findall(r"src='([^']+\.wav)'",text)
  self.assertEqual(len(paths),320)
  for path in paths:self.assertTrue((OUT/path).resolve().is_file(),path)
  self.assertIn('../../../experiments/tofu/data/',(OUT/'animation_preview.html').read_text())
 def test_originals_unchanged(self):
  for row in self.catalog['files']:self.assertEqual(hashlib.sha256((SOURCE/row['path']).read_bytes()).hexdigest(),row['sha256'])
 def test_sff_complete_and_rgba_hashes(self):
  self.assertEqual(self.sprites['decoded'],2064);self.assertFalse(self.sprites['failures'])
  for row in self.sprites['entries']:
   with Image.open(DATA/row['path']) as original:
    im=original.convert('RGBA');self.assertEqual(hashlib.sha256(im.tobytes()).hexdigest(),row['sha256']);im.close()
 def test_all_selected_air_frames_resolve(self):
  mapping=json.loads((OUT/'actor_mapping.json').read_text());self.assertEqual(len(mapping['actions']),11)
  for clip in mapping['actions']:
   for f in clip['source_frames']:
    if f['group']>=0:self.assertIn(f"{f['group']}_{f['index']}",self.sprites['sprites'])
  self.assertIn('2_DIR_POC_ONLY',mapping['direction_policy']);self.assertEqual(len(self.catalog['actions']),317);self.assertEqual(len(self.catalog['missing_air']),55)
 def test_pcm_catalog(self):
  self.assertEqual(len(self.catalog['sounds']),320)
  for row in self.catalog['sounds']:
   blob=(DATA/'audio'/f"{row['key']}.wav").read_bytes();self.assertEqual(hashlib.sha256(blob).hexdigest(),row['sha256'])
   with wave.open(io.BytesIO(blob)) as w:self.assertEqual(w.getnframes(),row['frames'])
 def test_audio_fallback_is_truthful_and_no_voice(self):
  cues=json.loads((ROOT/'assets/private_tofu/audio/cues.json').read_text())
  for key,rows in cues.items():
   for row in rows:
    self.assertEqual(row['provenance_status'],'original_generated_non_voice');self.assertNotEqual(row['channel'],'voice');self.assertIn('fallback_',row['path']);self.assertNotIn('500_',row['path'])
  for row in self.catalog['sounds']:self.assertEqual(row['identity'],'CANDIDATE_NOT_LISTENED')
 def test_prior_six_hero_gameplay_preserved(self):
  for hero in ['astra','vex','boros','viridian','graveshade']:
   for rel in [f'content/characters/{hero}_loadout.tres',f'content/characters/{hero}_stats.tres',f'content/skills/{hero}_basic.tres']:
    old=subprocess.check_output(['git','show','9f0aea8:'+rel],cwd=ROOT).replace(b'\r\n',b'\n')
    current=(ROOT/rel).read_bytes().replace(b'\r\n',b'\n')
    # ZONE-AIM-01: explicitly approved K targeting flag is the only allowed baseline delta.
    if rel in ['content/characters/viridian_loadout.tres','content/characters/graveshade_loadout.tres']:
     self.assertEqual(current.count(b'prefer_nearest_with_facing_fallback = true\n'),1)
     current=current.replace(b'prefer_nearest_with_facing_fallback = true\n',b'')
    self.assertEqual(current,old,rel)
 def test_atlas_bounded_and_source_runtime_not_raw_dependency(self):
  text=(ROOT/'assets/private_tofu/frames.tres').read_text();self.assertIn('filter_clip = true',text);self.assertNotIn('Toji Fushiguro.sff',text)
  for file in (ROOT/'assets/private_tofu').glob('actor_*.png'):
   with Image.open(file) as im:self.assertLessEqual(max(im.size),4096);self.assertEqual(im.mode,'RGBA')
  self.assertIn('melee_combo_basic', (ROOT/'content/skills/tofu_basic.tres').read_text())
if __name__=='__main__':unittest.main(verbosity=2)
