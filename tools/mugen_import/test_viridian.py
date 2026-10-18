import unittest,json,wave,hashlib,csv
from pathlib import Path
from PIL import Image,ImageChops
from viridian_audit import ROOT,OUT,DATA,SOURCE,SUPPLIED

class ViridianSourceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):cls.r=json.loads((OUT/'source_catalog.json').read_text())
    def test_source_unchanged(self):
        for row in self.r['files']:
            self.assertEqual(hashlib.sha256((SOURCE/row['path']).read_bytes()).hexdigest(),row['sha256'])
        with (SUPPLIED/'SOURCE_STATE_INVENTORY.csv').open() as f:self.assertEqual(len(list(csv.DictReader(f))),250)
    def test_decode_and_flags(self):
        self.assertEqual(self.r['sff']['decoded'],1147);self.assertEqual(self.r['sff']['failures'],[])
        self.assertEqual(len(self.r['sounds']),103)
        self.assertTrue(self.r['missing_air_sprite_refs'])
        self.assertFalse(next(x for x in self.r['defs']['MVC2_DrDoom.def'] if x['kind']=='stcommon')['exists'])
        self.assertIsNone(self.r['archive_sha256'])
    def test_audio_pcm(self):
        for sound in self.r['sounds']:
            with wave.open(str(DATA/'audio'/f"{sound['key']}.wav")) as w:
                self.assertGreater(w.getnframes(),0)
                self.assertEqual(len(w.readframes(w.getnframes())),w.getnframes()*w.getnchannels()*w.getsampwidth())
    def test_mapping(self):
        m=json.loads((OUT/'viridian_import_manifest.json').read_text())
        self.assertEqual(len(m['mappings']),5)
        self.assertEqual(m['source_direction_coverage'],'2_DIR_POC_ONLY')
        sprites={e['key'] for e in json.loads((DATA/'sprites.json').read_text())['entries']}
        for item in m['mappings']:
            self.assertTrue(item['verified_by_preview'])
            self.assertFalse(item['heard_by_agent'])
            self.assertTrue(set(item['sprite_refs']).issubset(sprites))
    def test_source_actor(self):
        m=json.loads((OUT/'actor_mapping.json').read_text())
        self.assertEqual(m['runtime_actor'],'MUGEN_SOURCE_SIDE_VIEW')
        self.assertEqual(len(m['actions']),9)
        actions={a['id']:a for a in self.r['actions']['base']}
        for row in m['actions']:
            source=actions[row['air_action']]
            self.assertEqual([f['ticks'] for f in row['frames']],[f['ticks'] for f in source['frames']])
            im=Image.open(ROOT/'assets/private_viridian'/('actor_'+row['action']+'.png'))
            self.assertEqual(im.size,(160*len(source['frames']),112))
            self.assertEqual(hashlib.sha256((ROOT/'assets/private_viridian'/('actor_'+row['action']+'.png')).read_bytes()).hexdigest(),row['texture_sha256'])
        text=(ROOT/'assets/viridian/frames.tres').read_text()
        self.assertIn('metadata/side_view = true',text)
        self.assertNotIn('res://assets/viridian/idle_north.png',text)
    def test_basic_nonvoice(self):
        cues=json.loads((ROOT/'assets/private_viridian/audio/cues.json').read_text())
        self.assertEqual(cues['basic'][0]['path'],'res://assets/viridian/audio/emerald_shot.wav')
        self.assertEqual(cues['impact:skill.viridian.basic'][0]['path'],'res://assets/viridian/audio/emerald_hit.wav')
        for name in ['emerald_shot','emerald_hit']:
            with wave.open(str(ROOT/'assets/viridian/audio'/f'{name}.wav')) as w:self.assertGreater(w.getnframes(),0)
    def test_catalog(self):
        self.assertTrue((OUT/'animation_preview.html').read_text().count('requestAnimationFrame')>=2)
        self.assertEqual((OUT/'sound_catalog.html').read_text().count('<audio controls'),103)
        for rows in self.r['actions'].values():
            self.assertTrue(all('loop_start' in a and all('boxes' in f and 'offset' in f for f in a['frames']) for a in rows))

if __name__=='__main__':unittest.main()
