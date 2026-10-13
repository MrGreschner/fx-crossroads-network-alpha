from pathlib import Path
from PIL import Image,ImageDraw
p=Path(__file__).resolve().parents[1]/'assets'
for hero in ['tempo','quill','quillling']:
 for pose in ['idle','walk1','walk2','attack']:
  im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im);dy=1 if pose=='walk2' else -1 if pose=='walk1' else 0
  def box(x,y,w,h,c):d.rectangle((x,y+dy,x+w-1,y+dy+h-1),fill=c)
  def oval(x,y,w,h,c):d.ellipse((x,y+dy,x+w-1,y+dy+h-1),fill=c)
  def poly(a,c):d.polygon([(x,y+dy) for x,y in a],fill=c)
  dark='#273b41';cream='#ecd6aa';brown='#97735a'
  if hero=='tempo':
   oval(23,6,23,23,'#ba8868');box(28,16,3,4,dark);box(39,16,3,4,dark);box(32,26,7,2,dark)
   poly([(22,29),(45,29),(51,52),(18,52)],'#b36346');box(26,30,15,17,'#e6c594');poly([(25,31),(35,43),(42,31),(37,47),(30,47)],'#f1d7a5');box(20,43,29,5,dark)
   box(23,51,8,9,dark);box(39,50 if pose=='walk2' else 51,8,9,dark)
   box(14,31,8,15,'#ba8868');box(47,29,8,15,'#ba8868')
   for y in [36,40]:box(15,y,7,2,cream);box(48,y-2,6,2,cream)
   if pose=='attack':box(49,20,11,11,'#ba8868');box(49,25,10,3,cream)
   for n in range(4):oval(27+n*4,35,3,3,brown)
  elif hero=='quill':
   for n in range(9):
    x=10+n*5;poly([(x,43),(x-5,12+(n%3)*3),(x+7,32)],'#514641');poly([(x,37),(x-4,14+(n%3)*3),(x+4,31)],cream)
   oval(15,29,35,25,brown);oval(24,11,24,23,'#c6a079');oval(21,10,7,9,brown);oval(45,11,7,9,brown)
   box(27,19,3,4,dark);box(40,19,3,4,dark);oval(32,25,12,8,cream);box(36,26,4,3,dark)
   box(20,35,29,7,'#788f77');box(23,46,7,14,dark);box(39,46 if pose=='walk2' else 49,7,11,dark)
   box(15,35,8,11,brown);box(48,34,8,12,brown)
   if pose=='attack':
    for n in range(3):box(52+n*3,22,2,13,cream)
  else:
   for n in range(6):poly([(16+n*6,40),(10+n*6,15+n%2*5),(23+n*6,28)],cream)
   oval(17,28,31,21,brown);oval(32,25,21,19,'#c6a079');box(43,29,3,3,dark);box(52,33,4,3,dark);box(21,46,7,8,dark);box(39,45 if pose=='walk2' else 46,7,8,dark)
  im.save(p/f'{hero}_{pose}.png')
