"""Technical PNG registration only: preserve pixels; copy, inspect alpha and register a cel."""
import argparse, hashlib, json, shutil
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / 'assets/2d/characters/luna/explorer_animation/manifest.json'

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('source', type=Path)
    parser.add_argument('view', choices=['front','front_right','side_right','back','back_right'])
    parser.add_argument('clip', choices=['walk','cast','blink','hair'])
    parser.add_argument('frame', type=int)
    args = parser.parse_args()
    image = Image.open(args.source).convert('RGBA')
    assert image.size == (1024,1536), image.size
    # Generated sprites sometimes contain low-alpha smoke in the empty canvas.
    # Character RGB is unchanged; hidden background RGB is also cleared. Raw masters stay untouched.
    image.putalpha(image.getchannel('A').point(lambda a:255 if a>=240 else 0))
    image.paste((0,0,0,0), mask=image.getchannel('A').point(lambda a:255 if a==0 else 0))
    bounds = image.getchannel('A').getbbox()
    assert bounds and bounds[0]>0 and bounds[1]>0 and bounds[2]<1024 and bounds[3]<1536, bounds
    filename = f'{args.view}/{args.clip}_{args.frame:02d}.png'
    raw = ROOT / 'art/generated/luna/explorer_animation' / filename
    runtime = ROOT / 'assets/2d/characters/luna/explorer_animation' / filename
    raw.parent.mkdir(parents=True,exist_ok=True)
    runtime.parent.mkdir(parents=True,exist_ok=True)
    if args.source.resolve() != raw.resolve():shutil.copy2(args.source, raw)
    image.save(runtime)
    data = json.loads(MANIFEST.read_text()) if MANIFEST.exists() else {'version':1,'views':{}}
    clips = data['views'].setdefault(args.view,{})
    frames = clips.setdefault(args.clip,[])
    while len(frames)<=args.frame:frames.append(None)
    frames[args.frame] = {'path':'res://assets/2d/characters/luna/explorer_animation/'+filename,'pivot':[512,bounds[3]],'sha256':hashlib.sha256(runtime.read_bytes()).hexdigest(),'source_sha256':hashlib.sha256(raw.read_bytes()).hexdigest(),'alpha_cutoff':240}
    MANIFEST.parent.mkdir(parents=True,exist_ok=True)
    MANIFEST.write_text(json.dumps(data,indent=2)+'\n')
    print(filename, 'alpha bounds',bounds)

if __name__=='__main__':main()
