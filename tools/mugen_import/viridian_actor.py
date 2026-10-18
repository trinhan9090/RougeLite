"""Import actual base DEF AIR/SFF body frames, preserving axes and relative ticks."""
import json
from PIL import Image,ImageOps
from viridian_audit import ROOT,DATA,OUT,sha

def build_actor(catalog,sprites):
    actions={a['id']:a for a in catalog['actions']['base']}
    # Verified CNS anim expressions:1510+(air),1450,3001+5*(air),1480,3081.
    mapping={'idle':0,'run':20,'basic':1510,'cast_j':1450,'cast_k':3001,'cast_l':1480,'cast_i':3081,'hit':5000,'death':5100}
    private=ROOT/'assets/private_viridian';private.mkdir(exist_ok=True)
    ext=[];sub=[];animations=[];ledger=[]
    # One shared canvas/scale retains source pivot; no frame-by-frame bounding-box recentering.
    scale=.43;cw,ch=160,112;anchor=(80,84)
    for name,aid in mapping.items():
        action=actions[aid];frames=action['frames'];sheet=Image.new('RGBA',(cw*len(frames),ch));records=[]
        for i,f in enumerate(frames):
            key=f"{f['group']}_{f['index']}";entry=sprites[key]
            source=Image.open(DATA/entry['path']).convert('RGBA')
            ax,ay=entry['axis'];ox,oy=f['offset']
            if 'H' in f['flip'].upper():source=ImageOps.mirror(source);ax=source.width-ax
            if 'V' in f['flip'].upper():source=ImageOps.flip(source);ay=source.height-ay
            assert f['scale']==[1.0,1.0] and f['angle']==0.0,(aid,i)
            source=source.resize((max(1,round(source.width*scale)),max(1,round(source.height*scale))),Image.Resampling.NEAREST)
            x=anchor[0]+round((ox-ax)*scale);y=anchor[1]+round((oy-ay)*scale)
            assert 0<=x and x+source.width<=cw and 0<=y and y+source.height<=ch,(name,i,x,y,source.size)
            sheet.alpha_composite(source,(i*cw+x,y))
            records.append(dict(sprite=key,axis=entry['axis'],offset=f['offset'],ticks=f['ticks'],decoded_sha256=entry['sha256']))
        path=private/f'actor_{name}.png';sheet.save(path)
        ext.append(f'[ext_resource type="Texture2D" path="res://assets/private_viridian/{path.name}" id="{name}"]')
        refs=[]
        for i,f in enumerate(frames):
            sid=f'{name}_{i}';sub.append(f'[sub_resource type="AtlasTexture" id="{sid}"]\natlas = ExtResource("{name}")\nregion = Rect2({cw*i},0,{cw},{ch})\nfilter_clip = true')
            refs.append('{"duration":'+str(float(max(1,f['ticks'])))+',"texture":SubResource("'+sid+'")}')
        # Source relative ticks; active total duration fits existing game action, never changes mechanics.
        total=sum(max(1,f['ticks']) for f in frames)
        duration={'basic':.65,'cast_j':.5,'cast_k':.4,'cast_l':.6,'cast_i':1.4,'hit':.12,'death':.6}.get(name,total/60)
        for direction in ['north','south','east','west']:
            animations.append('{"name":&"'+name+'_'+direction+'","loop":'+str(name in ['idle','run']).lower()+',"speed":'+str(total/duration)+',"frames":['+','.join(refs)+']}')
        ledger.append(dict(action=name,air_action=aid,frames=records,relative_ticks_preserved=True,runtime_duration=duration,texture_sha256=sha(path.read_bytes())))
    text='[gd_resource type="SpriteFrames" format=3]\n'+'\n'.join(ext)+'\n'+'\n'.join(sub)+'\n[resource]\nanimations = ['+',\n'.join(animations)+']\nmetadata/pixel_v3 = true\nmetadata/cardinal = true\nmetadata/side_view = true\nmetadata/aimed_actions = PackedStringArray("basic","cast_j","cast_k","cast_l","cast_i")\nmetadata/feet_anchor = Vector2(80,84)\nmetadata/body_center = Vector2(80,58)\nmetadata/vfx_color = Color(0.196,0.788,0.404,1)\nmetadata/audio_profile = "res://assets/private_viridian/audio/cues.json"\nmetadata/mapped_effects_profile = "res://assets/private_viridian/profile.json"\n'
    (ROOT/'assets/viridian/frames.tres').write_text(text)
    (OUT/'actor_mapping.json').write_text(json.dumps(dict(runtime_actor='MUGEN_SOURCE_SIDE_VIEW',source_tree_sha256=catalog['tree_sha256'],direction_policy='Source right-facing mirrored left; vertical movement retains last horizontal facing. Directional names are controller aliases, not distinct north/south artwork.',scale=scale,anchor=anchor,canvas=[cw,ch],actions=ledger),indent=2))
