extends RefCounted
## The public Studio remains free. This doorway gates curriculum access only.
const ENTRY=Vector2(-1000,2080)
const WALL=Rect2(-1190,1750,380,260)
var font:Font=preload("res://assets/fonts/CrossroadsUI.ttf")
static func allowed()->bool:
 var access=preload("res://scripts/education_access.gd").state()
 var dev=preload("res://scripts/profile_store.gd").dev_session()
 return bool(access.student) or bool(access.teacher) or (dev!=null and dev.active)
func blocked(p:Vector2)->bool:return WALL.grow(10).has_point(p)
func interact(g:Node)->bool:
 if g.position_in_world.distance_to(ENTRY)>85:return false
 g.hint="E • Crossroads Academy"+(" • enter classroom" if allowed() else " • door locked")
 if Input.is_action_just_pressed("interact"):
  if allowed():g.hero_workshop.open(true)
  else:g.message="The Academy door is locked. Education access is required; speak to the Elder Ram. Crossroads Studio is open to everyone.";g.message_time=6
 return true
func draw_on(g:Node2D,camera:Vector2)->void:
 if not Rect2(camera,g.VIEW).grow(150).intersects(WALL.grow(100)):return
 var p:Vector2=WALL.position-camera
 g.draw_rect(Rect2(p+Vector2(-15,240),Vector2(410,30)),Color(0,0,0,.18))
 g.draw_rect(Rect2(p,WALL.size),Color("#cabd9d"))
 for y in 12:
  for x in 12:
   var left:float=x*32+(16 if y%2 else 0)
   if left+30<380:g.draw_rect(Rect2(p+Vector2(left,y*21),Vector2(30,19)),Color("#d8ccb0") if y%3 else Color("#c0b08e"))
 g.draw_colored_polygon(PackedVector2Array([p+Vector2(-24,8),p+Vector2(190,-85),p+Vector2(404,8)]),Color("#496477"))
 g.draw_line(p+Vector2(-24,8),p+Vector2(190,-85),Color("#a8bbb8"),5);g.draw_line(p+Vector2(190,-85),p+Vector2(404,8),Color("#a8bbb8"),5)
 for x in [30,92,244,306]:
  g.draw_rect(Rect2(p+Vector2(x,98),Vector2(44,72)),Color("#344e59"));g.draw_rect(Rect2(p+Vector2(x+4,102),Vector2(36,64)),Color("#96cbd0"))
  g.draw_line(p+Vector2(x+22,102),p+Vector2(x+22,166),Color("#eddfb9"),3);g.draw_line(p+Vector2(x+4,130),p+Vector2(x+40,130),Color("#eddfb9"),3)
 # Formal columns, double doors, academy crest and broad steps.
 for x in [142,224]:g.draw_rect(Rect2(p+Vector2(x,102),Vector2(14,158)),Color("#eee2c3"));g.draw_rect(Rect2(p+Vector2(x-4,99),Vector2(22,9)),Color("#b7a680"))
 g.draw_rect(Rect2(p+Vector2(158,122),Vector2(64,138)),Color("#496471"));g.draw_line(p+Vector2(190,126),p+Vector2(190,254),Color("#d5c297"),3)
 for x in [183,198]:g.draw_circle(p+Vector2(x,208),3,Color("#f0d086"))
 for n in 4:g.draw_rect(Rect2(p+Vector2(132-n*7,260+n*8),Vector2(116+n*14,8)),Color("#b4ab91") if n%2 else Color("#d3c6a7"))
 g.draw_rect(Rect2(p+Vector2(25,29),Vector2(330,39)),Color("#203e4c"));g.draw_rect(Rect2(p+Vector2(25,29),Vector2(330,39)),Color("#d5bb7b"),false,2)
 g.draw_string(font,p+Vector2(30,55),"CROSSROADS ACADEMY",HORIZONTAL_ALIGNMENT_CENTER,320,20,Color("#f2dca5"))
 var crest:Vector2=p+Vector2(190,-16)
 g.draw_circle(crest,23,Color("#d8bb78"));g.draw_arc(crest+Vector2(-8,0),10,PI*.5,TAU,16,Color("#3b5668"),4,true);g.draw_arc(crest+Vector2(8,0),10,PI,TAU+PI*.5,16,Color("#3b5668"),4,true)
 var e:Vector2=ENTRY-camera;var near:bool=g.position_in_world.distance_to(ENTRY)<85
 g.draw_rect(Rect2(e-Vector2(56,23),Vector2(112,46)),Color(.65,.84,.84,.23 if near else .08));g.draw_rect(Rect2(e-Vector2(56,23),Vector2(112,46)),Color("#d9c48b"),false,2)
 g.draw_string(font,e+Vector2(-50,7),"E • ENTER" if allowed() else "LOCKED",HORIZONTAL_ALIGNMENT_CENTER,100,15,Color("#f1dfb3"))
 if not allowed():
  var lock:Vector2=p+Vector2(190,185);g.draw_arc(lock-Vector2(0,4),7,PI,TAU,12,Color("#dfbc73"),3,true);g.draw_rect(Rect2(lock-Vector2(9,2),Vector2(18,14)),Color("#dfbc73"))
