"""Build source-backed Graveshade body/VFX/audio; no source state code executes."""
from pathlib import Path
import json,csv,shutil,math
from PIL import Image,ImageOps
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'reports/graveshade';DATA=ROOT/'experiments/graveshade/data';DEST=ROOT/'assets/private_graveshade'
def build():
 DEST.mkdir(exist_ok=True);(DEST/'audio').mkdir(exist_ok=True)
 r=json.loads((OUT/'source_catalog.json').read_text());sprites=json.loads((DATA/'sprites.json').read_text())['sprites'];actions={a['id']:a for a in r['actions']}
 mapping={'idle':[0],'run':[20],'basic':[220],'cast_j':[1011],'cast_k':[1006],'cast_l':[1012],'cast_i':[3006],'hit':[5000],'death':[5100]}
 ex=[];sub=[];anims=[];ledger=[]
 scale=.125;cw,ch=160,112;anchor=(80,84)
 for name,ids in mapping.items():
  frames=[f for aid in ids for f in actions[aid]['frames']];sheet=Image.new('RGBA',(cw*len(frames),ch));refs=[]
  for i,f in enumerate(frames):
   e=sprites.get(f"{f['group']}_{f['index']}");im=Image.open(DATA/e['path']).convert('RGBA') if e else Image.new('RGBA',(1,1));ax,ay=e['axis'] if e else (0,0)
   if 'H' in f['flip'].upper():im=ImageOps.mirror(im);ax=im.width-ax
   if 'V' in f['flip'].upper():im=ImageOps.flip(im);ay=im.height-ay
   assert f['scale']==[1.0,1.0] and f['angle']==0
   im=im.resize((max(1,round(im.width*scale)),max(1,round(im.height*scale))),Image.Resampling.NEAREST)
   x=anchor[0]+round((f['offset'][0]-ax)*scale);y=anchor[1]+round((f['offset'][1]-ay)*scale)
   assert x>=0 and y>=0 and x+im.width<=cw and y+im.height<=ch,(name,i,x,y,im.size)
   sheet.alpha_composite(im,(i*cw+x,y));sid=f'{name}_{i}'
   sub.append(f'[sub_resource type="AtlasTexture" id="{sid}"]\natlas = ExtResource("{name}")\nregion = Rect2({cw*i},0,{cw},{ch})\nfilter_clip = true')
   refs.append('{"duration":'+str(float(max(1,f['ticks'])))+',"texture":SubResource("'+sid+'")}')
  sheet.save(DEST/f'actor_{name}.png');ex.append(f'[ext_resource type="Texture2D" path="res://assets/private_graveshade/actor_{name}.png" id="{name}"]')
  total=sum(max(1,f['ticks']) for f in frames);duration={'basic':.30,'cast_j':.65,'cast_k':.7,'cast_l':.5,'cast_i':.8,'hit':.12,'death':.6}.get(name,total/60)
  for direction in ['north','south','east','west']:anims.append('{"name":&"'+name+'_'+direction+'","loop":'+str(name in ['idle','run']).lower()+',"speed":'+str(total/duration)+',"frames":['+','.join(refs)+']}')
  ledger.append(dict(action=name,source_id='punisher_rahlonnir_local',source_file='P.sff/P.air',provenance_status='unverified_rights',usage='local_prototype_only',air_actions=ids,runtime_start_frame=1 if name=='basic' else 0,source_frames=frames,duration=duration,relative_ticks_preserved=True))
 (DEST/'frames.tres').write_text('[gd_resource type="SpriteFrames" format=3]\n'+'\n'.join(ex)+'\n'+'\n'.join(sub)+'\n[resource]\nanimations = ['+',\n'.join(anims)+']\nmetadata/pixel_v3 = true\nmetadata/cardinal = true\nmetadata/side_view = true\nmetadata/action_start_frames = {"basic":1}\nmetadata/sustained_actions = PackedStringArray("cast_j","cast_i")\nmetadata/aimed_actions = PackedStringArray("basic","cast_j","cast_k","cast_l","cast_i")\nmetadata/feet_anchor = Vector2(80,84)\nmetadata/body_center = Vector2(80,58)\nmetadata/vfx_color = Color(1,0.72,0.25,1)\nmetadata/audio_profile = "res://assets/private_graveshade/audio/cues.json"\nmetadata/tactical_effects_profile = "res://assets/private_graveshade/effects.json"\n')
 effects={}
 for name,aid in {'bullet':6191011,'muzzle':619220,'grenade':1007,'explosion':1008,'mine':6191012,'mine_explosion':6201012,'rocket':3008,'rocket_explosion':3009,'rocket_muzzle':6193007,'impact':6192}.items():
  seq=[]
  for i,f in enumerate(actions[aid]['frames']):
   if f['group']<0:continue
   e=sprites[f"{f['group']}_{f['index']}"];im=Image.open(DATA/e['path']).convert('RGBA')
   if f['blend'].upper().startswith('A'):
    im.putdata([(r,g,b,0 if max(r,g,b)<8 else round(a*max(r,g,b)/255)) for r,g,b,a in im.get_flattened_data()])
   box=im.getbbox()
   if box:im=im.crop(box)
   file=f'{name}_{i}.png';im.save(DEST/file)
   seq.append(dict(path=f'res://assets/private_graveshade/{file}',ticks=max(1,f['ticks']),source_sprite=e['key'],axis=e['axis'],offset=f['offset'],blend=f['blend'],runtime_blend='luminance_alpha' if f['blend'].upper().startswith('A') else 'source_alpha',source_id='punisher_rahlonnir_local',source_file='P.sff',sprite_group=f['group'],sprite_index=f['index'],source_palette=e['palette'],provenance_status='unverified_rights',usage='local_prototype_only'))
  effects[name]=seq
 (DEST/'effects.json').write_text(json.dumps(effects,indent=2))
 # All cue entries are S0: equipment/effect bank; never import S1 spoken voice into basic.
 cues={'basic':('0_16',-22),'round':('0_31',-24),'throw':('0_24',-22),'mine_arm':('0_24',-23),'explosion':('0_25',-20),'rocket_launch':('0_38',-20),'impact':('0_15',-25)}
 profile={}
 for key,(snd,db) in cues.items():
  assert any(s['key']==snd for s in r['sounds']),snd
  shutil.copy2(DATA/'audio'/f'{snd}.wav',DEST/'audio'/f'{snd}.wav');profile[key]=[dict(path=f'res://assets/private_graveshade/audio/{snd}.wav',delay=0,db=min(db,-26),source_id="punisher_rahlonnir_local",source_file="P.snd",snd_group=int(snd.split("_")[0]),snd_index=int(snd.split("_")[1]),provenance_status="unverified_rights",usage="local_prototype_only")]
 profile['impact:skill.graveshade.basic']=profile['impact']
 (DEST/'audio/cues.json').write_text(json.dumps(profile,indent=2))
 (OUT/'actor_mapping.json').write_text(json.dumps(dict(actions=ledger,direction_policy='SIDE_VIEW_LEFT_RIGHT_ONLY; north/south controller aliases, no fabricated rear view',scale=scale,anchor=anchor,source_tree_sha256=r['tree_sha256'],rights='unverified_rights/local_prototype_only',audio_verified='CNS_LINKED_PCM_DECODED; agent listening unavailable'),indent=2))
 with (OUT/'state_mapping.csv').open('w',newline='') as f:
  w=csv.writer(f);w.writerow(['slot','move','input','command','state_chain','body_air','effect_air','sound','confidence'])
  for row in [('Basic','Tactical Round','z','z','P.cns220','220','619220,620220','0,16','VERIFIED_TEXT_DECODED'),('J','Suppression Burst','D,F,c','SPECIAL9','specials.cns1011→6191011','1011','6191011,619220','0,31','VERIFIED_TEXT_DECODED'),('K','Frag Deployment','D,B,x','SPECIAL4','specials.cns1006→1007→1008','1006','1007,1008','0,24;0,25','VERIFIED_TEXT_DECODED'),('L','Tactical Minefield','D,B,a','SPECIAL10','specials.cns1012→6191012→6201012','1012','6191012,6201012','0,24;0,25','VERIFIED_TEXT_DECODED'),('I','Heavy Ordnance','D,F,a+b then fire','HYPER3','hypers.cns3005→3006→3007→3008→3009','3006','3007,3008,3009,6193007','0,38;0,25','VERIFIED_TEXT_DECODED')]:w.writerow(row)
 print('GRAVESHADE_BUILD',len(ledger),'body actions',sum(len(v) for v in effects.values()),'effect frames',len(cues),'cues')
if __name__=='__main__':build()
