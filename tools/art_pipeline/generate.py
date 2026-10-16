"""Original procedural PROTOTYPE pixel art. No reference image pixels are read.
Reproduce with Python 3.12 / Pillow 12.3: python tools/art_pipeline/generate.py.
"""
import json, math
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
DIRS = ('south', 'west', 'east', 'north')
CLIPS = {'idle': (4, 6, True), 'run': (8, 10, True), 'basic': (6, 12, False),
         **{f'cast_{k}': (6, 12, False) for k in 'jkli'}, 'hit': (3, 10, False), 'death': (8, 8, False)}
PALETTES = {'astra': ('#263759','#476796','#e9c977','#91e8ef'),
            'vex': ('#513a38','#987553','#d95749','#efcf8f'),
            'boros': ('#313b48','#617386','#be4e50','#cdd6cf')}

def frame(hero, direction, clip, index, count):
    # Author at logical 64px then nearest-neighbour enlarge. Feet remain fixed.
    im = Image.new('RGBA', (64,64)); d = ImageDraw.Draw(im)
    dark, mid, accent, light = PALETTES[hero]
    outline = '#151d2b'; skin = '#dab28e'; hair = '#453739'
    phase = math.sin(index/count*math.tau)
    bob = -int(phase > .5) if clip in ('idle','run') else 0
    stride = round(phase*3) if clip == 'run' else 0
    broad = 3 if hero == 'boros' else 0
    def rect(box, fill):
        x0,y0,x1,y1=box
        d.rectangle((min(x0,x1),min(y0,y1),max(x0,x1),max(y0,y1)), fill=fill)
    # Independent cardinal shapes; north hides face, side views change silhouette/socket.
    cx = 32; side = -1 if direction == 'west' else 1
    if clip == 'death':
        drop = min(index,5)*3
    else: drop = 0
    y = bob+drop
    rect((25-broad,37+y,38+broad,49+y),outline)
    rect((26-broad,38+y,37+broad,47+y),dark)
    for x, step in ((27,-stride),(34,stride)):
        rect((x,46+y,x+4,52+step),outline)
        rect((x+1,47+y,x+3,50+step),mid)
        rect((x-1,52+step,x+5,53+step),outline)
    rect((23-broad,28+y,40+broad,42+y),outline)
    rect((25-broad,29+y,38+broad,40+y),mid)
    rect((26,30+y,29,39+y),dark)
    rect((30,39+y,38,41+y),accent)
    # Coat/robe tails differ by class; distinct shoulder and head silhouettes.
    if hero == 'astra':
        d.polygon([(25,37+y),(39,37+y),(43,49+y),(21,49+y)],fill=outline)
        d.polygon([(27,38+y),(37,38+y),(40,47+y),(24,47+y)],fill=dark)
        rect((31,38+y,33,47+y),accent)
    elif hero == 'vex':
        rect((22,35+y,26,47+y),dark); rect((38,35+y,42,47+y),dark)
    else:
        rect((21,29+y,27,34+y),light); rect((37,29+y,43,34+y),light)
    rect((27,17+y,37,29+y),outline)
    rect((28,19+y,36,27+y),hair if direction == 'north' else skin)
    rect((27,17+y,37,21+y),hair)
    if direction != 'north':
        eyes = (29,34) if direction == 'south' else ((28,) if side < 0 else (35,))
        for eye in eyes: rect((eye,23+y,eye,24+y),outline)
    if hero == 'vex':
        rect((24,18+y,40,20+y),outline); rect((28,14+y,36,18+y),mid)
    if hero == 'astra': rect((29,16+y,35,18+y),accent)
    rect((26,28+y,38,30+y),accent)
    if direction == 'north': rect((34,30+y,37,38+y),accent)
    # Art-only pose recoil. Weapons are separate PNGs in production profiles.
    reach = round(math.sin(index/max(1,count-1)*math.pi)*4) if clip.startswith(('basic','cast')) else 0
    for hand_side in (-1,1):
        x = cx+hand_side*(10+broad)
        rect((x-2,31+y-reach,x+2,39+y-reach),outline)
        rect((x-1,32+y-reach,x+1,36+y-reach),mid)
        rect((x-1,37+y-reach,x+1,39+y-reach),skin)
    if clip == 'hit':
        # Palette flash does not add opaque background or adjacent-frame material.
        im = im.point(lambda v: v) if index != 1 else im
    return im.resize((128,128),Image.Resampling.NEAREST)

def generate():
    sheets=[]
    for hero in PALETTES:
        base=ROOT/'assets/characters'/hero; manifest={'character_id':hero,'canvas':[128,128],
            'feet_anchor':[64,108],'directions':list(DIRS),'animations':{},
            'visual_profile':{'prototype':True,'generator':'tools/art_pipeline/generate.py','seed':0,
                'body_height':74,'weapon':'weapon.png','weapon_count':2 if hero=='vex' else 1,'socket':[84,76],'vfx_color':PALETTES[hero][2] if hero=='boros' else PALETTES[hero][3]}}
        sheet=Image.new('RGB',(128*8,128*len(DIRS)), '#202735')
        for clip,(count,fps,loop) in CLIPS.items():
            animation={'fps':fps,'loop':loop,'directions':{}}
            for row,direction in enumerate(DIRS):
                paths=[]
                for index in range(count):
                    relative=f'frames/{clip}/{direction}/{index:03}.png'; path=base/relative
                    path.parent.mkdir(parents=True,exist_ok=True)
                    image=frame(hero,direction,clip,index,count); image.save(path)
                    paths.append(relative)
                    if clip=='run': sheet.paste(image,(index*128,row*128),image)
                animation['directions'][direction]=paths
            manifest['animations'][clip]=animation
        weapon=Image.new('RGBA',(32,64)); draw=ImageDraw.Draw(weapon)
        if hero=='astra':
            draw.rectangle((14,12,17,59),fill='#bba06a'); draw.polygon([(16,1),(23,9),(16,17),(9,9)],fill='#91e8ef')
        elif hero=='vex':
            draw.rectangle((5,24,26,30),fill='#cdd6cf'); draw.rectangle((6,30,12,42),fill='#513a38')
        else:
            draw.polygon([(15,1),(23,11),(19,45),(12,45),(8,11)],fill='#cdd6cf'); draw.rectangle((5,44,25,47),fill='#987553'); draw.rectangle((13,48,17,60),fill='#513a38')
        weapon.save(base/'weapon.png')
        (base/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
        out=ROOT/'screenshots/art'; out.mkdir(parents=True,exist_ok=True); sheet.save(out/f'{hero}_run_contact.png'); sheets.append(sheet)
    dashboard=Image.new('RGB',(1024,1536))
    for row,sheet in enumerate(sheets): dashboard.paste(sheet,(0,row*512))
    dashboard.save(ROOT/'screenshots/art/asset_qc.png')
    print(f'GENERATED 3 heroes; {sum(v[0] for v in CLIPS.values())*12} separate body frames; 3 weapons; 4 contact sheets')

if __name__=='__main__': generate()
