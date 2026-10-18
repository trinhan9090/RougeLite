"""Original integer pixel-layer artwork. No concept pixels are read or sampled.
Rebuild: python tools/art_v3/generate.py. Pillow MIT-CMU; own art project license.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import math,json,hashlib
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets/art_v3'; OUT.mkdir(parents=True,exist_ok=True)
P={'ink':'#101522','hair':'#191f36','hairlight':'#354268','skin':'#dfae91','skinlight':'#f7d7b0','skinshadow':'#ab746b','navy':'#222c4c','blue':'#344d83','lightblue':'#5977b3','white':'#dce3e8','shade':'#9caec4','gold':'#d6ab62','goldlight':'#f2d89b','boot':'#222332','bootlight':'#494451','cyan':'#a1d9ff','staff':'#79604e','darkgold':'#926c43'}
STATES={'idle':(6,5,True),'run':(8,10,True),'basic':(6,14,False),'cast_j':(6,14,False),'cast_k':(6,12,False),'cast_l':(8,12,False),'cast_i':(8,14,False),'hit':(4,12,False),'death':(8,10,False)}
DIRS={'south':(0,1),'north':(0,-1),'east':(1,0),'west':(-1,0)}
def hero(direction,state,f):
    body=Image.new('RGBA',(96,96)); weapon=Image.new('RGBA',(96,96))
    d=ImageDraw.Draw(body); w=ImageDraw.Draw(weapon)
    n=STATES[state][0]; t=f/(n-1); side=DIRS[direction][0]; back=direction=='north'
    run=state=='run'; bob=([0,-1,-2,-1,0,-1,-2,-1][f] if run else (1 if state=='idle' and f in (2,3) else 0))
    stride=([0,2,3,2,0,-2,-3,-2][f] if run else 0)
    lean=round(math.sin(t*math.pi)*3) if state not in ('idle','run') else 0
    cx=48+side*lean; y=36+bob
    def poly(points,c): d.polygon([(round(cx+x),round(y+yy)) for x,yy in points],fill=P[c])
    def rect(box,c): d.rectangle((cx+box[0],y+box[1],cx+box[2],y+box[3]),fill=P[c])
    # Split coat tails, individually stepped legs and boots; fixed floor at y=76.
    tail=2 if run and f in (1,2,5,6) else 0
    poly([(-9,16),(-11-tail,35),(-5,37),(-1,22),(2,34),(9+tail,36),(8,16)],'ink')
    poly([(-8,17),(-9-tail,32),(-5,34),(-2,22),(-1,17)],'blue')
    poly([(2,17),(7,17),(8+tail,33),(4,31)],'white')
    poly([(-8,19),(-6,21),(-8-tail,31)],'gold')
    for sign in (-1,1):
        x=sign*(3 if side else 4); foot=76-(max(0,stride*sign) if run else 0)
        if back:
            foot=76-(max(0,-stride*sign) if run else 0)
            d.rectangle((cx+x-2,y+24,cx+x+2,foot),fill=P['ink'])
            d.rectangle((cx+x-1,y+25,cx+x+1,foot-4),fill=P['navy'])
            d.rectangle((cx+x-2,foot-4,cx+x+2,foot-2),fill=P['bootlight'])
            d.line((cx+x-2,foot,cx+x+2,foot),fill=P['boot'])
            continue
        d.polygon([(cx+x-2,y+24),(cx+x+2,y+24),(cx+x+2,foot-3),(cx+x+4+(side*2),foot-1),(cx+x+3,foot),(cx+x-3,foot),(cx+x-3,foot-4)],fill=P['ink'])
        d.rectangle((cx+x-1,y+25,cx+x+1,foot-5),fill=P['navy'])
        d.line((cx+x-2,foot-2,cx+x+2,foot-2),fill=P['bootlight'])
        d.point((cx+x+2,foot-3),fill=P['gold'])
    if back:
        poly([(-8,19),(-10-tail,34),(-5,35),(-1,26),(2,35),(8+tail,34),(7,19)],'navy')
        poly([(-7,20),(-8-tail,32),(-5,32),(-2,22)],'blue')
        poly([(3,21),(6,20),(7+tail,32),(4,31)],'blue')
        d.line((cx-9-tail,y+34,cx-5,y+35),fill=P['gold'])
    poly([(-8,8),(-10,14),(-7,24),(7,24),(9,13),(7,7)],'ink')
    poly([(-6,9),(-7,17),(-5,23),(5,23),(7,12),(5,8)],'navy')
    poly([(-7,10),(-3,11),(-2,20),(-5,22),(-8,16)],'white')
    poly([(4,9),(7,10),(7,19),(4,20),(2,12)],'shade')
    poly([(-7,8),(-3,7),(-1,12),(-4,11)],'gold')
    poly([(3,7),(7,8),(5,12),(1,11)],'goldlight')
    rect((-5,22,5,23),'gold'); rect((-1,21,1,24),'goldlight')
    if back:
        poly([(-5,9),(-4,20),(4,20),(5,9)],'blue')
        d.line((cx,y+10,cx,y+18),fill=P['gold']); rect((-2,13,2,15),'goldlight')
    # Arms use per-action key poses, cast wrist and staff remain asymmetric.
    reach=round(math.sin(t*math.pi)*8) if state.startswith('cast') or state=='basic' else 0
    if state=='cast_k': reach=-round(math.sin(t*math.pi)*5)
    handx=(-10 if side>=0 else 10) + (-reach if side>=0 else reach)
    handy=18-reach//2
    if state=='cast_l': handy=25+round(math.sin(t*math.pi)*4)
    if state=='cast_i': handy=9-round(math.sin(t*math.pi)*6)
    if state in ('basic','cast_j','cast_i'):
        # The launch key pose places the casting palm at the runtime muzzle.
        handx=-reach if side>=0 else reach
        handy=28-reach//2
    poly([(-8,10),(-11,12),(handx-2,handy),(handx+2,handy+2),(-5,14)],'ink')
    poly([(-8,11),(-9,13),(handx,handy-1),(handx+1,handy),(-6,13)],'white')
    rect((handx-1,handy,handx+2,handy+2),'skinlight')
    poly([(7,10),(10,12),(12,20),(8,21),(5,13)],'ink')
    poly([(7,11),(9,13),(10,18),(8,18)],'blue')
    rect((9,19,12,21),'skin')
    # Head: dark swept hair, narrow visible face, facing-specific nose and eyes.
    hx=cx+side; hy=y+2
    d.rectangle((hx-5,hy-2,hx+5,hy+5),fill=P['ink'])
    if not back:
        d.rectangle((hx-4,hy-1,hx+4,hy+4),fill=P['skin'])
        d.rectangle((hx-3,hy,hx+3,hy+3),fill=P['skinlight'])
        if side:
            d.rectangle((hx+side*5-(1 if side<0 else 0),hy+1,hx+side*5+(1 if side>0 else 0),hy+2),fill=P['skin'])
    d.polygon([(hx-6,hy),(hx-7,hy-5),(hx-3,hy-8),(hx+2,hy-9),(hx+6,hy-6),(hx+7,hy-2),(hx+5,hy+3),(hx+3,hy-2),(hx,hy-1),(hx+1,hy-4),(hx-3,hy-2),(hx-4,hy+2)],fill=P['hair'])
    d.line([(hx-5,hy-5),(hx-1,hy-7),(hx+3,hy-6)],fill=P['hairlight'])
    d.line([(hx+2,hy-4),(hx+5,hy-3),(hx+5,hy)],fill=P['navy'])
    if back: d.rectangle((hx-4,hy-2,hx+4,hy+3),fill=P['hair'])
    # Gold crescent staff is independently editable, composited with each frame.
    sx=cx+(13 if side>=0 else -13); sy=y+17
    tip=sy-24-(reach//3 if state!='cast_l' else 3)
    w.line((sx,tip+5,sx-2,75),fill=P['ink'],width=3)
    w.line((sx,tip+5,sx-2,74),fill=P['staff'])
    w.line((sx,tip+8,sx-1,sy+13),fill=P['gold'])
    w.arc((sx-5,tip-5,sx+5,tip+5),35,320,fill=P['goldlight'],width=1)
    w.polygon([(sx,tip-5),(sx+1,tip-1),(sx+5,tip),(sx+1,tip+1),(sx,tip+5),(sx-1,tip+1),(sx-4,tip),(sx-1,tip-1)],fill=P['cyan'])
    w.point((sx,tip),fill=P['white'])
    if state=='hit': body=body.transform(body.size,Image.Transform.AFFINE,(1,0,2-f,0,1,0),resample=Image.Resampling.NEAREST)
    if state=='death':
        body=body.rotate(-min(85,f*14),resample=Image.Resampling.NEAREST,center=(48,74))
        weapon=weapon.rotate(min(60,f*10)*(1 if side>=0 else -1),resample=Image.Resampling.NEAREST,center=(48,74))
    return body,weapon

def characters(hero_id='astra',renderer=hero,palette=P):
    folder=OUT/'characters'/hero_id;folder.mkdir(parents=True,exist_ok=True)
    source=ROOT/'art_source/v3'/hero_id;source.mkdir(parents=True,exist_ok=True)
    exts=[]; clips=[]; hashes=[]
    board=Image.new('RGBA',(96*8,96*4),'#171e2c')
    for di,direction in enumerate(DIRS):
        for state,(count,fps,loop) in STATES.items():
            if hero_id=='vex' and state=='cast_k':fps=24
            if hero_id=='boros' and state=='cast_l':fps=24
            frame_refs=[]
            for f in range(count):
                body,weapon=renderer(direction,state,f)
                result=Image.alpha_composite(weapon,body) if hero_id in ('vex','boros') and direction=='north' else Image.alpha_composite(body,weapon)
                name=f'{state}_{direction}_{f:02d}.png';result.save(folder/name)
                # Layer sources allow editing without tracing supplied posters.
                if f==0: body.save(source/f'{state}_{direction}_body.png');weapon.save(source/f'{state}_{direction}_weapon.png')
                ident=str(len(exts)+1);exts.append(f'[ext_resource type="Texture2D" path="res://assets/art_v3/characters/{hero_id}/{name}" id="{ident}"]')
                frame_refs.append('{"duration": 1.0, "texture": ExtResource("'+ident+'")}')
                hashes.append(hashlib.sha256(result.tobytes()).hexdigest())
                if state in ('idle','run','basic','cast_j','cast_k','cast_l','cast_i','death') and f==min(2,count-1):
                    col=['idle','run','basic','cast_j','cast_k','cast_l','cast_i','death'].index(state);board.alpha_composite(result,(col*96,di*96))
            clips.append('{"frames": ['+','.join(frame_refs)+'], "loop": '+str(loop).lower()+', "name": &"'+state+'_'+direction+'", "speed": '+str(fps)+'}')
    metadata=''
    if hero_id in ('vex','boros'):metadata='metadata/motion_action = &"'+('cast_k' if hero_id=='vex' else 'cast_l')+'"\n'
    (folder/'frames.tres').write_text('[gd_resource type="SpriteFrames" format=3]\n'+'\n'.join(exts)+'\n[resource]\nanimations = ['+',\n'.join(clips)+']\nmetadata/cardinal = true\nmetadata/pixel_v3 = true\nmetadata/directions = PackedStringArray("south", "north", "east", "west")\nmetadata/feet_anchor = Vector2(48, 76)\nmetadata/body_center = Vector2(48, 52)\nmetadata/vfx_color = Color(0.63, 0.85, 1, 1)\n'+metadata)
    manifest={'spec_version':'3.0','asset_id':hero_id,'kind':'character','source_method':'pixel_layers','source_license':'ORIGINAL_CREATED_FOR_PROJECT','source_files':['tools/art_v3/generate.py','tools/art_v3/generate_roster.py','art_source/v3/'+hero_id],'frame_canvas_px':[96,96],'feet_anchor_px':[48,76],'directions':['N','S','E','W'],'palette':list(palette.values()),'animations':{k:{'frames':v[0],'fps':24 if ((hero_id=='vex' and k=='cast_k') or (hero_id=='boros' and k=='cast_l')) else v[1],'loop':v[2]} for k,v in STATES.items()},'godot_scene':'res://scenes/characters/character_visual.tscn','build_hash':hashlib.sha256(''.join(hashes).encode()).hexdigest()}
    (folder/'manifest.json').write_text(json.dumps(manifest,indent=2));(source/'palette.json').write_text(json.dumps(palette,indent=2))
    report=ROOT/'reports/visual_qa/v3_three_heroes';report.mkdir(parents=True,exist_ok=True)
    board.convert('RGB').save(report/(hero_id+'_contact.png'));board.resize((1536,768),Image.Resampling.NEAREST).convert('RGB').save(report/(hero_id+'_contact_2x.png'))

def effects():
    folder=OUT/'vfx';folder.mkdir(exist_ok=True)
    for kind in ['bolt','snare','impact','area','shield','beam','status','cast']:
        size={'bolt':(48,24),'snare':(48,32),'impact':(40,40),'area':(160,160),'shield':(80,80),'beam':(64,64),'status':(48,48),'cast':(32,32)}[kind]
        sheet=Image.new('RGBA',(size[0]*6,size[1]))
        for f in range(6):
            im=Image.new('RGBA',size);d=ImageDraw.Draw(im);cx,cy=size[0]//2,size[1]//2
            gold=P['goldlight'];white='#effaff';blue='#536bd9';ice=P['cyan']
            def star(x,y,r,c):d.polygon([(x-r,y),(x-1,y-1),(x,y-r),(x+1,y-1),(x+r,y),(x+1,y+1),(x,y+r),(x-1,y+1)],fill=c)
            if kind in ('bolt','snare'):
                d.polygon([(cx+9,cy),(cx-2,cy-4),(cx-20,cy),(cx-2,cy+4)],fill=blue)
                d.line((cx-17+f%3,cy,cx+5,cy),fill=ice,width=2);star(cx+2,cy,5,white)
                for k in range(3): d.point((cx-7-k*5,cy-4+(f+k)%3*3),fill=gold)
                if kind=='snare':d.ellipse((cx-4,cy-8,cx+8,cy+8),outline=gold)
            elif kind in ('area','shield','status'):
                r=cx-2;d.ellipse((2,2,size[0]-3,size[1]-3),outline=ice,width=2)
                d.ellipse((6,6,size[0]-7,size[1]-7),outline=blue)
                for k in range(8):
                    a=k*math.pi/4;xx=round(cx+math.cos(a)*(r-6));yy=round(cy+math.sin(a)*(r-6));star(xx,yy,3+(f+k)%2,gold)
                if kind=='area':
                    for k in range(6):
                        a=k*math.pi/3; b=(k+2)*math.pi/3
                        d.line((round(cx+math.cos(a)*r*.62),round(cy+math.sin(a)*r*.62),round(cx+math.cos(b)*r*.62),round(cy+math.sin(b)*r*.62)),fill='#43548b')
                    star(cx,cy,10+(f%2),gold)
                else:star(cx,cy,5,ice)
            elif kind=='beam':
                # Broken boundary sparks show full damage width without an opaque slab.
                for x in range(64):
                    edge=12+((x+f*3)//6)%3*3
                    d.line((x,32-edge,x,32+edge),fill=blue)
                    d.line((x,25-(x+f)%3,x,39+(x+f)%3),fill=ice)
                    d.line((x,29,x,35),fill=white)
                    if (x+f*3)%16<5:
                        d.point((x,2),fill='#5977b3');d.point((x,61),fill='#5977b3')
                for k in range(5):
                    x=(k*13+f*5)%64;d.rectangle((x,12+k%2*37,min(63,x+3),13+k%2*37),fill=gold)
            else:
                r=max(2,round(4+f*2)) if kind=='impact' else 5+f%3
                star(cx,cy,r,ice if f>2 else white)
                for k in range(4):
                    a=k*math.pi/2+math.pi/4; x=round(cx+math.cos(a)*(r+3)); y=round(cy+math.sin(a)*(r+3));d.rectangle((x,y,x+1,y+1),fill=gold)
            sheet.alpha_composite(im,(f*size[0],0))
        sheet.save(folder/f'{kind}.png')

def terrain():
    folder=OUT/'world';folder.mkdir(exist_ok=True)
    im=Image.new('RGBA',(64,16),'#272c3b');d=ImageDraw.Draw(im)
    for i in range(4):
        x=i*16;d.rectangle((x,0,x+15,15),fill=['#292f40','#2b3142','#282e3e','#2c3040'][i]);d.line((x,15,x+15,15),fill='#1c2433');d.line((x+15,0,x+15,15),fill='#202737')
        d.line((x+1,1,x+14,1),fill='#323a4b');d.point((x+3+i,9),fill='#373d4c')
        if i==2:d.line([(x+8,2),(x+8,5),(x+6,7),(x+6,10)],fill='#202737')
    im.save(folder/'courtyard.png')
    wall=Image.new('RGBA',(32,32),'#30374a');d=ImageDraw.Draw(wall)
    for yy in range(0,32,8):
        d.line((0,yy,31,yy),fill='#1c2433')
        for xx in range((-8 if yy%16 else 0),32,16):
            d.line((xx,yy,xx,yy+7),fill='#1c2433');d.line((xx+1,yy+1,min(31,xx+14),yy+1),fill='#495269')
    wall.save(folder/'wall.png')
    enemy=Image.new('RGBA',(32*4,40*4))
    for direction in range(4):
        for f in range(4):
            tile=Image.new('RGBA',(32,40));d=ImageDraw.Draw(tile);bob=f%2
            d.ellipse((6,32,27,38),fill='#10152280')
            for sign in [-1,1]:
                x=16+sign*4;foot=35-(2 if (f+sign)%4==0 else 0)
                d.rectangle((x-2,24,x+2,foot),fill='#191928');d.rectangle((x-2,foot-2,x+3,foot),fill='#69606b')
            d.polygon([(8,14+bob),(24,14+bob),(27,29),(21,32),(16,29),(10,32),(5,28)],fill='#201c30')
            d.polygon([(9,16+bob),(22,16+bob),(24,28),(17,25),(10,28)],fill='#62405c')
            d.line((8,17,7,24),fill='#ab6675',width=2);d.line((24,17,25,24),fill='#ab6675',width=2)
            d.polygon([(9,7+bob),(13,4+bob),(22,6+bob),(25,13+bob),(22,20+bob),(11,19+bob),(7,13+bob)],fill='#181b2d')
            d.line((10,9+bob,14,6+bob,20,7+bob),fill='#6e536d',width=2)
            if direction!=3:
                d.rectangle((11,11+bob,21,16+bob),fill='#3e2d46')
                eyes=[12,19] if direction==0 else ([20] if direction==1 else [11])
                for x in eyes:d.rectangle((x,12+bob,x+1,13+bob),fill='#f0bb81')
            enemy.alpha_composite(tile,(f*32,direction*40))
    enemy.save(folder/'shade_enemy.png')
if __name__=='__main__':
    characters();effects();terrain();print('GENERATED original Astra four-direction pixel frames, VFX sheets, 16px courtyard tiles')
