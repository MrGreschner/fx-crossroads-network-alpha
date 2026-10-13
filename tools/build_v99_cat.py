"""Polish the original cat in its existing compact palette and sprite footprint."""
from PIL import Image,ImageDraw
from pathlib import Path
p=Path(__file__).resolve().parents[1]/'assets'
for pose in ['idle','walk1','walk2','attack','spin']:
 im=Image.new('RGBA',(28,32));d=ImageDraw.Draw(im);step=1 if pose=='walk1' else -1 if pose=='walk2' else 0
 dark='#364342';fur='#aab5ad';light='#d4ddd0';pink='#dcaeac';head=1 if pose=='attack' else 0
 # Tail belongs to the torso; ears attach above the head, never to the shoulders.
 d.line([(21,24),(25,22),(26,17),(24,14)],fill='#76887f',width=3);d.point((24,14),fill=light)
 for x,shift in [(7,step),(17,-step)]:
  d.rectangle((x,23+shift,x+4,29),fill='#6d7b71');d.line((x,29,x+4,29),fill=dark,width=2)
 d.rounded_rectangle((6,17,23,25),radius=3,fill='#788c81');d.rounded_rectangle((9,17,20,24),radius=2,fill=fur);d.rectangle((10,21,18,24),fill=light)
 d.polygon([(5,9+head),(6,1+head),(13,8+head)],fill='#7f9387');d.polygon([(17,8+head),(23,1+head),(24,10+head)],fill='#7f9387')
 d.polygon([(7,7+head),(7,3+head),(11,8+head)],fill=pink);d.polygon([(19,8+head),(22,3+head),(22,8+head)],fill=pink)
 d.rounded_rectangle((5,7+head,24,19+head),radius=4,fill=fur);d.rounded_rectangle((8,10+head,21,18+head),radius=3,fill=light)
 for x in [10,18]:d.rectangle((x,10+head,x+1,12+head),fill=dark);d.point((x,10+head),fill='#526b61')
 d.polygon([(13,13+head),(16,13+head),(14,15+head)],fill='#b88e8c');d.line((14,15+head,14,16+head),fill=dark)
 for side in [-1,1]:
  d.line((14+side*4,14+head,14+side*10,13+head),fill='#7c8c80');d.line((14+side*5,16+head,14+side*9,17+head),fill='#7c8c80')
 d.rectangle((8,18+head,22,20+head),fill='#688f86');d.rectangle((18,20,21,23),fill='#8cb5a4')
 d.rounded_rectangle((3,20,8,25),radius=2,fill=fur)
 arm=(22,17,27,23) if pose in ['attack','spin'] else (22,20,26,25);d.rounded_rectangle(arm,radius=2,fill=fur)
 if pose=='attack':
  for y in [17,19,21]:d.line((25,y,27,y-1),fill=light)
 im.save(p/f'cat_{pose}.png')
 if pose=='idle':im.save(p/'cat_0.png')
 if pose=='walk1':im.save(p/'cat_1.png')
