from pathlib import Path
from PIL import Image,ImageDraw
import shutil,json
r=Path(__file__).resolve().parents[1];out=r/'assets/cinematic231';out.mkdir(exist_ok=True)
# Sprite articulation: keep the existing cinematic body and transform only its two lower limbs.
# This is a cached cutout rig (not newly painted anatomy) like the game's neutral walk rig.
rigs=[('ram',1,2,[(16,88,44,107),(56,96,91,118)]),('bramble',1,2,[(24,94,59,118),(84,94,106,110)]),('bramble',4,5,[(28,94,48,110),(65,92,100,118)])]
for h,a,b,boxes in rigs:
 src=Image.open(r/f'assets/cinematic231/{h}_base{a}.png').convert('RGBA');body=src.copy();patches=[]
 for box in boxes:
  patches.append(src.crop(box));ImageDraw.Draw(body).rectangle((box[0],box[1],box[2]-1,box[3]-1),fill=(0,0,0,0))
 for n in range(2):
  frame=body.copy()
  # Alternate the front/back depth and stride of the two EXISTING limbs.
  for side,(box,patch) in enumerate(zip(boxes,patches)):
   if n==0:pos=(box[0],box[1]);p=patch
   else:
    front=patch.width*patch.height==max(v.width*v.height for v in patches)
    f=.78 if front else 1.22;p=patch.resize((round(patch.width*f),round(patch.height*f)),Image.Resampling.NEAREST)
    direction=-1 if h=="bramble" and a==1 else 1
    dx=(-5 if front else 6)*direction;dy=-3 if front else 8
    if h=="ram":p=p.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    pos=(round((box[0]+box[2])/2-p.width/2)+dx,box[1]+dy)
   frame.alpha_composite(p,pos)
  frame.save(out/f'{h}_{a+n:02}.png')
  # Browser and native both consume the exact same selected frames.
  for dest in [r/'assets/cinematic223',r/'web/browser/film223']:shutil.copy2(out/f'{h}_{a+n:02}.png',dest/f'{h}_{a+n:02}.png')
(out/'rig.json').write_text(json.dumps(rigs,indent=2))
