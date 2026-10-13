extends RefCounted
const MOUNTAIN=[
 Rect2(9600,2000,1900,420),Rect2(11080,1180,420,1240),
 Rect2(11080,1180,2350,420),Rect2(13010,1180,420,1540),
 Rect2(13010,2300,2480,420),Rect2(15070,600,420,2120),
 Rect2(14000,400,1500,700)
]
const SKYWORKS=[
 Rect2(9600,4520,5850,600),Rect2(10800,3800,1300,700),
 Rect2(11200,4000,420,1740),Rect2(10750,5200,1500,650),
 Rect2(12400,5100,2900,550),Rect2(12400,3950,3000,500),
 Rect2(12400,3950,400,1600),Rect2(14900,3950,500,1600)
]
func terrain(point:Vector2)->bool:
 for floor in MOUNTAIN+SKYWORKS:
  if floor.grow(-20).has_point(point):return true
 return false
func draw_on(c:Node2D,camera:Vector2,clock:float,water_running:bool)->void:
 var bounds:Rect2=Rect2(camera-Vector2(180,180),c.get_viewport_rect().size+Vector2(360,360))
 for sign in [{"pos":Vector2(9630,2210),"text":"RIMECREST →"},{"pos":Vector2(9630,4700),"text":"SKYWORKS →"}]:
  if bounds.has_point(sign.pos):
   var point:Vector2=sign.pos-camera
   c.draw_line(point,point+Vector2(0,55),Color("#8d7358"),8)
   c.draw_rect(Rect2(point+Vector2(-72,-25),Vector2(144,35)),Color("#6c735e"))
   c.draw_string(ThemeDB.fallback_font,point+Vector2(-65,0),sign.text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#ede6ba"))
 if camera.x+c.get_viewport_rect().size.x<9900:return
 c.draw_rect(Rect2(Vector2(9900,0)-camera,Vector2(6100,3400)),Color("#384956"))
 c.draw_rect(Rect2(Vector2(9900,3400)-camera,Vector2(6100,3100)),Color("#31575d"))
 for floor in MOUNTAIN:
  if not floor.intersects(bounds):continue
  c.draw_rect(Rect2(floor.position+Vector2(0,75)-camera,floor.size),Color("#263b4c"))
  c.draw_rect(Rect2(floor.position-camera,floor.size),Color("#879994") if floor.position.x<12800 else Color("#c6e0df"))
  c.draw_rect(Rect2(floor.position-camera,floor.size),Color("#647b85"),false,7)
  surface_detail(c,camera,floor,bounds,true)
  for x in range(int(floor.position.x)+60,int(floor.end.x),170):
   for y in range(int(floor.position.y)+50,int(floor.end.y),180):
    var point:Vector2=Vector2(x,y)-camera
    c.draw_line(point,point+Vector2(30,8),Color("#a9bfbc"),2)
    if x>12800:c.draw_line(point,point+Vector2(5,24),Color("#8daebc"),1)
 for point in [Vector2(11020,2060),Vector2(11700,1250),Vector2(13200,2620),Vector2(15220,1700),Vector2(14520,480)]:
  if not bounds.has_point(point):continue
  var tree:Vector2=point-camera
  c.draw_line(tree+Vector2(0,12),tree+Vector2(0,-80),Color("#786955"),9)
  for tier in 3:
   var y:float=-30-tier*22
   c.draw_colored_polygon(PackedVector2Array([tree+Vector2(-32+tier*5,y+20),tree+Vector2(0,y-30),tree+Vector2(32-tier*5,y+20)]),Color("#73969b"))
   c.draw_line(tree+Vector2(-25+tier*5,y+13),tree+Vector2(25-tier*5,y+13),Color("#d9eeee"),5)
 for n in 36:
  var point:Vector2=Vector2(12900+fposmod(n*173+clock*25,2650),450+fposmod(n*97+clock*65,2300))
  if bounds.has_point(point):c.draw_circle(point-camera,1.7,Color(.92,1,1,.65))
 var bell:Vector2=Vector2(14600,620)-camera
 for side in [-1,1]:c.draw_rect(Rect2(bell+Vector2(side*55-5,-90),Vector2(10,100)),Color("#8d9fa5"))
 c.draw_line(bell+Vector2(-60,-90),bell+Vector2(60,-90),Color("#c2d1cd"),10)
 c.draw_arc(bell+Vector2(0,-40),23,PI,TAU,24,Color("#d7bb7f"),14,true)
 c.draw_line(bell+Vector2(-23,-40),bell+Vector2(23,-40),Color("#e9d59b"),6)
 c.draw_circle(bell+Vector2(0,-33),4,Color("#b39767"))
 c.draw_string(ThemeDB.fallback_font,bell+Vector2(-70,55),"RIMECREST SUMMIT",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#e7f2de"))
 for floor in SKYWORKS:
  if not floor.intersects(bounds):continue
  c.draw_rect(Rect2(floor.position-camera,floor.size),Color("#8e9c81"))
  c.draw_rect(Rect2(floor.position-camera,floor.size),Color("#b6ba99"),false,7)
  surface_detail(c,camera,floor,bounds,false)
  for n in range(int(floor.position.x)+60,int(floor.end.x),150):
   var top:Vector2=Vector2(n,floor.position.y+18)-camera
   c.draw_line(top,top+Vector2(0,25),Color("#667e76"),3)
 for center in [Vector2(11600,4120),Vector2(11500,5520),Vector2(14400,4140)]:
  if not bounds.has_point(center):continue
  var point:Vector2=center-camera
  for side in [-1,1]:c.draw_rect(Rect2(point+Vector2(side*125-15,-120),Vector2(30,160)),Color("#819889"))
  c.draw_arc(point+Vector2(0,-100),125,PI,TAU,32,Color("#bec6a7"),18,true)
  for col in 5:c.draw_rect(Rect2(point+Vector2(-110+col*48,75),Vector2(38,20)),Color("#c1b08a"))
  c.draw_circle(point+Vector2(90,-55),28,Color("#677d77"))
  for n in 6:
   var direction:Vector2=Vector2.from_angle(n*TAU/6+(clock*.8 if water_running else 0))
   c.draw_line(point+Vector2(90,-55),point+Vector2(90,-55)+direction*24,Color("#c8b985"),5)
 for center in [Vector2(12700,4740),Vector2(13900,5430),Vector2(15120,4770)]:
  var point:Vector2=center-camera
  c.draw_rect(Rect2(point+Vector2(-25,-28),Vector2(50,50)),Color("#677f77"))
  c.draw_arc(point+Vector2(0,-20),19,0,TAU,24,Color("#d9b980"),4,true)
  c.draw_line(point+Vector2(-18,-20),point+Vector2(18,-20),Color("#d9b980"),3)
  c.draw_line(point+Vector2(0,-38),point+Vector2(0,-2),Color("#d9b980"),3)
 # Running water is a visible consequence of completing the Skyworks.
 for x in [12880,14750]:
  c.draw_rect(Rect2(Vector2(x,4450)-camera,Vector2(80,650)),Color("#7da5a3") if water_running else Color("#4c6869"))
  if water_running:
   for n in 12:
    var point:Vector2=Vector2(x+12,4450+fposmod(clock*90+n*54,650))-camera
    c.draw_line(point,point+Vector2(55,0),Color("#b5dcce"),2)
 c.draw_string(ThemeDB.fallback_font,Vector2(10900,4820)-camera,"SKYWORKS • WATER GARDENS",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#dfdfb5"))

 for x in [12880,14750]:
  c.draw_rect(Rect2(Vector2(x-15,4650)-camera,Vector2(110,310)),Color("#95836a"))
  for y in range(4650,4960,24):c.draw_line(Vector2(x-15,y)-camera,Vector2(x+95,y)-camera,Color("#c5b18c"),2)

func surface_detail(c:Node2D,camera:Vector2,floor:Rect2,bounds:Rect2,ice:bool)->void:
 var snow:bool=ice and floor.position.x>=12800
 var left:int=maxi(int(floor.position.x),int(bounds.position.x))
 var right:int=mini(int(floor.end.x),int(bounds.end.x))
 var top:int=maxi(int(floor.position.y),int(bounds.position.y))
 var bottom:int=mini(int(floor.end.y),int(bounds.end.y))
 for x in range(floori(float(left)/52)*52,right,52):
  for y in range(floori(float(top)/46)*46,bottom,46):
   var cell:Vector2=Vector2(x,y)
   if not floor.grow(-12).has_point(cell):continue
   var seed_value:int=abs(x*7381+y*1933)
   var point:Vector2=cell-camera
   var color:Color=Color("#bad2d2") if snow else Color("#758b83") if ice else Color("#849279")
   color.a=.35
   c.draw_rect(Rect2(point,Vector2(45,39)),color)
   if seed_value%5==0:
    c.draw_line(point+Vector2(9,12),point+Vector2(20,16),Color("#7da0ae") if snow else Color("#6c8073"),1)
   if seed_value%13==0:
    c.draw_circle(point+Vector2(26,26),2,Color("#f0ffff") if snow else Color("#acb494"))
 # Edge stones and snowy drifts leave the walkable centre clear.
 for x in range(int(floor.position.x)+45,int(floor.end.x)-25,100):
  for y in [floor.position.y+26,floor.end.y-26]:
   var world_point:=Vector2(x,y)
   if not bounds.has_point(world_point):continue
   var point:Vector2=world_point-camera
   c.draw_colored_polygon(PackedVector2Array([point+Vector2(-21,10),point+Vector2(-18,-6),point+Vector2(0,-15),point+Vector2(18,-5),point+Vector2(24,10)]),Color("#7092a1") if snow else Color("#607b7b") if ice else Color("#607469"))
   c.draw_line(point+Vector2(-16,-5),point+Vector2(12,-8),Color("#edf8f4") if snow else Color("#a1b4a6"),5)
   if not ice:
    c.draw_line(point+Vector2(28,8),point+Vector2(32,-7),Color("#4f705c"),2)
    c.draw_circle(point+Vector2(32,-8),3,Color("#d4c891"))
