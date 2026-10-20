"""Source-backed Tofu body/effects and guaranteed non-voice original audio fallback."""
from pathlib import Path
import json,math,wave,struct,random,csv
from PIL import Image,ImageOps
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'reports/tofu/20261018';DATA=ROOT/'experiments/tofu/data';DEST=ROOT/'assets/private_tofu'
def build():
 DEST.mkdir(parents=True,exist_ok=True);(DEST/'audio').mkdir(exist_ok=True)
 report=json.loads((OUT/'source_catalog.json').read_text());sprites=json.loads((DATA/'sprites.json').read_text())['sprites'];actions={}
 for a in report['actions']:actions.setdefault(a['id'],a)
 mapping={'idle':0,'run':100,'basic':200,'combo_1':210,'combo_2':250,'cast_j':1300,'cast_k':1600,'cast_l':1400,'cast_i':1200,'hit':5000,'death':5100}
 scale=1.1;cw,ch=512,256;anchor=(256,200);subs=[];external=[];anims=[];ledger=[]
 def image_for(frame):
  if frame['group']<0:return Image.new('RGBA',(1,1)),(0,0)
  e=sprites[f"{frame['group']}_{frame['index']}"];im=Image.open(DATA/e['path']).convert('RGBA');ax,ay=e['axis']
  if 'H' in frame['flip']:im=ImageOps.mirror(im);ax=im.width-ax
  if 'V' in frame['flip']:im=ImageOps.flip(im);ay=im.height-ay
  sx,sy=frame['scale']
  if sx<0:im=ImageOps.mirror(im);ax=im.width-ax
  if sy<0:im=ImageOps.flip(im);ay=im.height-ay
  if abs(sx)!=1 or abs(sy)!=1:
   im=im.resize((max(1,round(im.width*abs(sx))),max(1,round(im.height*abs(sy)))),Image.Resampling.NEAREST);ax*=abs(sx);ay*=abs(sy)
  if frame['angle']:
   dx,dy=ax-im.width*.5,ay-im.height*.5;angle=math.radians(frame['angle']);im=im.rotate(frame['angle'],resample=Image.Resampling.NEAREST,expand=True)
   ax=im.width*.5+math.cos(angle)*dx+math.sin(angle)*dy;ay=im.height*.5-math.sin(angle)*dx+math.cos(angle)*dy
  ax,ay=round(ax),round(ay)
  return im,(ax,ay)
 for name,aid in mapping.items():
  frames=actions[aid]['frames'];cols=min(8,len(frames));rows=math.ceil(len(frames)/cols);sheet=Image.new('RGBA',(cw*cols,ch*rows));refs=[]
  for i,f in enumerate(frames):
   im,axis=image_for(f);im=im.resize((max(1,round(im.width*scale)),max(1,round(im.height*scale))),Image.Resampling.NEAREST)
   x=anchor[0]+round((f['offset'][0]-axis[0])*scale);y=anchor[1]+round((f['offset'][1]-axis[1])*scale)
   assert 0<=x and 0<=y and x+im.width<=cw and y+im.height<=ch,(name,i,x,y,im.size)
   tx=(i%cols)*cw;ty=(i//cols)*ch;sheet.alpha_composite(im,(tx+x,ty+y));sid=f'{name}_{i}'
   subs.append(f'[sub_resource type="AtlasTexture" id="{sid}"]\natlas = ExtResource("{name}")\nregion = Rect2({tx},{ty},{cw},{ch})\nfilter_clip = true')
   refs.append('{"duration":'+str(float(max(1,f['ticks'])))+',"texture":SubResource("'+sid+'")}')
  sheet.save(DEST/f'actor_{name}.png');external.append(f'[ext_resource type="Texture2D" path="res://assets/private_tofu/actor_{name}.png" id="{name}"]')
  total=sum(max(1,f['ticks']) for f in frames);duration={'basic':.4,'combo_1':.4,'combo_2':.45,'cast_j':.8,'cast_k':.6,'cast_l':1.0,'cast_i':.65,'hit':.12,'death':.7}.get(name,total/60)
  for d in ['north','south','east','west']:anims.append('{"name":&"'+name+'_'+d+'","loop":'+str(name in ['idle','run']).lower()+',"speed":'+str(total/duration)+',"frames":['+','.join(refs)+']}')
  ledger.append(dict(action=name,air_action_id=aid,state_id=aid if name not in ['idle','hit','death'] else None,source_frames=frames,source_id='tofu_user_toji_local',source_file='Toji Fushiguro.sff/Toji Fushiguro.air',relative_ticks_preserved=True,runtime_duration=duration,verified_by_preview=name=='idle',verification='DECODED_REFERENCES_RESOLVED; OWNER_ACTION_REVIEW_PENDING',fallback_required=False,license_status='unverified_rights',usage='local_prototype_only'))
 metadata='metadata/pixel_v3 = true\nmetadata/cardinal = true\nmetadata/slot_actions = true\nmetadata/side_view = true\nmetadata/feet_anchor = Vector2(256,200)\nmetadata/body_center = Vector2(256,164)\nmetadata/motion_action = &"cast_j"\nmetadata/combo_actions = PackedStringArray("basic","combo_1","combo_2")\nmetadata/sustained_actions = PackedStringArray("cast_j","cast_l","cast_i")\nmetadata/aimed_actions = PackedStringArray("basic","combo_1","combo_2","cast_j","cast_k","cast_l","cast_i")\nmetadata/vfx_color = Color(0.6,0.5,0.8,1)\nmetadata/audio_profile = "res://assets/private_tofu/audio/cues.json"\nmetadata/melee_effects_profile = "res://assets/private_tofu/effects.json"\n'
 (DEST/'frames.tres').write_text('[gd_resource type="SpriteFrames" format=3]\n'+'\n'.join(external)+'\n'+'\n'.join(subs)+'\n[resource]\nanimations = ['+',\n'.join(anims)+']\n'+metadata)
 fx={}
 for name,aid in {'slash':6052,'rush':6151,'weapon':1301,'slam':7702,'debris':9024,'chain':7040,'nuke':6700,'spear':6550}.items():
  frames=actions[aid]['frames'];prepared=[]
  for f in frames:
   if f['group']<0:continue
   im,axis=image_for(f)
   if f['blend'].upper().startswith('A'):im.putdata([(rr,g,b,0 if max(rr,g,b)<8 else round(a*max(rr,g,b)/255)) for rr,g,b,a in im.get_flattened_data()])
   x=f['offset'][0]-axis[0];y=f['offset'][1]-axis[1];prepared.append((f,im,x,y))
  left=min(x for f,im,x,y in prepared);top=min(y for f,im,x,y in prepared);right=max(x+im.width for f,im,x,y in prepared);bottom=max(y+im.height for f,im,x,y in prepared)
  seq=[]
  for i,(f,im,x,y) in enumerate(prepared):
   canvas=Image.new('RGBA',(right-left,bottom-top));canvas.alpha_composite(im,(x-left,y-top));file=f'{name}_{i}.png';canvas.save(DEST/file)
   seq.append(dict(path=f'res://assets/private_tofu/{file}',ticks=max(1,f['ticks']),source_sprite=f"{f['group']}_{f['index']}",air_action_id=aid,offset=f['offset'],axis=sprites[f"{f['group']}_{f['index']}"]['axis'],source_id='tofu_user_toji_local',source_file='Toji Fushiguro.sff',source_license_status='unverified_rights',usage='local_prototype_only',runtime_blend='luminance_alpha' if f['blend'].upper().startswith('A') else 'source_alpha'))
  fx[name]=seq
 (DEST/'effects.json').write_text(json.dumps(fx,indent=2))
 # No source bank semantics are asserted without listening. Locally authored fallback only.
 cue_map={'basic':'slash','combo_1':'slash','combo_2':'heavy','cast_j':'rush','cast_k':'slam','cast_l':'chain','cast_i':'spear','impact':'impact'}
 for index,key in enumerate(sorted(set(cue_map.values()))):
  rate=22050;duration={'slam':.22,'spear':.18,'heavy':.15}.get(key,.10);rng=random.Random(311+index);data=[]
  for i in range(int(rate*duration)):
   t=i/rate;env=math.sin(math.pi*t/duration)**2*(1-t/duration);freq=130+index*45
   v=(rng.uniform(-1,1)*.65+math.sin(2*math.pi*freq*t)*.35)*env*.32;data.append(struct.pack('<h',round(v*32767)))
  with wave.open(str(DEST/'audio'/f'fallback_{key}.wav'),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate);w.writeframes(b''.join(data))
 cues={cue:[dict(path=f'res://assets/private_tofu/audio/fallback_{key}.wav',delay=0,db=-18,provenance_status='original_generated_non_voice',channel='weapon' if cue in ['basic','combo_1','combo_2','impact'] else 'skill')] for cue,key in cue_map.items()}
 (DEST/'audio/cues.json').write_text(json.dumps(cues,indent=2))
 (OUT/'actor_mapping.json').write_text(json.dumps(dict(actions=ledger,direction_policy='2_DIR_POC_ONLY; vertical input aliases retain real horizontal artwork',source_tree_sha256=report['tree_sha256'],audio='320PCM entries extracted; semantic listening unavailable; all source bank identities remain CANDIDATE; original nonvoice fallback active'),indent=2))
 evidence=[]
 for slot,state in [('Basic',200),('Basic2',210),('Basic3',250),('J',1300),('K',1600),('L',1400),('I',1200)]:
  found=next(st for st in report['states'] if st['id']==state and st['file']=='Toji Fushiguro.cns')
  evidence.append(dict(slot=slot,state=state,file=found['file'],line=found['line'],anim=found['header'].get('anim'),controllers=[c for c in found['controllers'] if c['fields'].get('type',[''])[0].lower() in ['playsnd','explod','helper','hitdef','changestate']]))
 (OUT/'mapping_evidence.json').write_text(json.dumps(evidence,indent=2))
 with (OUT/'skill_mapping.csv').open('w',newline='') as f:
  w=csv.writer(f);w.writerow(['slot','state','AIR','FX','sound_policy','confidence'])
  for slot,state,fxid in [('Basic',200,'6052'),('Basic2',210,'6052'),('Basic3',250,'6052'),('J',1300,'6151/1301'),('K',1600,'7702/1605->9024'),('L',1400,'7040'),('I',1200,'6700/6550')]:w.writerow([slot,state,state,fxid,'ORIGINAL_NONVOICE_FALLBACK; S500_NOT_LISTENED','CNS_AIR_SFF_RESOLVED'])
 print('TOFU_BUILD',len(ledger),'body clips',sum(map(len,fx.values())),'source FX frames',len(cues),'fallback cues')
if __name__=='__main__':build()
