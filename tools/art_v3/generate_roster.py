"""Original faceless pixel actors and VFX; references guide silhouette, not skills.
Run with Python UTF-8. Shared exporter and runtime controller are reused.
"""
from pathlib import Path
from PIL import Image,ImageDraw
import math,json
import generate as g
R=Path(__file__).resolve().parents[2]
V={'ink':'#15161f','dark':'#262329','pants':'#34313c','boot':'#362728','leather':'#654334','light':'#99704c','gold':'#d5a35e','goldlight':'#f4d39c','red':'#a43e45','redlight':'#d76459','redshade':'#662c3c','skin':'#b98d70','shadow':'#302c35','metal':'#727c8b','metalbright':'#c8d1d8','white':'#f6ead0'}
B={'ink':'#141923','dark':'#252c37','steel':'#4c5969','mid':'#738298','shine':'#b1c0cf','white':'#e6eef3','red':'#913c45','redlight':'#c65b5a','darkred':'#522a36','skin':'#ba8e78','skinshade':'#825f59','hair':'#272832','hairlight':'#454b58','gold':'#b89365','boot':'#292a32'}
def actor(direction,state,f,role):
 p=V if role=='vex' else B
 im=Image.new('RGBA',(96,96));we=Image.new('RGBA',(96,96));d=ImageDraw.Draw(im);w=ImageDraw.Draw(we)
 n=g.STATES[state][0];t=f/(n-1);north=direction=='north';side=-1 if direction=='west' else 1
 run=state=='run' or (role=='boros' and state=='cast_l')
 bob=[0,-1,-2,-1,0,-1,-2,-1][f%8] if run else (1 if state=='idle' and f in (2,3) else 0)
 stride=[0,2,3,2,0,-2,-3,-2][f%8] if run else 0
 cx=48+(round(math.sin(t*math.pi)*2)*side if state not in ('idle','run') else 0); y=39+bob
 def poly(points,c,draw=d):draw.polygon([(cx+x,y+yy) for x,yy in points],fill=p[c])
 def rect(box,c,draw=d):draw.rectangle((cx+box[0],y+box[1],cx+box[2],y+box[3]),fill=p[c])
 # Cloth is layered behind individually stepped boots, with distinct rear heels.
 wide=9 if role=='vex' else 12
 tail=2 if run and f%4 in (1,2) else 0
 poly([(-wide,11),(-wide-tail-3,33),(-5,35),(-1,26),(3,34),(wide+tail,31),(wide,11)],'leather' if role=='vex' else 'darkred')
 for sign in [-1,1]:
  x=sign*(4 if role=='vex' else 5);foot=76-max(0,stride*sign*(-1 if north else 1))
  d.rectangle((cx+x-2,y+24,cx+x+2,foot),fill=p['ink'])
  d.rectangle((cx+x-1,y+25,cx+x+1,foot-4),fill=p['pants' if role=='vex' else 'steel'])
  if north:d.rectangle((cx+x-2,foot-3,cx+x+2,foot-2),fill=p['light' if role=='vex' else 'mid'])
  else:
   d.rectangle((cx+x-3,foot-3,cx+x+3,foot),fill=p['boot'])
   d.line((cx+x-2,foot-2,cx+x+2,foot-2),fill=p['light' if role=='vex' else 'shine'])
 if role=='vex':
  poly([(-8,8),(-10,14),(-7,25),(7,25),(9,13),(7,8)],'ink')
  poly([(-7,10),(-7,22),(6,22),(7,10)],'dark')
  poly([(-8,9),(-10,27),(-6,29),(-3,12)],'leather')
  poly([(6,9),(10,27),(6,29),(3,12)],'leather')
  d.line((cx-7,y+11,cx-8,y+24),fill=p['gold']);d.line((cx+7,y+11,cx+8,y+24),fill=p['light'])
  rect((-6,23,6,24),'gold');rect((-1,22,1,25),'goldlight')
  if not north:
   d.line((cx-4,y+12,cx+4,y+20),fill=p['gold'])
   rect((-1,13,0,14),'goldlight')
  # Long red scarf and coat sweep make role identifiable without a face.
  poly([(-6,7),(6,7),(7,10),(-5,12),(-8,9)],'red')
  poly([(-5,8),(-11-tail,15),(-16-tail,18),(-11,19),(-3,10)],'redshade')
  d.line((cx-4,y+8,cx-13-tail,y+16),fill=p['redlight'])
  # Blank shadow below the hat; hair remains visible around its edge.
  rect((-5,-1,5,6),'leather' if north else 'skin');rect((-6,-3,-4,4),'dark');rect((4,-3,6,3),'dark')
  poly([(-9,-4),(-6,-10),(4,-10),(8,-4),(13,-2),(10,1),(-10,1),(-14,-2)],'ink')
  poly([(-5,-9),(3,-9),(6,-4),(-7,-4)],'leather')
  rect((-8,-4,7,-3),'red');d.line((cx-11,y-1,cx+10,y-1),fill=p['light'])
  rect((2,-4,3,-3),'goldlight')
  fire=state in ('basic','cast_j','cast_l','cast_i')
  recoil=[0,-2,-1,0,1,0,0,0][f%8] if fire else 0
  for arm in [-1,1]:
   hx=arm*(8 if not fire else 4);hy=18+recoil
   poly([(arm*7,11),(arm*10,14),(hx+2,hy+3),(hx-2,hy+3),(arm*5,13)],'ink')
   d.line((cx+arm*7,y+12,cx+hx,y+hy),fill=p['leather'],width=3)
   rect((hx-1,hy,hx+1,hy+2),'skin')
   # Separate source weapon layer; both pistols visible, shot count stays runtime-owned.
   wx=cx+hx;wy=y+hy
   if direction in ('east','west') and fire:
    tip=wx+side*(8+recoil)
    w.line((wx,wy,tip,wy),fill=p['ink'],width=5);w.line((wx,wy-1,tip,wy-1),fill=p['goldlight'],width=2)
    w.rectangle((wx-1,wy,wx+1,wy+4),fill=p['leather'])
   else:
    tipy=wy+(-7 if north and fire else (6 if fire else 4))
    w.line((wx,wy,wx,tipy),fill=p['ink'],width=4);w.line((wx,wy,wx,tipy),fill=p['gold'],width=2)
    w.point((wx-1,tipy),fill=p['white'])
  if state=='cast_k':
   angle=round(t*360)*side
   im=im.rotate(angle,resample=Image.Resampling.NEAREST,center=(48,62));we=we.rotate(angle,resample=Image.Resampling.NEAREST,center=(48,62))
 else:
  # Steel pauldrons, broad cuirass, crimson mantle and short spiky dark hair.
  poly([(-10,8),(-14,14),(-11,24),(10,24),(14,13),(9,8)],'ink')
  poly([(-9,9),(-10,20),(-6,24),(7,23),(10,11)],'steel')
  poly([(-7,10),(-6,19),(-2,21),(2,10)],'mid')
  d.line((cx-8,y+10,cx+7,y+13),fill=p['shine'])
  poly([(-12,8),(-16,12),(-15,17),(-9,18),(-7,10)],'dark')
  poly([(-12,9),(-15,12),(-13,14),(-9,13)],'shine')
  poly([(9,8),(15,11),(16,16),(10,18),(7,11)],'dark')
  poly([(10,9),(14,11),(14,13),(9,13)],'mid')
  rect((-8,23,8,25),'dark');rect((-2,23,1,25),'gold')
  poly([(-2,25),(-3,35),(2,34),(3,25)],'red')
  poly([(-7,7),(5,7),(8,10),(-6,12),(-9,9)],'red')
  if north:
   poly([(-10,11),(-13-tail,30),(-7,34),(-3,30),(2,34),(11+tail,29),(9,11)],'red')
   d.line((cx-8,y+12,cx-10-tail,y+28),fill=p['redlight'])
  else:
   poly([(-6,9),(-13-tail,19),(-18-tail,22),(-13,24),(-3,11)],'darkred')
   d.line((cx-6,y+10,cx-16-tail,y+21),fill=p['red'])
  rect((-5,-1,5,7),'skinshade' if not north else 'hair')
  poly([(-6,1),(-7,-4),(-4,-8),(-2,-6),(1,-10),(3,-7),(6,-8),(7,-3),(5,2),(2,0),(-2,2)],'hair')
  d.line((cx-4,y-4,cx,y-7,cx+3,y-5),fill=p['hairlight'])
  if north:d.line((cx-4,y+3,cx+3,y+3),fill=p['hairlight'],width=2)
  # Actual two-handed blade changes pose across basic/slam/guard/charge/Titan.
  swing=state in ('basic','cast_j')
  hx=side*7;hy=20
  if state=='cast_k':hx=side*2;hy=14
  if state=='cast_i':hx=side*4;hy=12-round(math.sin(t*math.pi)*6)
  for arm in [-1,1]:
   poly([(arm*11,15),(arm*12,20),(hx+arm*2,hy+2),(hx,hy-1),(arm*8,15)],'dark')
   d.line((cx+arm*10,y+16,cx+hx+arm,y+hy),fill=p['mid'],width=3)
   rect((hx+arm-1,hy,hx+arm+1,hy+2),'skin')
  angle=(-.5+math.sin(t*math.pi)*2.1)*side if swing else (2.2*side)
  if state=='cast_j':angle=(-1.4+t*2.8)*side
  if state=='cast_k':angle=0
  if state=='cast_l':angle=side*1.15
  if state=='cast_i':angle=side*(-.3-math.sin(t*math.pi)*.4)
  ux=math.sin(angle);uy=-math.cos(angle);vx=-uy;vy=ux
  base=(cx+hx,y+hy);length=29
  def pt(a,b):return (round(base[0]+ux*a+vx*b),round(base[1]+uy*a+vy*b))
  w.polygon([pt(-5,-2),pt(1,-2),pt(2,-5),pt(length-4,-5),pt(length,0),pt(length-4,5),pt(2,5),pt(1,2),pt(-5,2)],fill=p['ink'])
  w.polygon([pt(3,-3),pt(length-4,-3),pt(length-1,0),pt(length-4,3),pt(3,3)],fill=p['shine'])
  w.polygon([pt(3,0),pt(length-1,0),pt(length-4,3),pt(3,3)],fill=p['mid'])
  w.line([pt(4,-3),pt(length-5,-3)],fill=p['white']);w.line([pt(0,-7),pt(0,7)],fill=p['gold'],width=2)
  w.line([pt(-5,0),pt(0,0)],fill=p['red'],width=2)
 # Rear cloth occludes chest trim, forward hands and the front-facing waist.
 if north:
  if role=='vex':
   poly([(-8,10),(8,10),(11+tail,31),(6,34),(0,30),(-7,34),(-11-tail,31)],'leather')
   d.line((cx,y+13,cx,y+29),fill=p['dark'])
   d.line((cx-7,y+12,cx-9-tail,y+29),fill=p['light'])
   poly([(-6,7),(6,7),(7,10),(-6,11)],'redshade')
   d.line((cx-5,y+8,cx+5,y+8),fill=p['red'])
  else:
   poly([(-10,10),(10,10),(12+tail,30),(7,34),(2,31),(-3,34),(-12-tail,30)],'red')
   d.line((cx-8,y+12,cx-10-tail,y+28),fill=p['redlight'])
   d.line((cx+5,y+13,cx+7,y+29),fill=p['darkred'])
 if state=='hit':im=im.transform(im.size,Image.Transform.AFFINE,(1,0,2-f,0,1,0),resample=Image.Resampling.NEAREST)
 if state=='death':
  im=im.rotate(-min(80,f*12),resample=Image.Resampling.NEAREST,center=(48,67));we=we.rotate(-min(75,f*11),resample=Image.Resampling.NEAREST,center=(48,67))
 return im,we

