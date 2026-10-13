"""Small procedural polish of the original 28x32 rams; retain silhouette/palette."""
from pathlib import Path
from PIL import Image, ImageDraw
assets=Path(__file__).resolve().parents[1]/'assets'
def make(step=0,elder=False,attack=False):
 im=Image.new('RGBA',(28,32));d=ImageDraw.Draw(im)
 d.ellipse((4,28,24,31),fill='#273e3d')
 for x,s in [(6,step),(18,-step)]:
  d.rectangle((x,21+s,x+4,29),fill='#564442');d.line((x,29,x+4,29),fill='#333c3f');d.point((x+1,25),fill='#927565')
 d.rounded_rectangle((5,11,23,24),radius=3,fill='#d6ccb5' if elder else '#dcd8c6')
 d.rounded_rectangle((7,12,21,23),radius=2,fill='#f6e8cf' if elder else '#faf0d9')
 for x,y in [(7,12),(9,20),(20,14)]:d.point((x,y),fill='#fff7e9')
 head=2 if attack else 0
 for left in [True,False]:
  box=(2,5+head,10,17+head) if left else (18,5+head,26,17+head)
  d.rounded_rectangle(box,radius=3,fill='#8d745a')
  inner=(3,6+head,9,15+head) if left else (19,6+head,25,15+head)
  d.rounded_rectangle(inner,radius=2,fill='#ccb485')
  d.line((5 if left else 23,8+head,5 if left else 23,13+head),fill='#ead2a0')
 d.rounded_rectangle((8,4+head,20,18+head),radius=3,fill='#f8eddb')
 d.rectangle((10,3+head,12,6+head),fill='#fff6e5');d.rectangle((15,3+head,17,5+head),fill='#fff6e5')
 for x in [10,17]:
  d.rectangle((x,10+head,x+1,12+head),fill='#423c43');d.point((x,10+head),fill='#6d6861')
 d.rounded_rectangle((12,14+head,17,18+head),radius=1,fill='#e5c3b2');d.rectangle((14,15+head,15,16+head),fill='#9e7871')
 if elder:
  d.polygon([(9,18),(19,18),(18,24),(14,27),(10,23)],fill='#e8eadc');d.line((11,20,14,24,17,20),fill='#fff6e6')
  d.rectangle((20,18,23,23),fill='#815e79');d.line((23,15,23,30),fill='#765b43');d.point((23,15),fill='#c6ae7e')
 else:
  d.rectangle((10,21,19,23),fill='#75aa9b');d.line((10,21,19,21),fill='#a4c5b0')
 return im
for pose,step in [('idle',0),('walk1',1),('walk2',-1),('attack',0)]:make(step,attack=pose=='attack').save(assets/f'ram_{pose}.png')
for n in [0,1]:make(n).save(assets/f'ram_{n}.png')
make(elder=True).save(assets/'elder_ram.png')
