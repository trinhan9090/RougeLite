"""Build a local review gallery and verify that supplied original assets survived."""
import csv, hashlib, html, json
from pathlib import Path
from PIL import Image
from generate import ROOT

def main():
    original=list(csv.DictReader((ROOT/'docs/art_baseline/inventory.csv').open(encoding='utf-8')))
    changed=[]; checked=0
    for row in original:
        if not row['path'].startswith('assets/'): continue
        checked+=1; path=ROOT/row['path']
        if not path.exists() or hashlib.sha256(path.read_bytes()).hexdigest()!=row['sha256']: changed.append(row['path'])
    result={'original_asset_files_checked':checked,'changed_originals':changed}
    (ROOT/'docs/art_baseline/original_integrity.json').write_text(json.dumps(result,indent=2)+'\n')
    if changed: raise SystemExit('Supplied original asset hashes changed: '+str(changed))
    folder=ROOT/'screenshots/art'
    for hero in ('astra','vex','boros'):
        paths=sorted(folder.glob(f'{hero}_anim_*.png'))
        if len(paths)==8:
            frames=[]
            for path in paths:
                with Image.open(path) as image: frames.append(image.convert('RGB').resize((768,480),Image.Resampling.NEAREST))
            frames[0].save(folder/f'{hero}_run.gif',save_all=True,append_images=frames[1:],duration=100,loop=0)
    cards=[]
    for hero in ('astra','vex','boros'):
        cards.append(f'<h2>{hero.capitalize()} — original procedural prototype</h2><img class="contact" src="{hero}_run_contact.png"><img src="{hero}_run.gif">')
        cards.append('<div class="grid">'+''.join(f'<figure><img src="{hero}_{action}.png"><figcaption>{hero} · {action} · actual executor</figcaption></figure>' for action in ('basic','j','k','l','i'))+'</div>')
    cards.append('<h2>Actual seeded maps</h2><div class="grid">'+''.join(f'<figure><img src="{theme}_{seed}.png"><figcaption>{theme} · seed {seed}</figcaption></figure>' for theme in ('enchanted_forest','ruined_temple','volcanic_arena') for seed in (1,42,999))+'</div>')
    cards.append('<h2>Stress fixtures (production cap remains 110)</h2><div class="grid">'+''.join(f'<figure><img src="stress_{count}.png"><figcaption>{count} enemies + 300 projectiles</figcaption></figure>' for count in (100,200,400))+'</div>')
    page='''<!doctype html><meta charset="utf-8"><title>Endless Survival — Asset QC</title>
<style>body{background:#171d28;color:#e2e8f0;font:16px system-ui;margin:32px;max-width:1500px}h1,h2{color:#f3d38d}img{max-width:100%;image-rendering:pixelated;border:1px solid #3b4658}.contact{max-width:65%}.grid{display:grid;grid-template-columns:repeat(2,1fr);gap:16px}figure{margin:0}figcaption{padding:8px;background:#222c3b}.notice{padding:16px;border-left:4px solid #f3d38d;background:#222c3b}</style>
<h1>Endless Survival · Asset QC</h1><p class="notice">Prototype art · Owner visual approval PENDING. Screenshots are actual Godot renderer captures. Concepts were not cropped into sprites. Geometry, damage and skill counts remain owned by gameplay.</p>'''+''.join(cards)+f'<p>Original asset integrity: {checked} files checked, {len(changed)} changed. Logs and acceptance details: docs/art_baseline and docs/ART_TASKS.md.</p>'
    (folder/'index.html').write_text(page,encoding='utf-8')
    print('ART_REPORT_OK '+json.dumps(result))
if __name__=='__main__': main()
