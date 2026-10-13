from pathlib import Path
from PIL import Image,ImageDraw
p=Path(__file__).resolve().parents[1]/'assets'
for hero in ['lumen','harbor','mosaic','apiary','bailiff','mosaicling','hive_drone']:
 for pose in ['idle','walk1','walk2','attack']:
  im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im);dy=-1 if pose=='walk1' else 1 if pose=='walk2' else 0
  def box(x,y,w,h,c):d.rectangle((x,y+dy,x+w-1,y+dy+h-1),fill=c)
  def oval(x,y,w,h,c):d.ellipse((x,y+dy,x+w-1,y+dy+h-1),fill=c)
  def poly(points,c):d.polygon([(x,y+dy) for x,y in points],fill=c)
  dark='#253541';cream='#f2e3b8';gold='#d3ab59'
  if hero=='lumen':
   poly([(20,26),(45,26),(52,53),(15,53)],'#416d73');box(25,29,17,18,'#76baa5');box(29,28,8,24,cream)
   box(22,50,8,10,dark);box(39,50,8,10,dark);oval(23,8,22,22,'#a27555');poly([(20,14),(24,5),(43,5),(48,15),(40,13),(36,8),(23,18)],'#4a3d45');box(26,17,3,4,dark);box(38,17,3,4,dark)
   box(14,30,8,14,'#a27555');box(46,30,7,14,'#a27555');box(52,23 if pose=='attack' else 37,9,13,gold);box(54,26 if pose=='attack' else 40,5,7,'#bdf4c8')
  elif hero=='harbor':
   oval(17,9,31,42,'#2d4255');oval(22,17,22,34,cream);box(22,13,5,5,cream);box(39,13,5,5,cream);box(24,15,3,3,dark);box(40,15,3,3,dark);poly([(29,21),(38,21),(34,27)],gold)
   poly([(18,30),(7,42),(17,45),(23,34)],'#2d4255');poly([(46,30),(56,40),(47,45),(42,35)],'#2d4255');box(20,50,11,6,gold);box(37,48 if pose=='walk2' else 50,11,6,gold);box(18,28,31,5,'#73c3c6')
   oval(48,28 if pose=='attack' else 42,12,13,gold);box(49,28 if pose=='attack' else 42,10,3,'#eae4b1')
  elif hero=='mosaic':
   oval(20,10,27,23,'#deb1b2');poly([(23,13),(11,9),(9,14),(20,19),(7,20),(9,25),(22,23)],'#b984b3');poly([(43,13),(55,9),(57,14),(46,19),(59,20),(57,25),(44,23)],'#b984b3');box(25,20,3,4,dark);box(39,20,3,4,dark);box(29,28,9,2,dark)
   poly([(22,32),(44,32),(49,50),(18,50)],'#688a77');box(24,35,7,9,'#a9d8c1');box(34,34,8,12,'#c7b0e0');box(24,49,6,11,cream);box(39,49,6,11,cream);box(14,35,8,10,'#deb1b2');box(45,35,8,10,'#deb1b2');box(49,25 if pose=='attack' else 41,10,10,'#bda2e1')
  elif hero=='apiary':
   poly([(21,28),(44,28),(49,51),(18,51)],'#a7834b');box(27,30,12,20,'#e1c276');box(21,43,25,4,dark);box(24,50,7,10,dark);box(38,50,7,10,dark)
   oval(22,6,25,25,'#e1c276');box(21,14,26,13,dark)
   for x in range(24,45,4):box(x,17,2,7,'#9eaa9b')
   box(15,30,7,15,'#a7834b');box(46,30,7,15,'#a7834b');oval(50,23 if pose=='attack' else 37,12,15,'#e1c276');box(52,27 if pose=='attack' else 41,8,4,dark)
  elif hero=='bailiff':
   oval(12,27,34,28,'#698074');oval(17,29,25,23,'#b49c67');box(27,31,3,19,'#715d47');box(18,40,24,3,'#715d47');box(23,49,7,12,'#92b3a3');box(38,49,7,12,'#92b3a3');oval(27,8,22,25,'#92b3a3');box(30,17,3,4,dark);box(42,17,3,4,dark);box(32,28,11,3,dark)
   box(25,31,23,5,'#997ab7');box(17,33,7,13,'#92b3a3');box(46,32,7,13,'#92b3a3');box(52,23 if pose=='attack' else 36,3,22,cream);oval(49,20 if pose=='attack' else 33,9,9,'#c8a5e5')
  elif hero=='mosaicling':
   poly([(18,22),(32,12),(47,24),(45,43),(33,52),(18,42)],dark);box(20,24,10,15,'#bda2e1');box(32,22,12,20,'#a9d8c1');box(24,29,3,4,dark);box(36,29,3,4,dark);box(26,39,11,3,cream);box(22,45,7,9,cream);box(37,45,7,9,cream)
  else:
   oval(9,20,17,14,'#c4e7e3');oval(37,20,17,14,'#c4e7e3');oval(19,25,29,20,'#e1c276');box(27,26,5,17,dark);box(37,27,4,15,dark);box(22,30,3,4,dark);poly([(48,33),(58,36),(48,39)],gold);box(22,45,5,6,dark);box(39,43 if pose=='walk2' else 45,5,6,dark)
  im.save(p/f'{hero}_{pose}.png')
