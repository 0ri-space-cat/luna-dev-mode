"""Prepare a candidate for QA before it can enter the gameplay manifest."""
import argparse,json
from pathlib import Path
from PIL import Image,ImageDraw
root=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('view');p.add_argument('clip');p.add_argument('frame',type=int);p.add_argument('--source',type=Path,required=True)
a=p.parse_args()
source=a.source
im=Image.open(source).convert('RGBA');assert im.size==(1024,1536)
im.putalpha(im.getchannel('A').point(lambda v:255 if v>=240 else 0))
im.paste((0,0,0,0),mask=im.getchannel('A').point(lambda v:255 if v==0 else 0))
bounds=im.getchannel('A').getbbox();assert bounds and bounds[0]>0 and bounds[1]>0 and bounds[2]<1024 and bounds[3]<1536,bounds
out=root/'art/prepared/luna'/a.view/f'{a.clip}_{a.frame:02d}.png';out.parent.mkdir(parents=True,exist_ok=True);im.save(out)
plate=Image.new('RGB',(768,600),'white');draw=ImageDraw.Draw(plate)
small=im.resize((384,576),Image.Resampling.NEAREST)
for x,color in [(0,(255,255,255)),(384,(75,205,190))]:
 plate.paste(color,(x,24,x+384,600));plate.paste(small,(x,24),small)
 draw.text((x+4,4),f'{a.view}/{a.clip}_{a.frame:02d} - prepared alpha',fill='black')
plate.save('/private/tmp/luna_candidate_qa.png')
meta={'source':str(source),'candidate':'res://'+str(out.relative_to(root)),'view':a.view,'clip':a.clip,'frame':a.frame,'bounds':bounds}
(root/'art/prepared/luna/pending.json').write_text(json.dumps(meta,indent=2)+'\n')
print(json.dumps(meta))