def effects():
 folder=g.OUT/'vfx';folder.mkdir(parents=True,exist_ok=True)
 for kind in ['bullet','piercing','muzzle','brass_impact','dust','slash','slam','iron','titan','charge','haste']:
  size={'bullet':(40,16),'piercing':(56,20),'muzzle':(32,32),'brass_impact':(40,40),'dust':(64,48),'slash':(128,128),'slam':(128,128),'iron':(80,80),'titan':(80,80),'charge':(64,48),'haste':(32,16)}[kind]
  sheet=Image.new('RGBA',(size[0]*6,size[1]))
  for f in range(6):
   im=Image.new('RGBA',size);d=ImageDraw.Draw(im);cx,cy=size[0]//2,size[1]//2
   gold='#e6ac61';white='#f8ead2';red='#bd515b';steel='#aabfce'
   if kind=='haste':
    for k in [-1,1]:
     x=cx+k*10;yy=cy+(f%3-1)
     d.line([(x-2,yy+2),(x,yy),(x+2,yy+2)],fill=gold,width=1)
     if f%2==0:d.point((x,yy-3),fill=white)
   elif kind in ('bullet','piercing'):
    length=18 if kind=='bullet' else 29
    d.polygon([(cx+5,cy),(cx-2,cy-2),(max(1,cx-length),cy),(cx-2,cy+2)],fill=gold)
    d.line((cx-length//2,cy,cx+4,cy),fill=white,width=2)
    if kind=='piercing':
     d.line((cx-13,cy-4,cx+2,cy-4),fill=steel);d.line((cx-13,cy+4,cx+2,cy+4),fill=gold)
   elif kind in ('muzzle','brass_impact'):
    r=3+f*2
    for k in range(6):
     a=k*math.pi/3+f*.1;start=(round(cx+math.cos(a)*r*.4),round(cy+math.sin(a)*r*.4));end=(round(cx+math.cos(a)*(r+3)),round(cy+math.sin(a)*(r+3)));d.line((start,end),fill=gold,width=2)
    if f<3:d.polygon([(cx-5,cy),(cx-1,cy-1),(cx,cy-6),(cx+1,cy-1),(cx+6,cy),(cx+1,cy+1),(cx,cy+6),(cx-1,cy+1)],fill=white)
   elif kind in ('dust','charge'):
    for k in range(7):
     x=8+k*6-f*2;y=cy+int(math.sin(k*2+f)*6);rr=2+(k+f)%3
     d.rectangle((max(0,x-rr),y-rr,max(1,x+rr),y+rr),fill=['#625a53','#908071','#b6a28a'][k%3])
    if kind=='charge':
     for k in range(3):d.line((8,cy-9+k*8,45-f*2,cy-9+k*8),fill=red,width=2)
   elif kind=='slash':
    r=35+f*5
    d.arc((cx-r,cy-r,cx+r,cy+r),285,75,fill='#713c4e',width=6)
    d.arc((cx-r,cy-r,cx+r,cy+r),290,70,fill=steel,width=3)
    d.arc((cx-r+2,cy-r+2,cx+r-2,cy+r-2),310,65,fill=white,width=2)
    for k in range(4):
     a=-.8+k*.45;xx=round(cx+math.cos(a)*(r-6));yy=round(cy+math.sin(a)*(r-6));d.line((xx-3,yy,xx+2,yy),fill=red,width=2)
   elif kind=='slam':
    r=18+f*9;d.ellipse((cx-r,cy-r,cx+r,cy+r),outline=steel,width=2)
    for k in range(9):
     a=k*math.tau/9;rr=14+f*5
     pts=[(cx,cy),(round(cx+math.cos(a+.12)*rr*.5),round(cy+math.sin(a+.12)*rr*.5)),(round(cx+math.cos(a)*rr),round(cy+math.sin(a)*rr))]
     d.line(pts,fill='#5b303d',width=2)
     xx,yy=pts[-1];d.rectangle((xx-2,yy-2,xx+2,yy+1),fill=red if k%3==0 else '#7a7c85')
    if f<2:d.ellipse((cx-9,cy-9,cx+9,cy+9),outline=white,width=3)
   else:
    r=34
    for k in range(8):
     a=k*45
     d.arc((cx-r,cy-r,cx+r,cy+r),a+3,a+36,fill=steel if kind=='iron' else red,width=3)
     x=round(cx+math.cos(math.radians(a))*r);y=round(cy+math.sin(math.radians(a))*r)
     d.rectangle((x-2,y-2,x+2,y+2),fill=gold if (k+f)%3==0 else red)
    if kind=='iron':
     d.polygon([(cx-9,cy-12),(cx+9,cy-12),(cx+8,cy+3),(cx,cy+13),(cx-8,cy+3)],outline=steel)
     d.line((cx,cy-8,cx,cy+7),fill=red,width=2)
    else:
     for k in range(7):
      x=12+k*8;y=cy+15-(f*5+k*3)%35;d.rectangle((x,y,x+1,y+4),fill=red)
   sheet.alpha_composite(im,(f*size[0],0))
  sheet.save(folder/(kind+'.png'))
def main():
 g.characters()
 g.characters('vex',lambda a,b,c:actor(a,b,c,'vex'),V)
 g.characters('boros',lambda a,b,c:actor(a,b,c,'boros'),B)
 effects()
 print('GENERATED faceless Astra/Vex/Boros:720 separate native frames;11 additional VFX sheets')
if __name__=='__main__':main()
