extends RefCounted
const A=preload("res://scripts/business_district/art.gd")
static func floor_plan(c:CanvasItem,o:Vector2,b:Dictionary,night:bool)->void:
 if b.trade=="minigolf":
  for j in 3:
   var p=o+Vector2(25+j*170,210);A.rounded(c,Rect2(p,Vector2(145,115)),Color("#769b73"),16,Color("#d0bd92"));c.draw_polyline(PackedVector2Array([p+Vector2(10,95),p+Vector2(25,25),p+Vector2(115,25),p+Vector2(130,90)]),Color("#a8c18c"),3,true);A.ellipse(c,p+Vector2(113,70),Vector2(9,5),Color("#294846"));c.draw_line(p+Vector2(113,70),p+Vector2(113,35),Color("#e7dfbd"),2);c.draw_colored_polygon(PackedVector2Array([p+Vector2(113,35),p+Vector2(132,42),p+Vector2(113,48)]),Color("#c8947c"))
 elif b.trade=="daycare":
  A.rounded(c,Rect2(o+Vector2(22,208),Vector2(505,137)),Color("#9faf83"),14,Color("#c2ad83"))
  for j in mini(8,int(b.assets.get("dog_pen",{}).get("count",0))*3):
   var p=o+Vector2(50+(j%5)*96,255+(j/5)*52);A.ellipse(c,p,Vector2(31,20),Color("#d7be92"));A.ellipse(c,p,Vector2(24,13),Color("#a87c67"))
  for j in 8:A.box(c,o+Vector2(23+j*70,354),Vector2(8,30),Color("#b8a184"),10)
  c.draw_line(o+Vector2(23,337),o+Vector2(520,337),Color("#d6bd94"),4)
 elif b.trade=="salon":
  for j in mini(6,int(b.assets.get("barber_chair",{}).get("count",0))):
   var p=o+Vector2(55+(j%3)*160,200+(j/3)*85);A.box(c,p,Vector2(110,28),Color("#947e83"),20);A.rounded(c,Rect2(p-Vector2(0,86),Vector2(105,68)),Color("#b7cfca"),10,Color("#e7d2ae"));c.draw_line(p+Vector2(7,-70),p+Vector2(35,-45),Color("#e6ece0"),3)
   A.box(c,p+Vector2(20,72),Vector2(65,30),Color("#c096a5"),28);A.ellipse(c,p+Vector2(53,52),Vector2(33,12),Color("#dec1b6"))
 elif b.trade in ["dessert","cafe"]:
  for j in 2:
   var p=o+Vector2(82+j*345,326);A.ellipse(c,p,Vector2(36,19),Color("#bd9b78"));A.ellipse(c,p-Vector2(0,3),Vector2(32,17),Color("#e1c7a2"));A.ellipse(c,p+Vector2(0,-9),Vector2(10,6),Color("#b0c5b2"))
   for dx in [-43,43]:A.ellipse(c,p+Vector2(dx,9),Vector2(11,8),Color("#a78683"))
  A.rounded(c,Rect2(o+Vector2(250,52),Vector2(115,61)),Color("#345351"),5);A.ink(c,o+Vector2(259,74),"DAILY TREATS" if b.trade=="dessert" else "COFFEE & TEA",12,Color("#ead9b2"));A.ink(c,o+Vector2(262,95),"MADE HERE",11,Color("#a8c9b7"))
static func dog(c:CanvasItem,p:Vector2,index:int,t:float)->void:
 var pose=1+posmod(int(t*6),2)
 var tex=preload("res://scripts/market_art233.gd").dog(index,pose)
 c.draw_texture_rect(tex,Rect2(p-Vector2(27,49),Vector2(54,54)),false)
static func live(c:CanvasItem,o:Vector2,b:Dictionary,t:float)->void:
 if b.trade=="daycare":
  for job in b.services:
   var slot=int(job.slots[0]);var p=o+Vector2(83+(slot%4)*115+sin(t+slot)*15,250+(slot/4)*65+cos(t*.8+slot)*12);dog(c,p,int(job.id),t)
 elif b.trade=="minigolf":
  if b.assets.has("obstacle_course"):
   var p=o+Vector2(325,221);A.box(c,p+Vector2(-16,18),Vector2(33,23),Color("#c6ac82"),38)
   for j in 4:
    var a=t*1.5+j*PI/2;c.draw_line(p,p+Vector2(cos(a),sin(a))*29,Color("#ead8ae"),7,true)
  for job in b.services:
   var slot=int(job.slots[0]);var p=o+Vector2(80+(slot%3)*168,242+sin(t+slot)*10);c.draw_circle(p+Vector2(23,20),4,Color("#eee5cc"));c.draw_line(p+Vector2(6,-1),p+Vector2(24+sin(t*3)*8,20),Color("#b4c2b4"),3,true)
 elif b.trade=="salon":
  for job in b.services:
   var p=o+Vector2(105+(int(job.slots[0])%3)*155,217);c.draw_line(p+Vector2(-8,-9),p+Vector2(12+sin(t*9)*5,-20),Color("#d7d4c0"),2);c.draw_arc(p-Vector2(3,4),16,t*2,t*2+1.4,8,Color("#ecd5ac"),2,true)
