from pathlib import Path
from PIL import Image,ImageDraw
import numpy as np,json,shutil
from scipy import ndimage
r=Path(__file__).resolve().parents[1];out=r/'assets/town230';out.mkdir(exist_ok=True)
groups={
'residents0':('dd43342b-a761-47a8-95e9-ce7fd1dcdde5',['Briar','Mira','Alden','Pip','Clover','Flint','Hazel'],[45,47,57,45,47,57,45]),
'residents1':('acaf2b33-6da5-47e5-8d8f-2c3ebd509d0e',['Theo','Nell','Rowe','Fern','Kit','Wren','Bram'],[47,57,45,47,57,45,47]),
'residents2':('f7170773-4572-4aa5-ad88-f6377d66d140',['Lark','Juniper','Tess','Oak','Ada','Finch','Ash'],[57,45,47,57,45,47,45]),
'keepers':('babc499c-ecda-47c3-9ce2-c734770fbc5d',['supply_keeper','Moss','Tessa','Scout_Alden','Rowan','carpenter','guide'],[49,61,67,52,49,52,49]),
'specialists0':('df3f2d52-d506-4872-b771-590808901445',['guard_melee','guard_ranged','Brin','Lio'],[48,52,48,48]),
'specialists1':('96c2fde1-5820-47de-bde0-056535c79ed7',['ox_farmer','fishing_keeper','postal_worker','exchange_worker'],[90,75,48,52])}
atlas=Image.new('RGBA',(240,36*80));manifest={};index=0
for group,(guid,names,world_heights) in groups.items():
 source=out/(group+'_source.png');im=Image.open(source).convert('RGBA');a=np.array(im)[:,:,3]>=210
 def gutter(axis,point,span):
  scores=np.convolve(a.sum(axis=axis),np.ones(3),mode='same');lo=max(1,int(point-span));hi=min(len(scores)-1,int(point+span));good=scores[lo:hi]<=scores[lo:hi].min()+1;labels,n=ndimage.label(good);sizes=np.bincount(labels);sizes[0]=0;k=sizes.argmax();positions=np.where(labels==k)[0];return lo+int((positions[0]+positions[-1])/2)
 xs=[0]+[gutter(0,im.width*i/3,im.width/3*.42) for i in [1,2]]+[im.width]
 ys=[0]+[gutter(1,im.height*i/len(names),im.height/len(names)*.4) for i in range(1,len(names))]+[im.height]
 for row,(name,world_height) in enumerate(zip(names,world_heights)):
  images=[];boxes=[]
  for n in range(3):
   data=np.array(im.crop((xs[n],ys[row],xs[n+1],ys[row+1])));data[:,:,3]=np.where(data[:,:,3]>=210,255,0)
   labels,count=ndimage.label(data[:,:,3]>0,np.ones((3,3)));sizes=np.bincount(labels.ravel());sizes[0]=0
   for label,size in enumerate(sizes):
    if label and size<18:data[labels==label,3]=0
   sprite=Image.fromarray(data);box=sprite.getbbox();assert box and box[0]>0 and box[2]<sprite.width,(name,n,'cut horizontal gutter');images.append(sprite.crop(box));boxes.append(box)
  factor=min(60/images[0].height,70/max(p.width*images[0].height/p.height for p in images))
  frames=[]
  for n,p in enumerate(images):
   f=factor*images[0].height/p.height;p=p.resize((round(p.width*f),round(p.height*f)),Image.Resampling.NEAREST);frame=Image.new('RGBA',(80,80));frame.alpha_composite(p,(40-p.width//2,74-p.height));frames.append(frame)
  # Register the upper body so pose changes do not cause a whole-body hop.
  offsets=[[0,0]];ref=np.array(frames[0]);weight=(ref[15:57,20:60,3]>128).astype(float)
  for n in [1,2]:
   src=np.array(frames[n]);best=None
   for dy in range(-4,5):
    for dx in range(-4,5):
     moved=Image.new('RGBA',(80,80));moved.alpha_composite(frames[n],(dx,dy));c=np.array(moved)[15:57,20:60];target=ref[15:57,20:60];dist=np.minimum(((c[:,:,:3].astype(float)-target[:,:,:3])**2).mean(2),10000);dist[(c[:,:,3]<128)&(weight>0)]=10000;score=(dist*weight).sum()/max(1,weight.sum())+(abs(dx)+abs(dy))*4
     if best is None or score<best[0]:best=(score,dx,dy,moved)
   offsets.append(list(best[1:3]));frames[n]=best[3]
  for n,frame in enumerate(frames):
   assert frame.getbbox()[0]>0 and frame.getbbox()[2]<80 and frame.getbbox()[3]<80,(name,n,'clipped')
   atlas.alpha_composite(frame,(n*80,index*80))
  visible=frames[0].getbbox()[3]-frames[0].getbbox()[1]
  manifest[name]={'index':index,'group':group,'row':row,'columns':xs,'rows':[ys[row],ys[row+1]],'source_boxes':boxes,'offsets':offsets,'world_height':world_height,'scale':world_height/visible};index+=1
atlas.save(out/'citizens.png');(out/'manifest230.json').write_text(json.dumps(manifest,indent=2)+'\n')
preview=Image.new('RGB',(1440,6*230+80),'#293e46');d=ImageDraw.Draw(preview);d.text((25,20),'V230 - TOWN CAST / idle, walk A, walk B',fill='#f0dfbb')
for i,(name,entry) in enumerate(manifest.items()):
 x=(i%6)*240;y=70+(i//6)*230
 for n in range(3):
  frame=atlas.crop((n*80,i*80,(n+1)*80,(i+1)*80));preview.paste(frame,(x+n*80,y),frame)
 d.text((x+6,y+100),name,fill='#c1d3d2')
preview.save('/tmp/cr230/normalized.png');print('Prepared',index,'town characters /',index*3,'frames / atlas',atlas.size)
