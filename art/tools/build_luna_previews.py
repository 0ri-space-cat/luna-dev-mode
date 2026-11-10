"""Assemble actual Godot screenshots into QA GIFs/strips; never edits game artwork."""
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[2]
for directory in (root/'docs/screenshots/animation_frames').glob('*'):
    paths=sorted(directory.glob('*.png'))
    if len(paths)!=32:continue
    images=[]
    for p in paths:
        im=Image.open(p).convert('RGB')
        images.append(im if im.size==(480,400) else im.crop((400,80,880,480)))
    output=root/'docs/screenshots'/('luna_'+directory.name)
    images[0].save(str(output)+'.gif',save_all=True,append_images=images[1:],duration=[70 if i%4==3 else 60 for i in range(len(images))],loop=0)
    strip=Image.new('RGB',(1920,400))
    # Include the brief close anticipation now used by the three-cel casts.
    indices=[0,1,2,4] if directory.name.endswith('_cast') else [0,2,4,6]
    for column,index in enumerate(indices):strip.paste(images[index],(480*column,0))
    strip.save(str(output)+'_strip.png')

performance=sorted((root/'docs/screenshots/luna_performance_frames').glob('*.png'))
if len(performance)==192:
    images=[Image.open(p).convert('RGB') for p in performance]
    images[0].save(root/'docs/screenshots/luna_animation_demo.gif',save_all=True,append_images=images[1:],duration=[70 if i%4==3 else 60 for i in range(len(images))],loop=0)
    strip=Image.new('RGB',(1920,800))
    for n,i in enumerate([0,20,40,60,100,116,132,164]):strip.paste(images[i],((n%4)*480,(n//4)*400))
    strip.save(root/'docs/screenshots/luna_animation_demo_strip.png')
