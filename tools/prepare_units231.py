from pathlib import Path
from PIL import Image,ImageOps
from scipy import ndimage
import numpy as np,json,shutil
r=Path(__file__).resolve().parents[1];out=r/'assets/unit231';out.mkdir(exist_ok=True)
groups={
'ai':('2c20486c-979c-47f5-8ed7-6cf398538b52',['npc_'+x for x in ['sable','bastion','cinder','lumen','thorn','iona','flint','unused_area']]),
'guards':('ae678e6b-364c-4c1d-962e-a73cbe7cc099',['guard_melee','guard_ranged','guard_area']),
 'team0_0':('0914c5dc-0ede-4d56-a180-0b985d1d529a',[f'bg_0_{i}' for i in range(6)]),'team0_1':('4b6cff6b-066e-42e0-b628-ea1c7c0c8ca3',[f'bg_0_{i}' for i in range(6,11)]),
 'team1_0':('e2ceb472-77eb-4a74-aa17-d6ee1db56c28',[f'bg_1_{i}' for i in range(6)]),'team1_1':('9bec1659-768e-4fc3-b52f-439c57008cf4',[f'bg_1_{i}' for i in range(6,11)]),
 'archerfix':('2fa61fa1-d3c7-49c2-a4de-d7566bfea93a',['bg_0_1']), 'tollbreaker':('41fc07af-50e6-4a34-b99a-6c20345d4cf8',['tollbreaker'])}
prior=json.loads((r/'tools/unit231_prior_geometry.json').read_text());manifest={};pieces={}
for group,(guid,names) in groups.items():
 source=out/(group+'_source.png');im=Image.open(source).convert('RGBA');a=np.array(im)[:,:,3]>=210
 def gutter(axis,point,span):
  score=np.convolve(a.sum(axis=axis),np.ones(3),mode='same');lo=max(1,int(point-span));hi=min(len(score)-1,int(point+span));labs,n=ndimage.label(score[lo:hi]<=score[lo:hi].min()+1);sz=np.bincount(labs);sz[0]=0;v=np.where(labs==sz.argmax())[0];return lo+int((v[0]+v[-1])/2)
 yy,xx=np.where(a);left,right=xx.min(),xx.max()+1;top,bottom=yy.min(),yy.max()+1
 xs=[0]+[gutter(0,left+(right-left)*i/4,(right-left)/4*.4) for i in range(1,4)]+[im.width]
 ys=[0]+[gutter(1,top+(bottom-top)*i/len(names),(bottom-top)/len(names)*.4) for i in range(1,len(names))]+[im.height]
 for row,h in enumerate(names):
  if h=='npc_unused_area':continue
  parts=[]
  for n in range(4):
   cell=np.array(im.crop((xs[n],ys[row],xs[n+1],ys[row+1])));cell[:,:,3]=np.where(cell[:,:,3]>=210,255,0);labels,c=ndimage.label(cell[:,:,3]>0,np.ones((3,3)));sz=np.bincount(labels.ravel());sz[0]=0
   for k,size in enumerate(sz):
    if k and size<14:cell[labels==k,3]=0
   p=Image.fromarray(cell);box=p.getbbox();assert box and box[0]>0 and box[2]<p.width,(h,n,'gutter');parts.append(p.crop(box))
  # Same body height, with enough clear space for contained attack equipment.
  ratios=[parts[0].height/p.height if n<3 else 1 for n,p in enumerate(parts)];f=min(60/parts[0].height,min(70/p.width/ratios[n] for n,p in enumerate(parts)),min(68/p.height/ratios[n] for n,p in enumerate(parts)))
  frames=[]
  for n,p in enumerate(parts):
   factor=f*ratios[n];p=p.resize((max(1,round(p.width*factor)),max(1,round(p.height*factor))),Image.Resampling.NEAREST);canvas=Image.new('RGBA',(80,80));canvas.alpha_composite(p,(40-p.width//2,74-p.height));frames.append(canvas)
  # Upper-body registration on the walk pair, without changing the painted artwork.
  ref=np.array(frames[0]);weight=(ref[10:58,19:61,3]>128).astype(float);offsets=[[0,0]]
  for n in [1,2]:
   best=None
   for dy in range(-4,5):
    for dx in range(-4,5):
     moved=Image.new('RGBA',(80,80));moved.alpha_composite(frames[n],(dx,dy));c=np.array(moved)[10:58,19:61];t=ref[10:58,19:61];dist=np.minimum(((c[:,:,:3].astype(float)-t[:,:,:3])**2).mean(2),10000);dist[(c[:,:,3]<128)&(weight>0)]=10000;score=(dist*weight).sum()/max(1,weight.sum())+(abs(dx)+abs(dy))*3
     if best is None or score<best[0]:best=(score,dx,dy,moved)
   frames[n]=best[3];offsets.append(list(best[1:3]))
  if h=='npc_lumen':frames=[ImageOps.mirror(p) for p in frames] # Preserve original staff side consistently.
  visible=frames[0].getbbox()[3]-frames[0].getbbox()[1]
  world=prior[h]['world_height'];factor=prior[h]['ratio']/(visible/80) if h.startswith('npc_') or h=='tollbreaker' else 1
  pieces[h]=frames;manifest[h]={'group':group,'row':row,'columns':xs,'rows':[ys[row],ys[row+1]],'offsets':offsets,'visible_height':visible,'world_height':float(world),'npc_factor':float(factor)}
atlas=Image.new('RGBA',(320,len(pieces)*80))
for row,(h,frames) in enumerate(pieces.items()):
 manifest[h]['index']=row
 for n,p in enumerate(frames):
  b=p.getbbox();assert b[0]>0 and b[2]<80 and b[3]<80,(h,n,'clipped');atlas.alpha_composite(p,(n*80,row*80))
atlas.save(out/'units.png');(out/'manifest231.json').write_text(json.dumps(manifest,indent=2)+'\n');print('Prepared',len(pieces),'designs /',len(pieces)*4,'poses',atlas.size)
