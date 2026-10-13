from pathlib import Path
from PIL import Image,ImageDraw
p=Path(__file__).resolve().parents[1]/'assets'
for hero in ['briar','recess','votary','teacher']:
 for pose in ['idle','walk1','walk2','attack']:
  im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im);dy=-1 if pose=='walk1' else 1 if pose=='walk2' else 0
  def box(x,y,w,h,c):d.rectangle((x,y+dy,x+w-1,y+dy+h-1),fill=c)
  def poly(points,c):d.polygon([(x,y+dy) for x,y in points],fill=c)
  def oval(x,y,w,h,c):d.ellipse((x,y+dy,x+w-1,y+dy+h-1),fill=c)
  dark='#253343';light='#f4e0b7';gold='#d7b46e';skin='#bc8d68'
  if hero=='teacher':
   box(23,45,8,15,dark);box(37,45,8,15,dark);box(20,56,13,5,'#4b3b32');box(36,54 if pose=='walk2' else 56,13,5,'#4b3b32')
   poly([(23,28),(43,28),(49,49),(18,49)],dark);poly([(27,28),(39,28),(36,45),(29,45)],'#ece6d8');box(31,30,4,15,'#ab4948');poly([(23,29),(28,29),(28,47),(21,47)],'#416981');poly([(39,29),(44,29),(46,47),(38,47)],'#416981')
   oval(14,8,17,18,'#815f47');oval(37,8,17,18,'#815f47');oval(18,11,10,11,gold);oval(40,11,10,11,gold);box(25,9,19,23,light);box(28,28,13,6,'#d6b795')
   box(28,18,3,4,dark);box(39,18,3,4,dark);box(32,27,7,2,dark)
   box(15,30,7,14,'#416981');box(45,29,7,14,'#416981')
   if pose=='attack':poly([(6,26),(19,29),(19,44),(6,40)],'#a87e52');box(8,29,9,10,light);box(51,24,9,4,'#e9e9d0')
   else:box(9,37,12,14,'#a87e52');box(11,39,8,10,light);box(50,36,4,12,gold);box(49,44,9,3,gold)
  elif hero=='briar':
   oval(13,41,15,15,'#e4d7ba');box(25,46,7,13,dark);box(37,45,7,14,dark);box(21,55,13,6,'#a07853');box(37,54 if pose=='walk2' else 56,13,5,'#a07853')
   poly([(22,28),(43,28),(47,48),(20,48)],'#456e50');box(26,31,14,14,'#7e9c68');box(23,40,23,4,'#8d654a');oval(41,39,12,14,'#a98055')
   poly([(22,13),(20,1),(25,1),(30,14)],'#b89972');poly([(36,14),(41,1),(46,2),(42,17)],'#b89972');box(23,4,3,9,'#ddb6a4');box(41,4,3,10,'#ddb6a4')
   oval(22,13,23,20,'#b89972');box(26,21,4,4,dark);box(37,21,4,4,dark);oval(27,26,13,9,light);box(32,27,4,3,dark)
   box(15,31,8,13,'#b89972');box(44,30,7,13,'#b89972');oval(49,25 if pose=='attack' else 39,12,12,gold);box(49,23 if pose=='attack' else 37,12,5,'#75513c')
  elif hero=='recess':
   oval(20,12,28,34,'#806b55');poly([(20,16),(18,5),(28,11)],'#806b55');poly([(40,11),(50,5),(48,18)],'#806b55')
   oval(22,14,13,16,'#e5d8ad');oval(35,14,13,16,'#e5d8ad');oval(26,18,5,7,dark);oval(39,18,5,7,dark);poly([(32,25),(39,25),(35,31)],gold)
   poly([(22,31),(46,31),(47,51),(20,51)],'#528e85');box(26,32,16,17,'#e6c26d');box(26,42,16,3,light)
   poly([(21,30),(13,37),(15,47),(23,43)],'#806b55');poly([(47,30),(55,37),(52,47),(45,43)],'#806b55')
   box(24,51,5,8,gold);box(38,51,5,8,gold);box(21,57,11,3,gold);box(35,55 if pose=='walk2' else 57,11,3,gold)
   box(7,40,12,11,'#ba7768');box(9,42,8,5,'#edd0a0');box(48,26 if pose=='attack' else 40,10,4,gold)

  else:
   poly([(18,28),(45,28),(53,56),(13,56)],dark);poly([(24,29),(40,29),(45,53),(20,53)],'#984353');box(29,32,6,17,gold);box(20,53,8,7,dark);box(39,53,8,7,dark)
   oval(24,10,21,22,'#b58669');poly([(22,12),(27,5),(44,6),(47,14),(41,15),(38,10),(25,18)],'#423741');box(27,18,4,4,dark);box(38,18,4,4,dark);box(29,27,12,3,'#654348');box(27,23,3,4,'#bd556a')
   box(15,31,8,15,'#984353');box(44,31,8,14,'#984353');box(51,28 if pose=='attack' else 38,4,15,gold)
   poly([(54,30),(59,18),(62,17),(60,32),(56,40),(53,40)],'#e7a6ac');box(10,39,6,6,'#c19b7c')
  im.save(p/f'{hero}_{pose}.png')
