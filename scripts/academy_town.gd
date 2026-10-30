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
func draw_structure_source(g:Node2D,camera:Vector2)->void:
 preload("res://scripts/town_landmarks241.gd").draw(g,"academy",camera)

func draw_on(g:Node2D,camera:Vector2)->void:
 if not Rect2(camera,g.VIEW).grow(150).intersects(WALL.grow(100)):return
 preload("res://scripts/town_art39.gd").draw(g,"academy",camera)
 var p:Vector2=WALL.position-camera
 var e:Vector2=ENTRY-camera;var near:bool=g.position_in_world.distance_to(ENTRY)<85
 g.draw_rect(Rect2(e-Vector2(56,23),Vector2(112,46)),Color(.65,.84,.84,.23 if near else .08));g.draw_rect(Rect2(e-Vector2(56,23),Vector2(112,46)),Color("#d9c48b"),false,2)
 g.draw_string(font,e+Vector2(-50,7),"E • ENTER" if allowed() else "LOCKED",HORIZONTAL_ALIGNMENT_CENTER,100,15,Color("#f1dfb3"))
 if not allowed():
  var lock:Vector2=p+Vector2(190,185);g.draw_arc(lock-Vector2(0,4),7,PI,TAU,12,Color("#dfbc73"),3,true);g.draw_rect(Rect2(lock-Vector2(9,2),Vector2(18,14)),Color("#dfbc73"))
