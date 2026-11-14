extends RefCounted
const WildArt=preload("res://scripts/wayfarer_art305.gd")
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
 var view:=Rect2(camera,c.get_viewport_rect().size)
 var bounds:=view.grow(180)
 for sign in [{"pos":Vector2(9630,2210),"text":"RIMECREST →"},{"pos":Vector2(9630,4700),"text":"SKYWORKS →"}]:
  if bounds.has_point(sign.pos):
   var point:Vector2=sign.pos-camera
   c.draw_line(point,point+Vector2(0,55),Color("#8d7358"),8)
   c.draw_rect(Rect2(point+Vector2(-72,-25),Vector2(144,35)),Color("#6c735e"))
   c.draw_string(ThemeDB.fallback_font,point+Vector2(-65,0),sign.text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#ede6ba"))
 if camera.x+c.get_viewport_rect().size.x<9900:return
 WildArt.surface(c,"snow",Rect2(9900,0,6100,3400),camera,view,Color("#51687b"))
 WildArt.surface(c,"river",Rect2(9900,3400,6100,3100),camera,view,Color("#526d6a"))
 for floor in MOUNTAIN:
  if not floor.intersects(bounds):continue
  c.draw_rect(Rect2(floor.position+Vector2(0,75)-camera,floor.size),Color("#263b4c"))
  WildArt.surface(c,"snow",floor,camera,view,Color("#a6b9b7") if floor.position.x<12800 else Color.WHITE)
  c.draw_rect(Rect2(floor.position-camera,floor.size),Color("#647b85"),false,7)
 for point in [Vector2(11020,2060),Vector2(11700,1250),Vector2(13200,2620),Vector2(15220,1700),Vector2(14520,480)]:
  if not bounds.has_point(point):continue
  WildArt.prop(c,"spruce",point-camera,Vector2(176,176))
 for point in [Vector2(10520,2060),Vector2(11340,1300),Vector2(13150,2350),Vector2(14890,510)]:
  if bounds.has_point(point):WildArt.prop(c,"ridge_rocks",point-camera,Vector2(128,102))
 for n in 36:
  var point:Vector2=Vector2(12900+fposmod(n*173+clock*25,2650),450+fposmod(n*97+clock*65,2300))
  if bounds.has_point(point):c.draw_circle(point-camera,1.7,Color(.92,1,1,.65))
 var bell:Vector2=Vector2(14600,620)-camera
 if bounds.has_point(bell+camera):WildArt.prop(c,"bell",bell+Vector2(0,21),Vector2(214,214))
 c.draw_string(ThemeDB.fallback_font,bell+Vector2(-70,55),"RIMECREST SUMMIT",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#e7f2de"))
 for floor in SKYWORKS:
  if not floor.intersects(bounds):continue
  WildArt.surface(c,"terrace",floor,camera,view)
  c.draw_rect(Rect2(floor.position-camera,floor.size),Color("#b6ba99"),false,7)
 for center in [Vector2(11600,4120),Vector2(11500,5520),Vector2(14400,4140)]:
  if not bounds.has_point(center):continue
  var point:Vector2=center-camera
  WildArt.prop(c,"valve",point+Vector2(0,28),Vector2(234,234))
  for n in 6:
   var direction:Vector2=Vector2.from_angle(n*TAU/6+(clock*.8 if water_running else 0))
   c.draw_line(point+Vector2(0,-78),point+Vector2(0,-78)+direction*16,Color("#c8b985"),5)
 for center in [Vector2(12700,4740),Vector2(13900,5430),Vector2(15120,4770)]:
  if not bounds.has_point(center):continue
  var point:Vector2=center-camera
  WildArt.prop(c,"seal",point+Vector2(0,22),Vector2(108,90))
 # Running water is a visible consequence of completing the Skyworks.
 for x in [12880,14750]:
  WildArt.surface(c,"river",Rect2(x,4450,80,650),camera,view,Color("#9bc4b3") if water_running else Color("#63736b"))
  if water_running:
   for n in 9:
    var point:=Vector2(x+12,4450+fposmod(clock*90+n*72,650))
    if bounds.has_point(point):c.draw_line(point-camera,point-camera+Vector2(55,0),Color("#b5dcce",.45),2)
 c.draw_string(ThemeDB.fallback_font,Vector2(10900,4820)-camera,"SKYWORKS • WATER GARDENS",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#dfdfb5"))

 for x in [12880,14750]:
  WildArt.surface(c,"wood",Rect2(x-15,4650,110,310),camera,view)
  for y in [4650,4930]:
   var point:=Vector2(x+38,y)
   if bounds.has_point(point):WildArt.prop(c,"rail",point-camera,Vector2(125,71))
