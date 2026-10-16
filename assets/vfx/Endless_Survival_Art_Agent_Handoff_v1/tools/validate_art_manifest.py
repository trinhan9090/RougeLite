#!/usr/bin/env python3
"""Standalone free PNG/manifest validator. Run python validate_art_manifest.py path/to/manifest.json. Requires Pillow."""
import sys, json, re
from pathlib import Path
from PIL import Image

def validate(path):
    p=Path(path); data=json.loads(p.read_text(encoding='utf8')); errors=[]
    w,h=data['canvas']; required={'south','west','east','north'}
    if set(data['directions']) != required:errors.append('directions must be 4 cardinals')
    for clip,cfg in data['animations'].items():
        if cfg['fps']<=0: errors.append(f'{clip}: fps <= 0')
        if not required.issubset(cfg['directions']):errors.append(f'{clip}: missing directions')
        for direction,frames in cfg['directions'].items():
            for i,relative in enumerate(frames):
                f=p.parent/relative
                if not f.is_file():errors.append(f'{clip}/{direction}: missing {relative}');continue
                with Image.open(f) as im:
                    if im.size!=(w,h):errors.append(f'{relative}: wrong canvas {im.size}')
                    if im.mode!='RGBA':errors.append(f'{relative}: requires RGBA ({im.mode})')
                    if im.getchannel('A').getbbox() is None:errors.append(f'{relative}: alpha empty')
                if not re.search(rf'/{i:03}\.png$',relative.replace('\\','/')):errors.append(f'{relative}: order mismatch {i:03}')
    return errors
if __name__=='__main__':
    if len(sys.argv)!=2:raise SystemExit('Usage: python validate_art_manifest.py manifest.json')
    issues=validate(sys.argv[1]);print('PASS' if not issues else '\n'.join(issues));sys.exit(bool(issues))
