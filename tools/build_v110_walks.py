from pathlib import Path
from PIL import Image,ImageDraw
p=Path(__file__).resolve().parents[1]/'assets'
for id in ['ram','cat']:
 base=Image.open(p/f'{id}_idle.png').convert('RGBA')
 for n in [1,2]:
  im=Image.new('RGBA',base.size);upper=base.crop((0,0,28,26));im.paste(upper,(0,-1 if n==1 else 0));d=ImageDraw.Draw(im)
  # Alternate feet and arms rather than copying the idle frame.
  left=base.crop((5,26,12,31));right=base.crop((17,26,24,31))
  im.paste(left,(4 if n==1 else 5,25 if n==1 else 27));im.paste(right,(17 if n==1 else 18,27 if n==1 else 25))
  if id=='ram':
   d.rectangle((5,22 if n==1 else 23,8,25 if n==1 else 26),fill='#ece6cf');d.rectangle((20,23 if n==1 else 22,22,26 if n==1 else 25),fill='#ece6cf')
  else:
   d.rectangle((3,21 if n==1 else 23,6,24 if n==1 else 26),fill='#9ca99d');d.rectangle((21,23 if n==1 else 21,24,26 if n==1 else 24),fill='#9ca99d');d.line([(23,26),(26,24 if n==1 else 28),(27,21 if n==1 else 25)],fill='#829688',width=2)
  im.save(p/f'{id}_walk{n}.png');im.save(p/f'{id}_{n}.png')
