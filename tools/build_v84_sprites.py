from PIL import Image,ImageDraw
from pathlib import Path
p=Path(__file__).resolve().parents[1]/'assets'
# Original 64px sprites authored on the same small pixel grid as the existing cast.
for id in ['tidewright','cantor','shuttle','regent','sluice_crab','coil_singer','glass_mender','confluence_heart']:
 for pose in ['idle','walk1','walk2','attack']:
  im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im);dy=-1 if pose=='walk1' else 1 if pose=='walk2' else 0
  def box(x,y,w,h,c):d.rectangle((x,y+dy,x+w-1,y+dy+h-1),fill=c)
  def poly(points,c):d.polygon([(x,y+dy) for x,y in points],fill=c)
  def oval(x,y,w,h,c):d.ellipse((x,y+dy,x+w-1,y+dy+h-1),fill=c)
  dark='#182d3e';gold='#dab77a';light='#fff0cc';water='#74dfd4';pink='#ed92c6'
  if id in ['tidewright','cantor']:
   accent=water if id=='tidewright' else '#ffdf83'
   fur='#9b785b' if id=='tidewright' else '#ab8465'
   poly([(17,41),(6,49),(4,56),(12,59),(25,49)],fur)
   box(25,45,7,14,dark);box(38,45,7,14,dark);box(23,55 if pose=='walk1' else 57,11,4,gold);box(37,55 if pose=='walk2' else 57,11,4,gold)
   poly([(23,30),(44,30),(49,50),(19,50)],dark);box(26,32,16,15,'#426b77');box(23,42,24,4,gold);box(31,33,6,6,accent)
   oval(22,9,7,8,fur);oval(42,9,7,8,fur);oval(24,12,24,23,fur);oval(27,23,17,11,light);box(28,19,3,4,dark);box(40,19,3,4,dark);box(33,25,5,3,dark)
   box(25,11,22,5,'#3c5d6b');box(28,12,5,3,gold);box(39,12,5,3,gold)
   box(16,33,8,14,fur);box(46,32,7,14,fur);box(54,25 if pose=='attack' else 35,3,20,gold)
   if id=='tidewright':oval(50,20 if pose=='attack' else 30,11,12,accent)
   else:poly([(56,17 if pose=='attack' else 27),(50,29 if pose=='attack' else 39),(57,28 if pose=='attack' else 38),(52,37 if pose=='attack' else 47),(62,23 if pose=='attack' else 33)],accent)
  elif id=='shuttle':
   poly([(5,33),(21,13),(43,13),(60,33),(43,53),(21,53)],dark);poly([(10,33),(23,18),(42,18),(55,33),(42,48),(23,48)],'#ad7757');box(24,21,18,24,'#533e46');box(27,20,12,26,pink)
   for y in range(23,44,4):box(27,y,12,2,'#ffd3e3')
   box(16,28,5,6,light);box(44,28,5,6,light);box(18,30,2,4,dark);box(46,30,2,4,dark)
   poly([(38,43),(49,55),(59,51),(61,55),(49,60),(34,47)],pink)
   if pose=='attack':box(1,31,15,3,'#f9eac0');poly([(0,32),(6,29),(6,35)],light)
  elif id=='regent':
   poly([(20,26),(43,26),(53,57),(34,62),(12,56)],dark);poly([(26,28),(40,28),(46,56),(32,51),(19,55)],'#665795');box(29,33,8,18,gold);box(22,53,6,7,gold);box(39,54,6,6,gold)
   oval(22,9,24,24,dark);poly([(25,13),(43,13),(41,29),(33,33),(26,27)],'#e7d6bf');box(27,19,5,4,'#665795');box(36,19,5,4,'#665795');poly([(22,12),(20,2),(28,7),(33,0),(38,7),(47,2),(44,12)],gold)
   box(46,30,6,15,'#665795');oval(47,32 if pose!='attack' else 17,14,14,gold);oval(50,35 if pose!='attack' else 20,8,8,dark);box(53,35 if pose!='attack' else 20,2,6,'#bdb2ff');box(15,31,7,14,'#665795')
  elif id=='sluice_crab':
   for x in [8,17,40,49]:box(x,37,6,16,gold)
   poly([(12,25),(24,18),(43,18),(54,27),(48,45),(18,45)],dark);box(19,24,29,17,'#659c9b');box(23,17,4,12,gold);box(39,17,4,12,gold);box(24,17,3,4,light);box(40,17,3,4,light);box(4,23,12,13,gold);box(49,23,12,13,gold);box(23,31,21,4,water)
  elif id=='coil_singer':
   poly([(22,30),(43,30),(49,55),(14,55)],dark);box(23,32,19,19,'#93714e');box(30,8,6,28,gold)
   for y in [10,17,24]:box(19,y,27,4,'#dbba74')
   oval(26,4,14,13,'#fae58d');box(28,8,3,3,dark);box(35,8,3,3,dark)
  elif id=='glass_mender':
   poly([(32,5),(48,23),(44,46),(32,59),(18,45),(15,23)],dark);poly([(32,10),(43,24),(39,44),(32,53),(23,43),(20,24)],water);poly([(32,14),(38,26),(32,43),(26,26)],light);box(25,28,4,4,dark);box(36,28,4,4,dark);box(7,34,10,6,gold);box(47,34,10,6,gold)
  else:
   oval(6,6,52,52,dark);oval(10,10,44,44,gold);oval(15,15,34,34,dark);poly([(20,18),(31,18),(31,47),(20,40)],water);poly([(34,18),(45,25),(45,40),(34,47)],'#ffe382');box(29,26,7,12,light)
   for x,y in [(3,25),(50,25),(26,1),(26,51)]:box(x,y,11,12,'#ae8460')
  im.save(p/f'{id}_{pose}.png')
