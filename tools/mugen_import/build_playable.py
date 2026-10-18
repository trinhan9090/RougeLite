"""Build private gameplay textures from decoded source; no concept slicing or QA media."""
import json
from pathlib import Path
from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / 'experiments/mugen_atyu/data'
OUT = ROOT / 'assets/private_atyu'

def build():
    OUT.mkdir(exist_ok=True)
    actions = json.loads((DATA / 'actions.json').read_text())['actions']
    sprites = json.loads((DATA / 'sprites.json').read_text())['sprites']
    by_id = {}
    for action in actions:
        by_id.setdefault(action['id'], action)
    # Explicit source mappings. Empty helper actions 1150/2044 are not actor poses.
    mapping = {'idle':[0], 'run':[100], 'basic':[200], 'combo_1':[210],
               'combo_2':[211], 'cast_j':[210], 'cast_k':[900],
               'cast_l':[2001], 'cast_i':[1406,1401], 'hit':[5000], 'death':[5110]}
    ext, animations, manifest = [], [], {}
    index = 0
    for name, ids in mapping.items():
        frames = []
        for aid in ids:
            for frame in by_id[aid]['frames']:
                canvas = Image.new('RGBA', (256,256))
                key = f"{frame['group']}_{frame['index']}"
                ticks = max(1, frame['ticks'])
                if key in sprites:
                    entry = sprites[key]
                    image = Image.open(DATA / entry['path']).convert('RGBA')
                    if 'H' in frame['flip']: image = ImageOps.mirror(image)
                    if 'V' in frame['flip']: image = ImageOps.flip(image)
                    sx,sy = frame['scale']
                    factor = 1.0 # source55px idle matches existing native48–53px heroes
                    image = image.resize((max(1,round(image.width*sx*factor)),max(1,round(image.height*sy*factor))),Image.Resampling.NEAREST)
                    ax = entry['width']-entry['axis'][0] if 'H' in frame['flip'] else entry['axis'][0]
                    ay = entry['height']-entry['axis'][1] if 'V' in frame['flip'] else entry['axis'][1]
                    x = 128+round((frame['offset'][0]-ax*sx)*factor)
                    y = 192+round((frame['offset'][1]-ay*sy)*factor)
                    if x<0 or y<0 or x+image.width>256 or y+image.height>256:
                        raise ValueError(f'clipped actor frame {name} {key}')
                    canvas.alpha_composite(image,(x,y))
                elif frame['group'] >= 0: raise ValueError(f'missing {key}')
                file = f'{name}_{index}.png'
                canvas.save(OUT/file)
                ext.append(f'[ext_resource type="Texture2D" path="res://assets/private_atyu/{file}" id="t{index}"]')
                frames.append('{"duration": %s, "texture": ExtResource("t%d")}' % (ticks,index))
                index += 1
        animations.append('{"name": &"%s", "loop": %s, "speed": 60.0, "frames": [%s]}' % (name,str(name in ['idle','run']).lower(),','.join(frames)))
        manifest[name] = {'air':ids,'frames':len(frames)}
    (OUT/'frames.tres').write_text('[gd_resource type="SpriteFrames" format=3]\n'+'\n'.join(ext)+'\n[resource]\nanimations = ['+',\n'.join(animations)+']\nmetadata/pixel_v3 = true\nmetadata/feet_anchor = Vector2(128,192)\nmetadata/body_center = Vector2(128,168)\nmetadata/slot_actions = true\nmetadata/side_view = true\nmetadata/audio_profile = "res://assets/private_atyu/audio/cues.json"\nmetadata/combo_actions = PackedStringArray("basic", "combo_1", "combo_2")\n',encoding='utf8')
    # Reusable source effect sequences, axes preserved within each cropped frame.
    effects = {'companion':10190,'companion_attack':10230,'beam':8067,'seal':661502}
    processed=set()
    for name,aid in effects.items():
        action = by_id.get(aid)
        if action is None: raise ValueError(f'missing action {aid}')
        entries=[]
        for f in action['frames']:
            key=f"{f['group']}_{f['index']}"
            if key not in sprites:
                if f['group']<0: continue
                raise ValueError(f'missing effect {key}')
            s=sprites[key]
            file=f"fx_{s['table_index']}.png"
            if file in processed:
                entries.append({'file':file,'axis':s['axis'],'offset':f['offset'],'ticks':max(1,f['ticks']),'flip':f['flip']})
                continue
            image=Image.open(DATA/s['path']).convert('RGBA')
            pixels=[]
            for r,g,b,a in image.get_flattened_data():
                if name in ['companion','companion_attack'] and g>r*1.5 and g>b*1.5 and g>65: a=0
                if name in ['beam','seal']: a=min(a,max(r,g,b))
                pixels.append((r,g,b,a))
            image.putdata(pixels)
            if name=='beam':
                image=image.rotate(90,expand=True)
                box=image.getbbox()
                if box: image=image.crop(box)
            image.save(OUT/file)
            processed.add(file)
            entries.append({'file':file,'axis':s['axis'],'offset':f['offset'],'ticks':max(1,f['ticks']),'flip':f['flip']})
        manifest[name]={'air':[aid],'sequence':entries}
    (OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
    print('PRIVATE_ATYU_ASSETS_OK actor_frames=',index,'effects=',len(effects))

if __name__=='__main__': build()
