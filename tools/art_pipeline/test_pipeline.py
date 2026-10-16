import copy, json, tempfile, unittest
from pathlib import Path
from generate import ROOT
from validate import validate
from schema_check import check
from generate import frame
tempfile.tempdir=str(ROOT/'.local-data')
(ROOT/'.local-data').mkdir(exist_ok=True)

class PipelineTests(unittest.TestCase):
    def test_deterministic_and_directional(self):
        for hero in ('astra','vex','boros'):
            image=frame(hero,'south','run',2,8)
            self.assertEqual(image.tobytes(),frame(hero,'south','run',2,8).tobytes())
            self.assertNotEqual(image.tobytes(),frame(hero,'north','run',2,8).tobytes())
            self.assertNotEqual(frame(hero,'west','idle',0,4).tobytes(),frame(hero,'east','idle',0,4).tobytes())

    def test_vfx_schemas(self):
        schema=json.loads((ROOT/'assets/vfx/Endless_Survival_Art_Agent_Handoff_v1/templates/vfx_manifest.schema.json').read_text())
        paths=list((ROOT/'assets/vfx/generated').glob('*.json'))
        self.assertEqual(len(paths),15)
        for path in paths:
            data=json.loads(path.read_text()); self.assertEqual(check(data,schema),[])
            data['category']='invented'; self.assertTrue(check(data,schema))
    def test_schema_keywords(self):
        cases=[({}, {'required':['x']}), ('bad', {'type':'number'}), (True,{'type':'integer'}),
               (0,{'exclusiveMinimum':0}), (-1,{'minimum':0}), ('abc',{'pattern':'^frames/'}),
               ([1,1],{'uniqueItems':True}), ([],{'minItems':1}), ([1,2],{'maxItems':1}),
               ('a',{'enum':['b']}), ([64,128],{'prefixItems':[{'const':128},{'const':128}]}),
               ({'x':1},{'properties':{'x':{'type':'string'}}}),
               ({'x':1},{'additionalProperties':{'type':'string'}})]
        for value,schema in cases: self.assertTrue(check(value,schema),(value,schema))
        self.assertEqual(check({'x':[1,2]}, {'type':'object','properties':{'x':{'type':'array','items':{'type':'integer'}}}}),[])
    def test_generated_assets(self):
        for name in ('astra','vex','boros'):
            self.assertEqual(validate(ROOT/f'assets/characters/{name}/manifest.json'),[])

    def test_rejects_invalid_manifests(self):
        source=json.loads((ROOT/'assets/characters/astra/manifest.json').read_text())
        mutations=[('canvas',[64,64]),('directions',['south']),('character_id','../escape'),('feet_anchor',[0,0])]
        with tempfile.TemporaryDirectory() as temporary:
            path=Path(temporary)/'manifest.json'
            for key,value in mutations:
                data=copy.deepcopy(source); data[key]=value; path.write_text(json.dumps(data))
                self.assertTrue(validate(path))

    def test_rejects_path_traversal_and_missing_png(self):
        data=json.loads((ROOT/'assets/characters/astra/manifest.json').read_text())
        data['animations']['idle']['directions']['south'][0]='../../escape.png'
        with tempfile.TemporaryDirectory() as temporary:
            path=Path(temporary)/'manifest.json'; path.write_text(json.dumps(data)); errors=validate(path)
            self.assertTrue(any('pattern' in error or 'unsafe' in error for error in errors))
            data['animations']['idle']['directions']['south'][0]='frames/idle/south/000.png'
            path.write_text(json.dumps(data))
            self.assertTrue(any('unreadable' in error for error in validate(path)))

if __name__=='__main__': unittest.main()
