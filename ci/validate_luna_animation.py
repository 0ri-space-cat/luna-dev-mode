"""Check generated-source preservation, runtime alpha and manifest integrity."""
import hashlib,json
from pathlib import Path
from PIL import Image, ImageChops
root=Path(__file__).resolve().parents[1]
p=root/'assets/2d/characters/luna/explorer_animation/manifest.json'
data=json.loads(p.read_text()); count=0
for view,clips in data['views'].items():
 for clip,frames in clips.items():
  hashes=set()
  for frame in frames:
   assert frame is not None,(view,clip,'hole')
   runtime=root/frame['path'].removeprefix('res://')
   raw=root/'art/generated/luna/explorer_animation'/view/runtime.name
   assert hashlib.sha256(runtime.read_bytes()).hexdigest()==frame['sha256'],runtime
   assert hashlib.sha256(raw.read_bytes()).hexdigest()==frame['source_sha256'],raw
   assert frame['sha256'] not in hashes,(view,clip,'duplicate')
   hashes.add(frame['sha256'])
   im=Image.open(runtime).convert('RGBA');source=Image.open(raw).convert('RGBA')
   assert im.size==(1024,1536)
   assert sum(im.getchannel('A').histogram()[1:255])==0,(runtime,'alpha halo')
   diff=ImageChops.difference(im.convert('RGB'),source.convert('RGB'))
   assert ImageChops.multiply(diff,im.getchannel('A').convert('RGB')).getbbox() is None,(runtime,'visible RGB changed')
   for band in im.split()[:3]:
    assert ImageChops.multiply(band,im.getchannel('A').point(lambda a:255-a)).getbbox() is None,(runtime,'hidden background RGB')
   # Passing steps can lift the support foot; their stable body registration
   # is deliberately below the painted foot rather than snapped to its edge.
   assert im.getchannel('A').getbbox()[3]+frame.get('registration_offset_y',0)==frame['pivot'][1]
   count+=1
print(f'Luna {count} runtime cels: hashes, visible RGB, dimensions, binary alpha and pivots PASS')

idle_count=0
for runtime in (root/'assets/2d/characters/luna/explorer_v1').glob('*.png'):
 raw=root/'art/generated/luna/explorer_v1'/runtime.name
 im=Image.open(runtime).convert('RGBA');source=Image.open(raw).convert('RGBA')
 assert sum(im.getchannel('A').histogram()[1:255])==0
 diff=ImageChops.difference(im.convert('RGB'),source.convert('RGB'))
 assert ImageChops.multiply(diff,im.getchannel('A').convert('RGB')).getbbox() is None
 for band in im.split()[:3]:
  assert ImageChops.multiply(band,im.getchannel('A').point(lambda a:255-a)).getbbox() is None
 idle_count+=1
assert idle_count==5
print('All five approved idles: visible artwork preserved and background completely clear PASS')
