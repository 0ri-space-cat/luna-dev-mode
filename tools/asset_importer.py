#!/usr/bin/env python3
"""Deterministic LUNA sprite-atlas slicer; requires Pillow."""
import json,sys
from pathlib import Path
from PIL import Image
def main(path):
 p=Path(path)
 cfg=json.loads(p.read_text(encoding="utf-8"))
 img=Image.open(p.parent/cfg["source"]).convert("RGBA")
 w,h=cfg["cell_size"]; cols,rows=cfg["grid"]
 if img.size!=(w*cols,h*rows): raise ValueError("Atlas size/grid mismatch")
 out=p.parent/cfg.get("output","export");out.mkdir(parents=True,exist_ok=True)
 index=[]
 for item in cfg["sprites"]:
  x,y=item["cell"]; name=item["name"]
  if not (0<=x<cols and 0<=y<rows) or "/" in name or ".." in name: raise ValueError(name)
  crop=img.crop((x*w,y*h,(x+1)*w,(y+1)*h))
  crop.save(out/(name+".png"))
  index.append({"name":name,"pivot":item.get("pivot",[0.5,1]),"size":list(crop.size)})
 (out/"index.json").write_text(json.dumps(index,ensure_ascii=False,indent=2),encoding="utf-8")
 print("Exported",len(index),"sprites")
if __name__=="__main__": main(sys.argv[1])
