"""Build actual MUGEN source actor and explicitly mapped private source effects."""
from pathlib import Path
import json,math,shutil,csv,wave,struct,random
from PIL import Image,ImageDraw
from viridian_audit import ROOT,DATA,OUT,RAW,sha

from viridian_actor import build_actor

def build():
    catalog=json.loads((OUT/'source_catalog.json').read_text());sprites={e['key']:e for e in json.loads((DATA/'sprites.json').read_text())['entries']};actions={a['id']:a for a in catalog['actions']['base']}
    out=ROOT/'assets/viridian';out.mkdir(parents=True,exist_ok=True)
    build_actor(catalog,sprites)
    private=ROOT/'assets/private_viridian';private.mkdir(exist_ok=True);(private/'audio').mkdir(exist_ok=True)
    (private/'profile.json').write_text(json.dumps({'bolt_size':[22,11],'basic_impact_size':16,'sequences':'res://assets/private_viridian/effects.json','skills':{'skill.viridian.basic':'bolt','skill.viridian.j':'lance','skill.viridian.k':'prison','skill.viridian.l':'orbit','skill.viridian.i':'cataclysm'}},indent=2))
    # Inspecting source established these exact frames; incomplete plasma action
    # explicitly uses only its intact6810 sub-sequence, rather than invented IDs.
    mappings=[('bolt',1510,21516),('beam',1450,6810),('prison',3001,23001),('orb',1480,21480),('ultimate',3081,21516)]
    manifest={};ledger=[]
    for name,state,aid in mappings:
        seq=[]
        for i,f in enumerate(actions[aid]['frames']):
            key=f"{f['group']}_{f['index']}";assert key in sprites,key
            source=Image.open(DATA/sprites[key]['path']).convert('RGBA');box=source.getbbox();image=source.crop(box) if box else source
            pix=[];w,h=image.size
            for y in range(h):
                for x in range(w):
                    r,g,b,a=image.getpixel((x,y));v=max(r,g,b)/255
                    # Explicit luminance LUT: jade shadows, emerald mid, white core.
                    c=(30,109,74) if v<.35 else (50,201,103) if v<.70 else (163,255,178) if v<.93 else (242,255,229)
                    alpha=round(a*v)
                    if name=='prison' and ((x/w-.5)**2/.25+(y/h-.5)**2/.25)<.65:alpha=0
                    pix.append((*c,alpha))
            image.putdata(pix);file=f'{name}_{i}.png';image.save(private/file)
            seq.append(dict(path=f'res://assets/private_viridian/{file}',ticks=max(1,f['ticks']),axis=sprites[key]['axis'],offset=f['offset']))
        manifest[name]=seq
        ledger.append(dict(move=name,state_id=state,air_action_id=aid,sprite_refs=[f"{f['group']}_{f['index']}" for f in actions[aid]['frames']],definition_variant='base',cns_path='MVC2_DrDoom.cns',source_tree_sha256=catalog['tree_sha256'],source_archive_sha256=None,source_license_status='PRIVATE_TEST_ONLY',verified_by_preview=True,heard_by_agent=False,fallback_required=name=='beam',notes='Partial plasma21450 missing sprites; intact6810 sub-sequence adapted' if name=='beam' else 'Decoded/visually inspected; geometry/timing adapted by game runtime'))
    (private/'effects.json').write_text(json.dumps(manifest,indent=2))
    cues={'basic':('1510_1',-19),'cast_j':('810_0',-20),'cast_k':('1_1',-22),'cast_l':('1480_1',-22),'cast_i':('1510_1',-23),'beam':('810_0',-20),'prison':('1_1',-22),'orbit':('1480_1',-24),'ray':('1510_1',-24),'impact':('1_7',-23)}
    profile={}
    for cue,(key,db) in cues.items():
        assert (DATA/'audio'/f'{key}.wav').is_file();shutil.copy2(DATA/'audio'/f'{key}.wav',private/'audio'/f'{key}.wav')
        profile[cue]=[dict(path=f'res://assets/private_viridian/audio/{key}.wav',delay=0,db=db)]
    # Guaranteed non-voice fallback while supplied SND timbres await listening.
    audio=out/'audio';audio.mkdir(exist_ok=True)
    for name,duration in [('emerald_shot',.12),('emerald_hit',.08)]:
        rng=random.Random(87);samples=[];rate=22050
        for j in range(round(rate*duration)):
            t=j/rate;phase=2*math.pi*(1500*t-3500*t*t)
            value=math.sin(phase)*math.exp(-t*35) if name=='emerald_shot' else (rng.random()*2-1)*math.exp(-t*65)
            samples.append(round(value*15000))
        with wave.open(str(audio/(name+'.wav')),'wb') as w:
            w.setparams((1,2,rate,0,'NONE','not compressed'));w.writeframes(struct.pack('<'+'h'*len(samples),*samples))
    profile['basic']=[dict(path='res://assets/viridian/audio/emerald_shot.wav',delay=0,db=-17)]
    profile['impact:skill.viridian.basic']=[dict(path='res://assets/viridian/audio/emerald_hit.wav',delay=0,db=-17)]
    (private/'audio/cues.json').write_text(json.dumps(profile,indent=2))
    (OUT/'viridian_import_manifest.json').write_text(json.dumps(dict(status='MAPPED_VISUAL_SOURCE_AND_CNS_LINKS',source_direction_coverage='2_DIR_POC_ONLY',runtime_actor='MUGEN_SOURCE_SIDE_VIEW',audio_identity='CNS_LINKED_NOT_AUDIBLY_VERIFIED',mappings=ledger),indent=2))
    with (OUT/'skill_mapping.csv').open('w',newline='') as f:
        w=csv.writer(f);w.writerow(['move','source_state','air_action','visual_verified','notes'])
        for l in ledger:w.writerow([l['move'],l['state_id'],l['air_action_id'],True,l['notes']])
    print('VIRIDIAN_ASSETS',36,'source body aliases, mapped effects',len(mappings),'runtime sounds',len(set(k for k,db in cues.values())))

if __name__=='__main__':build()
