from PIL import Image,ImageDraw
from pathlib import Path
p=Path(__file__).resolve().parents[1]/'assets'
for hero in ['morrow','mantis']:
 for pose in ['idle','walk1','walk2','attack']:
  im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im);dy=-1 if pose=='walk1' else 1 if pose=='walk2' else 0
  def rect(x,y,w,h,c):d.rectangle((x,y+dy,x+w-1,y+dy+h-1),fill=c)
  def poly(points,c):d.polygon([(x,y+dy) for x,y in points],fill=c)
  def oval(x,y,w,h,c):d.ellipse((x,y+dy,x+w-1,y+dy+h-1),fill=c)
  dark='#203b3f';ivory='#e4e5bb';gold='#dcb976'
  if hero=='morrow':
   poly([(21,26),(42,26),(49,56),(16,56)],dark);poly([(25,29),(38,29),(43,53),(21,53)],'#71847e')
   rect(27,30,6,24,'#b493af');rect(22,54,8,6,dark);rect(36,53 if pose=='walk2' else 55,8,5,dark)
   poly([(19,26),(20,13),(30,4),(42,10),(47,27)],dark);poly([(25,13),(37,12),(42,24),(24,25)],'#405659');rect(27,18,4,4,'#b8edd6');rect(36,18,4,4,'#b8edd6')
   rect(14,30,8,16,'#71847e');rect(43,29,8,12,'#71847e');rect(50,15 if pose=='attack' else 23,4,34,gold)
   poly([(50,22),(48,16),(51,10),(59,10),(61,15),(59,19),(55,19),(56,15),(53,15),(53,22)],ivory)
   if pose=='attack':oval(4,25,10,10,'#a9dcca');rect(7,28,4,4,ivory)
   rect(25,38,16,4,'#a77d98');rect(30,38,4,4,gold)
  else:
   poly([(24,30),(40,30),(45,45),(32,53),(21,44)],dark);poly([(27,31),(37,31),(40,43),(32,48),(25,42)],'#70a777')
   for y in [36,41,46]:rect(27,y,11,2,'#b9d897')
   poly([(21,11),(44,11),(48,22),(33,32),(17,22)],dark);poly([(23,14),(41,14),(44,22),(33,28),(21,22)],'#89b889')
   oval(17,14,10,10,gold);oval(38,14,10,10,gold);rect(20,17,4,4,dark);rect(41,17,4,4,dark)
   poly([(25,13),(19,4),(16,4),(22,14)],'#adcbb3');poly([(37,13),(42,4),(46,3),(40,14)],'#adcbb3')
   poly([(24,43),(14,48),(12,57),(19,57),(19,50),(29,48)],'#477c64');poly([(38,43),(49,48),(52,57),(45,57),(44,51),(35,48)],'#477c64')
   if pose=='attack':
    poly([(22,30),(10,27),(5,12),(11,16),(17,24),(27,30)],ivory);poly([(42,30),(51,27),(59,11),(60,24),(52,35),(42,36)],ivory)
   else:
    poly([(22,30),(11,37),(9,26),(6,30),(8,46),(23,36)],ivory);poly([(42,30),(54,37),(56,26),(59,30),(56,46),(41,36)],ivory)
   if pose=='walk1':rect(8,56,11,3,gold)
   if pose=='walk2':rect(46,57,11,3,gold)
  im.save(p/f'{hero}_{pose}.png')
