extends RefCounted
## A six-lab campus, with a central entrance and clear reserved lot.
const ENTRY=Vector2(-420,1420)
const WALL=Rect2(-680,1110,520,285)
var font:Font=preload("res://assets/fonts/CrossroadsUI.ttf")
func blocked(point:Vector2)->bool:return WALL.grow(12).has_point(point)
func interact(g:Node)->bool:
 if g.position_in_world.distance_to(ENTRY)>80:return false
 g.hint="E • Crossroads Studio • six labs • create, test and share"
 if Input.is_action_just_pressed("interact"):g.hero_workshop.open()
 return true
func draw_on(g:Node2D,camera:Vector2)->void:
 if not Rect2(Vector2.ZERO,g.VIEW).grow(120).intersects(Rect2(WALL.position-camera-Vector2(0,90),WALL.size+Vector2(0,150))):return
 var p=WALL.position-camera
 g.draw_rect(Rect2(p+Vector2(-12,268),Vector2(544,46)),Color("#9f9476"))
 for y in 4:g.draw_line(p+Vector2(-6,280+y*9),p+Vector2(526,280+y*9),Color("#cdc29f"),2)
 g.draw_rect(Rect2(p+Vector2(6,28),Vector2(508,250)),Color("#9ba8a6"));g.draw_rect(Rect2(p+Vector2(166,0),Vector2(188,280)),Color("#c5c7b8"))
 for x in [0,434]:
  g.draw_rect(Rect2(p+Vector2(x,-12),Vector2(86,290)),Color("#899c9d"))
  g.draw_colored_polygon(PackedVector2Array([p+Vector2(x-8,-12),p+Vector2(x+43,-88),p+Vector2(x+94,-12)]),Color("#426478"))
  g.draw_line(p+Vector2(x-8,-12),p+Vector2(x+43,-88),Color("#a5c1c0"),4)
  g.draw_circle(p+Vector2(x+43,-34),13,Color("#a2dee0"));g.draw_arc(p+Vector2(x+43,-34),16,0,TAU,20,Color("#e8d29a"),2)
 for y in [48,130]:
  for x in [24,106,370,452]:
   g.draw_rect(Rect2(p+Vector2(x,y),Vector2(44,57)),Color("#324d5d"));g.draw_rect(Rect2(p+Vector2(x+4,y+4),Vector2(36,48)),Color("#8ccbd0"));g.draw_line(p+Vector2(x+22,y+4),p+Vector2(x+22,y+51),Color("#ded3b6"),3)
 for x in [172,338]:g.draw_rect(Rect2(p+Vector2(x,82),Vector2(10,198)),Color("#e0d7be"))
 g.draw_colored_polygon(PackedVector2Array([p+Vector2(151,20),p+Vector2(260,-49),p+Vector2(369,20)]),Color("#426478"))
 g.draw_rect(Rect2(p+Vector2(192,56),Vector2(136,43)),Color("#243f50"));g.draw_string(font,p+Vector2(197,76),"CROSSROADS",HORIZONTAL_ALIGNMENT_CENTER,126,17,Color("#f1d798"));g.draw_string(font,p+Vector2(197,94),"STUDIO",HORIZONTAL_ALIGNMENT_CENTER,126,14,Color("#d8eeea"))
 for n in 3:
  var x=200+n*44;g.draw_rect(Rect2(p+Vector2(x,113),Vector2(32,54)),Color("#49677a"));g.draw_rect(Rect2(p+Vector2(x+4,118),Vector2(24,42)),Color("#9fd4d7"))
 g.draw_rect(Rect2(p+Vector2(226,190),Vector2(68,90)),Color("#324654"));g.draw_rect(Rect2(p+Vector2(232,195),Vector2(56,84)),Color("#6b8b95"));g.draw_line(p+Vector2(260,196),p+Vector2(260,279),Color("#d7c599"),3)
 for x in [212,302]:g.draw_circle(p+Vector2(x,214),5,Color("#efd691"))
 var entry=ENTRY-camera;g.draw_rect(Rect2(entry-Vector2(52,20),Vector2(104,40)),Color(.5,.85,.9,.16))
 if g.position_in_world.distance_to(ENTRY)<80:g.draw_arc(entry,32,0,TAU,24,Color("#ffe39e"),2)
