from pathlib import Path
from PIL import Image
import numpy as np,shutil,json
from scipy import ndimage
r=Path(__file__).resolve().parents[1];out=r/'assets/cinematic223'
assets={'cat':('',2,2),'ram':('',3,2),'bramble':('',3,2)}
for h,(f,cols,rows) in assets.items():
 im=Image.open(out/f'{h}_source.png').convert('RGBA');parts=[]
 for n in range(cols*rows):
  a=np.array(im.crop((n%cols*im.width//cols,n//cols*im.height//rows,(n%cols+1)*im.width//cols,(n//cols+1)*im.height//rows)))
  a[:,:,3]=np.where(a[:,:,3]>=210,a[:,:,3],0);labels,c=ndimage.label(a[:,:,3]>0,np.ones((3,3)));sizes=np.bincount(labels.ravel());sizes[0]=0;maxs=sizes.max()
  for k,size in enumerate(sizes):
   if k and size<maxs*.02:a[labels==k,3]=0
  pic=Image.fromarray(a);box=pic.getbbox();pic=pic.crop(box);parts.append(pic)
 scale=min(104/parts[0].height,min(116/p.width for p in parts),min(112/p.height for p in parts))
 for n,pic in enumerate(parts):
  k=scale*(parts[0].height/pic.height if n<3 and h!='cat' else 1)
  pic=pic.resize((round(pic.width*k),round(pic.height*k)),Image.Resampling.NEAREST);frame=Image.new('RGBA',(128,128));frame.paste(pic,(round(64-pic.width/2),118-pic.height));frame.save(out/f'{h}_{n:02}.png')
for pose in [0,4]:shutil.copy2(r/f'assets/hero210/elder_ram_{pose:02}.png',out/f'elder{pose}.png')
# Clean translucent colour fringes on supplied foliage; the visible artwork remains unchanged.
leaves=Image.open(out/'leaves_source.png').convert('RGBA')
for side in range(2):
 part=leaves.crop((side*leaves.width//2,0,(side+1)*leaves.width//2,leaves.height));a=np.array(part);a[:,:,3]=np.where(a[:,:,3]>=180,a[:,:,3],0);part=Image.fromarray(a);part.thumbnail((780,440),Image.Resampling.LANCZOS);part.save(out/('leaves_left.png' if side==0 else 'leaves_right.png'))
# Preserve the same transparent layer and sprites for the browser export.
Image.open(out/'scene_source.png').convert('RGB').resize((1280,720),Image.Resampling.LANCZOS).save(out/'scene.png')
folder=r/'web/browser/film223';folder.mkdir(exist_ok=True)
for p in out.glob('*.png'):
 if not p.name.endswith('_source.png'):shutil.copy2(p,folder/p.name)
shutil.copy2(r/'content/intro223.json',folder/'intro223.json')
print('Prepared cinematic-only sprites and browser source assets')
