from pathlib import Path
from PIL import Image,ImageDraw
p=Path(__file__).resolve().parents[1]
# Extend original low-resolution sprite construction, retaining its palette and silhouette.
for key in ['ram','book','cat']:
 base=Image.open(p/f'assets/{key}_walk1.png').convert('RGBA')
 im=base.copy();d=ImageDraw.Draw(im)
 if key=='ram':
  # A lowered head and braced stance rather than a newly illustrated ram.
  head=base.crop((2,3,26,20))
  d.rectangle((2,3,25,19),fill=(0,0,0,0))
  im.alpha_composite(head,(3,5));d=ImageDraw.Draw(im)
  d.rectangle((6,24,10,29),fill='#564442');d.rectangle((19,24,23,29),fill='#564442')
 elif key=='book':
  # One protruding paper edge, with the same square face and cover.
  d.polygon([(19,19),(27,16),(27,19),(20,22)],fill='#faf0d9')
  d.line((20,22,27,19),fill='#e4d9c7')
 else:
  # Raised paw, original grey fur and teal collar.
  d.rectangle((22,19,28,21),fill='#d3c6b7')
  d.rectangle((26,15,28,19),fill='#d3c6b7')
 im.save(p/f'assets/{key}_attack.png')
 # Channel/spin frames use the same pixel size and original character palette too.
 if key=='book':
  opened=Image.new('RGBA',base.size);o=ImageDraw.Draw(opened)
  o.ellipse((3,27,25,31),fill='#293e43')
  o.rectangle((7,25,10,29),fill='#564442');o.rectangle((18,25,21,29),fill='#564442')
  o.polygon([(1,8),(12,10),(14,12),(16,10),(26,8),(26,24),(16,24),(14,26),(12,24),(1,24)],fill='#ac7787')
  o.polygon([(3,10),(12,12),(13,13),(13,23),(3,22)],fill='#f5e5b5')
  o.polygon([(15,13),(17,12),(24,10),(24,22),(15,23)],fill='#f5e5b5')
  o.rectangle((7,17,8,18),fill='#423c43');o.rectangle((20,17,21,18),fill='#423c43')
  opened.save(p/'assets/book_open.png')
 elif key=='cat':
  spin=base.copy();o=ImageDraw.Draw(spin)
  o.arc((0,17,28,30),10,230,fill='#c5b5aa',width=3)
  spin.save(p/'assets/cat_spin.png')
# Reproducible generation is included for student editing.
