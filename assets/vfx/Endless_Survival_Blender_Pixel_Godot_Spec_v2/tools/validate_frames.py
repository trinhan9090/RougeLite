"""Standalone PNG frame validator. Usage: python tools/validate_frames.py path/to/frames --width 192 --height 192
Requires Pillow. Exits nonzero for invalid dimensions/mode, no transparency, or empty frame.
This is a starter QA tool, not an artistic-quality verifier.
"""
from pathlib import Path
import argparse,sys
from PIL import Image
p=argparse.ArgumentParser();p.add_argument('directory');p.add_argument('--width',type=int,required=True);p.add_argument('--height',type=int,required=True)
a=p.parse_args();files=sorted(Path(a.directory).rglob('*.png'));errors=[]
if not files: errors.append('no PNG frames found')
for file in files:
 try:
  with Image.open(file) as im:
   if im.mode!='RGBA':errors.append(f'{file}: mode {im.mode} != RGBA');continue
   if im.size!=(a.width,a.height):errors.append(f'{file}: size {im.size}')
   alpha=im.getchannel('A'); lo,hi=alpha.getextrema()
   if hi==0:errors.append(f'{file}: empty alpha')
   if lo==255:errors.append(f'{file}: no transparent canvas area')
 except Exception as ex:errors.append(f'{file}: {ex}')
print(f'Validated {len(files)} PNG frames; failures: {len(errors)}')
for error in errors: print('FAIL:',error,file=sys.stderr)
sys.exit(1 if errors else 0)
