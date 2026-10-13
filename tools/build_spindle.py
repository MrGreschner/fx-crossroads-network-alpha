from pathlib import Path
from PIL import Image,ImageDraw
R=Path(__file__).resolve().parents[1]
for n,pose in enumerate(['idle','walk1','walk2','attack']):
 im=Image.new('RGBA',(48,48));d=ImageDraw.Draw(im);ink='#253347';b=[0,1,-1,0][n]
 d.ellipse((7,41,41,47),fill='#15243060');d.rectangle((21,2+b,27,14+b),fill='#dfbf76',outline=ink)
 d.polygon([(24,43),(7,24+b),(13,13+b),(35,13+b),(42,24+b)],fill='#599b9d',outline=ink)
 d.ellipse((7,16+b,42,29+b),fill='#87c9be',outline=ink,width=2);d.line((9,28+b,39,28+b),fill='#dfbd79',width=3)
 d.polygon([(15,31),(33,31),(24,44)],fill='#4a728e',outline=ink)
 for x in [18,29]:d.rectangle((x,21+b,x+2,24+b),fill=ink)
 if pose=='attack':d.arc((1,5,46,43),20,300,fill='#ecdb9d',width=2)
 im.save(R/f'assets/spindle_{pose}.png')
 if n<2:im.save(R/f'assets/spindle_{n}.png')
im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im)
d.ellipse((1,8,63,63),fill='#181c2d70');d.polygon([(2,36),(10,13),(25,3),(46,9),(60,26),(59,48),(41,60),(18,57)],fill='#6e7884',outline='#30394a',width=3)
d.polygon([(10,13),(25,3),(46,9),(36,29),(13,34)],fill='#9aa4a7');d.polygon([(36,29),(46,9),(60,26),(59,48),(43,44)],fill='#818c99');d.line((13,34,36,29,43,44,18,57),fill='#4d586b',width=3)
im.save(R/'assets/rock.png')
