"""Original 32px muted terrain; deterministic per tile seed, no external assets."""
import csv, json, random
from pathlib import Path
from PIL import Image, ImageDraw
from generate import ROOT, PALETTES
THEMES={'enchanted_forest':('#233c35','#29463a','#334c3d','#4d6250'),
        'ruined_temple':('#292e3b','#323747','#3c4252','#555a69'),
        'volcanic_arena':('#382d37','#42323c','#4d3b42','#67505a')}
def main():
    for theme,colors in THEMES.items():
        sheet=Image.new('RGBA',(128,32))
        for variant in range(4):
            tile=Image.new('RGBA',(32,32),colors[0]); d=ImageDraw.Draw(tile); rng=random.Random(100+variant)
            if theme=='ruined_temple':
                d.line((0,0,31,0),fill=colors[0]); d.line((0,0,0,31),fill=colors[0]); d.line((16,0,16,15),fill=colors[2]); d.line((0,16,31,16),fill=colors[0])
            for _ in range(8):
                x,y=rng.randrange(2,30),rng.randrange(2,30)
                d.line((x,y,x+rng.randrange(1,4),y),fill=colors[rng.randrange(2,4)])
            sheet.paste(tile,(variant*32,0))
        path=ROOT/'assets/tiles'/theme; path.mkdir(parents=True,exist_ok=True); sheet.save(path/'terrain.png')
    vfx=ROOT/'assets/vfx/generated'; vfx.mkdir(parents=True,exist_ok=True)
    categories={'astra':['projectile','projectile','aura','area','beam'],
                'vex':['projectile','projectile','dash','projectile','projectile'],
                'boros':['slash','area','aura','dash','aura']}
    for hero in PALETTES:
        styles={'astra':['orb','snare','shield','sigil','beam'],'vex':['bullet','barrage','roll','piercing','storm'],'boros':['sword','slam','shield','charge','titan']}[hero]
        for action,category,style in zip(['basic','j','k','l','i'],categories[hero],styles):
            data={'effect_id':f'{hero}_{action}','category':category,'layer':1,'max_instances':80,
                  'event_type':'actual_projectile' if category=='projectile' else 'confirmed_execution',
                  'parameters':{'skill_id':f'skill.{hero}.{action}','color':PALETTES[hero][2] if hero=='boros' else PALETTES[hero][3],'style':style,
                      'geometry':'runtime snapshot','prototype':True}}
            if hero=='astra':
                data['parameters'].update(renderer='celestial',revision='astra-vfx-02',art_status='OWNER_REVIEW_PENDING')
            (vfx/f'{hero}_{action}.json').write_text(json.dumps(data,indent=2)+'\n')
    ledger=ROOT/'docs/art_asset_ledger.csv'
    columns=['asset_id','asset_path','source_url','author','license','license_url','modifications','commercial_use_allowed','attribution_required','verification_date','notes']
    with ledger.open('w',newline='') as output:
        writer=csv.DictWriter(output,fieldnames=columns); writer.writeheader()
        for folder in ['assets/characters','assets/tiles','assets/vfx/generated']:
            for path in sorted((ROOT/folder).rglob('*')):
                if path.suffix not in ('.png','.json','.tres'): continue
                relative=path.relative_to(ROOT).as_posix()
                writer.writerow(dict(zip(columns,[relative,relative,'local procedural source','Project procedural art pipeline','Project original; rights reserved','LICENSE_PROJECT.txt','Original generated prototype','yes (project owner)','no external attribution','2026-10-16','Source tools/art_pipeline; no concept pixels; seed0 body / seed100+ tile'])))
    print('ENVIRONMENT_GENERATED themes=3 vfx_manifests=15 ledger='+str(ledger))
if __name__=='__main__': main()
