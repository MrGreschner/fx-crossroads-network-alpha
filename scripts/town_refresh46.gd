extends RefCounted
## Small culled props, shared collision footprints and a scheduled social destination.
const PAVILION=Rect2(1100,1530,220,100)
const REST=Vector2(1210,1685)
const MASSIF=Rect2(-1650,465,450,870)
const POSTS=[Vector2(-1210,1260),Vector2(-945,1260)]
static func reserved(p:Vector2)->bool:return MASSIF.grow(100).has_point(p) or Rect2(1060,1460,310,255).has_point(p)
static func blocked(p:Vector2)->bool:
 if Rect2(-1700,360,500,990).has_point(p) or PAVILION.grow(6).has_point(p):return true
 for at in POSTS:
  if p.distance_to(at)<15:return true
 return false
static func interact(g:Node)->bool:
 if g.position_in_world.distance_to(REST)>75:return false
 g.hint="E • Wayfarer’s Rest • tea, games & travellers’ stories"
 if Input.is_action_just_pressed("interact"):
  g.presentation.window("WAYFARER’S REST","wayfarers_rest")
  g.presentation.label(g.presentation.content,"A little space to meet the people of Crossroads.",20)
  g.presentation.label(g.presentation.content,"Monday, Wednesday & Friday • lunch and tea, noon–1 pm\nTuesday & Thursday • board games, 6–8 pm\nSunday • travellers’ stories, 4–7 pm\nThe pavilion stays open for a quiet rest between gatherings.",17)
  g.presentation.button(g.presentation.content,"Back to town",g.presentation.close)
 return true
static func cliffs(g:Node2D,camera:Vector2)->void:
 if not Rect2(camera,g.VIEW).grow(180).intersects(MASSIF.grow(100)):return
 g.draw_rect(Rect2(MASSIF.position-camera,MASSIF.size),Color("#4c5856"))
 for row in 6:
  var y=485+row*142
  for col in 3:
   var p=Vector2(-1680+col*142,y+(col%2)*42)-camera
   var rock=PackedVector2Array([p+Vector2(-20,100),p+Vector2(5,-30),p+Vector2(65,-95),p+Vector2(135,-20),p+Vector2(160,105)])
   g.draw_colored_polygon(rock,Color("#65716b") if (row+col)%2 else Color("#566560"))
   g.draw_colored_polygon(PackedVector2Array([p+Vector2(65,-95),p+Vector2(135,-20),p+Vector2(160,105),p+Vector2(78,64)]),Color("#485754"))
   g.draw_line(p+Vector2(65,-90),p+Vector2(78,64),Color("#8d9481"),3)
   for n in 3:g.draw_line(p+Vector2(8,12+n*25),p+Vector2(60,5+n*29),Color("#788273"),2)
 # A stone approach gives the Descent its own footprint and a clear approach from the street.
 var court=Rect2(Vector2(-1175,1195)-camera,Vector2(245,130));g.draw_rect(court,Color("#8d907a"));g.draw_rect(court,Color("#b6b298"),false,3)
 for y in range(1200,1325,25):
  for x in range(-1170,-930,40):g.draw_rect(Rect2(Vector2(x+(10 if y%2 else 0),y)-camera,Vector2(36,21)),Color("#9b9d87"),false,1)
 # Buttresses frame, rather than hide, the existing cave and its interaction point.
 for x in [-1205,-965]:
  var p=Vector2(x,1200)-camera
  g.draw_rect(Rect2(p-Vector2(15,135),Vector2(30,150)),Color("#69736b"));g.draw_rect(Rect2(p-Vector2(20,142),Vector2(40,14)),Color("#a5aa92"))
  for n in 5:g.draw_line(p+Vector2(-14,-n*27),p+Vector2(14,-n*27),Color("#909a85"),2)
static func draw(g:Node2D,camera:Vector2)->void:
 var view=Rect2(camera,g.VIEW).grow(170);var night=float(g.town_life.calendar.night_amount())
 if view.intersects(PAVILION.grow(130)):
  var p=PAVILION.position-camera
  g.draw_rect(Rect2(p+Vector2(-17,75),Vector2(254,48)),Color("#a59b79"))
  for x in [0,220]:g.draw_line(p+Vector2(x,8),p+Vector2(x,98),Color("#866344"),9)
  var roof=PackedVector2Array([p+Vector2(-27,8),p+Vector2(25,-65),p+Vector2(195,-65),p+Vector2(247,8)])
  g.draw_colored_polygon(roof,Color("#486b66"));g.draw_polyline(PackedVector2Array([p+Vector2(-27,8),p+Vector2(25,-65),p+Vector2(195,-65),p+Vector2(247,8)]),Color("#cbb181"),4)
  for x in range(15,220,27):g.draw_line(p+Vector2(x,0),p+Vector2(35+x*.7,-59),Color("#73918a"),2)
  g.draw_rect(Rect2(p+Vector2(22,17),Vector2(176,26)),Color("#254341"));g.draw_string(ThemeDB.fallback_font,p+Vector2(31,36),"WAYFARER’S REST",HORIZONTAL_ALIGNMENT_CENTER,160,15,Color("#f5dfab"))
  # A game board and tea service are distinct visible objects, with benches facing the street.
  g.draw_rect(Rect2(p+Vector2(45,64),Vector2(130,22)),Color("#b18a57"))
  for y in 4:
   for x in 4:g.draw_rect(Rect2(p+Vector2(88+x*7,60+y*5),Vector2(7,5)),Color("#eed9a5") if (x+y)%2 else Color("#4b6460"))
  for x in [60,146]:g.draw_circle(p+Vector2(x,67),5,Color("#c5ded3"));g.draw_arc(p+Vector2(x+5,67),3,-PI*.5,PI*.5,8,Color("#c5ded3"),2)
  for x in [20,156]:
   g.draw_rect(Rect2(p+Vector2(x,103),Vector2(49,10)),Color("#b39164"));g.draw_line(p+Vector2(x,95),p+Vector2(x+49,95),Color("#d3b780"),5)
  for x in [-15,235]:preload("res://scripts/town_calendar.gd").draw_lantern(g,p+Vector2(x,90),night)
  # An inexpensive chime supplies small motion without particles or simulation actors.
  var sway=sin(g.town_life.clock*1.3)*3
  for n in 3:g.draw_line(p+Vector2(199+n*6,11),p+Vector2(199+n*6+sway,24+n*3),Color("#d2bd86"),2)
 if view.intersects(Rect2(-1240,1050,350,300)):
  for at in POSTS:
   var p=at-camera;g.draw_line(p,p-Vector2(0,105),Color("#c0ab7b"),4)
   var wave=sin(g.town_life.clock*1.4)*2
   g.draw_colored_polygon(PackedVector2Array([p+Vector2(1,-100),p+Vector2(28+wave,-98),p+Vector2(28,-45),p+Vector2(13,-34),p+Vector2(1,-44)]),Color("#436e77"))
   g.draw_arc(p+Vector2(14,-74),8,PI,TAU,16,Color("#f2d99c"),3)
