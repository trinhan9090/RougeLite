from pathlib import Path
from PIL import Image,ImageChops,ImageDraw
R=Path(__file__).resolve().parents[2];O=R/'reports/visual_qa/v3_fix01'
board=Image.new('RGB',(384,192),'#171e2c');d=ImageDraw.Draw(board)
for f in range(8):
 n=Image.open(R/f'assets/art_v3/characters/astra/run_north_{f:02d}.png').convert('RGBA')
 s=Image.open(R/f'assets/art_v3/characters/astra/run_south_{f:02d}.png').convert('RGBA')
 a=n.crop((36,59,60,77));b=s.crop((36,59,60,77))
 assert ImageChops.difference(a,b).convert('RGB').getbbox(),f'lower body still identical at frame{f}'
 for row,im in enumerate([n,s]):
  board.paste(im.crop((32,24,64,80)).resize((32,56),Image.Resampling.NEAREST),(f*48,row*96+20),im.crop((32,24,64,80)).getchannel('A'))
d.text((0,0),'NORTH / rear heels',fill='white');d.text((0,96),'SOUTH / forward toes',fill='white')
O.mkdir(parents=True,exist_ok=True);board.resize((768,384),Image.Resampling.NEAREST).save(O/'north_south_frames.png')
print('RESULT north/south lower-body checks=8 failures=0')
