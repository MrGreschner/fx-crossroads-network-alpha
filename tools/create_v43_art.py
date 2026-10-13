"""Original v43 pixel sprite source. Requires Pillow; overwrites these sprite poses only."""
from pathlib import Path
from PIL import Image, ImageDraw
r=Path(__file__).resolve().parents[1]
for id in ['veyra','gravity_husk','singularity_oracle','ashen_revenant','mercy_cantor','brood_reliquary','chrysalis_knight','exalted_wraith','cinderling','last_creditor']:
 for pose in ['idle','walk1','walk2','attack','0','1','hurt']:
  im=Image.new('RGBA',(64,72));g=ImageDraw.Draw(im);dark='#202a37';shift=2 if pose in ['walk2','1'] else 0
  if id=='veyra':
   g.polygon([(15,30),(33,20),(48,31),(56,65),(12,65)],fill='#685080',outline=dark);g.rectangle((21,56,29,70-shift),fill='#343848');g.rectangle((39,56,47,70+shift),fill='#343848');g.ellipse((22,9,43,31),fill='#c6ad91');g.polygon([(18,20),(22,3),(39,2),(48,22),(41,28),(39,11),(25,12),(24,30)],fill='#d2ccd0');g.rectangle((26,21,28,23),fill='#72e4d4');g.rectangle((37,21,39,23),fill='#72e4d4');g.rectangle((2,32,19,48),fill='#397e7b',outline='#e3c188',width=2);g.line((10,33,10,48),fill='#e3c188',width=2);g.line((48,35,59,24),fill='#adb0bd',width=3);g.ellipse((55,17,63,25),fill='#9be7dc')
  elif id=='gravity_husk':
   g.polygon([(12,27),(27,12),(47,24),(57,60),(10,61)],fill='#4e5267',outline=dark);g.rectangle((14,56,25,70-shift),fill='#353d4d');g.rectangle((42,56,54,70+shift),fill='#353d4d');g.ellipse((21,7,44,32),fill='#60647c',outline=dark);g.rectangle((24,20,41,24),fill='#ada4ef');g.ellipse((20,34,45,55),fill='#343341');g.ellipse((26,39,39,51),fill='#c1aae6');g.line((10,30,3,55),fill='#817995',width=8)
  elif id=='singularity_oracle':
   g.polygon([(10,59),(31,16),(53,59),(31,67)],fill='#69507b',outline=dark);g.ellipse((17,9,46,35),fill='#292b42',outline='#8c81ad',width=3);g.ellipse((27,20,36,26),fill='#c1e5f2');g.arc((5,3,56,51),15,155,fill='#ba9fde',width=3);g.ellipse((19,40,46,66),fill='#1e2635',outline='#9581ca',width=2)
  elif id=='ashen_revenant':
   g.line((20,48,15,68-shift),fill='#9aa6a0',width=6);g.line((42,48,48,68+shift),fill='#9aa6a0',width=6);g.polygon([(16,25),(44,25),(47,54),(11,54)],fill='#806859',outline=dark);g.ellipse((21,5,44,28),fill='#d3c9aa',outline=dark);g.rectangle((25,16,29,20),fill='#79d9b5');g.rectangle((36,16,40,20),fill='#79d9b5');g.line((7,30,5,62),fill='#c3c7bd',width=4);g.line((21,34,41,44),fill='#9a8d73',width=3)
  elif id=='mercy_cantor':
   g.polygon([(18,25),(43,25),(56,65),(9,65)],fill='#a48b89',outline=dark);g.ellipse((22,6,43,29),fill='#cbc3b4');g.polygon([(17,18),(33,1),(49,18)],fill='#d6bc8b',outline=dark);g.rectangle((25,17,40,22),fill=dark);g.line((4,22,4,67),fill='#b9a267',width=3);g.ellipse((0,13,10,25),fill='#9fe0ba');g.rectangle((23,34,43,50),fill='#dfc689',outline=dark);g.line((33,35,33,49),fill='#a28f70',width=2)
  elif id=='brood_reliquary':
   g.ellipse((4,40,60,66),fill='#4e453f',outline=dark,width=2);g.polygon([(12,48),(18,15),(45,15),(52,48)],fill='#72506a',outline=dark);g.rectangle((15,14,48,21),fill='#ada183');g.ellipse((18,26,46,51),fill='#262b37');g.ellipse((24,34,34,44),fill='#d7ad83');g.ellipse((37,37,44,45),fill='#deab8b');g.line((9,54,54,60),fill='#938579',width=3)
  elif id=='chrysalis_knight':
   g.rectangle((17,49,27,69-shift),fill='#54516c');g.rectangle((40,49,49,69+shift),fill='#54516c');g.polygon([(16,25),(47,25),(53,56),(10,56)],fill='#77708c',outline=dark);g.ellipse((19,4,46,30),fill='#807797',outline=dark);g.line((24,17,42,17),fill='#cec1df',width=3);g.line((29,32,35,50),fill='#e7c8a1',width=3);g.line((55,16,57,62),fill='#b8b7c7',width=5);g.line((49,43,62,43),fill='#b6a16a',width=3)
  elif id=='exalted_wraith':
   g.polygon([(30,24),(1,8),(4,45),(24,50)],fill='#739b98',outline=dark);g.polygon([(36,24),(63,8),(58,45),(42,50)],fill='#739b98',outline=dark);g.polygon([(26,20),(42,20),(48,65),(30,57),(18,65)],fill='#c3c1b0',outline=dark);g.ellipse((24,8,41,30),fill='#53626d');g.rectangle((27,17,39,21),fill='#f4d68f')
  elif id=='cinderling':
   g.ellipse((14,27,48,61),fill='#9a665a',outline=dark);g.polygon([(18,36),(8,8),(28,30),(39,28),(54,7),(46,40)],fill='#b27d6b',outline=dark);g.rectangle((22,39,26,43),fill='#f8e1ad');g.rectangle((39,39,43,43),fill='#f8e1ad');g.line((18,57,11,68-shift),fill='#c09b7b',width=4);g.line((44,57,51,68+shift),fill='#c09b7b',width=4)
  else:
   g.polygon([(13,29),(49,29),(62,68),(4,68)],fill='#504c68',outline=dark);g.ellipse((19,8,47,36),fill='#bcb59c',outline=dark);g.polygon([(17,11),(18,0),(27,7),(34,0),(39,8),(48,0),(49,15)],fill='#d6ba78',outline=dark);g.rectangle((24,21,43,25),fill='#7bd5c6');g.rectangle((1,36,24,56),fill='#82909c',outline='#d6ba78',width=2);g.line((52,22,57,67),fill='#e6c282',width=4)
  if pose=='attack':g.arc((4,3,61,61),220,330,fill='#b9f0d6',width=3)
  if pose=='hurt':g.line((18,25,45,52),fill='#ffe3bb',width=3)
  im.save(r/f'assets/{id}_{pose}.png')
