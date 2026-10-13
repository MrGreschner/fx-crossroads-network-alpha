from pathlib import Path
from PIL import Image,ImageDraw
p=Path(__file__).resolve().parents[1]/'assets'
for hero in ['cindervane','tova','merrymask','dunecook','dustmarshal','stagelet','lanternling','deputyling']:
 for pose in ['idle','walk1','walk2','attack','open'] if hero=='cindervane' else ['idle','walk1','walk2','attack']:
  im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im);dy=-1 if pose=='walk1' else 1 if pose=='walk2' else 0
  def box(x,y,w,h,c):d.rectangle((x,y+dy,x+w-1,y+dy+h-1),fill=c)
  def oval(x,y,w,h,c):d.ellipse((x,y+dy,x+w-1,y+dy+h-1),fill=c)
  def poly(a,c):d.polygon([(x,y+dy) for x,y in a],fill=c)
  dark='#293a40';cream='#ead6aa'
  if hero=='cindervane':
   for n in range(5):poly([(22+n*4,45),(3+n*4,58-n*4),(25+n*4,52)],['#ac4849','#e77c4c','#efbd70'][n%3])
   oval(20,22,29,29,'#b34f4e');oval(25,30,20,22,'#e69458');oval(26,8,22,23,'#d98751');poly([(25,17),(28,3),(34,12),(38,1),(42,13)],'#f0b16a');poly([(42,18),(56,23),(44,27)],cream);box(39,17,3,4,dark)
   if pose=='walk1':
    poly([(21,30),(8,9),(4,17),(11,30),(23,42)],'#edba71');poly([(46,30),(57,9),(62,17),(55,30),(44,42)],'#edba71')
    poly([(11,14),(16,29),(20,35)],'#f6d69c');poly([(57,14),(52,29),(48,35)],'#f6d69c')
   elif pose=='walk2':
    poly([(21,29),(8,41),(6,51),(17,46),(24,37)],'#edba71');poly([(45,29),(58,41),(62,51),(50,46),(43,37)],'#edba71')
    poly([(9,44),(18,39),(22,34)],'#f6d69c');poly([(59,44),(50,39),(46,34)],'#f6d69c')
   else:
    poly([(19,29),(7 if pose=='open' else 16,17),(4 if pose=='open' else 13,40),(23,46)],'#edba71');poly([(46,29),(61 if pose=='open' else 54,17),(63 if pose=='open' else 57,40),(45,47)],'#edba71')
   box(27,49,5,11,dark);box(42,49,5,11,dark)
   if pose=='attack':poly([(45,28),(60,25),(58,38),(43,43)],'#f6d69c')
  elif hero=='tova':
   poly([(21,47),(8,52),(4,43),(12,45),(25,41)],'#638f7a');oval(20,9,27,24,'#6ca48b');oval(20,9,11,9,'#87b59b');oval(39,9,11,9,'#87b59b');box(26,17,3,4,dark);box(41,17,3,4,dark);box(28,27,15,2,cream)
   poly([(21,30),(45,30),(49,53),(18,53)],'#57686d');box(24,34,18,18,'#a9c2a0');box(21,52,8,8,dark);box(39,52,8,8,dark);box(13,30,7,16,'#6ca48b');box(45,30,6,16,'#6ca48b');box(53,18,3,39,'#ab966a');oval(47,10,13,16,'#486c63');oval(50,13,7,10,'#e9d293')
  elif hero in ['merrymask','stagelet']:
   scale=hero=='stagelet';oval(21,7,25,26,'#c99874');poly([(20,14),(24,4),(34,10),(44,4),(47,14)],'#766898');box(27,17,3,4,dark);box(39,17,3,4,dark);poly([(27,25),(38,28),(42,23)],'#623e54');poly([(21,31),(46,31),(48,51),(19,51)],'#93698a');box(27,33,12,13,'#d4b284');box(12,32,8,15,'#c99874');box(48,32,8,15,'#c99874');box(23,51,7,10,dark);box(39,51,7,10,dark)
   for x in [17,51]:box(x,2,1,32,'#d7c3a4')
   if pose=='attack':poly([(48,29),(59,20),(60,37),(48,43)],'#d4b284')
   if scale:im=im.resize((44,44),Image.Resampling.NEAREST);out=Image.new('RGBA',(64,64));out.paste(im,(10,18));im=out
  elif hero=='dunecook':
   # A living layer cake, not a desert animal: icing, sponge, cherries and chef hat.
   box(17,19,33,32,dark);box(19,20,29,30,'#e1b775');box(19,27,29,5,'#974d5a');box(19,40,29,5,'#974d5a')
   box(17,17,33,8,'#fff0d6')
   for x in [19,28,39,46]:oval(x,20,5,10,'#fff0d6')
   box(26,32,3,4,dark);box(39,32,3,4,dark);d.arc((29,36+dy,38,41+dy),0,180,fill=dark,width=2)
   box(23,8,21,10,'#f4f1e2');box(21,14,25,4,'#d3dad1')
   for x in [21,29,37]:oval(x,2,11,11,'#f4f1e2')
   oval(17,12,7,7,'#c96265');oval(44,12,7,7,'#c96265')
   box(22,49,22,4,'#f6ead3');box(22,53,7,8,dark);box(40,53,7,8,dark)
   box(10,29,8,17,'#e1b775');box(50,29,7,17,'#e1b775');box(55,26,3,24,'#725442');box(52,15 if pose=='attack' else 21,10,13,'#b9cccf')
  elif hero in ['dustmarshal','deputyling']:
   oval(20,8,28,26,'#987259');oval(22,9,24,12,'#735844');oval(23,24,23,12,'#b49573');box(26,19,3,4,dark);box(41,19,3,4,dark)
   poly([(15,19),(8,10),(10,6),(17,14)],cream);poly([(50,19),(57,10),(55,6),(49,14)],cream);box(12,10,44,7,'#6b5340');box(23,2,26,11,'#a68659');box(23,9,26,3,'#c9aa78')
   poly([(18,33),(49,33),(52,53),(16,53)],'#697f81');box(28,34,12,18,'#aa8963');box(28,34,12,4,'#c57c5c');box(21,52,9,9,dark);box(40,52,9,9,dark);box(10,33,8,16,'#987259');box(51,33,7,16,'#987259')
   d.ellipse((47,35+dy,61,52+dy),outline='#e0c38e',width=2)
   box(50,28,11,4,dark);box(52,30,4,9,dark)
   if pose=='attack':box(53,25,10,4,'#bfc9c6')
   if hero=='deputyling':im=im.resize((48,48),Image.Resampling.NEAREST);out=Image.new('RGBA',(64,64));out.paste(im,(8,14));im=out
  else:
   oval(20,17,27,26,'#547d70');oval(25,20,17,20,'#e9d899');box(24,41,18,10,'#735b46');box(29,7,4,11,'#baa77d');box(28,26,3,4,dark);box(39,26,3,4,dark)
   for x in [15,48]:poly([(x,28),(x-5,17),(x+4,23)],'#b5d7b6')
  im.save(p/f'{hero}_{pose}.png')
