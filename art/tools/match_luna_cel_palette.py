"""Technical straight-back cel palette correction; never draws, moves, or resamples pixels."""
import argparse
from pathlib import Path
import numpy as np
from PIL import Image

def groups(a):
    rgb=Image.fromarray(a[:,:,:3], 'RGB').convert('HSV')
    h,s,v=np.array(rgb).transpose(2,0,1)
    g=np.zeros(h.shape,dtype=np.uint8)
    g[(h>=160)&(h<212)]=1 # violet fabric
    g[(h>=212)|(h<8)]=2 # pink hair and trim
    g[(h>=8)&(h<45)]=3 # skin and golden motifs
    g[s<30]=4 # neutral highlights
    g[v<85]=0 # retain dark contour color family
    return g

def main():
    p=argparse.ArgumentParser();p.add_argument('source');p.add_argument('reference');p.add_argument('output');args=p.parse_args()
    a=np.array(Image.open(args.source).convert('RGBA'));b=np.array(Image.open(args.reference).convert('RGBA'))
    ga,gb=groups(a),groups(b);result=a.copy()
    # Stable, non-gesturing material samples in the approved straight-back view.
    regions={1:(350,800,640,1000),2:(300,490,600,740),3:(380,1130,640,1300)}
    for group,(x,y,r,bottom) in regions.items():
        sa=a[y:bottom,x:r];ref=b[y:bottom,x:r]
        ma=(ga[y:bottom,x:r]==group)&(sa[:,:,3]>=240)
        mb=(gb[y:bottom,x:r]==group)&(ref[:,:,3]>=240)
        delta=np.median(ref[:,:,:3][mb],axis=0)-np.median(sa[:,:,:3][ma],axis=0)
        mask=(ga==group)&(a[:,:,3]>=240)
        result[:,:,:3][mask]=np.clip(a[:,:,:3][mask].astype(float)+delta,0,255).astype('uint8')
        print('material',group,'RGB offset',delta.tolist())
    assert np.array_equal(result[:,:,3],a[:,:,3])
    assert result.shape==a.shape
    Path(args.output).parent.mkdir(parents=True,exist_ok=True)
    Image.fromarray(result).save(args.output)
if __name__=='__main__':main()
