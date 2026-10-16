"""Strict character PNG/manifest acceptance checks, independent of Godot."""
import json, re
from pathlib import Path
from PIL import Image
from generate import ROOT, DIRS, CLIPS
from schema_check import check
SCHEMA=ROOT/'assets/vfx/Endless_Survival_Art_Agent_Handoff_v1/templates/character_manifest.schema.json'

def validate(path):
    errors=[]
    try: data=json.loads(path.read_text())
    except (ValueError,OSError) as exc: return [str(exc)]
    errors.extend(check(data,json.loads(SCHEMA.read_text())))
    if errors: return errors
    if not re.fullmatch('[a-z_]+',str(data.get('character_id',''))): errors.append('character_id')
    if data.get('canvas') != [128,128]: errors.append('canvas')
    if data.get('feet_anchor') != [64,108]: errors.append('feet_anchor')
    if data.get('directions') != list(DIRS): errors.append('directions')
    if not isinstance(data.get('visual_profile'),dict): errors.append('visual_profile')
    for clip,(minimum,_,_) in CLIPS.items():
        anim=data.get('animations',{}).get(clip,{})
        if type(anim.get('fps')) not in (int,float) or anim.get('fps',0)<=0: errors.append(f'{clip}: fps')
        if type(anim.get('loop')) is not bool: errors.append(f'{clip}: loop')
        for direction in DIRS:
            frames=anim.get('directions',{}).get(direction,[])
            if len(frames)<minimum: errors.append(f'{clip}/{direction}: missing frames')
            for index,name in enumerate(frames):
                expected=f'frames/{clip}/{direction}/{index:03}.png'
                if name != expected: errors.append(f'unsafe or nonsequential path: {name}'); continue
                file=path.parent/name
                try:
                    with Image.open(file) as im:
                        if im.mode!='RGBA' or im.size!=(128,128): errors.append(f'{name}: size/mode')
                        if im.getextrema()[3] != (0,255): errors.append(f'{name}: alpha')
                        bbox=im.getbbox()
                        if not bbox or bbox[0]==0 or bbox[2]==128: errors.append(f'{name}: empty/clipped')
                        if len(im.getcolors(100000) or [])>25: errors.append(f'{name}: palette budget')
                except (OSError,ValueError): errors.append(f'{name}: unreadable')
    return errors

if __name__=='__main__':
    failures=[]
    paths=sorted((ROOT/'assets/characters').glob('*/manifest.json'))
    if len(paths)!=3: failures.append('expected exactly three character manifests')
    for path in paths:
        errors=validate(path); failures.extend(errors); print(path.parent.name, 'PASS' if not errors else errors)
    vfx_schema=json.loads((SCHEMA.parent/'vfx_manifest.schema.json').read_text())
    effects=sorted((ROOT/'assets/vfx/generated').glob('*.json'))
    if len(effects)!=15: failures.append('expected fifteen VFX manifests')
    for path in effects: failures.extend(check(json.loads(path.read_text()),vfx_schema))
    if failures:
        print(failures)
        raise SystemExit(1)
